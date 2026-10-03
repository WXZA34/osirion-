import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../domain/repositories/valerion_repository.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:math' as math;
import '../../features/home/models/arc_data.dart';

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
    // Note: Les permissions ne sont plus demandées automatiquement au démarrage
    // pour éviter le crash "Permission controller isn't responding".
    // Appelez requestPermissions() plus tard dans le cycle de vie.

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
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      debugPrint("❌ [Notifications] Impossible de détecter le fuseau horaire: $e");
    }

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

  /// Demander explicitement les permissions de notification
  static Future<void> requestPermissions() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       // Demande de permission pour afficher des notifications (Android 13+)
       final status = await Permission.notification.request();
       
       // Demande de permission pour les alarmes exactes (Android 14+ pour scheduled notifications)
       if (await Permission.scheduleExactAlarm.isDenied) {
         await Permission.scheduleExactAlarm.request();
       }

       if (kDebugMode) {
         debugPrint('🔔 [Notifications] Statut permission Android 13+: $status');
       }
    }

    // 1. Demander les permissions Firebase
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('🔔 [Notifications] Firebase Permission Status: ${settings.authorizationStatus}');
    }
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

  static List<Map<String, String>> _getMorningQuotes(AlphaArc arc) {
    switch (arc) {
      case AlphaArc.winter:
        return const [
          {"title": "L'Aube du Guerrier ⚔️", "body": "Le Panthéon n'attendra pas. Debout, et forge ta légende aujourd'hui."},
          {"title": "Dans l'Ombre 🌑", "body": "Il fait froid, il fait sombre. C'est le moment parfait pour t'entraîner."},
          {"title": "La Voie de la Force 🌪️", "body": "La discipline bâtit des empires. Commence le tien aujourd'hui."},
          {"title": "Le Réveil de la Forge 🔥", "body": "Le feu ne s'allume pas tout seul. Lève-toi et frappe le fer."},
          {"title": "Le Serment de l'Hiver ❄️", "body": "Les faibles restent au lit. Les forts conquièrent la journée."},
          {"title": "Silence et Acier ⚔️", "body": "Personne ne te regarde. C'est maintenant que tu deviens grand."},
          {"title": "Activation Alpha ⚡", "body": "Le monde dort encore. C'est l'heure de prendre l'avantage."},
          {"title": "L'Heure Sombre ⏳", "body": "Chaque matin difficile est une victoire de plus sur toi-même."},
          {"title": "Le Sang de l'Hiver 🩸", "body": "Le froid endurcit l'esprit. Lève-toi, ton entraînement t'attend."},
          {"title": "La Forge t'appelle 🔨", "body": "Le marteau doit frapper l'enclume. Ne manque pas ta séance du matin."},
        ];
      case AlphaArc.summer:
        return const [
          {"title": "L'Éclat du Soleil ☀️", "body": "Le jour se lève. Il est temps de rayonner et de montrer tes résultats."},
          {"title": "Énergie Solaire ⚡", "body": "La lumière est là. Sors, entraîne-toi et absorbe la puissance de l'été."},
          {"title": "Le Sang des Anciens 🔥", "body": "Ton corps est un temple. Honore-le en ce jour éclatant."},
          {"title": "L'Heure de Briller ✨", "body": "Le Summer Body ne se maintient pas tout seul. En avant !"},
          {"title": "Guerrier de Lumière ⚔️", "body": "Ne laisse pas la chaleur t'abattre. Elle est ton alliée."},
          {"title": "Chaleur et Sueur 💦", "body": "Transpire aujourd'hui pour rayonner demain."},
          {"title": "L'Appel de l'Extérieur 🏃", "body": "Le monde est ton terrain de jeu. Va conquérir ta journée."},
          {"title": "Rayonnement Alpha 👑", "body": "La discipline est aussi importante en été qu'en hiver. Lève-toi."},
          {"title": "Le Feu de l'Été 🔥", "body": "Alimente la flamme de ta motivation. L'entraînement n'attend pas."},
          {"title": "Aube Estivale 🌅", "body": "Chaque lever de soleil est une nouvelle chance d'être meilleur."},
        ];
      case AlphaArc.royal:
        return const [
          {"title": "L'Éveil du Roi 👑", "body": "Le trône t'attend. Mais d'abord, tu dois prouver que tu en es digne."},
          {"title": "Souveraineté ⚖️", "body": "Un vrai leader maîtrise d'abord son propre corps. Lève-toi."},
          {"title": "L'Empire Alpha 🏛️", "body": "Chaque répétition est une brique de plus à ton empire."},
          {"title": "Appel aux Armes 🛡️", "body": "Les Dieux te regardent. Prouve-leur ta noblesse dès ce matin."},
          {"title": "Le Sang Royal 🩸", "body": "Tu n'es pas né pour être moyen. Réveille ta grandeur."},
          {"title": "La Couronne Lourde 👑", "body": "Assumer le pouvoir demande de la discipline. Ton entraînement t'attend."},
          {"title": "Majesté et Force ⚔️", "body": "Le respect ne s'achète pas, il se gagne à la sueur de ton front."},
          {"title": "L'Aube de l'Empereur 🌅", "body": "Le monde est à toi, si tu es prêt à le prendre aujourd'hui."},
          {"title": "Le Rituel du Sacre 📜", "body": "Ta discipline matinale est ton couronnement quotidien."},
          {"title": "Volonté Inébranlable 🛡️", "body": "Un roi ne trouve pas d'excuses. Il trouve des solutions. Lève-toi."},
        ];
    }
  }

  static List<Map<String, String>> _getEveningQuotes(AlphaArc arc) {
    switch (arc) {
      case AlphaArc.winter:
        return const [
          {"title": "Le Silence de la Forge 🌑", "body": "Le marteau se tait. Il est temps de contempler l'acier forgé aujourd'hui."},
          {"title": "Le Froid de la Nuit ❄️", "body": "Tu as survécu à un jour de plus. Valide tes exploits dans ton journal."},
          {"title": "Le Bilan du Sang 🩸", "body": "Les batailles du jour sont terminées. Inscris tes victoires."},
          {"title": "Le Repos du Guerrier 🏕️", "body": "Avant de fermer les yeux, consigne tes échecs et tes succès."},
          {"title": "Les Braises S'Éteignent 🔥", "body": "La forge se repose. N'oublie pas de noter tes statistiques."},
          {"title": "Ombre et Discipline 🐺", "body": "Tu as travaillé dans l'ombre. Maintenant, garde une trace de tes progrès."},
          {"title": "La Fin de la Garde 🛡️", "body": "Ton tour de garde est terminé. Remplis ton journal d'entraînement."},
          {"title": "Bilan Énergétique ⚔️", "body": "L'hiver est dur, mais tu l'es encore plus. Valide tes entraînements."},
          {"title": "Héritage Quotidien ⏳", "body": "Qu'as-tu accompli sous le regard des Anciens aujourd'hui ?"},
          {"title": "L'Heure des Comptes ⚖️", "body": "As-tu été digne du Panthéon ? Mets ton journal à jour avant de dormir."},
        ];
      case AlphaArc.summer:
        return const [
          {"title": "Le Crépuscule 🌅", "body": "Le soleil se couche sur tes efforts. Valide tes statistiques du jour."},
          {"title": "Chaleur Retombante 🌙", "body": "La journée a été intense. C'est l'heure de faire le point."},
          {"title": "Bilan Estival ☀️", "body": "As-tu rayonné aujourd'hui ? Inscris tes exploits dans le journal."},
          {"title": "Le Repos de la Lumière ✨", "body": "Même le soleil doit se reposer. N'oublie pas de valider ton sport."},
          {"title": "L'Éclat du Soir 🌇", "body": "Termine ta journée sur une victoire. Remplis ton journal."},
          {"title": "Sueur Séchée 💧", "body": "Tu as tout donné. Laisse une trace de tes efforts dans ton carnet."},
          {"title": "La Fin de l'Aventure 🏕️", "body": "Une autre journée de conquête s'achève. Fais tes comptes."},
          {"title": "Bilan Énergétique 🛡️", "body": "La lumière décline. C'est le moment de consigner tes succès."},
          {"title": "Mémoire du Soleil 📜", "body": "Garde en mémoire les efforts fournis sous le soleil d'aujourd'hui."},
          {"title": "L'Heure du Repos 🌊", "body": "Après l'effort, le réconfort. Mais d'abord, le journal ! "},
        ];
      case AlphaArc.royal:
        return const [
          {"title": "Le Coucher du Roi 👑", "body": "Le royaume est en paix. Valide tes exploits de la journée."},
          {"title": "Chroniques d'Osirion 📜", "body": "Ton histoire s'écrit maintenant. Enregistre tes statistiques du jour."},
          {"title": "L'Heure des Comptes ⚖️", "body": "As-tu régné en maître aujourd'hui ? Remplis ton journal."},
          {"title": "Le Sceptre Posé 🔱", "body": "Ta garde est terminée. Il est temps de faire le bilan de tes forces."},
          {"title": "La Table Ronde 🏰", "body": "Avant le repos, consigne tes actes de bravoure pour la postérité."},
          {"title": "Bilan Royal 🛡️", "body": "Un souverain connaît ses troupes et ses limites. Valide ton entraînement."},
          {"title": "Le Poids de la Couronne 👑", "body": "Tu as assumé tes responsabilités. Note tes progrès avant de dormir."},
          {"title": "Héritage du Trône ⏳", "body": "Ce que tu fais aujourd'hui résonnera demain. Remplis le journal."},
          {"title": "Sagesse Nocturne 🦉", "body": "Réfléchis à tes actions. Inscris tes victoires et tes échecs."},
          {"title": "Majesté Reposée 🌙", "body": "Ton empire peut dormir tranquille. N'oublie pas de valider tes séances."},
        ];
    }
  }

  /// Programme des rappels sportifs quotidiens (sur 7 jours pour la variété)
  static Future<void> scheduleDailyMotivations(AlphaArc currentArc) async {
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

    final random = math.Random();

    final morningList = _getMorningQuotes(currentArc);
    final eveningList = _getEveningQuotes(currentArc);

    // Programmer pour les 7 prochains jours
    for (int i = 0; i < 7; i++) {
      final morningQuote = morningList[random.nextInt(morningList.length)];
      final eveningQuote = eveningList[random.nextInt(eveningList.length)];

      // Motivation du Matin (08:00)
      await _scheduleNotification(
        id: 100 + i,
        title: morningQuote["title"]!,
        body: morningQuote["body"]!,
        hour: 8,
        minute: 0,
        dayOffset: i,
        details: notificationDetails,
        payload: '{"type": "home"}',
      );

      // Motivation du Soir (18:30)
      await _scheduleNotification(
        id: 200 + i,
        title: eveningQuote["title"]!,
        body: eveningQuote["body"]!,
        hour: 18,
        minute: 30,
        dayOffset: i,
        details: notificationDetails,
        payload: '{"type": "journal"}',
      );
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int dayOffset,
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

    // Si on veut programmer pour aujourd'hui mais que l'heure est passée, on passe à demain (offset 0 -> 1)
    if (dayOffset == 0 && scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    } else if (dayOffset > 0) {
      scheduledDate = scheduledDate.add(Duration(days: dayOffset));
    }

    // Le paramètre matchDateTimeComponents est supprimé car on veut une vraie notification unique par jour 
    // qui change au fil du temps (sur les 7 prochains jours)
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
