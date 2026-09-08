import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'OSIRION'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue dans l\'architecte de destin'**
  String get welcomeMessage;

  /// No description provided for @winterArc.
  ///
  /// In fr, this message translates to:
  /// **'Winter Arc'**
  String get winterArc;

  /// No description provided for @summerArc.
  ///
  /// In fr, this message translates to:
  /// **'Summer Arc'**
  String get summerArc;

  /// No description provided for @royalArc.
  ///
  /// In fr, this message translates to:
  /// **'Royal Arc'**
  String get royalArc;

  /// No description provided for @arenaAnomalieDTectE.
  ///
  /// In fr, this message translates to:
  /// **'ANOMALIE DÉTECTÉE'**
  String get arenaAnomalieDTectE;

  /// No description provided for @arenaLUtilisationDUne.
  ///
  /// In fr, this message translates to:
  /// **'L\'utilisation d\'une position GPS simulée est interdite par les protocoles de Valerion. Votre session a été interrompue.'**
  String get arenaLUtilisationDUne;

  /// No description provided for @arenaAlerteZoneCompromiseRecalcul.
  ///
  /// In fr, this message translates to:
  /// **'ALERTE : ZONE COMPROMISE - RECALCUL TACTIQUE'**
  String get arenaAlerteZoneCompromiseRecalcul;

  /// No description provided for @arenaSignalementEnvoyUplinkTactique.
  ///
  /// In fr, this message translates to:
  /// **'SIGNALEMENT ENVOYÉ - UPLINK TACTIQUE ÉTABLI'**
  String get arenaSignalementEnvoyUplinkTactique;

  /// No description provided for @arenaVRificationDesProtocoles.
  ///
  /// In fr, this message translates to:
  /// **'VÉRIFICATION DES PROTOCOLES ALPHA...'**
  String get arenaVRificationDesProtocoles;

  /// No description provided for @arenaRivalGhost.
  ///
  /// In fr, this message translates to:
  /// **'RIVAL GHOST'**
  String get arenaRivalGhost;

  /// No description provided for @arenaDFiPerformanceD.
  ///
  /// In fr, this message translates to:
  /// **'DÉFI PERFORMANCE DÉTECTÉ'**
  String get arenaDFiPerformanceD;

  /// No description provided for @arenaPerformanceExceptionnelle.
  ///
  /// In fr, this message translates to:
  /// **'Performance exceptionnelle.'**
  String get arenaPerformanceExceptionnelle;

  /// No description provided for @arenaVoulezVousGraverCe.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous graver ce tracé dans la section rivaux afin que d\'autres puissent affronter votre Ghost ?'**
  String get arenaVoulezVousGraverCe;

  /// No description provided for @arenaGraverLeTrac.
  ///
  /// In fr, this message translates to:
  /// **'GRAVER LE TRACÉ'**
  String get arenaGraverLeTrac;

  /// No description provided for @arenaGravureDansLeColis.
  ///
  /// In fr, this message translates to:
  /// **'GRAVURE DANS LE COLISÉE EN COURS...'**
  String get arenaGravureDansLeColis;

  /// No description provided for @arenaSessionEnregistrETrac.
  ///
  /// In fr, this message translates to:
  /// **'SESSION ENREGISTRÉE : TRACÉ PARTAGÉ AVEC LA COMMUNAUTÉ.'**
  String get arenaSessionEnregistrETrac;

  /// No description provided for @arenaSynchronisationDeLaSession.
  ///
  /// In fr, this message translates to:
  /// **'SYNCHRONISATION DE LA SESSION...'**
  String get arenaSynchronisationDeLaSession;

  /// No description provided for @arenaSessionTerminE.
  ///
  /// In fr, this message translates to:
  /// **'SESSION TERMINÉE'**
  String get arenaSessionTerminE;

  /// No description provided for @arenaAucuneDonnEGps.
  ///
  /// In fr, this message translates to:
  /// **'AUCUNE DONNÉE GPS'**
  String get arenaAucuneDonnEGps;

  /// No description provided for @arenaAllureMoy.
  ///
  /// In fr, this message translates to:
  /// **'ALLURE MOY.'**
  String get arenaAllureMoy;

  /// No description provided for @arenaAnalyseDeLaVitesse.
  ///
  /// In fr, this message translates to:
  /// **'ANALYSE DE LA VITESSE (KM/H)'**
  String get arenaAnalyseDeLaVitesse;

  /// No description provided for @arenaRCompensesAcquises.
  ///
  /// In fr, this message translates to:
  /// **'RÉCOMPENSES ACQUISES'**
  String get arenaRCompensesAcquises;

  /// No description provided for @arenaRetournerAuMenu.
  ///
  /// In fr, this message translates to:
  /// **'RETOURNER AU MENU'**
  String get arenaRetournerAuMenu;

  /// No description provided for @arenaLArNe.
  ///
  /// In fr, this message translates to:
  /// **'L\'ARÈNE'**
  String get arenaLArNe;

  /// No description provided for @arenaTricheDTectE.
  ///
  /// In fr, this message translates to:
  /// **'TRICHE DÉTECTÉE : Veuillez désactiver les fausses positions GPS (Mock Locations).'**
  String get arenaTricheDTectE;

  /// No description provided for @arenaDClarezVosR.
  ///
  /// In fr, this message translates to:
  /// **'DÉCLAREZ VOS RÉSULTATS POUR PRENDRE LE CONTRÔLE.'**
  String get arenaDClarezVosR;

  /// No description provided for @arenaErreurVousDevezEffectuer.
  ///
  /// In fr, this message translates to:
  /// **'ERREUR : VOUS DEVEZ EFFECTUER AU MOINS UNE RÉPÉTITION.'**
  String get arenaErreurVousDevezEffectuer;

  /// No description provided for @arenaConquRir.
  ///
  /// In fr, this message translates to:
  /// **'CONQUÉRIR'**
  String get arenaConquRir;

  /// No description provided for @arenaRadarDeBastions.
  ///
  /// In fr, this message translates to:
  /// **'RADAR DE BASTIONS'**
  String get arenaRadarDeBastions;

  /// No description provided for @arenaProtocoleOsirionScan.
  ///
  /// In fr, this message translates to:
  /// **'PROTOCOLE OSIRION : SCAN...'**
  String get arenaProtocoleOsirionScan;

  /// No description provided for @arenaQuartierSCurisAucun.
  ///
  /// In fr, this message translates to:
  /// **'QUARTIER SÉCURISÉ : AUCUN BASTION'**
  String get arenaQuartierSCurisAucun;

  /// No description provided for @arenaSignalTropFaibleRapprochez.
  ///
  /// In fr, this message translates to:
  /// **'SIGNAL TROP FAIBLE : Rapprochez-vous à moins de 50m.'**
  String get arenaSignalTropFaibleRapprochez;

  /// No description provided for @arenaAucunQuipementSpCifique.
  ///
  /// In fr, this message translates to:
  /// **'Aucun équipement spécifique détecté par les capteurs OSM.'**
  String get arenaAucunQuipementSpCifique;

  /// No description provided for @arenaPositionSatelliteGuidage.
  ///
  /// In fr, this message translates to:
  /// **'POSITION SATELLITE (GUIDAGE)'**
  String get arenaPositionSatelliteGuidage;

  /// No description provided for @arenaMissionDeReconnaissance.
  ///
  /// In fr, this message translates to:
  /// **'MISSION DE RECONNAISSANCE'**
  String get arenaMissionDeReconnaissance;

  /// No description provided for @arenaFournissezLeRenseignementVisuel.
  ///
  /// In fr, this message translates to:
  /// **'FOURNISSEZ LE RENSEIGNEMENT VISUEL'**
  String get arenaFournissezLeRenseignementVisuel;

  /// No description provided for @arenaCapturerLIntel.
  ///
  /// In fr, this message translates to:
  /// **'CAPTURER L\'INTEL'**
  String get arenaCapturerLIntel;

  /// No description provided for @arena250Xp.
  ///
  /// In fr, this message translates to:
  /// **'+250 XP'**
  String get arena250Xp;

  /// No description provided for @arenaErreurSignalGpsPosition.
  ///
  /// In fr, this message translates to:
  /// **'ERREUR SIGNAL GPS : Position non détectée. Attendez le fix GPS.'**
  String get arenaErreurSignalGpsPosition;

  /// No description provided for @arenaRenseignementTransmis250Xp.
  ///
  /// In fr, this message translates to:
  /// **'RENSEIGNEMENT TRANSMIS : +250 XP ! OSIRION vous remercie, Éclaireur.'**
  String get arenaRenseignementTransmis250Xp;

  /// No description provided for @arenaImpossibleDeLancerLe.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lancer le guidage satellite.'**
  String get arenaImpossibleDeLancerLe;

  /// No description provided for @arenaViolationDeSCurit.
  ///
  /// In fr, this message translates to:
  /// **'VIOLATION DE SÉCURITÉ'**
  String get arenaViolationDeSCurit;

  /// No description provided for @arenaVousTesTropLoin.
  ///
  /// In fr, this message translates to:
  /// **'VOUS ÊTES TROP LOIN'**
  String get arenaVousTesTropLoin;

  /// No description provided for @arenaAutorisationRequise.
  ///
  /// In fr, this message translates to:
  /// **'AUTORISATION REQUISE'**
  String get arenaAutorisationRequise;

  /// No description provided for @arenaSoyezLePremierGraver.
  ///
  /// In fr, this message translates to:
  /// **'Soyez le premier à graver votre exploit !'**
  String get arenaSoyezLePremierGraver;

  /// No description provided for @arenaMatchmakingGlobalAlphaDisponible.
  ///
  /// In fr, this message translates to:
  /// **'MATCHMAKING GLOBAL ALPHA DISPONIBLE'**
  String get arenaMatchmakingGlobalAlphaDisponible;

  /// No description provided for @arenaModeMatchmakingRelatifGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Mode : Matchmaking Relatif Global'**
  String get arenaModeMatchmakingRelatifGlobal;

  /// No description provided for @arenaVousAllezAffronterLe.
  ///
  /// In fr, this message translates to:
  /// **'Vous allez affronter le fantôme de ce coureur sur votre propre terrain.'**
  String get arenaVousAllezAffronterLe;

  /// No description provided for @arenaLancerLeDuel.
  ///
  /// In fr, this message translates to:
  /// **'LANCER LE DUEL'**
  String get arenaLancerLeDuel;

  /// No description provided for @arenaGNRerLa.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRER LA BOUCLE'**
  String get arenaGNRerLa;

  /// No description provided for @arenaLesTerritoires.
  ///
  /// In fr, this message translates to:
  /// **'LES TERRITOIRES'**
  String get arenaLesTerritoires;

  /// No description provided for @arenaConquTesGOlocalis.
  ///
  /// In fr, this message translates to:
  /// **'Conquêtes géolocalisées via grille hexagonale. Courez pour dominer votre quartier.'**
  String get arenaConquTesGOlocalis;

  /// No description provided for @arenaDVeloppementEnCours.
  ///
  /// In fr, this message translates to:
  /// **'DÉVELOPPEMENT EN COURS (MAP ENGINE)'**
  String get arenaDVeloppementEnCours;

  /// No description provided for @arenaValiderLaDestination.
  ///
  /// In fr, this message translates to:
  /// **'VALIDER LA DESTINATION'**
  String get arenaValiderLaDestination;

  /// No description provided for @arenaOsirionPerformance.
  ///
  /// In fr, this message translates to:
  /// **'OSIRION PERFORMANCE'**
  String get arenaOsirionPerformance;

  /// No description provided for @arenaAucunTracDisponible.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN TRACÉ DISPONIBLE'**
  String get arenaAucunTracDisponible;

  /// No description provided for @arenaEngineeredByValerion.
  ///
  /// In fr, this message translates to:
  /// **'ENGINEERED BY VALERION'**
  String get arenaEngineeredByValerion;

  /// No description provided for @arenaSessionTropCourtePour.
  ///
  /// In fr, this message translates to:
  /// **'SESSION TROP COURTE POUR ANALYSE'**
  String get arenaSessionTropCourtePour;

  /// No description provided for @arenaPartageDePerformance.
  ///
  /// In fr, this message translates to:
  /// **'PARTAGE DE PERFORMANCE'**
  String get arenaPartageDePerformance;

  /// No description provided for @arenaPerformancePartagEAvec.
  ///
  /// In fr, this message translates to:
  /// **'Performance partagée avec succès 🚀'**
  String get arenaPerformancePartagEAvec;

  /// No description provided for @arenaRSeauAthlTes.
  ///
  /// In fr, this message translates to:
  /// **'RÉSEAU ATHLÈTES'**
  String get arenaRSeauAthlTes;

  /// No description provided for @arenaQuipesClubs.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPES & CLUBS'**
  String get arenaQuipesClubs;

  /// No description provided for @dojoQuTeQuotidienneAccomplie.
  ///
  /// In fr, this message translates to:
  /// **'🏆 QUÊTE QUOTIDIENNE ACCOMPLIE : 50 POMPES ! (+20 XP)'**
  String get dojoQuTeQuotidienneAccomplie;

  /// No description provided for @dojoConnexionNeurologique.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Neurologique...'**
  String get dojoConnexionNeurologique;

  /// No description provided for @dojoCalibrationIaEnCours.
  ///
  /// In fr, this message translates to:
  /// **'CALIBRATION IA EN COURS...'**
  String get dojoCalibrationIaEnCours;

  /// No description provided for @dojoAdaptationVotreMorphologie.
  ///
  /// In fr, this message translates to:
  /// **'ADAPTATION À VOTRE MORPHOLOGIE'**
  String get dojoAdaptationVotreMorphologie;

  /// No description provided for @dojoCorpsNonDTect.
  ///
  /// In fr, this message translates to:
  /// **'CORPS NON DÉTECTÉ'**
  String get dojoCorpsNonDTect;

  /// No description provided for @dojoRSultatsSynchronisS.
  ///
  /// In fr, this message translates to:
  /// **'Résultats synchronisés !'**
  String get dojoRSultatsSynchronisS;

  /// No description provided for @dojoRapportDeMission.
  ///
  /// In fr, this message translates to:
  /// **'RAPPORT DE MISSION'**
  String get dojoRapportDeMission;

  /// No description provided for @dojoValiderLEntraNement.
  ///
  /// In fr, this message translates to:
  /// **'VALIDER L\'ENTRAÎNEMENT'**
  String get dojoValiderLEntraNement;

  /// No description provided for @dojoLeDojoConfiguration.
  ///
  /// In fr, this message translates to:
  /// **'LE DOJO : CONFIGURATION'**
  String get dojoLeDojoConfiguration;

  /// No description provided for @dojoModeVision.
  ///
  /// In fr, this message translates to:
  /// **'MODE VISION'**
  String get dojoModeVision;

  /// No description provided for @dojoIaActiveTrackingDes.
  ///
  /// In fr, this message translates to:
  /// **'IA Active • Tracking des Articulations • Feedback Auto'**
  String get dojoIaActiveTrackingDes;

  /// No description provided for @dojoModeGuide.
  ///
  /// In fr, this message translates to:
  /// **'MODE GUIDE'**
  String get dojoModeGuide;

  /// No description provided for @dojoSimulation3dModeChrono.
  ///
  /// In fr, this message translates to:
  /// **'Simulation 3D • Mode Chrono • Validation Manuelle'**
  String get dojoSimulation3dModeChrono;

  /// No description provided for @dojoDMonstration.
  ///
  /// In fr, this message translates to:
  /// **'DÉMONSTRATION'**
  String get dojoDMonstration;

  /// No description provided for @dojoAngleCamRaRequis.
  ///
  /// In fr, this message translates to:
  /// **'ANGLE CAMÉRA REQUIS'**
  String get dojoAngleCamRaRequis;

  /// No description provided for @dojoCommencerLeProtocole.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER LE PROTOCOLE'**
  String get dojoCommencerLeProtocole;

  /// No description provided for @dojoPrPareToi.
  ///
  /// In fr, this message translates to:
  /// **'PRÉPARE-TOI'**
  String get dojoPrPareToi;

  /// No description provided for @dojoVidODeD.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo de démonstration\\nbientôt disponible'**
  String get dojoVidODeD;

  /// No description provided for @dojoChargementDMo.
  ///
  /// In fr, this message translates to:
  /// **'CHARGEMENT DÉMO...'**
  String get dojoChargementDMo;

  /// No description provided for @dojoVidONonDisponible.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo non disponible\\nVous pourrez quand même démarrer l\'exercice'**
  String get dojoVidONonDisponible;

  /// No description provided for @dojoIgnorerLaDMo.
  ///
  /// In fr, this message translates to:
  /// **'IGNORER LA DÉMO'**
  String get dojoIgnorerLaDMo;

  /// No description provided for @dojoSLectionDeL.
  ///
  /// In fr, this message translates to:
  /// **'SÉLECTION DE L\'EXERCICE'**
  String get dojoSLectionDeL;

  /// No description provided for @dojoAucunProtocoleDisponiblePour.
  ///
  /// In fr, this message translates to:
  /// **'Aucun protocole disponible pour cette configuration.'**
  String get dojoAucunProtocoleDisponiblePour;

  /// No description provided for @dojoSimulationHq.
  ///
  /// In fr, this message translates to:
  /// **'SIMULATION HQ'**
  String get dojoSimulationHq;

  /// No description provided for @dojoCalibrageDuFlux.
  ///
  /// In fr, this message translates to:
  /// **'CALIBRAGE DU FLUX...'**
  String get dojoCalibrageDuFlux;

  /// No description provided for @dojoDMarrerLEntra.
  ///
  /// In fr, this message translates to:
  /// **'DÉMARRER L\'ENTRAÎNEMENT'**
  String get dojoDMarrerLEntra;

  /// No description provided for @dojoPrParezVous.
  ///
  /// In fr, this message translates to:
  /// **'PRÉPAREZ-VOUS...'**
  String get dojoPrParezVous;

  /// No description provided for @dojoRPTitions.
  ///
  /// In fr, this message translates to:
  /// **'RÉPÉTITIONS'**
  String get dojoRPTitions;

  /// No description provided for @dojoTapezLeCercleChaque.
  ///
  /// In fr, this message translates to:
  /// **'(Tapez le cercle à chaque répétition)'**
  String get dojoTapezLeCercleChaque;

  /// No description provided for @dojoEmptyKey.
  ///
  /// In fr, this message translates to:
  /// **'🧠'**
  String get dojoEmptyKey;

  /// No description provided for @dojoDurE.
  ///
  /// In fr, this message translates to:
  /// **'DURÉE'**
  String get dojoDurE;

  /// No description provided for @dojoXpGagnS.
  ///
  /// In fr, this message translates to:
  /// **'XP GAGNÉS'**
  String get dojoXpGagnS;

  /// No description provided for @libraryLeOnAncrE.
  ///
  /// In fr, this message translates to:
  /// **'Leçon ancrée dans le Livre d\'Or. +10 XP.'**
  String get libraryLeOnAncrE;

  /// No description provided for @librarySessionTerminE.
  ///
  /// In fr, this message translates to:
  /// **'Session Terminée'**
  String get librarySessionTerminE;

  /// No description provided for @libraryProuesseIntellectuelleValidE.
  ///
  /// In fr, this message translates to:
  /// **'Prouesse intellectuelle validée. +15 XP de Sagesse.'**
  String get libraryProuesseIntellectuelleValidE;

  /// No description provided for @libraryLaForgeDeL.
  ///
  /// In fr, this message translates to:
  /// **'LA FORGE DE L\'ESPRIT'**
  String get libraryLaForgeDeL;

  /// No description provided for @libraryMigrationFirestoreRUssie.
  ///
  /// In fr, this message translates to:
  /// **'✅ Migration Firestore réussie (Livres, Audios, Reliques) !'**
  String get libraryMigrationFirestoreRUssie;

  /// No description provided for @libraryMigrerCloud.
  ///
  /// In fr, this message translates to:
  /// **'MIGRER CLOUD'**
  String get libraryMigrerCloud;

  /// No description provided for @libraryCollectionsFirestorePurgEs.
  ///
  /// In fr, this message translates to:
  /// **'🧹 Collections Firestore purgées (Livres, Audios, Reliques, Dojo) !'**
  String get libraryCollectionsFirestorePurgEs;

  /// No description provided for @librarySagesseActuelle.
  ///
  /// In fr, this message translates to:
  /// **'Sagesse Actuelle'**
  String get librarySagesseActuelle;

  /// No description provided for @libraryNePasDRanger.
  ///
  /// In fr, this message translates to:
  /// **'NE PAS DÉRANGER ACTIVÉ'**
  String get libraryNePasDRanger;

  /// No description provided for @libraryContratDHonneur.
  ///
  /// In fr, this message translates to:
  /// **'CONTRAT D\'HONNEUR'**
  String get libraryContratDHonneur;

  /// No description provided for @libraryLaVieNeVaut.
  ///
  /// In fr, this message translates to:
  /// **'\\\"La vie ne vaut d\'être vécue sans être examinée.\\\"'**
  String get libraryLaVieNeVaut;

  /// No description provided for @libraryAiJeTFid.
  ///
  /// In fr, this message translates to:
  /// **'Ai-je été fidèle à mes valeurs et à mes objectifs aujourd\'hui ?'**
  String get libraryAiJeTFid;

  /// No description provided for @libraryScellerLeContrat.
  ///
  /// In fr, this message translates to:
  /// **'SCELLER LE CONTRAT'**
  String get libraryScellerLeContrat;

  /// No description provided for @libraryOuvrirLeLivreD.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le Livre d\'Or (Archives)'**
  String get libraryOuvrirLeLivreD;

  /// No description provided for @libraryRCupRationMentale.
  ///
  /// In fr, this message translates to:
  /// **'RÉCUPÉRATION MENTALE'**
  String get libraryRCupRationMentale;

  /// No description provided for @libraryDevenezAlpha.
  ///
  /// In fr, this message translates to:
  /// **'Devenez Alpha+'**
  String get libraryDevenezAlpha;

  /// No description provided for @libraryDBloquezLeMode.
  ///
  /// In fr, this message translates to:
  /// **'Débloquez le mode hors ligne et des thématiques niches.'**
  String get libraryDBloquezLeMode;

  /// No description provided for @libraryThMe.
  ///
  /// In fr, this message translates to:
  /// **'THÈME'**
  String get libraryThMe;

  /// No description provided for @libraryPourquoiLIntGrer.
  ///
  /// In fr, this message translates to:
  /// **'POURQUOI L\'INTÉGRER ?'**
  String get libraryPourquoiLIntGrer;

  /// No description provided for @libraryCitationCl.
  ///
  /// In fr, this message translates to:
  /// **'CITATION CLÉ'**
  String get libraryCitationCl;

  /// No description provided for @libraryLancerLaLecture.
  ///
  /// In fr, this message translates to:
  /// **'LANCER LA LECTURE'**
  String get libraryLancerLaLecture;

  /// No description provided for @libraryAucunLivreTrouv.
  ///
  /// In fr, this message translates to:
  /// **'Aucun livre trouvé.'**
  String get libraryAucunLivreTrouv;

  /// No description provided for @libraryNouveauxContenusSynchronisS.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux contenus synchronisés avec Firestore'**
  String get libraryNouveauxContenusSynchronisS;

  /// No description provided for @libraryAnnulerLaLecture.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la lecture'**
  String get libraryAnnulerLaLecture;

  /// No description provided for @libraryQuelleLeOnAvez.
  ///
  /// In fr, this message translates to:
  /// **'Quelle leçon avez-vous tiré aujourd\'hui ?'**
  String get libraryQuelleLeOnAvez;

  /// No description provided for @libraryHagakureLeCodeDu.
  ///
  /// In fr, this message translates to:
  /// **'Hagakure : Le Code du Samouraï'**
  String get libraryHagakureLeCodeDu;

  /// No description provided for @libraryLObstacleEstLe.
  ///
  /// In fr, this message translates to:
  /// **'L\'Obstacle est le Chemin'**
  String get libraryLObstacleEstLe;

  /// No description provided for @libraryLeManuel.
  ///
  /// In fr, this message translates to:
  /// **'Le Manuel'**
  String get libraryLeManuel;

  /// No description provided for @libraryPensEsPourMoi.
  ///
  /// In fr, this message translates to:
  /// **'Pensées pour moi-même'**
  String get libraryPensEsPourMoi;

  /// No description provided for @libraryDeLaBriVet.
  ///
  /// In fr, this message translates to:
  /// **'De la brièveté de la vie'**
  String get libraryDeLaBriVet;

  /// No description provided for @libraryDeLaTranquillitDe.
  ///
  /// In fr, this message translates to:
  /// **'De la tranquillité de l\'âme'**
  String get libraryDeLaTranquillitDe;

  /// No description provided for @libraryConsolationDeLaPhilosophie.
  ///
  /// In fr, this message translates to:
  /// **'Consolation de la philosophie'**
  String get libraryConsolationDeLaPhilosophie;

  /// No description provided for @libraryAtomicHabits.
  ///
  /// In fr, this message translates to:
  /// **'Atomic Habits'**
  String get libraryAtomicHabits;

  /// No description provided for @libraryLaPsychologieDesFoules.
  ///
  /// In fr, this message translates to:
  /// **'La Psychologie des foules'**
  String get libraryLaPsychologieDesFoules;

  /// No description provided for @libraryLArtDAvoir.
  ///
  /// In fr, this message translates to:
  /// **'L\'Art d\'avoir toujours raison'**
  String get libraryLArtDAvoir;

  /// No description provided for @libraryLesCaractRes.
  ///
  /// In fr, this message translates to:
  /// **'Les Caractères'**
  String get libraryLesCaractRes;

  /// No description provided for @libraryTraitDeLaVie.
  ///
  /// In fr, this message translates to:
  /// **'Traité de la vie élégante'**
  String get libraryTraitDeLaVie;

  /// No description provided for @libraryLArtDeLa.
  ///
  /// In fr, this message translates to:
  /// **'L\'Art de la Guerre'**
  String get libraryLArtDeLa;

  /// No description provided for @libraryLePrince.
  ///
  /// In fr, this message translates to:
  /// **'Le Prince'**
  String get libraryLePrince;

  /// No description provided for @libraryTraitDesCinqRoues.
  ///
  /// In fr, this message translates to:
  /// **'Traité des cinq roues'**
  String get libraryTraitDesCinqRoues;

  /// No description provided for @libraryTaoTeKing.
  ///
  /// In fr, this message translates to:
  /// **'Tao Te King'**
  String get libraryTaoTeKing;

  /// No description provided for @libraryLeLivreDuCourtisan.
  ///
  /// In fr, this message translates to:
  /// **'Le Livre du Courtisan'**
  String get libraryLeLivreDuCourtisan;

  /// No description provided for @libraryTempsCoul.
  ///
  /// In fr, this message translates to:
  /// **'TEMPS ÉCOULÉ'**
  String get libraryTempsCoul;

  /// No description provided for @librarySouhaitezVousContinuerLire.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous continuer à lire pour 15 minutes supplémentaires, ou sceller la session et rédiger votre contrat d\'honneur ?'**
  String get librarySouhaitezVousContinuerLire;

  /// No description provided for @libraryForger15Min.
  ///
  /// In fr, this message translates to:
  /// **'FORGER (+15 MIN)'**
  String get libraryForger15Min;

  /// No description provided for @libraryScellerLaSession.
  ///
  /// In fr, this message translates to:
  /// **'SCELLER LA SESSION'**
  String get libraryScellerLaSession;

  /// No description provided for @libraryTempsRestant.
  ///
  /// In fr, this message translates to:
  /// **'Temps Restant'**
  String get libraryTempsRestant;

  /// No description provided for @arsenalLArsenal.
  ///
  /// In fr, this message translates to:
  /// **'L\'ARSENAL'**
  String get arsenalLArsenal;

  /// No description provided for @arsenalPossD.
  ///
  /// In fr, this message translates to:
  /// **'POSSÉDÉ'**
  String get arsenalPossD;

  /// No description provided for @arsenalPacteDuForgeron.
  ///
  /// In fr, this message translates to:
  /// **'Pacte du Forgeron'**
  String get arsenalPacteDuForgeron;

  /// No description provided for @arsenalVotreSacEstVide.
  ///
  /// In fr, this message translates to:
  /// **'Votre sac est vide. Visitez le Forgeron.'**
  String get arsenalVotreSacEstVide;

  /// No description provided for @laboratoryInitialisationDeLaVision.
  ///
  /// In fr, this message translates to:
  /// **'Initialisation de la vision IA...'**
  String get laboratoryInitialisationDeLaVision;

  /// No description provided for @laboratoryEntraNementEnPause.
  ///
  /// In fr, this message translates to:
  /// **'Entraînement en pause (Simulation)'**
  String get laboratoryEntraNementEnPause;

  /// No description provided for @laboratoryLeLaboratoire.
  ///
  /// In fr, this message translates to:
  /// **'LE LABORATOIRE'**
  String get laboratoryLeLaboratoire;

  /// No description provided for @laboratoryAucunProfilDTect.
  ///
  /// In fr, this message translates to:
  /// **'Aucun profil détecté.'**
  String get laboratoryAucunProfilDTect;

  /// No description provided for @laboratoryVosStatistiquesDeCombat.
  ///
  /// In fr, this message translates to:
  /// **'Vos statistiques de combat (XP Force, Sagesse, Records Tractions/Pompes) ne peuvent pas être altérées manuellement. Elles sont régies exclusivement par l\'Intelligence Artificielle du Dojo et vos entraînements validés.'**
  String get laboratoryVosStatistiquesDeCombat;

  /// No description provided for @laboratorySynchroniserLesModifications.
  ///
  /// In fr, this message translates to:
  /// **'SYNCHRONISER LES MODIFICATIONS'**
  String get laboratorySynchroniserLesModifications;

  /// No description provided for @laboratoryAvatarMisJourDans.
  ///
  /// In fr, this message translates to:
  /// **'Avatar mis à jour dans le Cloud.'**
  String get laboratoryAvatarMisJourDans;

  /// No description provided for @laboratoryStatutDeSynchronisation.
  ///
  /// In fr, this message translates to:
  /// **'Statut de Synchronisation'**
  String get laboratoryStatutDeSynchronisation;

  /// No description provided for @laboratorySauvegardeForcER.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde forcée réussie.'**
  String get laboratorySauvegardeForcER;

  /// No description provided for @laboratoryCacheEtFichiersTemporaires.
  ///
  /// In fr, this message translates to:
  /// **'Cache et fichiers temporaires nettoyés.'**
  String get laboratoryCacheEtFichiersTemporaires;

  /// No description provided for @laboratoryAttentionCesFonctionnalitS.
  ///
  /// In fr, this message translates to:
  /// **'ATTENTION : Ces fonctionnalités expérimentales peuvent être instables ou fortement solliciter la batterie.'**
  String get laboratoryAttentionCesFonctionnalitS;

  /// No description provided for @laboratoryCentreDAideOsirion.
  ///
  /// In fr, this message translates to:
  /// **'CENTRE D\'AIDE OSIRION'**
  String get laboratoryCentreDAideOsirion;

  /// No description provided for @laboratoryDiagnosticSystMe.
  ///
  /// In fr, this message translates to:
  /// **'DIAGNOSTIC SYSTÈME'**
  String get laboratoryDiagnosticSystMe;

  /// No description provided for @laboratorySignalementValerion.
  ///
  /// In fr, this message translates to:
  /// **'SIGNALEMENT VALERION'**
  String get laboratorySignalementValerion;

  /// No description provided for @laboratoryTypeDeRetour.
  ///
  /// In fr, this message translates to:
  /// **'TYPE DE RETOUR'**
  String get laboratoryTypeDeRetour;

  /// No description provided for @laboratoryNoteLesDonnEs.
  ///
  /// In fr, this message translates to:
  /// **'Note : Les données de diagnostic (OS, Version, Niveau) seront jointes automatiquement.'**
  String get laboratoryNoteLesDonnEs;

  /// No description provided for @laboratoryChecDirectOuvertureDu.
  ///
  /// In fr, this message translates to:
  /// **'Échec direct. Ouverture du menu de partage...'**
  String get laboratoryChecDirectOuvertureDu;

  /// No description provided for @smartMapParcoursDeSant.
  ///
  /// In fr, this message translates to:
  /// **'Parcours de Santé'**
  String get smartMapParcoursDeSant;

  /// No description provided for @smartMapParcoursOptimisS.
  ///
  /// In fr, this message translates to:
  /// **'Parcours Optimisés'**
  String get smartMapParcoursOptimisS;

  /// No description provided for @smartMapDCouvrezDesItin.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez des itinéraires adaptés à votre niveau.'**
  String get smartMapDCouvrezDesItin;

  /// No description provided for @smartMapLArNe.
  ///
  /// In fr, this message translates to:
  /// **'L\'ARÈNE'**
  String get smartMapLArNe;

  /// No description provided for @smartMapSignalDeDTresse.
  ///
  /// In fr, this message translates to:
  /// **'Signal de détresse prêt à être envoyé.'**
  String get smartMapSignalDeDTresse;

  /// No description provided for @smartMapDMarrer.
  ///
  /// In fr, this message translates to:
  /// **'DÉMARRER'**
  String get smartMapDMarrer;

  /// No description provided for @smartMapPhaseDInitialisationAr.
  ///
  /// In fr, this message translates to:
  /// **'Phase d\'initialisation Arène...'**
  String get smartMapPhaseDInitialisationAr;

  /// No description provided for @smartMapParcNord.
  ///
  /// In fr, this message translates to:
  /// **'Parc Nord'**
  String get smartMapParcNord;

  /// No description provided for @smartMapDistanceCible.
  ///
  /// In fr, this message translates to:
  /// **'Distance Cible'**
  String get smartMapDistanceCible;

  /// No description provided for @smartMapGNRer3.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRER 3 OPTIONS DE TRÈFLE'**
  String get smartMapGNRer3;

  /// No description provided for @smartMapSYRendreGps.
  ///
  /// In fr, this message translates to:
  /// **'S\'y rendre (GPS)'**
  String get smartMapSYRendreGps;

  /// No description provided for @smartMapOmbrePersonnelle.
  ///
  /// In fr, this message translates to:
  /// **'Ombre Personnelle'**
  String get smartMapOmbrePersonnelle;

  /// No description provided for @smartMapRecord2845.
  ///
  /// In fr, this message translates to:
  /// **'Record: 28:45'**
  String get smartMapRecord2845;

  /// No description provided for @smartMapCourezContreVotrePerformance.
  ///
  /// In fr, this message translates to:
  /// **'Courez contre votre performance du 12 Février sur la boucle de 6 km. L\'audio vous donnera votre retard/avance.'**
  String get smartMapCourezContreVotrePerformance;

  /// No description provided for @smartMapLeaderboardsSegments.
  ///
  /// In fr, this message translates to:
  /// **'LEADERBOARDS SEGMENTS'**
  String get smartMapLeaderboardsSegments;

  /// No description provided for @smartMapCoachVocalDucking.
  ///
  /// In fr, this message translates to:
  /// **'Coach Vocal (Ducking)'**
  String get smartMapCoachVocalDucking;

  /// No description provided for @smartMapAttNueSpotifyLors.
  ///
  /// In fr, this message translates to:
  /// **'Atténue Spotify lors des directions'**
  String get smartMapAttNueSpotifyLors;

  /// No description provided for @smartMapSafetySync.
  ///
  /// In fr, this message translates to:
  /// **'Safety Sync'**
  String get smartMapSafetySync;

  /// No description provided for @smartMapPartageEnDirectContact.
  ///
  /// In fr, this message translates to:
  /// **'Partage en direct (Contact urgence)'**
  String get smartMapPartageEnDirectContact;

  /// No description provided for @splashOSIR.
  ///
  /// In fr, this message translates to:
  /// **'O S I R I O N'**
  String get splashOSIR;

  /// No description provided for @splashForceLoyautSagesse.
  ///
  /// In fr, this message translates to:
  /// **'FORCE . LOYAUTÉ . SAGESSE'**
  String get splashForceLoyautSagesse;

  /// No description provided for @visionAiVisionAiActive.
  ///
  /// In fr, this message translates to:
  /// **'Vision AI Active'**
  String get visionAiVisionAiActive;

  /// No description provided for @homeMenuAlpha.
  ///
  /// In fr, this message translates to:
  /// **'MENU ALPHA'**
  String get homeMenuAlpha;

  /// No description provided for @homeQuitterLaSession.
  ///
  /// In fr, this message translates to:
  /// **'QUITTER LA SESSION'**
  String get homeQuitterLaSession;

  /// No description provided for @homeBalanceDesForces.
  ///
  /// In fr, this message translates to:
  /// **'BALANCE DES FORCES'**
  String get homeBalanceDesForces;

  /// No description provided for @homeRoyalArc.
  ///
  /// In fr, this message translates to:
  /// **'ROYAL ARC'**
  String get homeRoyalArc;

  /// No description provided for @homeLeCouronnementAlpha.
  ///
  /// In fr, this message translates to:
  /// **'LE COURONNEMENT ALPHA'**
  String get homeLeCouronnementAlpha;

  /// No description provided for @homeSummerBody.
  ///
  /// In fr, this message translates to:
  /// **'SUMMER BODY'**
  String get homeSummerBody;

  /// No description provided for @homeLClatDeL.
  ///
  /// In fr, this message translates to:
  /// **'L\'ÉCLAT DE L\'EFFORT'**
  String get homeLClatDeL;

  /// No description provided for @homeWinterArc.
  ///
  /// In fr, this message translates to:
  /// **'WINTER ARC'**
  String get homeWinterArc;

  /// No description provided for @homeLaForgeDansL.
  ///
  /// In fr, this message translates to:
  /// **'LA FORGE DANS L\'OMBRE'**
  String get homeLaForgeDansL;

  /// No description provided for @homePilierPhysique.
  ///
  /// In fr, this message translates to:
  /// **'Pilier Physique'**
  String get homePilierPhysique;

  /// No description provided for @homePilierMental.
  ///
  /// In fr, this message translates to:
  /// **'Pilier Mental'**
  String get homePilierMental;

  /// No description provided for @homeActionLifestyle.
  ///
  /// In fr, this message translates to:
  /// **'Action Lifestyle'**
  String get homeActionLifestyle;

  /// No description provided for @homeSuggestionsLecture.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions Lecture'**
  String get homeSuggestionsLecture;

  /// No description provided for @homeLaBibliothQueDu.
  ///
  /// In fr, this message translates to:
  /// **'La Bibliothèque du Winter Arc'**
  String get homeLaBibliothQueDu;

  /// No description provided for @homeRCompensesAjoutEs.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses ajoutées à ton profil ! 🏆'**
  String get homeRCompensesAjoutEs;

  /// No description provided for @homeArcTermin.
  ///
  /// In fr, this message translates to:
  /// **'ARC TERMINÉ'**
  String get homeArcTermin;

  /// No description provided for @homeRClamerEtEntrer.
  ///
  /// In fr, this message translates to:
  /// **'RÉCLAMER ET ENTRER DANS LA LUMIÈRE'**
  String get homeRClamerEtEntrer;

  /// No description provided for @homePulseQuotidien.
  ///
  /// In fr, this message translates to:
  /// **'PULSE QUOTIDIEN'**
  String get homePulseQuotidien;

  /// No description provided for @homeTransmissionAlpha.
  ///
  /// In fr, this message translates to:
  /// **'TRANSMISSION ALPHA'**
  String get homeTransmissionAlpha;

  /// No description provided for @homeOuvrirLaVidO.
  ///
  /// In fr, this message translates to:
  /// **'OUVRIR LA VIDÉO'**
  String get homeOuvrirLaVidO;

  /// No description provided for @authUnEmailContenantUn.
  ///
  /// In fr, this message translates to:
  /// **'Un email contenant un lien de réinitialisation a été envoyé à cette adresse.'**
  String get authUnEmailContenantUn;

  /// No description provided for @authInitieTaConnexionAu.
  ///
  /// In fr, this message translates to:
  /// **'Initie ta connexion au système'**
  String get authInitieTaConnexionAu;

  /// No description provided for @authCodeDAccS.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'accès perdu ?'**
  String get authCodeDAccS;

  /// No description provided for @authNouveauCandidatRejoindreL.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau candidat ? Rejoindre l\'Ordre OSIRION.'**
  String get authNouveauCandidatRejoindreL;

  /// No description provided for @authIdentifiantAlphaEmail.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant Alpha (Email)'**
  String get authIdentifiantAlphaEmail;

  /// No description provided for @authCodeDeSCurit.
  ///
  /// In fr, this message translates to:
  /// **'Code de sécurité'**
  String get authCodeDeSCurit;

  /// No description provided for @authNouvelleRecrue.
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLE RECRUE'**
  String get authNouvelleRecrue;

  /// No description provided for @authLReDOsirion.
  ///
  /// In fr, this message translates to:
  /// **'L\'ère d\'OSIRION t\'attend. Crée ton profil.'**
  String get authLReDOsirion;

  /// No description provided for @authSEnrLerDans.
  ///
  /// In fr, this message translates to:
  /// **'S\'ENRÔLER DANS OSIRION'**
  String get authSEnrLerDans;

  /// No description provided for @authNomDeCodePseudo.
  ///
  /// In fr, this message translates to:
  /// **'Nom de code (Pseudo)'**
  String get authNomDeCodePseudo;

  /// No description provided for @authMotDePasseD.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe d\'accès'**
  String get authMotDePasseD;

  /// No description provided for @authBienvenueDansLOrdre.
  ///
  /// In fr, this message translates to:
  /// **'BIENVENUE DANS L\'ORDRE'**
  String get authBienvenueDansLOrdre;

  /// No description provided for @authForceLoyautSagesse.
  ///
  /// In fr, this message translates to:
  /// **'Force • Loyauté • Sagesse'**
  String get authForceLoyautSagesse;

  /// No description provided for @authSEnrLerMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'S\'ENRÔLER MAINTENANT'**
  String get authSEnrLerMaintenant;

  /// No description provided for @authDJMembreDe.
  ///
  /// In fr, this message translates to:
  /// **'DÉJÀ MEMBRE DE L\'ORDRE'**
  String get authDJMembreDe;

  /// No description provided for @profileUploadDeLaPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Upload de la photo en cours...'**
  String get profileUploadDeLaPhoto;

  /// No description provided for @profileProfilJour.
  ///
  /// In fr, this message translates to:
  /// **'Profil à jour !'**
  String get profileProfilJour;

  /// No description provided for @profileLeSanctuaire.
  ///
  /// In fr, this message translates to:
  /// **'LE SANCTUAIRE'**
  String get profileLeSanctuaire;

  /// No description provided for @profileDualTrack.
  ///
  /// In fr, this message translates to:
  /// **'DUAL-TRACK'**
  String get profileDualTrack;

  /// No description provided for @profileCalendrierDeCohRence.
  ///
  /// In fr, this message translates to:
  /// **'CALENDRIER DE COHÉRENCE'**
  String get profileCalendrierDeCohRence;

  /// No description provided for @profileLaboratoireBiomTrique.
  ///
  /// In fr, this message translates to:
  /// **'LABORATOIRE BIOMÉTRIQUE'**
  String get profileLaboratoireBiomTrique;

  /// No description provided for @profileRegistreLeDojoIa.
  ///
  /// In fr, this message translates to:
  /// **'REGISTRE : LE DOJO (IA)'**
  String get profileRegistreLeDojoIa;

  /// No description provided for @profileGestionDuSanctuaire.
  ///
  /// In fr, this message translates to:
  /// **'GESTION DU SANCTUAIRE'**
  String get profileGestionDuSanctuaire;

  /// No description provided for @profileLeCodexDeL.
  ///
  /// In fr, this message translates to:
  /// **'LE CODEX DE L\'ESPRIT'**
  String get profileLeCodexDeL;

  /// No description provided for @profileSRieDHonneur.
  ///
  /// In fr, this message translates to:
  /// **'SÉRIE D\'HONNEUR'**
  String get profileSRieDHonneur;

  /// No description provided for @profileJoursConsCutifs.
  ///
  /// In fr, this message translates to:
  /// **'JOURS CONSÉCUTIFS'**
  String get profileJoursConsCutifs;

  /// No description provided for @profileArchivesDuJournal.
  ///
  /// In fr, this message translates to:
  /// **'ARCHIVES DU JOURNAL'**
  String get profileArchivesDuJournal;

  /// No description provided for @profileErreurLorsDuChargement.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement des archives.'**
  String get profileErreurLorsDuChargement;

  /// No description provided for @profileRegistreLArNe.
  ///
  /// In fr, this message translates to:
  /// **'REGISTRE : L\'ARÈNE (GPS)'**
  String get profileRegistreLArNe;

  /// No description provided for @profilePassAlphaInactif.
  ///
  /// In fr, this message translates to:
  /// **'PASS ALPHA+ INACTIF'**
  String get profilePassAlphaInactif;

  /// No description provided for @profileSoutenirLeProjetEt.
  ///
  /// In fr, this message translates to:
  /// **'Soutenir le projet et débloquer les stats avancées.'**
  String get profileSoutenirLeProjetEt;

  /// No description provided for @profileAvisFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Avis & Feedback'**
  String get profileAvisFeedback;

  /// No description provided for @profileVotreAvisCompte.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis compte'**
  String get profileVotreAvisCompte;

  /// No description provided for @profileAidezNousAmLiorer.
  ///
  /// In fr, this message translates to:
  /// **'Aidez-nous à améliorer OSIRION pour le Winter Arc.'**
  String get profileAidezNousAmLiorer;

  /// No description provided for @profileMerciPourVotreAvis.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get profileMerciPourVotreAvis;

  /// No description provided for @profilePartagezVotreExpRience.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience...'**
  String get profilePartagezVotreExpRience;

  /// No description provided for @profileMDitationAchevE.
  ///
  /// In fr, this message translates to:
  /// **'✨ Méditation achevée. +20 XP de Sagesse.'**
  String get profileMDitationAchevE;

  /// No description provided for @profileMDitationDeepWork.
  ///
  /// In fr, this message translates to:
  /// **'MÉDITATION & DEEP WORK'**
  String get profileMDitationDeepWork;

  /// No description provided for @profileRInitialiser.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get profileRInitialiser;

  /// No description provided for @pantheonUploadDuLogoEn.
  ///
  /// In fr, this message translates to:
  /// **'Upload du logo en cours...'**
  String get pantheonUploadDuLogoEn;

  /// No description provided for @pantheonLogoDuClanMis.
  ///
  /// In fr, this message translates to:
  /// **'Logo du clan mis à jour !'**
  String get pantheonLogoDuClanMis;

  /// No description provided for @pantheonLePanthOn.
  ///
  /// In fr, this message translates to:
  /// **'LE PANTHÉON'**
  String get pantheonLePanthOn;

  /// No description provided for @pantheonChangerVotreStatut.
  ///
  /// In fr, this message translates to:
  /// **'CHANGER VOTRE STATUT'**
  String get pantheonChangerVotreStatut;

  /// No description provided for @pantheonAucunCanalActifNrejoignez.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN CANAL ACTIF.\\nREJOIGNEZ UN CLAN OU AJOUTEZ DES AMIS.'**
  String get pantheonAucunCanalActifNrejoignez;

  /// No description provided for @pantheonRechercherUnAlpha.
  ///
  /// In fr, this message translates to:
  /// **'RECHERCHER UN ALPHA'**
  String get pantheonRechercherUnAlpha;

  /// No description provided for @pantheonAucunAlphaTrouv.
  ///
  /// In fr, this message translates to:
  /// **'Aucun Alpha trouvé'**
  String get pantheonAucunAlphaTrouv;

  /// No description provided for @pantheonEnAttente.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get pantheonEnAttente;

  /// No description provided for @pantheonModuleEnCoursDe.
  ///
  /// In fr, this message translates to:
  /// **'MODULE EN COURS DE DÉVELOPPEMENT'**
  String get pantheonModuleEnCoursDe;

  /// No description provided for @pantheonLeCentreDeCommandement.
  ///
  /// In fr, this message translates to:
  /// **'Le centre de commandement stratégique OSIRION arrive bientôt. Préparez vos clans pour la conquête territoriale.'**
  String get pantheonLeCentreDeCommandement;

  /// No description provided for @pantheonAucunImmortelTrouv.
  ///
  /// In fr, this message translates to:
  /// **'Aucun immortel trouvé...'**
  String get pantheonAucunImmortelTrouv;

  /// No description provided for @pantheonFonderUnNouveauClan.
  ///
  /// In fr, this message translates to:
  /// **'FONDER UN NOUVEAU CLAN'**
  String get pantheonFonderUnNouveauClan;

  /// No description provided for @pantheonAucunClanNExiste.
  ///
  /// In fr, this message translates to:
  /// **'Aucun clan n\'existe encore...'**
  String get pantheonAucunClanNExiste;

  /// No description provided for @pantheonVousNeFaitesPartie.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne faites partie d\'aucun clan.\\nRejoignez-en un via les classements ou fondez le vôtre !'**
  String get pantheonVousNeFaitesPartie;

  /// No description provided for @pantheonForgerUnNouveauClan.
  ///
  /// In fr, this message translates to:
  /// **'FORGER UN NOUVEAU CLAN'**
  String get pantheonForgerUnNouveauClan;

  /// No description provided for @pantheonCrErLeClan.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER LE CLAN'**
  String get pantheonCrErLeClan;

  /// No description provided for @pantheonDissoudreLeClan.
  ///
  /// In fr, this message translates to:
  /// **'Dissoudre le Clan'**
  String get pantheonDissoudreLeClan;

  /// No description provided for @pantheonLeClanAT.
  ///
  /// In fr, this message translates to:
  /// **'Le clan a été dissous avec succès.'**
  String get pantheonLeClanAT;

  /// No description provided for @pantheonQuitterLeClan.
  ///
  /// In fr, this message translates to:
  /// **'Quitter le Clan'**
  String get pantheonQuitterLeClan;

  /// No description provided for @pantheonActionRequise.
  ///
  /// In fr, this message translates to:
  /// **'Action Requise'**
  String get pantheonActionRequise;

  /// No description provided for @pantheonNouvelleDemandeLancE.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande lancée !'**
  String get pantheonNouvelleDemandeLancE;

  /// No description provided for @pantheonRInviter.
  ///
  /// In fr, this message translates to:
  /// **'RÉ-INVITER'**
  String get pantheonRInviter;

  /// No description provided for @pantheonLAccSAu.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès au micro est requis dans les paramètres de votre téléphone.'**
  String get pantheonLAccSAu;

  /// No description provided for @pantheonPermissionMicroRefusE.
  ///
  /// In fr, this message translates to:
  /// **'Permission micro refusée.'**
  String get pantheonPermissionMicroRefusE;

  /// No description provided for @pantheonPrendreUnePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get pantheonPrendreUnePhoto;

  /// No description provided for @pantheonPhotosGalerie.
  ///
  /// In fr, this message translates to:
  /// **'Photos (Galerie)'**
  String get pantheonPhotosGalerie;

  /// No description provided for @pantheonVidOclip15sMax.
  ///
  /// In fr, this message translates to:
  /// **'Vidéoclip (15s max)'**
  String get pantheonVidOclip15sMax;

  /// No description provided for @pantheonChargementDuProfil.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du profil...'**
  String get pantheonChargementDuProfil;

  /// No description provided for @pantheonChatIndisponibleMockup.
  ///
  /// In fr, this message translates to:
  /// **'Chat indisponible (Mockup)'**
  String get pantheonChatIndisponibleMockup;

  /// No description provided for @pantheonCodageH264R.
  ///
  /// In fr, this message translates to:
  /// **'Codage H.264 & Réduction Bitrate'**
  String get pantheonCodageH264R;

  /// No description provided for @pantheonEffacerDFinitivement.
  ///
  /// In fr, this message translates to:
  /// **'Effacer définitivement ?'**
  String get pantheonEffacerDFinitivement;

  /// No description provided for @pantheonCeMessageSeraSupprim.
  ///
  /// In fr, this message translates to:
  /// **'Ce message sera supprimé pour tout le monde et sera irrécupérable dans la base de données.'**
  String get pantheonCeMessageSeraSupprim;

  /// No description provided for @pantheonMessageEffacDFinitivement.
  ///
  /// In fr, this message translates to:
  /// **'Message effacé définitivement.'**
  String get pantheonMessageEffacDFinitivement;

  /// No description provided for @pantheonDButDeLa.
  ///
  /// In fr, this message translates to:
  /// **'Début de la conversation sécurisée alpha.'**
  String get pantheonDButDeLa;

  /// No description provided for @pantheonTLChargementDe.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement de la photo...'**
  String get pantheonTLChargementDe;

  /// No description provided for @pantheonPhotoEnregistrE.
  ///
  /// In fr, this message translates to:
  /// **'Photo enregistrée ! ✅'**
  String get pantheonPhotoEnregistrE;

  /// No description provided for @pantheonVousDevezTreChef.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être chef pour recruter.'**
  String get pantheonVousDevezTreChef;

  /// No description provided for @pantheonRecruterAmis.
  ///
  /// In fr, this message translates to:
  /// **'RECRUTER / AMIS'**
  String get pantheonRecruterAmis;

  /// No description provided for @pantheonRetirerDesAmis.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des amis ?'**
  String get pantheonRetirerDesAmis;

  /// No description provided for @pantheonVoulezVousGalementEffacer.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous également effacer définitivement tout l\'historique de votre conversation ?'**
  String get pantheonVoulezVousGalementEffacer;

  /// No description provided for @pantheonGarderChat.
  ///
  /// In fr, this message translates to:
  /// **'GARDER CHAT'**
  String get pantheonGarderChat;

  /// No description provided for @pantheonEffacerTout.
  ///
  /// In fr, this message translates to:
  /// **'EFFACER TOUT'**
  String get pantheonEffacerTout;

  /// No description provided for @pantheonRetirerDeMesAmis.
  ///
  /// In fr, this message translates to:
  /// **'RETIRER DE MES AMIS'**
  String get pantheonRetirerDeMesAmis;

  /// No description provided for @pantheonLeCrAteurNe.
  ///
  /// In fr, this message translates to:
  /// **'Le créateur ne peut pas être banni.'**
  String get pantheonLeCrAteurNe;

  /// No description provided for @pantheonAucunMembreTrouv.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre trouvé.'**
  String get pantheonAucunMembreTrouv;

  /// No description provided for @pantheonDemandeDAdhSion.
  ///
  /// In fr, this message translates to:
  /// **'Demande d\'adhésion envoyée !'**
  String get pantheonDemandeDAdhSion;

  /// No description provided for @pantheonEnregistrerDansLaPellicule.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer dans la pellicule'**
  String get pantheonEnregistrerDansLaPellicule;

  /// No description provided for @pantheonRechercherUneFaction.
  ///
  /// In fr, this message translates to:
  /// **'RECHERCHER UNE FACTION...'**
  String get pantheonRechercherUneFaction;

  /// No description provided for @pantheonExLesSpartiatesDu.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Les Spartiates du Parc'**
  String get pantheonExLesSpartiatesDu;

  /// No description provided for @pantheonTransmettreUnMessage.
  ///
  /// In fr, this message translates to:
  /// **'Transmettre un message...'**
  String get pantheonTransmettreUnMessage;

  /// No description provided for @pantheonAlphaCam.
  ///
  /// In fr, this message translates to:
  /// **'ALPHA CAM'**
  String get pantheonAlphaCam;

  /// No description provided for @pantheonVidOEnregistrE.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo enregistrée dans la pellicule ! ✅'**
  String get pantheonVidOEnregistrE;

  /// No description provided for @pantheonTabClassements.
  ///
  /// In fr, this message translates to:
  /// **'Classements'**
  String get pantheonTabClassements;

  /// No description provided for @pantheonLesImmortels.
  ///
  /// In fr, this message translates to:
  /// **'LES IMMORTELS'**
  String get pantheonLesImmortels;

  /// No description provided for @pantheonMondial.
  ///
  /// In fr, this message translates to:
  /// **'Mondial'**
  String get pantheonMondial;

  /// No description provided for @pantheonAlphaSupreme.
  ///
  /// In fr, this message translates to:
  /// **'Alpha Suprême (Harmonie)'**
  String get pantheonAlphaSupreme;

  /// No description provided for @pantheonMaitresDuDojo.
  ///
  /// In fr, this message translates to:
  /// **'Maîtres du Dojo (Force)'**
  String get pantheonMaitresDuDojo;

  /// No description provided for @pantheonSagesArN.
  ///
  /// In fr, this message translates to:
  /// **'Sages de l\'Arène (Sagesse)'**
  String get pantheonSagesArN;

  /// No description provided for @pantheonFactionsTopClans.
  ///
  /// In fr, this message translates to:
  /// **'Factions (Top Clans)'**
  String get pantheonFactionsTopClans;

  /// No description provided for @pantheonVotrePosition.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE POSITION'**
  String get pantheonVotrePosition;

  /// No description provided for @pantheonInvitationsRecues.
  ///
  /// In fr, this message translates to:
  /// **'INVITATIONS REÇUES'**
  String get pantheonInvitationsRecues;

  /// No description provided for @pantheonRejoindre.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get pantheonRejoindre;

  /// No description provided for @profileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Profil introuvable'**
  String get profileNotFound;

  /// No description provided for @profileNoJournalArchives.
  ///
  /// In fr, this message translates to:
  /// **'Aucune archive de journal.'**
  String get profileNoJournalArchives;

  /// No description provided for @profileTabEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Évolution'**
  String get profileTabEvolution;

  /// No description provided for @profileTabPhysique.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get profileTabPhysique;

  /// No description provided for @profileTabEsprit.
  ///
  /// In fr, this message translates to:
  /// **'Esprit'**
  String get profileTabEsprit;

  /// No description provided for @profileTabReglages.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get profileTabReglages;

  /// No description provided for @profileRegistreArene.
  ///
  /// In fr, this message translates to:
  /// **'REGISTRE : L\'AR�NE (GPS)'**
  String get profileRegistreArene;

  /// No description provided for @profileLangueTitle.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLangueTitle;

  /// No description provided for @profileLangueSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue (FR/EN)'**
  String get profileLangueSubtitle;

  /// No description provided for @profileChangerLangueDialog.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get profileChangerLangueDialog;

  /// No description provided for @profileThemeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Th�me & Arc Actif'**
  String get profileThemeTitle;

  /// No description provided for @profileThemeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Basculer manuellement d\'Arc'**
  String get profileThemeSubtitle;

  /// No description provided for @profileExportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Export des Donn�es'**
  String get profileExportTitle;

  /// No description provided for @profileExportSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'T�l�charger le rapport PDF'**
  String get profileExportSubtitle;

  /// No description provided for @profileConfidentialiteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialit�'**
  String get profileConfidentialiteTitle;

  /// No description provided for @profileConfidentialiteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Visibilit� dans le Panth�on'**
  String get profileConfidentialiteSubtitle;

  /// No description provided for @dojoChoixCible.
  ///
  /// In fr, this message translates to:
  /// **'1. CHOIX DE LA CIBLE'**
  String get dojoChoixCible;

  /// No description provided for @dojoTypeEntrainement.
  ///
  /// In fr, this message translates to:
  /// **'2. TYPE D\'ENTRAÎNEMENT'**
  String get dojoTypeEntrainement;

  /// No description provided for @dojoModeExecution.
  ///
  /// In fr, this message translates to:
  /// **'3. MODE D\'EXÉCUTION'**
  String get dojoModeExecution;

  /// No description provided for @dojoSelectionnezMode.
  ///
  /// In fr, this message translates to:
  /// **'SÉLECTIONNEZ UN MODE'**
  String get dojoSelectionnezMode;

  /// No description provided for @dojoDemarrerProtocole.
  ///
  /// In fr, this message translates to:
  /// **'DÉMARRER LE PROTOCOLE'**
  String get dojoDemarrerProtocole;

  /// No description provided for @dojoCorpsEntier.
  ///
  /// In fr, this message translates to:
  /// **'Corps Entier'**
  String get dojoCorpsEntier;

  /// No description provided for @dojoHautDuCorps.
  ///
  /// In fr, this message translates to:
  /// **'Haut du Corps'**
  String get dojoHautDuCorps;

  /// No description provided for @dojoBasDuCorps.
  ///
  /// In fr, this message translates to:
  /// **'Bas du Corps'**
  String get dojoBasDuCorps;

  /// No description provided for @dojoSangleAbdos.
  ///
  /// In fr, this message translates to:
  /// **'Sangle Abdos'**
  String get dojoSangleAbdos;

  /// No description provided for @dojoCiblageIsole.
  ///
  /// In fr, this message translates to:
  /// **'Ciblage Isolé (Rééduc.)'**
  String get dojoCiblageIsole;

  /// No description provided for @dojoLentControle.
  ///
  /// In fr, this message translates to:
  /// **'Lent & Contrôlé'**
  String get dojoLentControle;

  /// No description provided for @dojoCardioLong.
  ///
  /// In fr, this message translates to:
  /// **'Cardio long'**
  String get dojoCardioLong;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'FERMER'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'ANNULER'**
  String get commonCancel;

  /// No description provided for @commonModify.
  ///
  /// In fr, this message translates to:
  /// **'MODIFIER'**
  String get commonModify;

  /// No description provided for @commonErase.
  ///
  /// In fr, this message translates to:
  /// **'EFFACER'**
  String get commonErase;

  /// No description provided for @commonSend.
  ///
  /// In fr, this message translates to:
  /// **'ENVOYER'**
  String get commonSend;

  /// No description provided for @commonReplay.
  ///
  /// In fr, this message translates to:
  /// **'REJOUER'**
  String get commonReplay;

  /// No description provided for @commonFinish.
  ///
  /// In fr, this message translates to:
  /// **'TERMINER'**
  String get commonFinish;

  /// No description provided for @commonAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get commonAccept;

  /// No description provided for @commonSuspend.
  ///
  /// In fr, this message translates to:
  /// **'SUSPENDRE'**
  String get commonSuspend;

  /// No description provided for @commonPurge.
  ///
  /// In fr, this message translates to:
  /// **'PURGER'**
  String get commonPurge;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String commonError(String error);

  /// No description provided for @commonErrorSimple.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get commonErrorSimple;

  /// No description provided for @commonFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get commonFrench;

  /// No description provided for @commonEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get commonEnglish;

  /// No description provided for @arenaAucunDiscipleTrouve.
  ///
  /// In fr, this message translates to:
  /// **'Aucun disciple trouvé.'**
  String get arenaAucunDiscipleTrouve;

  /// No description provided for @arenaAucuneFactionRejointe.
  ///
  /// In fr, this message translates to:
  /// **'Aucune faction rejointe.'**
  String get arenaAucuneFactionRejointe;

  /// No description provided for @commonReturn.
  ///
  /// In fr, this message translates to:
  /// **'RETOUR'**
  String get commonReturn;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'IGNORER'**
  String get commonSkip;

  /// No description provided for @arenaForge.
  ///
  /// In fr, this message translates to:
  /// **'FORGE'**
  String get arenaForge;

  /// No description provided for @arenaZones.
  ///
  /// In fr, this message translates to:
  /// **'ZONES'**
  String get arenaZones;

  /// No description provided for @arenaSpots.
  ///
  /// In fr, this message translates to:
  /// **'SPOTS'**
  String get arenaSpots;

  /// No description provided for @arenaRivaux.
  ///
  /// In fr, this message translates to:
  /// **'RIVAUX'**
  String get arenaRivaux;

  /// No description provided for @commonShare.
  ///
  /// In fr, this message translates to:
  /// **'PARTAGER'**
  String get commonShare;

  /// No description provided for @arenaTractions.
  ///
  /// In fr, this message translates to:
  /// **'TRACTIONS'**
  String get arenaTractions;

  /// No description provided for @arenaDips.
  ///
  /// In fr, this message translates to:
  /// **'DIPS'**
  String get arenaDips;

  /// No description provided for @arenaPompes.
  ///
  /// In fr, this message translates to:
  /// **'POMPES'**
  String get arenaPompes;

  /// No description provided for @arenaAbdos.
  ///
  /// In fr, this message translates to:
  /// **'ABDOS'**
  String get arenaAbdos;

  /// No description provided for @arenaDefiPrefix.
  ///
  /// In fr, this message translates to:
  /// **'DÉFI : '**
  String get arenaDefiPrefix;

  /// No description provided for @arenaDefiAction.
  ///
  /// In fr, this message translates to:
  /// **'DÉFI'**
  String get arenaDefiAction;

  /// No description provided for @arenaErreurTransmission.
  ///
  /// In fr, this message translates to:
  /// **'ERREUR DE TRANSMISSION.'**
  String get arenaErreurTransmission;

  /// No description provided for @arenaEchecSignalGps.
  ///
  /// In fr, this message translates to:
  /// **'ÉCHEC : SIGNAL GPS DÉGRADÉ OU TROP LOIN DU SPOT.'**
  String get arenaEchecSignalGps;

  /// No description provided for @arenaLePlusProche.
  ///
  /// In fr, this message translates to:
  /// **'LE PLUS PROCHE : '**
  String get arenaLePlusProche;

  /// No description provided for @arenaScanDesStations.
  ///
  /// In fr, this message translates to:
  /// **'SCAN DES STATIONS À PROXIMITÉ'**
  String get arenaScanDesStations;

  /// No description provided for @arenaEstimation.
  ///
  /// In fr, this message translates to:
  /// **'ESTIMATION: '**
  String get arenaEstimation;

  /// No description provided for @arenaBossPrefix.
  ///
  /// In fr, this message translates to:
  /// **'BOSS: '**
  String get arenaBossPrefix;

  /// No description provided for @arenaZoneVierge.
  ///
  /// In fr, this message translates to:
  /// **'ZONE VIERGE'**
  String get arenaZoneVierge;

  /// No description provided for @arenaRegneDepuis.
  ///
  /// In fr, this message translates to:
  /// **'RÈGNE DEPUIS: '**
  String get arenaRegneDepuis;

  /// No description provided for @arenaRepsSuffix.
  ///
  /// In fr, this message translates to:
  /// **' REPS'**
  String get arenaRepsSuffix;

  /// No description provided for @arenaBriefingTactiquePrefix.
  ///
  /// In fr, this message translates to:
  /// **'📝 BRIEFING TACTIQUE (OSM) : '**
  String get arenaBriefingTactiquePrefix;

  /// No description provided for @arenaInfo.
  ///
  /// In fr, this message translates to:
  /// **'INFO'**
  String get arenaInfo;

  /// No description provided for @arenaTracer.
  ///
  /// In fr, this message translates to:
  /// **'TRACER'**
  String get arenaTracer;

  /// No description provided for @arenaMoinsDuneMinute.
  ///
  /// In fr, this message translates to:
  /// **'MOINS D\'UNE MINUTE'**
  String get arenaMoinsDuneMinute;

  /// No description provided for @arenaJoursSuffix.
  ///
  /// In fr, this message translates to:
  /// **' JOURS'**
  String get arenaJoursSuffix;

  /// No description provided for @arenaHeuresSuffix.
  ///
  /// In fr, this message translates to:
  /// **' HEURES'**
  String get arenaHeuresSuffix;

  /// No description provided for @arenaRecent.
  ///
  /// In fr, this message translates to:
  /// **'RÉCENT'**
  String get arenaRecent;

  /// No description provided for @arenaTransmettreRenseignement.
  ///
  /// In fr, this message translates to:
  /// **'TRANSMETTRE LE RENSEIGNEMENT (+250 XP)'**
  String get arenaTransmettreRenseignement;

  /// No description provided for @arenaArsenalTactique.
  ///
  /// In fr, this message translates to:
  /// **'ARSENAL TACTIQUE'**
  String get arenaArsenalTactique;

  /// No description provided for @arenaRenseignementAlpha.
  ///
  /// In fr, this message translates to:
  /// **'RENSEIGNEMENT ALPHA'**
  String get arenaRenseignementAlpha;

  /// No description provided for @arenaBossActuel.
  ///
  /// In fr, this message translates to:
  /// **'Boss Actuel'**
  String get arenaBossActuel;

  /// No description provided for @arenaInconnuCaps.
  ///
  /// In fr, this message translates to:
  /// **'INCONNU'**
  String get arenaInconnuCaps;

  /// No description provided for @arenaInconnuCamel.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get arenaInconnuCamel;

  /// No description provided for @arenaRecordEffort.
  ///
  /// In fr, this message translates to:
  /// **'Record d\'Effort'**
  String get arenaRecordEffort;

  /// No description provided for @arenaTempsDeRegne.
  ///
  /// In fr, this message translates to:
  /// **'Temps de Règne'**
  String get arenaTempsDeRegne;

  /// No description provided for @arenaEchecsRecents.
  ///
  /// In fr, this message translates to:
  /// **'Échecs récents'**
  String get arenaEchecsRecents;

  /// No description provided for @arenaTentativesSuffix.
  ///
  /// In fr, this message translates to:
  /// **' TENTATIVES'**
  String get arenaTentativesSuffix;

  /// No description provided for @arenaBriefingTactiqueSansIcone.
  ///
  /// In fr, this message translates to:
  /// **'BRIEFING TACTIQUE (OSM)'**
  String get arenaBriefingTactiqueSansIcone;

  /// No description provided for @arenaCoordonneesMission.
  ///
  /// In fr, this message translates to:
  /// **'COORDONNÉES DE MISSION'**
  String get arenaCoordonneesMission;

  /// No description provided for @arenaQuartier.
  ///
  /// In fr, this message translates to:
  /// **'Quartier'**
  String get arenaQuartier;

  /// No description provided for @arenaLatitude.
  ///
  /// In fr, this message translates to:
  /// **'Latitude'**
  String get arenaLatitude;

  /// No description provided for @arenaLongitude.
  ///
  /// In fr, this message translates to:
  /// **'Longitude'**
  String get arenaLongitude;

  /// No description provided for @arenaForgeDiscipline.
  ///
  /// In fr, this message translates to:
  /// **'1. DISCIPLINE'**
  String get arenaForgeDiscipline;

  /// No description provided for @commonCourse.
  ///
  /// In fr, this message translates to:
  /// **'Course'**
  String get commonCourse;

  /// No description provided for @commonMarche.
  ///
  /// In fr, this message translates to:
  /// **'Marche'**
  String get commonMarche;

  /// No description provided for @commonVelo.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get commonVelo;

  /// No description provided for @arenaForgeDenivele.
  ///
  /// In fr, this message translates to:
  /// **'2. DÉNIVELÉ'**
  String get arenaForgeDenivele;

  /// No description provided for @arenaForgePlat.
  ///
  /// In fr, this message translates to:
  /// **'Plat'**
  String get arenaForgePlat;

  /// No description provided for @arenaForgeVallonne.
  ///
  /// In fr, this message translates to:
  /// **'Vallonné'**
  String get arenaForgeVallonne;

  /// No description provided for @arenaForgeDistanceBoucle.
  ///
  /// In fr, this message translates to:
  /// **'3. DISTANCE (BOUCLE IA)'**
  String get arenaForgeDistanceBoucle;

  /// No description provided for @arenaGenererPerformanceCard.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRER MA PERFORMANCE CARD'**
  String get arenaGenererPerformanceCard;

  /// No description provided for @arenaParPrefix.
  ///
  /// In fr, this message translates to:
  /// **'PAR '**
  String get arenaParPrefix;

  /// No description provided for @arenaDefierPrefix.
  ///
  /// In fr, this message translates to:
  /// **'DÉFIER '**
  String get arenaDefierPrefix;

  /// No description provided for @commonDistanceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get commonDistanceTitle;

  /// No description provided for @commonRecordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Record'**
  String get commonRecordTitle;

  /// No description provided for @commonTempsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Temps'**
  String get commonTempsTitle;

  /// No description provided for @commonVitesseMoy.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse Moy.'**
  String get commonVitesseMoy;

  /// No description provided for @commonVitesseMoyCaps.
  ///
  /// In fr, this message translates to:
  /// **'VITESSE MOY.'**
  String get commonVitesseMoyCaps;

  /// No description provided for @commonDistanceCaps.
  ///
  /// In fr, this message translates to:
  /// **'DISTANCE'**
  String get commonDistanceCaps;

  /// No description provided for @commonTempsCaps.
  ///
  /// In fr, this message translates to:
  /// **'TEMPS'**
  String get commonTempsCaps;

  /// No description provided for @arenaPrecisionIa.
  ///
  /// In fr, this message translates to:
  /// **'PRECISION IA'**
  String get arenaPrecisionIa;

  /// No description provided for @arenaForce.
  ///
  /// In fr, this message translates to:
  /// **'FORCE'**
  String get arenaForce;

  /// No description provided for @arenaSagesse.
  ///
  /// In fr, this message translates to:
  /// **'SAGESSE'**
  String get arenaSagesse;

  /// No description provided for @arenaAether.
  ///
  /// In fr, this message translates to:
  /// **'AETHER'**
  String get arenaAether;

  /// No description provided for @arenaGenerationEnCours.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRATION EN COURS...'**
  String get arenaGenerationEnCours;

  /// No description provided for @arenaConqueteReussie.
  ///
  /// In fr, this message translates to:
  /// **'CONQUÊTE RÉUSSIE : {total} REPS TOTALES ! VOUS ÊTES LE BOSS DE {spotName}.'**
  String arenaConqueteReussie(String total, String spotName);

  /// No description provided for @arenaRenseignementEchecs.
  ///
  /// In fr, this message translates to:
  /// **'⚠️ RENSEIGNEMENT : {count} JOUEURS ONT ÉCHOUÉ CETTE SEMAINE'**
  String arenaRenseignementEchecs(String count);

  /// No description provided for @arenaEnvMinutes.
  ///
  /// In fr, this message translates to:
  /// **'ENV. {minutes} MIN'**
  String arenaEnvMinutes(String minutes);

  /// No description provided for @arenaCompleterRenseignement.
  ///
  /// In fr, this message translates to:
  /// **'COMPLÉTER LE RENSEIGNEMENT ({count}/4)'**
  String arenaCompleterRenseignement(String count);

  /// No description provided for @arenaAucunTraceDeGrave.
  ///
  /// In fr, this message translates to:
  /// **'AUCUN TRACÉ DE {sportName} GRAVÉ'**
  String arenaAucunTraceDeGrave(String sportName);

  /// No description provided for @libraryTabLivres.
  ///
  /// In fr, this message translates to:
  /// **'Livres'**
  String get libraryTabLivres;

  /// No description provided for @libraryTabFocus.
  ///
  /// In fr, this message translates to:
  /// **'Focus'**
  String get libraryTabFocus;

  /// No description provided for @libraryTabJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get libraryTabJournal;

  /// No description provided for @libraryTabAudio.
  ///
  /// In fr, this message translates to:
  /// **'Audio'**
  String get libraryTabAudio;

  /// No description provided for @libraryFiche.
  ///
  /// In fr, this message translates to:
  /// **'FICHE'**
  String get libraryFiche;

  /// No description provided for @libraryLire.
  ///
  /// In fr, this message translates to:
  /// **'LIRE'**
  String get libraryLire;

  /// No description provided for @libraryLecturePrefix.
  ///
  /// In fr, this message translates to:
  /// **'LECTURE : '**
  String get libraryLecturePrefix;

  /// No description provided for @libraryModeImmersion.
  ///
  /// In fr, this message translates to:
  /// **'MODE IMMERSION'**
  String get libraryModeImmersion;

  /// No description provided for @libraryCommencerLecture.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER LA LECTURE'**
  String get libraryCommencerLecture;

  /// No description provided for @libraryArreterImmersion.
  ///
  /// In fr, this message translates to:
  /// **'ARRÊTER L\'IMMERSION'**
  String get libraryArreterImmersion;

  /// No description provided for @libraryCommencerImmersion.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER L\'IMMERSION'**
  String get libraryCommencerImmersion;

  /// No description provided for @libraryLeconNumeroUn.
  ///
  /// In fr, this message translates to:
  /// **'Leçon numéro un tirée de : '**
  String get libraryLeconNumeroUn;

  /// No description provided for @libraryParAuteur.
  ///
  /// In fr, this message translates to:
  /// **'par '**
  String get libraryParAuteur;

  /// No description provided for @libraryFermer.
  ///
  /// In fr, this message translates to:
  /// **'FERMER'**
  String get libraryFermer;

  /// No description provided for @libraryTransmissionAlphaCalee.
  ///
  /// In fr, this message translates to:
  /// **'Transmission Alpha calée sur : '**
  String get libraryTransmissionAlphaCalee;

  /// No description provided for @libraryMinutesSuffix.
  ///
  /// In fr, this message translates to:
  /// **' min'**
  String get libraryMinutesSuffix;

  /// No description provided for @bookHagakureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hagakure : Le Code du Samouraï'**
  String get bookHagakureTitle;

  /// No description provided for @bookHagakureTag.
  ///
  /// In fr, this message translates to:
  /// **'Discipline'**
  String get bookHagakureTag;

  /// No description provided for @bookHagakureTheme.
  ///
  /// In fr, this message translates to:
  /// **'Discipline absolue et résolution.'**
  String get bookHagakureTheme;

  /// No description provided for @bookHagakureWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'C\'est un texte radical sur la voie du guerrier (Bushido). Il prône une discipline de chaque instant et une préparation mentale à l\'épreuve de tout.'**
  String get bookHagakureWhyRead;

  /// No description provided for @bookHagakureKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'La Voie du Samouraï se trouve dans la mort (le dépassement de soi).'**
  String get bookHagakureKeyPhrase;

  /// No description provided for @bookObstacleTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'Obstacle est le Chemin'**
  String get bookObstacleTitle;

  /// No description provided for @bookObstacleTag.
  ///
  /// In fr, this message translates to:
  /// **'Stoïcisme'**
  String get bookObstacleTag;

  /// No description provided for @bookObstacleTheme.
  ///
  /// In fr, this message translates to:
  /// **'Transformer la difficulté en avantage.'**
  String get bookObstacleTheme;

  /// No description provided for @bookObstacleWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre à voir les problèmes non pas comme des murs, mais comme des opportunités pour grow et devenir meilleur.'**
  String get bookObstacleWhyRead;

  /// No description provided for @bookObstacleKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Le but de l\'obstacle n\'est pas de t\'arrêter, mais de te montrer à quel point tu désires avancer.'**
  String get bookObstacleKeyPhrase;

  /// No description provided for @bookEpicteteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Manuel'**
  String get bookEpicteteTitle;

  /// No description provided for @bookEpicteteTheme.
  ///
  /// In fr, this message translates to:
  /// **'Stoïcisme Radical et Maîtrise de soi.'**
  String get bookEpicteteTheme;

  /// No description provided for @bookEpicteteWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'La base absolue. Il apprend à ne plus gaspiller d\'énergie sur ce qu\'on ne controlle pas pour se concentrer uniquement sur son effort.'**
  String get bookEpicteteWhyRead;

  /// No description provided for @bookEpicteteKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Il y a des choses qui dépendent de nous, et d\'autres qui n\'en dépendent pas.'**
  String get bookEpicteteKeyPhrase;

  /// No description provided for @bookAureleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pensées pour moi-même'**
  String get bookAureleTitle;

  /// No description provided for @bookAureleTheme.
  ///
  /// In fr, this message translates to:
  /// **'Force mentale et Dialogue intérieur.'**
  String get bookAureleTheme;

  /// No description provided for @bookAureleWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour montrer que l\'Alpha doit être son propre juge le plus strict. Idéal pour garder le cap lors des entraînements solitaires.'**
  String get bookAureleWhyRead;

  /// No description provided for @bookAureleKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'L’obstacle à l’action favorise l’action. Ce qui barre le chemin devient le chemin.'**
  String get bookAureleKeyPhrase;

  /// No description provided for @bookSenequeTempsTitle.
  ///
  /// In fr, this message translates to:
  /// **'De la brièveté de la vie'**
  String get bookSenequeTempsTitle;

  /// No description provided for @bookSenequeTempsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Gestion du temps et Philosophie de l\'action.'**
  String get bookSenequeTempsTheme;

  /// No description provided for @bookSenequeTempsWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour supprimer l\'excuse du \"je n\'ai pas le temps\". Ce livre motive à couper les distractions pour se consacrer à l\'essentiel.'**
  String get bookSenequeTempsWhyRead;

  /// No description provided for @bookSenequeTempsKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas que nous disposions de peu de temps, c\'est que nous en perdons beaucoup.'**
  String get bookSenequeTempsKeyPhrase;

  /// No description provided for @bookSenequeAmeTitle.
  ///
  /// In fr, this message translates to:
  /// **'De la tranquillité de l\'âme'**
  String get bookSenequeAmeTitle;

  /// No description provided for @bookSenequeAmeTheme.
  ///
  /// In fr, this message translates to:
  /// **'Sérénité et Constance.'**
  String get bookSenequeAmeTheme;

  /// No description provided for @bookSenequeAmeWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre à rester stable émotionnellement même quand l\'entraînement est dur ou que les résultats tardent.'**
  String get bookSenequeAmeWhyRead;

  /// No description provided for @bookSenequeAmeKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Il faut s\'habituer à sa condition, s\'en plaindre le moins possible et saisir tous les avantages qu\'elle peut offrir.'**
  String get bookSenequeAmeKeyPhrase;

  /// No description provided for @bookBoeceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Consolation de la philosophie'**
  String get bookBoeceTitle;

  /// No description provided for @bookBoeceTheme.
  ///
  /// In fr, this message translates to:
  /// **'Résilience face à l\'adversité.'**
  String get bookBoeceTheme;

  /// No description provided for @bookBoeceWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Écrit en prison, ce livre est l\'ultime leçon de force mentale : rien ni personne ne peut t\'enlever ta liberté intérieure.'**
  String get bookBoeceWhyRead;

  /// No description provided for @bookBoeceKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'La fortune ne t\'a point tout enlevé, puisque tu as encore l\'usage de ta raison.'**
  String get bookBoeceKeyPhrase;

  /// No description provided for @bookAtomicTitle.
  ///
  /// In fr, this message translates to:
  /// **'Atomic Habits'**
  String get bookAtomicTitle;

  /// No description provided for @bookAtomicTag.
  ///
  /// In fr, this message translates to:
  /// **'Productivité'**
  String get bookAtomicTag;

  /// No description provided for @bookAtomicTheme.
  ///
  /// In fr, this message translates to:
  /// **'Le pouvoir des petits changements.'**
  String get bookAtomicTheme;

  /// No description provided for @bookAtomicWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour comprendre que le succès n\'est pas une question d\'intensité, mais de constance et de construction de systèmes viables.'**
  String get bookAtomicWhyRead;

  /// No description provided for @bookAtomicKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'On ne s\'élève pas au niveau de ses objectifs, on tombe au niveau de ses systèmes.'**
  String get bookAtomicKeyPhrase;

  /// No description provided for @bookLeBonTitle.
  ///
  /// In fr, this message translates to:
  /// **'La Psychologie des foules'**
  String get bookLeBonTitle;

  /// No description provided for @bookLeBonTag.
  ///
  /// In fr, this message translates to:
  /// **'Influence'**
  String get bookLeBonTag;

  /// No description provided for @bookLeBonTheme.
  ///
  /// In fr, this message translates to:
  /// **'Sociologie et Psychologie des groupes.'**
  String get bookLeBonTheme;

  /// No description provided for @bookLeBonWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Indispensable pour comprendre comment influencer son entourage et devenir un leader charismatique.'**
  String get bookLeBonWhyRead;

  /// No description provided for @bookLeBonKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'L\'affirmation pure et simple, dégagée de tout raisonnement, est un des moyens les plus sûrs pour faire pénétrer une idée dans l\'esprit des foules.'**
  String get bookLeBonKeyPhrase;

  /// No description provided for @bookSchopenhauerTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'Art d\'avoir toujours raison'**
  String get bookSchopenhauerTitle;

  /// No description provided for @bookSchopenhauerTheme.
  ///
  /// In fr, this message translates to:
  /// **'Rhétorique et Débat.'**
  String get bookSchopenhauerTheme;

  /// No description provided for @bookSchopenhauerWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour apprendre à défendre sa vision et son Arc face aux sceptiques. C\'est l\'armure intellectuelle de l\'Alpha.'**
  String get bookSchopenhauerWhyRead;

  /// No description provided for @bookSchopenhauerKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'La vérité est que chaque homme veut avoir raison, par tous les moyens possibles.'**
  String get bookSchopenhauerKeyPhrase;

  /// No description provided for @bookLaBruyereTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les Caractères'**
  String get bookLaBruyereTitle;

  /// No description provided for @bookLaBruyereTheme.
  ///
  /// In fr, this message translates to:
  /// **'Observation humaine et Psychologie.'**
  String get bookLaBruyereTheme;

  /// No description provided for @bookLaBruyereWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour développer une vision perçante. Apprendre à lire les gens comme on lit un itinéraire de course.'**
  String get bookLaBruyereWhyRead;

  /// No description provided for @bookLaBruyereKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Tout est dit, et l\'on vient trop tard depuis sept mille ans qu\'il y a des hommes et qui pensent.'**
  String get bookLaBruyereKeyPhrase;

  /// No description provided for @bookRochefoucauldTitle.
  ///
  /// In fr, this message translates to:
  /// **'Maximes'**
  String get bookRochefoucauldTitle;

  /// No description provided for @bookRochefoucauldTheme.
  ///
  /// In fr, this message translates to:
  /// **'Nature humaine et Réalisme.'**
  String get bookRochefoucauldTheme;

  /// No description provided for @bookRochefoucauldWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Des phrases courtes et percutantes (parfaites pour l\'UI de l\'app) qui révèlent les ressorts cachés de nos actions.'**
  String get bookRochefoucauldWhyRead;

  /// No description provided for @bookRochefoucauldKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Nos vertus ne sont, le plus souvent, que des vices déguisés.'**
  String get bookRochefoucauldKeyPhrase;

  /// No description provided for @bookBalzacTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traité de la vie élégante'**
  String get bookBalzacTitle;

  /// No description provided for @bookBalzacTheme.
  ///
  /// In fr, this message translates to:
  /// **'Style, Énergie et Présence sociale.'**
  String get bookBalzacTheme;

  /// No description provided for @bookBalzacWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour l\'utilisateur qui cherche l\'excellence esthétique et le rayonnement en société après avoir forgé son corps.'**
  String get bookBalzacWhyRead;

  /// No description provided for @bookBalzacKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'L\'élégance est tout à la fois un art, une science, un goût, un enthousiasme.'**
  String get bookBalzacKeyPhrase;

  /// No description provided for @bookArtOfWarTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'Art de la Guerre'**
  String get bookArtOfWarTitle;

  /// No description provided for @bookArtOfWarTag.
  ///
  /// In fr, this message translates to:
  /// **'48 Lois du Pouvoir'**
  String get bookArtOfWarTag;

  /// No description provided for @bookArtOfWarTheme.
  ///
  /// In fr, this message translates to:
  /// **'Stratégie et Maîtrise émotionnelle.'**
  String get bookArtOfWarTheme;

  /// No description provided for @bookArtOfWarWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'La bible de l\'efficacité. Apprendre à économiser ses forces pour frapper au moment opportun.'**
  String get bookArtOfWarWhyRead;

  /// No description provided for @bookArtOfWarKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Le plus grand conquérant est celui qui sait vaincre sans bataille.'**
  String get bookArtOfWarKeyPhrase;

  /// No description provided for @bookMachiavelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Prince'**
  String get bookMachiavelTitle;

  /// No description provided for @bookMachiavelTheme.
  ///
  /// In fr, this message translates to:
  /// **'Leadership et Réalisme de pouvoir.'**
  String get bookMachiavelTheme;

  /// No description provided for @bookMachiavelWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Comprendre les dynamiques de groupe et la hiérarchie pour diriger son propre Clan dans Valérion.'**
  String get bookMachiavelWhyRead;

  /// No description provided for @bookMachiavelKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a pas d\'autre moyen de se garder de la flatterie que de faire comprendre aux hommes que dire la vérité ne vous offense pas.'**
  String get bookMachiavelKeyPhrase;

  /// No description provided for @bookMusashiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Traité des cinq roues'**
  String get bookMusashiTitle;

  /// No description provided for @bookMusashiTag.
  ///
  /// In fr, this message translates to:
  /// **'Stratégie'**
  String get bookMusashiTag;

  /// No description provided for @bookMusashiTheme.
  ///
  /// In fr, this message translates to:
  /// **'Discipline martiale et Maîtrise totale.'**
  String get bookMusashiTheme;

  /// No description provided for @bookMusashiWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Le plus grand samouraï explique comment appliquer la stratégie dans chaque petit geste. Parfait pour le Calisthenics technique.'**
  String get bookMusashiWhyRead;

  /// No description provided for @bookMusashiKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'D\'une chose, apprends-en dix mille.'**
  String get bookMusashiKeyPhrase;

  /// No description provided for @bookLaoTseuTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tao Te King'**
  String get bookLaoTseuTitle;

  /// No description provided for @bookLaoTseuTheme.
  ///
  /// In fr, this message translates to:
  /// **'Équilibre, Fluidité et Harmonie.'**
  String get bookLaoTseuTheme;

  /// No description provided for @bookLaoTseuWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour contrebalancer la force brute. C\'est le livre qui aide à atteindre l\'Indice d\'Harmonie maximal.'**
  String get bookLaoTseuWhyRead;

  /// No description provided for @bookLaoTseuKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Rien au monde n\'est plus souple et plus faible que l\'eau. Pourtant, pour attaquer ce qui est dur et fort, rien ne la surpasse.'**
  String get bookLaoTseuKeyPhrase;

  /// No description provided for @bookCastiglioneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Livre du Courtisan'**
  String get bookCastiglioneTitle;

  /// No description provided for @bookCastiglioneTheme.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrise de soi et Sprezzatura (aisance).'**
  String get bookCastiglioneTheme;

  /// No description provided for @bookCastiglioneWhyRead.
  ///
  /// In fr, this message translates to:
  /// **'Pour cultiver cette aisance naturelle où l\'effort colossal derrière la performance ne doit jamais se voir.'**
  String get bookCastiglioneWhyRead;

  /// No description provided for @bookCastiglioneKeyPhrase.
  ///
  /// In fr, this message translates to:
  /// **'Faire paraître sans effort ce qui a été accompli avec une grande peine.'**
  String get bookCastiglioneKeyPhrase;

  /// No description provided for @audioTransformerTitle.
  ///
  /// In fr, this message translates to:
  /// **'3 Minutes Pour Transformer Ta Vie'**
  String get audioTransformerTitle;

  /// No description provided for @audioTransformerSub.
  ///
  /// In fr, this message translates to:
  /// **'3 min • Motivation'**
  String get audioTransformerSub;

  /// No description provided for @audioProcrastinesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Si Tu Procrastines, Écoute Ça'**
  String get audioProcrastinesTitle;

  /// No description provided for @audioProcrastinesSub.
  ///
  /// In fr, this message translates to:
  /// **'Motivation • Focus'**
  String get audioProcrastinesSub;

  /// No description provided for @audioSaitamaTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Discours de Saitama'**
  String get audioSaitamaTitle;

  /// No description provided for @audioSaitamaSub.
  ///
  /// In fr, this message translates to:
  /// **'Détermination • Alpha'**
  String get audioSaitamaSub;

  /// No description provided for @audioReveillerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réveiller quelque chose en toi'**
  String get audioReveillerTitle;

  /// No description provided for @audioReveillerSub.
  ///
  /// In fr, this message translates to:
  /// **'David Goggins • Interview'**
  String get audioReveillerSub;

  /// No description provided for @audioObstacleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton Seul Obstacle, C’est TOI'**
  String get audioObstacleTitle;

  /// No description provided for @audioObstacleSub.
  ///
  /// In fr, this message translates to:
  /// **'Mindset Alpha'**
  String get audioObstacleSub;

  /// No description provided for @audioMaitriserTitle.
  ///
  /// In fr, this message translates to:
  /// **'L\'Art de Maîtriser Son Esprit'**
  String get audioMaitriserTitle;

  /// No description provided for @audioMaitriserSub.
  ///
  /// In fr, this message translates to:
  /// **'David Goggins • Interview'**
  String get audioMaitriserSub;

  /// No description provided for @arenaParcoursDePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Parcours de '**
  String get arenaParcoursDePrefix;

  /// No description provided for @arsenalUnlockedAtLevel.
  ///
  /// In fr, this message translates to:
  /// **'Débloqué au Niveau {level}'**
  String arsenalUnlockedAtLevel(int level);

  /// No description provided for @arsenalEquipped.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPÉ'**
  String get arsenalEquipped;

  /// No description provided for @arsenalEquip.
  ///
  /// In fr, this message translates to:
  /// **'ÉQUIPER'**
  String get arsenalEquip;

  /// No description provided for @arsenalTheBlacksmith.
  ///
  /// In fr, this message translates to:
  /// **'Le Forgeron'**
  String get arsenalTheBlacksmith;

  /// No description provided for @arsenalRanks.
  ///
  /// In fr, this message translates to:
  /// **'Grades'**
  String get arsenalRanks;

  /// No description provided for @arsenalMyRelics.
  ///
  /// In fr, this message translates to:
  /// **'Mes Reliques'**
  String get arsenalMyRelics;

  /// No description provided for @arsenalTypePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get arsenalTypePrefix;

  /// No description provided for @arsenalExchangeAetherFor.
  ///
  /// In fr, this message translates to:
  /// **'Échanger {cost} Aether contre \'{name}\' ?'**
  String arsenalExchangeAetherFor(String cost, String name);

  /// No description provided for @commonRefuse.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get commonRefuse;

  /// No description provided for @arsenalRelicAcquired.
  ///
  /// In fr, this message translates to:
  /// **'Relique acquise : {name}'**
  String arsenalRelicAcquired(String name);

  /// No description provided for @arsenalConsumable.
  ///
  /// In fr, this message translates to:
  /// **'CONSOMMABLE'**
  String get arsenalConsumable;

  /// No description provided for @arsenalEquippedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'{name} équipé avec succès !'**
  String arsenalEquippedSuccess(String name);

  /// No description provided for @arsenalUnequipped.
  ///
  /// In fr, this message translates to:
  /// **'{name} déséquipé.'**
  String arsenalUnequipped(String name);

  /// No description provided for @arsenalEquipError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'équipement : {error}'**
  String arsenalEquipError(String error);

  /// No description provided for @carouselTitle1.
  ///
  /// In fr, this message translates to:
  /// **'FORGE TON CORPS'**
  String get carouselTitle1;

  /// No description provided for @carouselDesc1.
  ///
  /// In fr, this message translates to:
  /// **'OSIRION est plus qu\'un simple tracker. C\'est ton arène. Relève des défis physiques et repousse tes limites.'**
  String get carouselDesc1;

  /// No description provided for @carouselTitle2.
  ///
  /// In fr, this message translates to:
  /// **'ÉLÈVE TON ESPRIT'**
  String get carouselTitle2;

  /// No description provided for @carouselDesc2.
  ///
  /// In fr, this message translates to:
  /// **'La force sans la sagesse n\'est rien. Développe ta discipline, accomplis des quêtes et trouve l\'harmonie parfaite.'**
  String get carouselDesc2;

  /// No description provided for @carouselTitle3.
  ///
  /// In fr, this message translates to:
  /// **'RÉCOLTE L\'AETHER'**
  String get carouselTitle3;

  /// No description provided for @carouselDesc3.
  ///
  /// In fr, this message translates to:
  /// **'Chaque effort te rapporte de l\'Aether. Achète des reliques mythiques, débloque des titres et personnalise ton aura.'**
  String get carouselDesc3;

  /// No description provided for @carouselTitle4.
  ///
  /// In fr, this message translates to:
  /// **'REJOINS LE PANTHÉON'**
  String get carouselTitle4;

  /// No description provided for @carouselDesc4.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'es pas seul. Forme des alliances, affronte d\'autres recrues et inscris ton nom dans les légendes du Panthéon.'**
  String get carouselDesc4;

  /// No description provided for @carouselNext.
  ///
  /// In fr, this message translates to:
  /// **'SUIVANT'**
  String get carouselNext;

  /// No description provided for @carouselStart.
  ///
  /// In fr, this message translates to:
  /// **'COMMENCER'**
  String get carouselStart;

  /// No description provided for @googlePseudoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nom de Code'**
  String get googlePseudoTitle;

  /// No description provided for @googlePseudoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton pseudonyme unique de recrue.'**
  String get googlePseudoDesc;

  /// No description provided for @googlePseudoCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get googlePseudoCancel;

  /// No description provided for @googlePseudoValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get googlePseudoValidate;

  /// No description provided for @googlePseudoEmptyError.
  ///
  /// In fr, this message translates to:
  /// **'Le pseudo ne peut pas être vide'**
  String get googlePseudoEmptyError;

  /// No description provided for @googlePseudoTakenError.
  ///
  /// In fr, this message translates to:
  /// **'Ce pseudo est déjà pris'**
  String get googlePseudoTakenError;

  /// No description provided for @googleSignInButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get googleSignInButton;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
