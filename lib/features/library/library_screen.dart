import 'package:valerion/l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'screens/audio_player_screen.dart';
import '../../core/providers/repository_providers.dart';
import '../profile/profile_screen.dart';
import 'models/journal_entry.dart';
import 'widgets/book_cover_widget.dart';
import 'models/book_entity.dart';
import 'screens/reading_session_screen.dart';
import '../home/models/arc_data.dart';
import '../../core/providers/arc_provider.dart';
import '../../core/domain/entities/library_audio_entity.dart';
import '../../core/providers/library_providers.dart';
import '../arsenal/models/relic.dart';
import '../dojo/models/exercise_config.dart';
import '../../core/services/notification_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  // --- State variables ---
  ArcData get _currentArc => ref.watch(arcProvider);
  bool get _isSummer => _currentArc.arcType == AlphaArc.summer;
  Color get _accentColor => _currentArc.primaryColor;
  Color get _surfaceColor => _currentArc.surfaceColor;
  Color get _onSurfaceColor => _currentArc.onSurfaceColor;

  String _activeArc = 'Winter Arc';
  int _selectedTabIndex = 0; // 0: Lectures, 1: Focus, 2: Journal, 3: Podcasts
  BookEntity? _selectedBookForReading;

  // Focus Timer State
  int _focusTimeGoal = 15; // en minutes (15, 30, 60)
  int _remainingSeconds = 15 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;
  String _selectedAmbientSound = 'Silence';

  // Journal State
  final TextEditingController _journalController = TextEditingController();
  bool _isHonorContractChecked = false;

  @override
  void initState() {
    super.initState();
    // Initialiser l'Arc actif depuis le profil utilisateur si disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).valueOrNull;
      if (user?.activeArcId != null) {
        setState(() => _activeArc = user!.activeArcId!);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _journalController.dispose();
    super.dispose();
  }

  // --- Timer Logic ---
  void _setTimerGoal(int minutes) {
    if (_isTimerRunning) return;
    setState(() {
      _focusTimeGoal = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            // Timer terminé
            _timer?.cancel();
            _isTimerRunning = false;
            _showCompletionDialog();
          }
        });
      });
    }
  }

  void _sealContract() async {
    final text = _journalController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProfileProvider).valueOrNull;
    if (user != null) {
      try {
        final repo = ref.read(valerionRepositoryProvider);

        final entry = JournalEntry(
          id: Uuid().v4(),
          userId: user.id,
          content: text,
          date: DateTime.now(),
          isSealed: true, // Immuable
        );

        await repo.addJournalEntry(entry, arcId: user.activeArcId);

        // Ajouter une récompense de Sagesse pour la réflexion stoïcienne (Sécurisé)
        await repo.addManualReward(user.id, 'journal');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.libraryLeOnAncrE),
              backgroundColor: _accentColor,
            ),
          );
          _journalController.clear();
          setState(() => _isHonorContractChecked = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.commonError(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToReadingSession() async {
    if (_selectedBookForReading == null) return;

    // Si on navigue, on coupe la musique de fond et le timer de cette page (si jamais lancés)
    _resetTimer();

    // Ouvre la masterclass littéraire. L'écran lira l'entité book.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReadingSessionScreen(
              book: _selectedBookForReading!,
              durationMinutes: _focusTimeGoal,
              ambientSound: _selectedAmbientSound,
            ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _selectedTabIndex = 2; // Onglet Journal
        _journalController.text =
            AppLocalizations.of(context)!.libraryLeconNumeroUn + _selectedBookForReading!.title + "\n";
        _selectedBookForReading = null;
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _focusTimeGoal * 60;
      _isTimerRunning = false;
    });
  }

  void _updateActiveArc(String arcId) async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null || user.activeArcId == arcId) {
      setState(() => _activeArc = arcId);
      return;
    }

    final oldArc = user.activeArcId;
    setState(() => _activeArc = arcId);

    try {
      final repo = ref.read(valerionRepositoryProvider);

      // 1. Mettre à jour Firestore
      await repo.saveUserProfile(user.copyWith(activeArcId: arcId));

      // 2. Mettre à jour les abonnements Notifications
      if (oldArc != null) {
        await NotificationService.unsubscribeFromArc(oldArc);
      }
      await NotificationService.subscribeToArc(arcId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.libraryTransmissionAlphaCalee + arcId),
            backgroundColor: _accentColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Erreur changement d'arc: $e");
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _surfaceColor,
            title: Text(
              AppLocalizations.of(context)!.librarySessionTerminE,
              style: TextStyle(
                color: _isSummer ? _onSurfaceColor : Colors.white,
                fontFamily: 'Noto Serif',
              ),
            ),
            content: Text(AppLocalizations.of(context)!.libraryProuesseIntellectuelleValidE,
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetTimer();
                },
                child: Text(
                  AppLocalizations.of(context)!.libraryFermer,
                  style: TextStyle(color: _accentColor),
                ),
              ),
            ],
          ),
    );
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color surfaceColor = _surfaceColor;

    final userProfileAsync = ref.watch(userProfileProvider);
    final user = userProfileAsync.valueOrNull;

    // Calcul de Sagesse (Sagesse Level = wisdomXp / 200 + 1)
    final int wisdomXp = user?.wisdomXp ?? 0;
    final int wisdomLevel = (wisdomXp ~/ 200) + 1;
    final double wisdomProgress = (wisdomXp % 200) / 200.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.libraryLaForgeDeL,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontFamily: 'Noto Serif', // Typographie Serif pour ce module
            letterSpacing: 1,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
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
                child: _buildCurrentTabContent(surfaceColor, wisdomLevel, wisdomProgress),
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
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavTab(0, AppLocalizations.of(context)!.libraryTabLivres, Icons.menu_book),
          _buildNavTab(1, AppLocalizations.of(context)!.libraryTabFocus, Icons.timer),
          _buildNavTab(2, AppLocalizations.of(context)!.libraryTabJournal, Icons.edit_note),
          _buildNavTab(3, AppLocalizations.of(context)!.libraryTabAudio, Icons.headphones),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, String label, IconData icon) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.cyan : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? _accentColor 
              : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(Color surfaceColor, int wisdomLevel, double wisdomProgress) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildReadingPlans(surfaceColor, wisdomLevel, wisdomProgress);
      case 1:
        return _buildFocusReader(surfaceColor);
      case 2:
        return _buildJournalEntry(surfaceColor);
      case 3:
        return _buildAudioPodcasts(surfaceColor);
      default:
        return SizedBox.shrink();
    }
  }

  // --- Tab 0: Reading Plans ---
  Widget _buildReadingPlans(Color surfaceColor, int wisdomLevel, double wisdomProgress) {
    return Column(
      key: ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Arc Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                [AppLocalizations.of(context)!.winterArc, 'Summer Body', 'Royal Arc'].map((arc) {
                  bool isSelected = _activeArc == arc;
                  return GestureDetector(
                    onTap: () => _updateActiveArc(arc),
                    child: Container(
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? _accentColor.withValues(alpha: 0.2)
                                : surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? _accentColor 
                              : (_isSummer ? Colors.black12 : Colors.white10),
                        ),
                      ),
                      child: Text(
                        arc,
                        style: TextStyle(
                          color: isSelected ? _accentColor : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        SizedBox(height: 16),

        // Bouton Admin pour créer les données de test (Migration Firestore)
        if (kDebugMode)
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final repo = ref.read(valerionRepositoryProvider);
                      
                      // 1. Migration des Livres
                      final books = getLibraryCatalog(context).values.expand((e) => e).toList();
                      await repo.uploadDefaultBooks(books);

                      // 2. Migration des Audios
                      await repo.uploadDefaultLibraryAudios(ValerionAudios.getCatalogue(context));

                      // 3. Migration des Reliques
                      await repo.uploadDefaultRelics([...arsenalRelics, ...levelTitles]);
                      
                      // 4. Migration des Exercices Dojo
                      await repo.uploadDefaultExercises(ValerionExercises.catalogue);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.libraryMigrationFirestoreRUssie),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("❌ Erreur migration : $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.commonError(e.toString())),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.cloud_upload),
                  label: Text(AppLocalizations.of(context)!.libraryMigrerCloud),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white24),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final repo = ref.read(valerionRepositoryProvider);
                      await repo.purgeLibraryBooks();
                      await repo.purgeLibraryAudios();
                      await repo.purgeRelics();
                      await repo.purgeExercises();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.libraryCollectionsFirestorePurgEs),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.commonError(e.toString()))),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.delete_sweep),
                  label: Text(AppLocalizations.of(context)!.commonPurge),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
                    foregroundColor: Colors.orangeAccent,
                    side: BorderSide(color: Colors.orangeAccent),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 16),

        // Jauge de Sagesse (Gamification)
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.librarySagesseActuelle,
                      style: TextStyle(
                        color: _isSummer ? _onSurfaceColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: wisdomProgress,
                      backgroundColor: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                      color: Colors.purpleAccent,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Niv. $wisdomLevel",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Liste des livres (Hybride Isolée pour éviter les ANR)
        _DynamicBookList(
          activeArc: _activeArc,
          surfaceColor: surfaceColor,
          onBuildCard: (book) => _buildDetailedBookCard(book, surfaceColor),
        ),
      ],
    );
  }

  Widget _buildDetailedBookCard(BookEntity book, Color surfaceColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isSummer ? Colors.black12 : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCoverWidget(
            title: book.title,
            author: book.author,
            thumbnailUrl: book.thumbnailUrl,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    color: _isSummer ? _onSurfaceColor : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Serif',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  book.author,
                  style: TextStyle(
                    color: _isSummer ? _currentArc.primaryColor : _accentColor,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        book.tag,
                        style: TextStyle(
                          color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white70,
                            minimumSize: Size(60, 30),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(color: _isSummer ? Colors.black12 : Colors.white24),
                          ),
                          onPressed: () => _showBookDetailsSheet(book),
                          child: Text(
                            AppLocalizations.of(context)!.libraryFiche,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
                            foregroundColor: _isSummer ? _onSurfaceColor : Colors.white,
                            minimumSize: Size(60, 30),
                            padding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed:
                              () => setState(() {
                                _selectedBookForReading = book;
                                _selectedTabIndex = 1;
                              }), // Go to Focus Timer
                          child: Text(
                            AppLocalizations.of(context)!.libraryLire,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 1: Focus Reader ---
  Widget _buildFocusReader(Color surfaceColor) {
    return Column(
      key: ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _selectedBookForReading != null
                    ? AppLocalizations.of(context)!.libraryLecturePrefix + _selectedBookForReading!.title.toUpperCase()
                    : AppLocalizations.of(context)!.libraryModeImmersion,
                style: TextStyle(
                  color: _accentColor,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_selectedBookForReading != null)
              IconButton(
                icon: Icon(
                  Icons.close, 
                  color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54, 
                  size: 20
                ),
                onPressed: () => setState(() => _selectedBookForReading = null),
                tooltip: AppLocalizations.of(context)!.libraryAnnulerLaLecture,
              ),
          ],
        ),
        SizedBox(height: 24),

        // Timer Display
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isTimerRunning ? _accentColor : (_isSummer ? Colors.black12 : Colors.white10),
                width: 4,
              ),
              boxShadow: [
                if (_isTimerRunning)
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: -5,
                  ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      color: _isTimerRunning ? _accentColor : (_isSummer ? _onSurfaceColor : Colors.white),
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  if (_isTimerRunning)
                    Text(
                      AppLocalizations.of(context)!.libraryNePasDRanger,
                      style: TextStyle(
                        color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.3) : Colors.grey,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 40),

        // Time Selectors
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              [15, 30, 60].map((mins) {
                bool isSelected = _focusTimeGoal == mins;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () => _setTimerGoal(mins),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.cyan.withValues(alpha: 0.2)
                                : surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _accentColor : (_isSummer ? Colors.black12 : Colors.white10),
                        ),
                      ),
                      child: Text(
                        mins.toString() + AppLocalizations.of(context)!.libraryMinutesSuffix,
                        style: TextStyle(
                          color: isSelected 
                              ? _accentColor 
                              : (_isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        SizedBox(height: 16),

        // Start/Stop
        ElevatedButton(
          onPressed:
              _selectedBookForReading != null
                  ? _navigateToReadingSession
                  : _toggleTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _selectedBookForReading != null
                    ? _accentColor
                    : (_isTimerRunning
                        ? (_isSummer 
                            ? Colors.redAccent.withValues(alpha: 0.1) 
                            : Colors.redAccent.withValues(alpha: 0.2))
                        : _accentColor),
            foregroundColor:
                _selectedBookForReading != null
                    ? Colors.black
                    : (_isTimerRunning ? Colors.redAccent : Colors.black),
            padding: EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _selectedBookForReading != null
                ? AppLocalizations.of(context)!.libraryCommencerLecture
                : (_isTimerRunning
                    ? AppLocalizations.of(context)!.libraryArreterImmersion
                    : AppLocalizations.of(context)!.libraryCommencerImmersion),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // --- Tab 2: Journal ---
  Widget _buildJournalEntry(Color surfaceColor) {
    return Column(
      key: ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.libraryContratDHonneur,
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.5) : Colors.white70,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.libraryLaVieNeVaut,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54,
            fontStyle: FontStyle.italic,
            fontFamily: 'Noto Serif',
          ),
        ),
        SizedBox(height: 32),

        // Text Area
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _journalController,
            maxLength: 280,
            maxLines: 5,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Noto Serif',
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.libraryQuelleLeOnAvez,
              hintStyle: TextStyle(color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.25) : Colors.white24),
              border: InputBorder.none,
              counterStyle: TextStyle(color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.4) : Colors.white54),
            ),
          ),
        ),
        SizedBox(height: 24),

        // Contract Checkbox
        Row(
          children: [
            Checkbox(
              value: _isHonorContractChecked,
              onChanged:
                  (val) =>
                      setState(() => _isHonorContractChecked = val ?? false),
              fillColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected)
                        ? _accentColor
                        : Colors.transparent,
              ),
              side: BorderSide(color: _accentColor),
            ),
            Expanded(child: Text(AppLocalizations.of(context)!.libraryAiJeTFid,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        SizedBox(height: 32),

        ElevatedButton(
          onPressed:
              _isHonorContractChecked && _journalController.text.isNotEmpty
                  ? _sealContract
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white10,
            disabledForegroundColor: Colors.white54,
            padding: EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(AppLocalizations.of(context)!.libraryScellerLeContrat,
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
        SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            child: Text(AppLocalizations.of(context)!.libraryOuvrirLeLivreD,
              style: TextStyle(
                color: Colors.white54,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Tab 3: Audio Podcasts ---
  Widget _buildAudioPodcasts(Color surfaceColor) {
    return Column(
      key: ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.libraryRCupRationMentale,
          style: TextStyle(
            color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : Colors.white70,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),

        // Liste des Audios (Hybride Isolée pour éviter les ANR)
        _DynamicAudioList(
          surfaceColor: surfaceColor,
          buildAudioCard: (title, subtitle, icon, path) => _buildAudioCard(title, subtitle, icon, surfaceColor, path),
        ),

        SizedBox(height: 32),

        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.libraryDevenezAlpha,
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.libraryDBloquezLeMode,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildAudioCard(
    String title,
    String subtitle,
    IconData icon,
    Color surfaceColor,
    String audioPath,
  ) {
    return Builder(
      builder: (context) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSummer ? Colors.black.withValues(alpha: 0.05) : Colors.white10,
              ),
            ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _accentColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _isSummer ? _onSurfaceColor : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _isSummer ? _onSurfaceColor.withValues(alpha: 0.6) : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.play_circle_fill,
                  color: _isSummer ? _accentColor : Colors.white,
                  size: 36,
                ),
                onPressed: () {
                  final isRemote = audioPath.startsWith('http');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AudioPlayerScreen(
                            title: title,
                            subtitle: subtitle,
                            audioPath: audioPath,
                            isAsset: !isRemote,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookDetailsSheet(BookEntity book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne de fermeture cachée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                book.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Serif',
                ),
              ),
              SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.libraryParAuteur + book.author,
                style: TextStyle(color: _accentColor, fontSize: 12),
              ),
              SizedBox(height: 24),

              Text(AppLocalizations.of(context)!.libraryThMe,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(book.theme, style: TextStyle(color: Colors.white)),
              SizedBox(height: 16),

              Text(AppLocalizations.of(context)!.libraryPourquoiLIntGrer,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(book.whyRead, style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),

              Text(AppLocalizations.of(context)!.libraryCitationCl,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "\"${book.keyPhrase}\"",
                style: TextStyle(
                  color: _accentColor,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Noto Serif',
                ),
              ),
              SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedBookForReading = book;
                      _selectedTabIndex = 1;
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.libraryLancerLaLecture,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// Widget isolé pour gérer la liste dynamique des livres sans freezer l'écran principal.
class _DynamicBookList extends ConsumerWidget {
  final String activeArc;
  final Color surfaceColor;
  final Widget Function(BookEntity) onBuildCard;

  const _DynamicBookList({
    required this.activeArc,
    required this.surfaceColor,
    required this.onBuildCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(libraryBooksProvider).when(
      data: (firebaseBooks) {
        final staticBooks = getLibraryCatalog(context)[activeArc] ?? [];
        final dynamicBooks = firebaseBooks.where((b) => b.arc == activeArc).toList();
        
        // Dédoublonnage par ID (priorité au contenu Firestore si présent)
        final Map<String, BookEntity> bookMap = {};
        for (var b in staticBooks) { bookMap[b.id] = b; }
        for (var b in dynamicBooks) { bookMap[b.id] = b; }
        
        final allBooks = bookMap.values.toList();

        if (allBooks.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.libraryAucunLivreTrouv,
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ),
          );
        }

        return Column(
          children: allBooks.map((book) => onBuildCard(book)).toList(),
        );
      },
      loading: () => _buildStaticFallback(context),
      error: (err, stack) => _buildStaticFallback(context),
    );
  }

  Widget _buildStaticFallback(BuildContext context) {
    final staticBooks = getLibraryCatalog(context)[activeArc] ?? [];
    return Column(
      children: staticBooks.map((book) => onBuildCard(book)).toList(),
    );
  }
}

/// Widget isolé pour gérer la liste dynamique des audios.
class _DynamicAudioList extends ConsumerWidget {
  final Color surfaceColor;
  final Widget Function(String, String, IconData, String) buildAudioCard;

  const _DynamicAudioList({
    required this.surfaceColor,
    required this.buildAudioCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(libraryAudiosProvider).when(
      data: (firebaseAudios) {
        final staticAudios = ValerionAudios.getCatalogue(context);
        
        // Dédoublonnage par ID
        final Map<String, LibraryAudioEntity> audioMap = {};
        for (var a in staticAudios) { audioMap[a.id] = a; }
        for (var a in firebaseAudios) { audioMap[a.id] = a; }
        
        final allAudios = audioMap.values.toList();
        allAudios.sort((a, b) => a.order.compareTo(b.order));

        return Column(
          children: [
            ...allAudios.map((audio) {
              IconData icon;
              switch (audio.iconName) {
                case 'flash_on': icon = Icons.flash_on; break;
                case 'av_timer': icon = Icons.av_timer; break;
                case 'looks_one': icon = Icons.looks_one; break;
                case 'self_improvement': icon = Icons.self_improvement; break;
                case 'campaign': icon = Icons.campaign; break;
                case 'sports_martial_arts': icon = Icons.sports_martial_arts; break;
                default: icon = Icons.music_note;
              }
              return buildAudioCard(audio.title, audio.subtitle, icon, audio.audioUrl);
            }),
            SizedBox(height: 16),
            Divider(color: Colors.white10),
            Text(AppLocalizations.of(context)!.libraryNouveauxContenusSynchronisS,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        );
      },
      loading: () => _buildStaticFallback(context),
      error: (err, stack) => _buildStaticFallback(context),
    );
  }

  Widget _buildStaticFallback(BuildContext context) {
    final staticAudios = ValerionAudios.getCatalogue(context);
    return Column(
      children: staticAudios.map((audio) {
        return buildAudioCard(audio.title, audio.subtitle, Icons.music_note, audio.audioUrl);
      }).toList(),
    );
  }
}
