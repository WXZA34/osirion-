import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../domain/repositories/valerion_repository.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream pour notifier l'UI des clics sur notifications
  static final StreamController<Map<String, dynamic>> _onNotificationClick =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onNotificationClick =>
      _onNotificationClick.stream;

  // Stockage temporaire pour le message initial si l'UI n'est pas encore prête
  static Map<String, dynamic>? _initialPayload;
  static Map<String, dynamic>? consumeInitialPayload() {
    final data = _initialPayload;
    _initialPayload = null;
    return data;
  }

  static Future<void> initialize() async {
    // 0. Pour Android 13+, demander explicitement la permission via permission_handler
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       final status = await Permission.notification.request();
       if (kDebugMode) {
         debugPrint('🔔 [Notifications] Statut permission Android 13+: $status');
       }
    }

    // 1. Demander les permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('🔔 [Notifications] Firebase Permission Status: ${settings.authorizationStatus}');
    }

    // 2. Initialiser les notifications locales pour le premier plan
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            debugPrint("🔔 [NotificationService] Clic sur notification locale. Payload: ${response.payload}");
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            if (_onNotificationClick.hasListener) {
              _onNotificationClick.add(data);
            } else {
              _initialPayload = data;
            }
          } catch (e) {
            debugPrint("❌ Erreur décodage payload notification : $e");
          }
        }
      },
    );

    // Initialiser les fuseaux horaires pour le scheduling
    tz.initializeTimeZones();

    // 3. Configurer les canaux Android (nécessaire pour Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications OSIRION',
      description:
          'Ce canal est utilisé pour les alertes critiques de l\'application.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 4. ÉCOUTEURS

    // Premier plan (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔔 [NotificationService] onMessageOpenedApp déclenché ! Data: ${message.data}");
      if (_onNotificationClick.hasListener) {
        _onNotificationClick.add(message.data);
      } else {
        _initialPayload = message.data;
      }
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🔔 [NotificationService] getInitialMessage trouvé ! Data: ${initialMessage.data}");
      if (_onNotificationClick.hasListener) {
        _onNotificationClick.add(initialMessage.data);
      } else {
        _initialPayload = initialMessage.data;
      }
    }

    // 5. Fin initialisation
    if (kDebugMode) {
      debugPrint('🔔 Service de Notifications initialisé.');
    }

    // Souscription automatique au Topic global pour les messages système (Non-bloquant)
    _messaging.subscribeToTopic('all_users').then((_) {
      if (kDebugMode) {
        debugPrint('📡 [Notifications] Souscrit au topic all_users');
      }
    }).catchError((e) {
      debugPrint('❌ [Notifications] Erreur souscription topic: $e');
    });
  }

  /// Met à jour le token FCM de l'utilisateur dans Firestore
  static Future<void> updateUserToken(
    String uid,
    IValerionRepository repository,
  ) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await repository.saveFcmToken(uid, token);
      }
    } catch (e) {
      debugPrint("❌ Erreur updateUserToken : $e");
    }
  }

  /// SÉCURITÉ & SCALABILITÉ : Souscription aux Topics de Clan
  static Future<void> subscribeToClan(String clanId) async {
    try {
      await _messaging.subscribeToTopic('clan_$clanId');
      debugPrint("📡 [FCM] Souscrit au topic clan_$clanId");
    } catch (e) {
      debugPrint("❌ [FCM] Erreur souscription clan_$clanId : $e");
    }
  }

  static Future<void> unsubscribeFromClan(String clanId) async {
    try {
      await _messaging.unsubscribeFromTopic('clan_$clanId');
      debugPrint("📡 [FCM] Désinscrit du topic clan_$clanId");
    } catch (e) {
      debugPrint("❌ [FCM] Erreur désinscription clan_$clanId : $e");
    }
  }

  /// SÉCURITÉ & SCALABILITÉ : Souscription aux Topics d'Arc (Motivation segmentée)
  static Future<void> subscribeToArc(String arcId) async {
    try {
      // Normalisation de l'ID pour le topic (ex: "winter_arc")
      final topicId = arcId.toLowerCase().replaceAll(' ', '_');
      await _messaging.subscribeToTopic('motivation_$topicId');
      debugPrint("📡 [FCM] Souscrit au topic motivation_$topicId");
    } catch (e) {
      debugPrint("❌ [FCM] Erreur souscription motivation topic : $e");
    }
  }

  static Future<void> unsubscribeFromArc(String arcId) async {
    try {
      final topicId = arcId.toLowerCase().replaceAll(' ', '_');
      await _messaging.unsubscribeFromTopic('motivation_$topicId');
      debugPrint("📡 [FCM] Désinscrit du topic motivation_$topicId");
    } catch (e) {
      debugPrint("❌ [FCM] Erreur désinscription motivation topic : $e");
    }
  }

  /// Programme des rappels sportifs quotidiens
  static Future<void> scheduleDailyMotivations() async {
    const androidDetails = AndroidNotificationDetails(
      'fitness_reminders',
      'Coach Alpha',
      channelDescription: 'Rappels quotidiens pour rester en forme.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Annuler les anciennes pour éviter les doublons
    await _localNotifications.cancelAll();

    // Motivation du Matin (08:00)
    await _scheduleNotification(
      id: 100,
      title: "Activation Alpha ⚡",
      body: "Le Panthéon n'attend pas. Prêt pour ta première quête ?",
      hour: 8,
      minute: 0,
      details: notificationDetails,
      payload: '{"type": "home"}',
    );

    // Motivation du Soir (18:30)
    await _scheduleNotification(
      id: 101,
      title: "Bilan Énergétique 🛡️",
      body: "N'oublie pas de valider tes exploits du jour dans ton journal.",
      hour: 18,
      minute: 30,
      details: notificationDetails,
      payload: '{"type": "journal"}',
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

}

// Fonction obligatoire pour le traitement en arrière-plan (Top-level pour accès natif fiable)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint("Handling a background message: ${message.messageId}");
  }
}
