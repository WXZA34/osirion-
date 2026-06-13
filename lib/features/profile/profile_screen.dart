import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/domain/entities/user_entity.dart';
import '../arsenal/models/relic.dart';
import '../library/models/journal_entry.dart';
import 'widgets/focus_timer.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/avatar_viewer.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _selectedTabIndex = 0; // 0: Évolution, 1: Physique, 2: Esprit, 3: Réglages

  // --- Theme Colors and Arc Data ---
  ArcData get _currentArc => ref.watch(arcProvider);
  bool get _isSummer => _currentArc.arcType == AlphaArc.summer;
  Color get _bgBlack => Colors.transparent; 
  Color get _surfaceDark => _currentArc.surfaceColor;
  Color get _onSurfaceColor => _currentArc.onSurfaceColor;
  Color get _accentWinter => _currentArc.primaryColor;

  bool _isPickingImage = false;

  Future<void> _updateProfileImage(UserEntity user) async {
    if (_isPickingImage) return;

    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload de la photo en cours...')),
      );

      final bytes = await pickedFile.readAsBytes();
      final storageService = ref.read(storageServiceProvider);
      final valerionRepo = ref.read(valerionRepositoryProvider);

      final downloadUrl = await storageService.uploadUserProfileImage(
        user.id,
        bytes,
      );
      final updatedUser = user.copyWith(profileImageUrl: downloadUrl);
      await valerionRepo.saveUserProfile(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil à jour !'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        title: Text(
          "LE SANCTUAIRE",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor : Colors.white,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: _isSummer ? _onSurfaceColor : Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildIdentityHeader(),
          const SizedBox(height: 16),
          _buildTopNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _buildCurrentTabContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _isSummer ? Colors.black12 : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavTab(0, "Évolution"),
          _buildNavTab(1, "Physique"),
          _buildNavTab(2, "Esprit"),
          _buildNavTab(3, "Réglages"),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, String label) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? (_isSummer ? _onSurfaceColor : Colors.white) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected 
                ? (_isSummer ? _onSurfaceColor : Colors.white)
                : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    // Récupération globale pour distribuer aux sous-onglets
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = userProfileAsync.valueOrNull;

    switch (_selectedTabIndex) {
      case 0:
        return _buildEvolutionTab(user);
      case 1:
        return _buildPhysicsTab(user);
      case 2:
        return _buildMindTab(user);
      case 3:
        return _buildSettingsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Header: Identité & Prestige ---
  Widget _buildIdentityHeader() {
    // 1. Lire le profil en temps réel depuis Riverpod + Firestore
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text(
              "Profil introuvable",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final Relic? activeHalo = Relic.findById(user.activeHalo);
        final Relic? activeTitle = Relic.findById(user.activeTitle);
        final Color haloColor = activeHalo?.color ?? _accentWinter;

        return Column(
          children: [
            const SizedBox(height: 10),
            // Avatar avec Aura Dynamique
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AvatarViewer(
                  imageUrl: user.profileImageUrl,
                  radius: 40,
                  borderColor: haloColor.withValues(alpha: 0.5),
                  borderWidth: 2,
                  boxShadow: [
                    BoxShadow(
                      color: haloColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                // Bouton d'édition superposé
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _updateProfileImage(user),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.black, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user.username.toUpperCase(),
              style: TextStyle(
                color: _isSummer ? _onSurfaceColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "RANG : ${activeTitle?.name.toUpperCase() ?? "DISCIPLE"}  •  LVL. ${user.level}",
              style: TextStyle(
                color: activeTitle?.color ?? _accentWinter,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Prestige Global : ${user.xp} XP",
                style: TextStyle(
                  color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      error:
          (e, st) =>
              Text("Erreur: $e", style: const TextStyle(color: Colors.red)),
    );
  }

  // --- Tab 0: Évolution (Jauges & Calendrier) ---
  Widget _buildEvolutionTab(UserEntity? user) {
    // Calculs d'XP
    int forceVal = user?.forceXp ?? 0;
    int wisdomVal = user?.wisdomXp ?? 0;
    int totalXp = forceVal + wisdomVal;

    // Ratios (0.0 à 1.0)
    double forceRatio = totalXp > 0 ? forceVal.toDouble() / totalXp.toDouble() : 0.0;
    double wisdomRatio = totalXp > 0 ? wisdomVal.toDouble() / totalXp.toDouble() : 0.0;

    // Harmonie (Ex: le plus bas / le plus haut) pour évaluer l'équilibre global
    int harmonyPercent = 0;
    if (totalXp > 0) {
      double minRatio = forceRatio < wisdomRatio ? forceRatio : wisdomRatio;
      double maxRatio = forceRatio > wisdomRatio ? forceRatio : wisdomRatio;
      harmonyPercent =
          maxRatio > 0 ? ((minRatio / maxRatio) * 100).toInt() : 100;
    }

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "DUAL-TRACK",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 24),

        // Jauges de Force et Sagesse
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCircularGauge("FORCE", forceRatio),
            Column(
              children: [
                const Icon(Icons.all_inclusive, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  "HARMONIE",
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
                    fontSize: 8,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "$harmonyPercent%",
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            _buildCircularGauge("SAGESSE", wisdomRatio),
          ],
        ),
        const SizedBox(height: 40),

        Text(
          "CALENDRIER DE COHÉRENCE",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        if (user != null) _buildActivityCalendar(user),
      ],
    );
  }

  Widget _buildCircularGauge(String label, double percentage) {
    Color color = label == "FORCE" ? Colors.cyan : Colors.purpleAccent;
    int pseudoLevel = (percentage * 100).toInt(); // Simulation du Lvl
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                backgroundColor: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              "LVL $pseudoLevel",
              style: TextStyle(
                color: _isSummer ? _onSurfaceColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.7) : Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCalendar(UserEntity user) {
    final arc = ref.watch(arcProvider);
    final repo = ref.read(valerionRepositoryProvider);

    return StreamBuilder<Map<String, dynamic>>(
      stream: repo.listenArcActivity(user.id, arc.arcType.name),
      builder: (context, snapshot) {
        final history = snapshot.data ?? {};
        
        // Calcul des jours de l'Arc
        final List<DateTime> arcDays = [];
        DateTime current = arc.startDate;
        while (current.isBefore(arc.endDate) || current.isAtSameMomentAs(arc.endDate)) {
          arcDays.add(current);
          current = current.add(const Duration(days: 1));
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return Container(
          height: 160,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    arc.title,
                    style: TextStyle(
                      color: arc.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "${history.length} / ${arcDays.length} JOURS ACTIFS",
                    style: TextStyle(
                      color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  // On groupe par semaines (7 jours)
                  itemCount: (arcDays.length / 7).ceil(),
                  itemBuilder: (context, weekIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (dayIndex) {
                          int actualDayIndex = (weekIndex * 7) + dayIndex;
                          if (actualDayIndex >= arcDays.length) {
                            return const SizedBox(width: 8, height: 8);
                          }
                          
                          DateTime day = arcDays[actualDayIndex];
                          String dateKey = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                          
                          bool isFuture = day.isAfter(today);
                          bool isToday = day.isAtSameMomentAs(today);
                          var data = history[dateKey];
                          
                          Color dotColor;
                          IconData icon;
                          double size = 8;

                          if (isFuture) {
                            dotColor = _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05);
                            icon = Icons.circle;
                          } else if (data != null) {
                            int done = data['questsDone'] ?? 0;
                            int total = data['totalQuests'] ?? 3;
                            if (done >= total && total > 0) {
                              dotColor = arc.primaryColor;
                            } else if (done > 0) {
                              dotColor = arc.primaryColor.withValues(alpha: 0.5);
                            } else {
                              dotColor = _isSummer ? Colors.black.withValues(alpha: 0.1) : Colors.white10;
                            }
                            icon = Icons.circle;
                          } else {
                            dotColor = isToday ? arc.primaryColor.withValues(alpha: 0.2) : (_isSummer ? Colors.black.withValues(alpha: 0.1) : Colors.white10);
                            icon = Icons.circle;
                          }

                          return Icon(icon, color: dotColor, size: size);
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Tab 1: Physique (Labo & Perf) ---
  Widget _buildPhysicsTab(UserEntity? user) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "LABORATOIRE BIOMÉTRIQUE",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDataCard(
                "Poids",
                user?.weight != null ? user!.weight!.toStringAsFixed(1) : "--",
                "kg",
                Icons.monitor_weight,
                Colors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataCard(
                "Masse Grasse",
                user?.bodyFat != null
                    ? user!.bodyFat!.toStringAsFixed(1)
                    : "--",
                "%",
                Icons.opacity,
                Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDataCard(
                "Muscle",
                user?.muscleMass != null
                    ? user!.muscleMass!.toStringAsFixed(1)
                    : "--",
                "kg",
                Icons.fitness_center,
                Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDataCard(
                "Sommeil",
                "--h--", // Mock (Complexe à traquer sans API Santé, neutralisé temporairement)
                "moy.",
                Icons.bedtime,
                Colors.indigoAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          "REGISTRE : LE DOJO (IA)",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecordRow(
          "Max Pompes (Unbroken)",
          "${user?.maxPushups ?? 0} reps",
        ),
        _buildRecordRow("Max Tractions", "${user?.maxPullups ?? 0} reps"),
        _buildRecordRow(
          "Précision Mouvement",
          "${(user?.movementPrecision ?? 0.0).toStringAsFixed(0)}% (${_getPrecisionGrade(user?.movementPrecision)})",
        ),

        const SizedBox(height: 24),
        Text(
          "GESTION DU SANCTUAIRE",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecordRow(
          "Meilleure Allure (1km)",
          _formatPace(user?.bestPace1km ?? 0.0),
        ),
        _buildRecordRow(
          "Boucle Alpha (6km)",
          _formatDuration(user?.bestAlphaLoop6km ?? 0.0),
        ),
        _buildRecordRow("Distance Totale", "${user?.totalDistance ?? 0.0} km"),
      ],
    );
  }

  String _getPrecisionGrade(double? precision) {
    if (precision == null || precision == 0) return "--";
    if (precision >= 95) return "S";
    if (precision >= 90) return "A";
    if (precision >= 80) return "B";
    if (precision >= 70) return "C";
    return "D";
  }

  String _formatPace(double paceInSeconds) {
    if (paceInSeconds == 0) return "--:-- min/km";
    int minutes = (paceInSeconds / 60).floor();
    int seconds = (paceInSeconds % 60).round();
    return "$minutes:${seconds.toString().padLeft(2, '0')} min/km";
  }

  String _formatDuration(double durationInSeconds) {
    if (durationInSeconds == 0) return "--m --s";
    int minutes = (durationInSeconds / 60).floor();
    int seconds = (durationInSeconds % 60).round();
    if (minutes >= 60) {
      int hours = (minutes / 60).floor();
      minutes = minutes % 60;
      return "${hours}h ${minutes}m ${seconds}s";
    }
    return "${minutes}m ${seconds}s";
  }

  Widget _buildDataCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSummer ? Colors.black.withValues(alpha: 0.1) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _isSummer ? _onSurfaceColor : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.7) : Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Esprit (Codex) ---
  Widget _buildMindTab(UserEntity? user) {
    final arc = ArcData.getCurrentArc();
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "LE CODEX DE L'ESPRIT",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: arc.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: arc.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SÉRIE D'HONNEUR",
                          style: TextStyle(
                            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : arc.primaryColor.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${user == null ? 0 : user.streak}",
                              style: TextStyle(
                                color: _isSummer ? _onSurfaceColor : Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "JOURS CONSÉCUTIFS",
                              style: TextStyle(
                                color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Barre de progression dans l'Arc
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (user?.streak ?? 0) / arc.endDate.difference(arc.startDate).inDays,
                  backgroundColor: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                  color: arc.primaryColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DÉBUT : ${DateFormat('dd MMM').format(arc.startDate)}",
                    style: TextStyle(color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white24, fontSize: 8),
                  ),
                  Text(
                    "FIN : ${DateFormat('dd MMM').format(arc.endDate)}",
                    style: TextStyle(color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white24, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const SizedBox(height: 32),
        const FocusTimer(), // Injection du nouveau composant immersif Codex

        const SizedBox(height: 40),
        Text(
          "ARCHIVES DU JOURNAL",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        if (user != null)
          StreamBuilder<List<JournalEntry>>(
            stream: ref
                .read(valerionRepositoryProvider)
                .listenUserJournal(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  "Erreur lors du chargement des archives.",
                  style: TextStyle(color: Colors.red),
                );
              }
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    "Aucune archive de journalisée.",
                    style: TextStyle(
                      color: Colors.white24,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  // DateFormat dd/MM/yyyy HH:mm
                  final dateStr = DateFormat(
                    'dd/MM/yyyy à HH:mm',
                  ).format(entry.date);
                  return _buildJournalArchive(dateStr, entry.content);
                },
              );
            },
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBookItem(String title, String author) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            author,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildJournalArchive(String date, String excerpt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: Colors.purpleAccent, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: const TextStyle(
              color: Colors.purpleAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            excerpt,
            style: TextStyle(
              color: _isSummer ? _onSurfaceColor : Colors.white70,
              fontStyle: FontStyle.italic,
              fontFamily: 'Noto Serif',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Réglages (Laboratoire / Gestion) ---
  Widget _buildSettingsTab() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "REGISTRE : L'ARÈNE (GPS)",
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),

        _buildSettingsButton(
          Icons.color_lens,
          "Thème & Arc Actif",
          "Basculer manuellement d'Arc",
        ),
        _buildSettingsButton(
          Icons.download,
          "Export des Données",
          "Télécharger le rapport PDF",
        ),
        _buildSettingsButton(
          Icons.lock,
          "Confidentialité",
          "Visibilité dans le Panthéon",
        ),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.withValues(alpha: 0.2), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PASS ALPHA+ INACTIF",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Soutenir le projet et débloquer les stats avancées.",
                      style: TextStyle(
                        color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.7) : Colors.white70, 
                        fontSize: 10
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsButton(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white54, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : Colors.white54, 
                    fontSize: 10
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}
