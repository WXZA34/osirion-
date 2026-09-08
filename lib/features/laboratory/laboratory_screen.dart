import 'package:valerion/l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../core/providers/repository_providers.dart';
import '../auth/login_screen.dart';
import 'dojo_camera_test_screen.dart';
import '../../core/domain/entities/user_entity.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';
import '../../core/providers/lab_settings_provider.dart';

class LaboratoryScreen extends ConsumerStatefulWidget {
  LaboratoryScreen({super.key});

  @override
  ConsumerState<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends ConsumerState<LaboratoryScreen> {
  int _selectedTabIndex =
      0; // 0: Avatar, 1: Moteurs, 2: Données, 3: Support, 4: Alpha Labs

  // --- Theme Colors for Laboratory (Tech / Schematic) ---
  ArcData get _currentArc => ref.watch(arcProvider);
  bool get _isSummer => _currentArc.arcType == AlphaArc.summer;
  Color get _bgLab => Colors.transparent;
  Color get _surfaceLab => _currentArc.surfaceColor;
  Color get _onSurfaceLab => _currentArc.onSurfaceColor;
  Color get _accentTech => _currentArc.primaryColor;
  final Color _accentWarning = Colors.orangeAccent;
  Color get _lineColor => _isSummer ? Colors.black.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.1);

  // Mock State for cloud
  final bool _cloudSyncStatus = true; // True: Synced, False: Syncing/Error

  // Controllers Avatar Form
  final _usernameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _muscleMassCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isInitialized = false; // Flag pour éviter le reset par Riverpod

