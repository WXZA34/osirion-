import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valerion/firebase_options.dart';
import 'package:valerion/core/theme/app_theme.dart';
import 'package:valerion/core/navigation/main_navigation_shell.dart';
import 'package:valerion/features/auth/welcome_screen.dart';
import 'package:valerion/features/auth/onboarding/language_selection_screen.dart';
import 'package:valerion/features/splash/animated_splash_screen.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/core/providers/locale_provider.dart';
import 'package:valerion/l10n/app_localizations.dart';
import 'package:valerion/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Settings;
import 'package:valerion/core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialiser le token Mapbox (Nécessaire avant de charger un MapWidget)
  MapboxOptions.setAccessToken(AppConstants.mapboxAccessToken);

  // 2. Initialiser Firebase sans bloquer l'interface si possible (nécessaire pour ProviderScope)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



  // 3. Initialisations secondaires en arrière-plan (Après le premier frame)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!kDebugMode) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }

    // Configuration Firestore
    firestore.FirebaseFirestore.instance.settings = firestore.Settings(
      persistenceEnabled: true,
      cacheSizeBytes: firestore.Settings.CACHE_SIZE_UNLIMITED,
    );

    // Notifications
    NotificationService.initialize();
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // 4. Supprimer les logs pour les exceptions d'images réseau (ex: URL Avatar 401)
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      final exceptionStr = details.exceptionAsString();
      if (exceptionStr.contains('NetworkImageLoadException') || 
          exceptionStr.contains('statusCode: 401')) {
        return;
      }
      debugPrint("🛠️ [FlutterError] ${details.exception}");
      debugPrint("📍 Emplacement: ${details.library}");
    }
    if (originalOnError != null) originalOnError(details);
  };

  // Les erreurs asynchrones d'ImageStream échappent parfois à FlutterError
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    
    // Ignorer les erreurs d'image connues (401, etc.)
    if (errorStr.contains('NetworkImageLoadException') || errorStr.contains('401')) {
      return true;
    }

    if (kDebugMode) {
      debugPrint("🚨 [AsyncError] Type: ${error.runtimeType}");
      debugPrint("📝 Message: $error");
      if (errorStr.contains('TimeoutException')) {
        debugPrint("⏳ Alerte : Une opération Firebase a dépassé le délai de 10s.");
      }
    }
    return false;
  };

  runApp(const ProviderScope(child: OsirionApp()));

  // 4. Initialisations secondaires en arrière-plan
  _deferredInitialization();
}

Future<void> _deferredInitialization() async {
  try {
    // Mettre à jour le token et programmer les motivations (déjà fait en partie dans initialize mais bon de garder ici pour rafraîchir)
    debugPrint("✅ Background initializations complete.");
  } catch (e) {
    debugPrint("⚠️ Partial initialization failure: $e");
  }
}

class OsirionApp extends ConsumerWidget {
  const OsirionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'OSIRION',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.winterTheme,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // English
      ],
      home: const AnimatedSplashScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainNavigationShell();
        } else {
          return const OnboardingChecker();
        }
      },
      loading:
          () => const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      error:
          (e, trace) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Erreur d'authentification : $e",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
    );
  }
}

class OnboardingChecker extends StatefulWidget {
  const OnboardingChecker({super.key});

  @override
  State<OnboardingChecker> createState() => _OnboardingCheckerState();
}

class _OnboardingCheckerState extends State<OnboardingChecker> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_onboardingCompleted) {
      return const WelcomeScreen();
    } else {
      return const LanguageSelectionScreen();
    }
  }
}
