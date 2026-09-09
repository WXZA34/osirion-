import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../core/utils/relic_translator.dart';
import 'package:valerion/features/arena/arena_screen.dart';
import 'package:valerion/features/dojo/dojo_screen.dart';
import 'package:valerion/features/pantheon/pantheon_screen.dart';
import 'package:valerion/features/arsenal/arsenal_screen.dart';
import 'package:valerion/features/laboratory/laboratory_screen.dart';
import 'package:valerion/features/profile/profile_screen.dart';
import 'package:valerion/features/library/library_screen.dart';
import 'package:valerion/features/auth/login_screen.dart';
import 'package:valerion/features/home/models/arc_data.dart';
import 'package:valerion/features/home/widgets/arc_card.dart';
import 'package:valerion/features/home/widgets/daily_pulse.dart';
import 'package:valerion/features/home/widgets/smart_trigger.dart';
import 'package:valerion/features/home/widgets/daily_video_card.dart';
import 'package:valerion/features/home/widgets/dual_balance_widget.dart';
import 'package:valerion/features/home/providers/daily_pulse_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:valerion/core/providers/repository_providers.dart';
import 'package:valerion/core/providers/arc_provider.dart';
import 'package:valerion/core/domain/entities/user_entity.dart';
import 'package:valerion/features/arsenal/models/relic.dart';
import 'package:valerion/core/widgets/avatar_viewer.dart';
import 'package:valerion/core/services/notification_service.dart';
import 'package:in_app_update/in_app_update.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  String _activeTab = 'dashboard';
  int _pantheonInitialTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ArcData get _currentArc => ref.watch(arcProvider);
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureProfileExists();
    _checkForUpdate();
    _initNotifications();
    
    // Traiter une éventuelle notification qui a lancé l'app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialPayload = NotificationService.consumeInitialPayload();
      if (initialPayload != null) {
        debugPrint("🚀 [HomeScreen] Notification initiale détectée au démarrage !");
        _handleNotificationNavigation(initialPayload);
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint("Erreur in_app_update: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Rafraîchir les quêtes du jour au retour sur l'app (changement de jour possible en tâche de fond)
      ref.read(dailyPulseProvider.notifier).refreshQuests();
    }
  }

  void _initNotifications() {
    // Écouter les clics sur notifications pour la navigation
    _notificationSubscription = NotificationService.onNotificationClick.listen((payload) {
      _handleNotificationNavigation(payload);
    });

    // Mettre à jour le token et programmer les motivations
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        final repository = ref.read(valerionRepositoryProvider);
        await NotificationService.updateUserToken(user.id, repository);
        await NotificationService.scheduleDailyMotivations();
        
        // SÉCURITÉ : Forcer l'abonnement au sujet de motivation de l'Arc actuel
        final currentArc = ref.read(arcProvider);
        await NotificationService.subscribeToArc(currentArc.title);
      }
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> payload) {
    debugPrint("🚀 [HomeScreen] Traitement du clic notification. Payload: $payload");
    
    if (!payload.containsKey('type')) {
      debugPrint("⚠️ [HomeScreen] Payload invalide : clé 'type' manquante.");
      return;
    }
    
    final String type = payload['type'].toString();

    setState(() {
      switch (type) {
        case 'home':
        case 'journal':
          _activeTab = 'dashboard';
          break;
        case 'chat':
          debugPrint("💬 [HomeScreen] Type CHAT détecté.");
          _activeTab = 'clans';
          _pantheonInitialTab = 0; // Connect (Chats)
          if (payload.containsKey('friendId') || 
              payload.containsKey('clanId') || 
              payload.containsKey('senderId')) {
            _navigateToChat(payload);
          }
          break;
        case 'clan_request':
          debugPrint("🛡️ [HomeScreen] Type CLAN_REQUEST détecté.");
          _activeTab = 'clans';
          _pantheonInitialTab = 1; // Onglet Clans
          break;
        case 'friend_request':
          debugPrint("🤝 [HomeScreen] Type FRIEND_REQUEST détecté.");
          _activeTab = 'clans';
          _pantheonInitialTab = 0; // Onglet Connect
          break;
        case 'pantheon':
          _activeTab = 'clans';
          _pantheonInitialTab = 0;
          break;
        case 'arena':
          _activeTab = 'maps';
          break;
        case 'dojo':
          _activeTab = 'exercises';
          break;
        default:
          debugPrint("❓ [HomeScreen] Type de notification inconnu : $type");
      }
    });
  }

  void _navigateToChat(Map<String, dynamic> payload) {
    // On attend que le changement d'onglet (setState) soit effectif
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final String? friendId = (payload['friendId'] ?? payload['senderId'])?.toString();
      final String? clanId = payload['clanId']?.toString();
      final String chatName = payload['chatName']?.toString() ?? (friendId != null ? "Ami Alpha" : "Clan Alpha");

      debugPrint("🧭 [HomeScreen] Navigation vers PantheonChatScreen (friendId: $friendId, clanId: $clanId)");

      // Petit délai supplémentaire pour s'assurer que le Navigator est prêt
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PantheonChatScreen(
            chatName: chatName,
            friendId: friendId,
            clanId: clanId,
            surfaceColor: _currentArc.surfaceColor,
            accentColor: _currentArc.primaryColor,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _ensureProfileExists() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser != null) {
      await ref.read(valerionRepositoryProvider).ensureProfileExists(authUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(arcTransitionProvider);
    final int unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF020617),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: _currentArc.arcType == AlphaArc.summer
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEA580C), Color(0xFFFACC15)],
                )
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentArc.primaryColor.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentArc.secondaryColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [_buildHeader(), Expanded(child: _buildMainContent())],
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildBottomNavigation(unreadCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = userProfileAsync.valueOrNull;
    final String shortUid = user != null ? user.id.substring(0, 6).toUpperCase() : "----";
    final Relic? activeTitle = Relic.findById(user?.activeTitle);
    final Relic? activeHalo = Relic.findById(user?.activeHalo);
    final Color avatarBorderColor = activeHalo?.color ?? _currentArc.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Logo / Menu
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _currentArc.arcType == AlphaArc.summer ? Colors.white : Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      if (_currentArc.arcType == AlphaArc.summer)
                        BoxShadow(
                          color: _currentArc.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Icon(
                    _currentArc.arcType == AlphaArc.summer ? Icons.wb_sunny : Icons.menu,
                    color: _currentArc.arcType == AlphaArc.summer ? _currentArc.primaryColor : Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentArc.arcType == AlphaArc.summer ? "OSIRION" : (activeTitle?.getLocalizedName(context).toUpperCase() ?? "OSIRION"),
                    style: TextStyle(
                      color: _currentArc.arcType == AlphaArc.summer ? Colors.white : (activeTitle?.color ?? Colors.white),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 18,
                    ),
                  ),
                  if (activeTitle != null)
                    Text(
                      activeTitle.name,
                      style: TextStyle(
                        color: activeTitle.color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    )
                  else
                    Text(
                      _currentArc.arcType == AlphaArc.summer ? "SUMMER BODY ARC" : "UID: $shortUid",
                      style: TextStyle(
                        color: _currentArc.arcType == AlphaArc.summer ? Colors.white.withValues(alpha: 0.8) : _currentArc.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Bell Icon (Maquette) or Avatar
          AvatarViewer(
            imageUrl: user?.profileImageUrl,
            radius: 25,
            borderColor: (_currentArc.arcType == AlphaArc.summer ? Colors.white : avatarBorderColor).withValues(alpha: 0.5),
            borderWidth: 2,
            boxShadow: [
              if (activeHalo != null)
                BoxShadow(color: activeHalo.color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return IndexedStack(
      index: _getTabIndex(_activeTab),
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
          child: _buildDashboardContent(),
        ),
        const DojoScreen(),
        PantheonScreen(
          key: ValueKey('pantheon_$_pantheonInitialTab'),
          initialTabIndex: _pantheonInitialTab,
        ),
        const ArenaScreen(),
      ],
    );
  }

  int _getTabIndex(String tab) {
    switch (tab) {
      case 'dashboard': return 0;
      case 'exercises': return 1;
      case 'clans': return 2;
      case 'maps': return 3;
      default: return 0;
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArcCard(arc: _currentArc),
        const DailyVideoCard(),
        const SizedBox(height: 24),
        const _UserXpBalanceCard(),
        const SizedBox(height: 24),
        DailyPulse(themeColor: _currentArc.primaryColor),
        const SizedBox(height: 24),
        SmartTrigger(onNavigate: (tab) => setState(() => _activeTab = tab)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBottomNavigation(int unreadCount) {
    final bool isSummer = _currentArc.arcType == AlphaArc.summer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _currentArc.surfaceColor.withValues(alpha: isSummer ? 1.0 : 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isSummer ? Colors.white24 : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (isSummer)
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('dashboard', Icons.grid_view_rounded, "Hub", unreadCount),
          _buildNavItem('exercises', Icons.fitness_center_rounded, "Dojo", unreadCount),
          _buildNavItem('clans', Icons.groups_rounded, "Clans", unreadCount),
          _buildNavItem('maps', Icons.map_rounded, "Arena", unreadCount),
        ],
      ),
    );
  }

  Widget _buildNavItem(String tab, IconData icon, String label, int unreadCount) {
    final bool isActive = _activeTab == tab;
    final bool isSummer = _currentArc.arcType == AlphaArc.summer;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? (_currentArc.arcType == AlphaArc.summer ? _currentArc.onSurfaceColor.withValues(alpha: 0.15) : _currentArc.primaryColor.withValues(alpha: 0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isActive && _currentArc.arcType == AlphaArc.summer)
              BoxShadow(color: _currentArc.onSurfaceColor.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive 
                      ? (_currentArc.arcType == AlphaArc.summer ? const Color(0xFFEA580C) : _currentArc.primaryColor)
                      : (isSummer ? _currentArc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.5)),
                  size: 24,
                ),
                if (tab == 'clans' && unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSummer ? _currentArc.onSurfaceColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(30))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.homeMenuAlpha, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -1)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDrawerItem(context, Icons.menu_book, AppLocalizations.of(context)!.localeName == "en" ? "The Library" : "La Bibliothèque", LibraryScreen()),
                      const SizedBox(height: 16),
                      _buildDrawerItem(context, Icons.person, AppLocalizations.of(context)!.localeName == "en" ? "The Sanctuary" : "Le Sanctuaire", ProfileScreen()),
                      const SizedBox(height: 16),
                      _buildDrawerItem(context, Icons.bar_chart, AppLocalizations.of(context)!.localeName == "en" ? "The Pantheon" : "Le Panthéon", PantheonScreen()),
                      const SizedBox(height: 16),
                      _buildDrawerItem(context, Icons.security, AppLocalizations.of(context)!.localeName == "en" ? "The Arsenal" : "L'Arsenal", ArsenalScreen()),
                      const SizedBox(height: 16),
                      _buildDrawerItem(context, Icons.settings, AppLocalizations.of(context)!.localeName == "en" ? "The Laboratory" : "Le Laboratoire", LaboratoryScreen()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authRepositoryProvider).signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent[400], size: 20),
                      const SizedBox(width: 12),
                      Text(AppLocalizations.of(context)!.homeQuitterLaSession, style: TextStyle(color: Colors.redAccent[400], fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: Colors.cyan[400], size: 24),
            const SizedBox(width: 16),
            Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _UserXpBalanceCard extends ConsumerWidget {
  const _UserXpBalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    UserEntity? user = userProfileAsync.valueOrNull;
    int forceVal = user?.forceXp ?? 0;
    int wisdomVal = user?.wisdomXp ?? 0;
    int totalXp = forceVal + wisdomVal;
    double forceRatio = totalXp > 0 ? forceVal.toDouble() / totalXp.toDouble() : 0.0;
    double wisdomRatio = totalXp > 0 ? wisdomVal.toDouble() / totalXp.toDouble() : 0.0;
    final arc = ref.watch(arcProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: arc.surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: arc.arcType == AlphaArc.summer ? Colors.black12 : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.balance, color: arc.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.homeBalanceDesForces, style: TextStyle(color: arc.onSurfaceColor.withValues(alpha: 0.6), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          DualBalanceWidget(
            forcePercentage: forceRatio,
            wisdomPercentage: wisdomRatio,
            forceColor: const Color(0xFF38BDF8),
            wisdomColor: arc.primaryColor,
            wisdomLabel: arc.wisdomLabel,
          ),
        ],
      ),
    );
  }
}