  @override
  void initState() {
    super.initState();
    // Les réglages sont chargés via le provider
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bodyFatCtrl.dispose();
    _muscleMassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labSettings = ref.watch(labSettingsProvider);
    return Scaffold(
      backgroundColor: _bgLab,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science, color: _accentTech, size: 20),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.laboratoryLeLaboratoire,
              style: TextStyle(
                color: _isSummer ? _currentArc.onSurfaceColor : Colors.white,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: _isSummer ? _onSurfaceLab : Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildTopNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _buildCurrentTabContent(labSettings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceLab,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _lineColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavTab(0, "Avatar"),
            _buildNavTab(1, "Moteurs"),
            _buildNavTab(2, "Données"),
            _buildNavTab(3, "Support"),
            _buildNavTab(4, "Bêta", isExperimental: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, String label, {bool isExperimental = false}) {
    bool isSelected = _selectedTabIndex == index;
    Color tabColor = isExperimental ? Colors.purpleAccent : _accentTech;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? tabColor : Colors.transparent,
              width: 2,
            ),
            right: BorderSide(
              color: index < 4 ? _lineColor : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            if (isExperimental)
              Icon(Icons.biotech, color: Colors.purpleAccent, size: 12),
            if (isExperimental) SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected 
                    ? tabColor 
                    : (_isSummer ? _onSurfaceLab.withValues(alpha: 0.4) : Colors.white54),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(LabSettings labSettings) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAvatarTab();
      case 1:
        return _buildEnginesTab(labSettings);
      case 2:
        return _buildDataTab();
      case 3:
        return _buildSupportTab();
      case 4:
        return _buildAlphaLabsTab();
      default:
        return SizedBox.shrink();
    }
  }

  // --- Tab 0: Avatar ---
  Widget _buildAvatarTab() {
    final userAsync = ref.watch(userProfileProvider);

    return userAsync.when(
      loading:
          () => Center(
            child: CircularProgressIndicator(color: _accentTech),
          ),
      error: (e, st) => Center(child: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
      data: (user) {
        if (user == null) {
          return Center(child: Text(AppLocalizations.of(context)!.laboratoryAucunProfilDTect));
        }

        // On assigne les valeurs initiales UNE SEULE FOIS
        // (Pour éviter que le champ saute quand on tape si le stream refraichit)
        if (!_isInitialized) {
          _usernameCtrl.text = user.username;
          _ageCtrl.text = user.age?.toString() ?? "";
          _heightCtrl.text = user.height?.toString() ?? "";
          _weightCtrl.text = user.weight?.toString() ?? "";
          _bodyFatCtrl.text = user.bodyFat?.toString() ?? "";
          _muscleMassCtrl.text = user.muscleMass?.toString() ?? "";
          // On diffère le set du flag après la fin de la frame de build courante
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          });
        }

        return Column(
          key: ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(
              "MODIFICATION DE L'AVATAR",
              Icons.person_outline,
            ),
            SizedBox(height: 16),
            _buildTechContainer(
              child: Column(
                children: [
                  _buildInputRow(
                    "Nom de code",
                    "Identifiant public",
                    _usernameCtrl,
                  ),
                  Divider(color: Colors.black12),
                  _buildInputRow("Âge", "Années", _ageCtrl, isNumber: true),
                  Divider(color: Colors.black12),
                  _buildInputRow("Taille", "cm", _heightCtrl, isNumber: true),
                  Divider(color: Colors.black12),
                  _buildInputRow(
                    "Poids (Total)",
                    "kg",
                    _weightCtrl,
                    isNumber: true,
                  ),
                  Divider(color: Colors.black12),
                  _buildInputRow(
                    "Masse Grasse",
                    "%",
                    _bodyFatCtrl,
                    isNumber: true,
                  ),
                  Divider(color: Colors.black12),
                  _buildInputRow(
                    "Muscle",
                    "kg",
                    _muscleMassCtrl,
                    isNumber: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildSectionHeader(
              "ARCHIVES DE COMBAT (VERROUILLÉES)",
              Icons.lock,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(AppLocalizations.of(context)!.laboratoryVosStatistiquesDeCombat,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentTech,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isSaving ? null : () => _saveProfileToCloud(user),
              child:
                  _isSaving
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(AppLocalizations.of(context)!.laboratorySynchroniserLesModifications,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
            ),
          ],
        );
      },
    );
  }

  // --- Helpers pour le formulaire Avatar ---

  Widget _buildInputRow(
    String title,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                color: _isSummer ? _onSurfaceLab : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              keyboardType:
                  isNumber
                      ? TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
              style: TextStyle(
                color: _accentTech,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.25) : Colors.white24, 
                  fontSize: 10
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileToCloud(UserEntity currentUser) async {
    setState(() => _isSaving = true);

    try {
      final updatedUser = currentUser.copyWith(
        username: _usernameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text),
        height: int.tryParse(_heightCtrl.text),
        weight: double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
        bodyFat: double.tryParse(_bodyFatCtrl.text.replaceAll(',', '.')),
        muscleMass: double.tryParse(_muscleMassCtrl.text.replaceAll(',', '.')),
      );

      await ref.read(valerionRepositoryProvider).saveUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.laboratoryAvatarMisJourDans,
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: _accentTech,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Échec de la liaison: $e",
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Tab 1: Calibration (IA & GPS) ---
  Widget _buildEnginesTab(LabSettings labSettings) {
    return Column(
      key: ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("STATION DE CALIBRATION IA", Icons.visibility),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildSliderSetting(
                "Sensibilité de Détection",
                "Ajustez selon la luminosité de la pièce",
                labSettings.aiSensitivity,
                (val) => ref.read(labSettingsProvider.notifier).updateAiSensitivity(val),
              ),
              Divider(color: Colors.white10),
              _buildSwitchSetting(
                "Superposition Squelettique",
                "Afficher les lignes sur le flux vidéo",
                labSettings.showSkeleton,
                (val) => ref.read(labSettingsProvider.notifier).updateShowSkeleton(val),
              ),
              Divider(color: Colors.white10),
              _buildDropdownSetting("Mode Énergétique", [
                "Haute Précision",
                "Équilibré",
                "Économie",
              ]),
            ],
          ),
        ),
        SizedBox(height: 32),

        _buildSectionHeader("OPTIMISATION CARTOGRAPHIE (GPS)", Icons.explore),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildSliderSetting(
                "Fréquence de Scan GPS",
                "Précision vs Batterie",
                labSettings.gpsFrequency,
                (val) => ref.read(labSettingsProvider.notifier).updateGpsFrequency(val),
              ),
              Divider(color: Colors.white10),
              _buildSwitchSetting(
                "Filtre de Lissage (Kalman)",
                "Évite les sauts de position",
                true,
                (v) {},
              ),
              Divider(color: Colors.white10),
              _buildDropdownSetting("Calque par défaut", [
                "Standard",
                "Satellite",
                "Hybride",
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 2: Données (Cloud & Offline) ---
  Widget _buildDataTab() {
    return Column(
      key: ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("CLOUD & SÉCURITÉ", Icons.cloud),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.laboratoryStatutDeSynchronisation,
                        style: TextStyle(
                          color: _isSummer ? _onSurfaceLab : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _cloudSyncStatus
                            ? "Données alignées"
                            : "Synchronisation en cours...",
                        style: TextStyle(
                          color:
                              _cloudSyncStatus ? _accentTech : _accentWarning,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _cloudSyncStatus ? Icons.cloud_done : Icons.cloud_sync,
                    color: _cloudSyncStatus ? _accentTech : _accentWarning,
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(color: Colors.white10),
              _buildActionSetting(
                "Forcer la Sauvegarde",
                Icons.backup,
                "Synchronisation manuelle vers le Cloud",
                () => _handleForceBackup(),
              ),
              _buildActionSetting(
                "Export RGPD",
                Icons.download,
                "Générer et partager mon archive JSON",
                () => _handleDataExport(),
              ),
              _buildActionSetting(
                "Nettoyage du Cache",
                Icons.cleaning_services,
                "Optimiser le stockage local",
                () => _handleCacheCleanup(),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        _buildSectionHeader("HORS LIGNE (OFFLINE HUB)", Icons.wifi_off),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildInfoRow(
                "Modèles IA Embarqués",
                "v1.4.2 Téléchargé",
                Icons.memory,
                _accentTech,
              ),
              SizedBox(height: 12),
              _buildInfoRow(
                "Cartes Locales",
                "Paris, Lyon",
                Icons.map,
                Colors.white54,
              ),
              SizedBox(height: 16),
              _buildActionSetting(
                "Gérer le Stockage",
                Icons.storage,
                "Vider les fichiers temporaires",
                () => _handleCacheCleanup(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LOGIQUE DE GESTION DES DONNÉES ---

  Future<void> _handleForceBackup() async {
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(valerionRepositoryProvider).saveUserProfile(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.laboratorySauvegardeForcER)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDataExport() async {
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;
    if (user == null) return;

    try {
      final jsonData = await ref
          .read(valerionRepositoryProvider)
          .exportUserData(user.id);
      
      final tempDir = await getTemporaryDirectory();
      
      // 1. Fichier JSON (Technique / Portabilité)
      final jsonFile = File('${tempDir.path}/valerion_archive_${user.id}.json');
      await jsonFile.writeAsString(jsonData);

      // 2. Fichier TXT (Lisible / Humain)
      final txtFile = File('${tempDir.path}/RESUME_OSIRION_${user.id}.txt');
      final summary = _generateHumanReadableSummary(user);
      await txtFile.writeAsString(summary);

      await Share.shareXFiles(
        [
          XFile(jsonFile.path, name: 'Archive_Technique.json'),
          XFile(txtFile.path, name: 'Resume_OSIRION.txt'),
        ],
        text: 'Mon archive de données OSIRION (RGPD)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
        );
      }
    }
  }

  String _generateHumanReadableSummary(dynamic user) {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";
    
    return """
╔══════════════════════════════════════════════╗
║        RAPPPORT DE PROGRESSION OSIRION       ║
╚══════════════════════════════════════════════╝
Généré le : $dateStr

--- IDENTITÉ ---
Codename : ${user.username}
Niveau : ${user.level}
Titre Actuel : ${user.activeTitle ?? 'Aucun'}
Série Actuelle : ${user.streak} jours consécutifs

--- STATISTIQUES ---
XP Totale : ${user.xp}
Aether Balance : ${user.aetherBalance}
Distance Totale : ${user.totalDistance?.toStringAsFixed(2) ?? '0.00'} km

--- ARSENAL (RELIQUES) ---
${user.inventory.isEmpty ? 'Aucune relique possédée.' : user.inventory.map((id) => "- $id").join('\n')}

--- NOTE RGPD ---
Ceci est un résumé lisible de vos données. 
L'archive .json jointe contient l'intégralité technique 
de votre profil, journal et statistiques d'activité.
________________________________________________
Propulsé par le Moteur OSIRION v1.1
""";
  }

  Future<void> _handleCacheCleanup() async {
    try {
      // Nettoyage des fichiers temporaires
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.laboratoryCacheEtFichiersTemporaires)),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
        );
      }
    }
  }

  // --- Tab 3: Support & Crowdsourcing ---
  Widget _buildSupportTab() {
    return Column(
      key: ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader("RÉSOLUTION DE PROBLÈMES", Icons.build),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildActionSetting(
                "Diagnostic Rapide",
                Icons.health_and_safety,
                "Vérifier la caméra et le GPS",
                () => _handleQuickDiagnostic(),
              ),
              Divider(color: Colors.white10),
              _buildActionSetting(
                "Signalement & Suggestions",
                Icons.bug_report,
                "Bugs ou Améliorations",
                () => _handleFeedback(),
              ),
              Divider(color: Colors.white10),
              _buildActionSetting(
                "Centre d'Aide",
                Icons.help_outline,
                "Tutoriels de placement caméra",
                () => _showHelpCenter(),
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        _buildSectionHeader("CROWDSOURCING", Icons.groups),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildActionSetting(
                "Proposer un nouveau Parc",
                Icons.add_location_alt,
                "Street Workout",
                () {},
              ),
              Divider(color: Colors.white10),
              _buildActionSetting(
                "Suggérer un Livre",
                Icons.menu_book,
                "Pour l'Arc Actuel",
                () {},
              ),
              Divider(color: Colors.white10),
              _buildActionSetting(
                "Déconnexion du Système",
                Icons.logout,
                "Clôturer la session OSIRION",
                () async {
                  await ref.read(authRepositoryProvider).signOut();
                  // Le AuthWrapper dans main.dart détectera le changement
                  // Mais pour forcer la vidange de l'arbre de navigation on push le Login:
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 4: Alpha Labs (Bêta) ---
  Widget _buildAlphaLabsTab() {
    return Column(
      key: ValueKey(4),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.purpleAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.laboratoryAttentionCesFonctionnalitS,
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        _buildSectionHeader("ENVIRONNEMENTS INTERACTIFS", Icons.layers),
        SizedBox(height: 16),
        _buildTechContainer(
          child: Column(
            children: [
              _buildActionSetting(
                "Tester l'Overlay Dojo (Caméra IA)",
                Icons.center_focus_strong,
                "Affiche l'overlay de sport sur flux vidéo live",
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DojoCameraTestScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 32),

        _buildSectionHeader("PROJETS EN COURS", Icons.science),
        SizedBox(height: 16),
        _buildExperimentalFeature(
          "Capteur Cardiaque (Optique)",
          "Mesure du pouls via flash caméra",
          false,
        ),
        _buildExperimentalFeature(
          "Nouveaux Mouvements IA",
          "Détection Planche & Front Lever",
          true,
        ),
        _buildExperimentalFeature(
          "Coach Vocal Génératif",
          "IA conversationnelle pendant l'effort",
          false,
        ),
      ],
    );
  }

  Widget _buildExperimentalFeature(String title, String desc, bool isEnabled) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLab,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.6) : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (val) {},
            activeColor: Colors.purpleAccent,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.5) : Colors.white54, size: 14),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.5) : Colors.white54,
            fontSize: 10,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(width: 12),
        Expanded(child: Divider(color: _lineColor)),
      ],
    );
  }

  Widget _buildTechContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceLab,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _lineColor),
      ),
      child: child,
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _isSummer ? _onSurfaceLab : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: TextStyle(
                color: _accentTech,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.6) : Colors.white54,
            fontSize: 10,
          ),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: _accentTech,
          inactiveColor: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.6) : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _accentTech,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(String title, List<String> options) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _isSummer ? _onSurfaceLab : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  options.first,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.8) : Colors.white70,
                    fontSize: 10,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.5) : Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE DE RÉSOLUTION DE PROBLÈMES ---

  Future<void> _handleQuickDiagnostic() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiagnosticDialog(),
    );
  }

  void _handleFeedback() {
    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FeedbackDialog(user: user),
    );
  }

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isSummer ? Colors.white : _bgLab,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildHelpCenterContent(),
    );
  }

  Widget _buildHelpCenterContent() {
    return Container(
      padding: EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.laboratoryCentreDAideOsirion,
                style: TextStyle(
                  color: _isSummer ? _onSurfaceLab : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.5) : Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildHelpItem(
                  "Positionnement Caméra",
                  "Placez votre téléphone à environ 2 mètres au sol ou à hauteur de hanche. Votre corps entier doit être visible dans le cadre (de la tête aux pieds).",
                  Icons.videocam,
                ),
                _buildHelpItem(
                  "Éclairage Optimal",
                  "Assurez-vous que la lumière vient de face ou du côté, pas de derrière vous (contre-jour), pour que l'IA détecte correctement vos articulations.",
                  Icons.lightbulb,
                ),
                _buildHelpItem(
                  "Précision GPS",
                  "Dans l'Arène, restez à découvert. Les grands bâtiments ou tunnels perturbent le signal de corrélation.",
                  Icons.gps_fixed,
                ),
                _buildHelpItem(
                  "Synchronisation",
                  "Si vos points d'XP ne montent pas, vérifiez votre connexion dans l'onglet 'Données' et forcez la sauvegarde.",
                  Icons.sync,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String content, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentTech, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.7) : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: _onSurfaceLab, size: 18),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _isSummer ? _onSurfaceLab : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.6) : Colors.white24,
                fontSize: 10,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _isSummer ? _onSurfaceLab.withValues(alpha: 0.3) : Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _isSummer ? _onSurfaceLab : Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _DiagnosticDialog extends StatefulWidget {
  @override
  State<_DiagnosticDialog> createState() => _DiagnosticDialogState();
}

class _DiagnosticDialogState extends State<_DiagnosticDialog> {
  bool? _cameraOk;
  bool? _gpsOk;
  bool? _storageOk;

  @override
  void initState() {
    super.initState();
    _startDiagnostic();
  }

  Future<void> _startDiagnostic() async {
    // 1. Check Camera
    final camStatus = await Permission.camera.status;
    setState(() => _cameraOk = camStatus.isGranted);

    // 2. Check GPS
    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    final gpsStatus = await Geolocator.checkPermission();
    setState(() => _gpsOk = gpsEnabled && (gpsStatus == LocationPermission.always || gpsStatus == LocationPermission.whileInUse));

    // 3. Check Storage
    try {
      await getTemporaryDirectory();
      setState(() => _storageOk = true);
    } catch (_) {
      setState(() => _storageOk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arc = ArcData.getCurrentArc();
    final isSummer = arc.arcType == AlphaArc.summer;
    return AlertDialog(
      backgroundColor: arc.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
      ),
      title: Text(
        AppLocalizations.of(context)!.laboratoryDiagnosticSystMe,
        style: TextStyle(
          color: isSummer ? arc.onSurfaceColor : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDiagLine("Vision IA (Caméra)", _cameraOk),
          _buildDiagLine("Géolocalisation (GPS)", _gpsOk),
          _buildDiagLine("Archives Locales (Stockage)", _storageOk),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.commonClose, style: TextStyle(color: ArcData.getCurrentArc().primaryColor)),
        ),
      ],
    );
  }

  Widget _buildDiagLine(String label, bool? status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ArcData.getCurrentArc().arcType == AlphaArc.summer ? ArcData.getCurrentArc().onSurfaceColor.withValues(alpha: 0.7) : Colors.white70,
              fontSize: 12,
            ),
          ),
          if (status == null)
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
          else
            Icon(status ? Icons.check_circle : Icons.error, color: status ? ArcData.getCurrentArc().primaryColor : Colors.redAccent, size: 18),
        ],
      ),
    );
  }
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  final UserEntity user;
  const _FeedbackDialog({required this.user});

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  String _type = "BUG"; // BUG or SUGGESTION
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arc = ArcData.getCurrentArc();
    final accent = arc.primaryColor;
    final isSummer = arc.arcType == AlphaArc.summer;
    final bg = arc.surfaceColor;

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
      ),
      title: Text(
        AppLocalizations.of(context)!.laboratorySignalementValerion,
        style: TextStyle(
          color: isSummer ? arc.onSurfaceColor : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.laboratoryTypeDeRetour,
              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildTypeButton("BUG", Icons.bug_report, _type == "BUG"),
                SizedBox(width: 8),
                _buildTypeButton("SUGGESTION", Icons.tips_and_updates, _type == "SUGGESTION"),
              ],
            ),
            SizedBox(height: 24),
            Text(
              "DESCRIPTION",
              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: _type == "BUG" 
                    ? "Décrivez le bug précisément..." 
                    : "Quelle est votre idée d'amélioration ?",
                hintStyle: TextStyle(
                  color: isSummer ? arc.onSurfaceColor.withValues(alpha: 0.4) : Colors.white24, 
                  fontSize: 12
                ),
                filled: true,
                fillColor: isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isSummer ? Colors.black.withValues(alpha: 0.1) : Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.5)),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.laboratoryNoteLesDonnEs,
              style: TextStyle(color: Colors.white30, fontSize: 9, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.commonCancel, style: TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _sendFeedback,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent.withValues(alpha: 0.2),
            foregroundColor: accent,
            side: BorderSide(color: accent.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSending 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: accent))
              : Text(AppLocalizations.of(context)!.commonSend, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String label, IconData icon, bool isSelected) {
    final accent = ArcData.getCurrentArc().primaryColor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _type = label),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? accent.withValues(alpha: 0.5) : Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? accent : Colors.white24, size: 20),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? accent : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFeedback() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    final String message = _controller.text.trim();
    final String report = """
--- OSIRION FEEDBACK REPORT ---
Type : $_type
Timestamp : ${DateTime.now().toIso8601String()}
Version : 1.0.1+3
User ID : ${widget.user.id}
User Level : ${widget.user.level}

--- DEVICE ---
OS : ${Platform.isAndroid ? 'Android' : 'iOS'} ${Platform.operatingSystemVersion}
Locale : ${Platform.localeName}

--- MESSAGE ---
$message

------------------------------
""";

    try {
      final repo = ref.read(valerionRepositoryProvider);
      await repo.sendSupportTicket(widget.user.id, {
        'type': _type,
        'version': '1.0.1+3',
        'device': {
          'os': Platform.isAndroid ? 'Android' : 'iOS',
          'osVersion': Platform.operatingSystemVersion,
          'locale': Platform.localeName,
        },
        'userLevel': widget.user.level,
        'message': message,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == "BUG" ? "Bug envoyé à Firebase ! 🛡️" : "Suggestion envoyée à Firebase ! ✨"),
            backgroundColor: ArcData.getCurrentArc().primaryColor.withValues(alpha: 0.8),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Erreur envoi ticket Firestore: $e");
      
      // Fallback : partage manuel si Firestore échoue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.laboratoryChecDirectOuvertureDu)),
        );
      }
      
      await Share.share(
        report,
        subject: "[$_type] Retour Utilisateur - OSIRION",
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
