const fs = require('fs');

function updateBookEntity() {
  const path = 'lib/features/library/models/book_entity.dart';
  let c = fs.readFileSync(path, 'utf8');

  // Add import for AppLocalizations and flutter/material.dart if missing
  if (!c.includes('app_localizations.dart')) {
    c = "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';\n" + c;
  }

  // Change final Map... to Map... getLibraryCatalog(BuildContext context) { return { ... }; }
  c = c.replace('final Map<String, List<BookEntity>> libraryCatalog = {', 'Map<String, List<BookEntity>> getLibraryCatalog(BuildContext context) {\n  return {');
  // At the end of the file, we have "};" which we need to change to "};\n}"
  c = c.replace('};\n', '};\n}\n');

  // Replace strings with AppLocalizations.of(context)!.xxx
  const reps = {
    '"Hagakure : Le Code du Samouraï"': 'AppLocalizations.of(context)!.bookHagakureTitle',
    '"Discipline"': 'AppLocalizations.of(context)!.bookHagakureTag',
    '"Discipline absolue et résolution."': 'AppLocalizations.of(context)!.bookHagakureTheme',
    '"C\'est un texte radical sur la voie du guerrier (Bushido). Il prône une discipline de chaque instant et une préparation mentale à l\'épreuve de tout."': 'AppLocalizations.of(context)!.bookHagakureWhyRead',
    '"La Voie du Samouraï se trouve dans la mort (le dépassement de soi)."': 'AppLocalizations.of(context)!.bookHagakureKeyPhrase',

    '"L\'Obstacle est le Chemin"': 'AppLocalizations.of(context)!.bookObstacleTitle',
    '"Stoïcisme"': 'AppLocalizations.of(context)!.bookObstacleTag',
    '"Transformer la difficulté en avantage."': 'AppLocalizations.of(context)!.bookObstacleTheme',
    '"Apprendre à voir les problèmes non pas comme des murs, mais comme des opportunités pour grow et devenir meilleur."': 'AppLocalizations.of(context)!.bookObstacleWhyRead',
    '"Le but de l\'obstacle n\'est pas de t\'arrêter, mais de te montrer à quel point tu désires avancer."': 'AppLocalizations.of(context)!.bookObstacleKeyPhrase',

    '"Le Manuel"': 'AppLocalizations.of(context)!.bookEpicteteTitle',
    '"Stoïcisme Radical et Maîtrise de soi."': 'AppLocalizations.of(context)!.bookEpicteteTheme',
    '"La base absolue. Il apprend à ne plus gaspiller d\'énergie sur ce qu\'on ne controlle pas pour se concentrer uniquement sur son effort."': 'AppLocalizations.of(context)!.bookEpicteteWhyRead',
    '"Il y a des choses qui dépendent de nous, et d\'autres qui n\'en dépendent pas."': 'AppLocalizations.of(context)!.bookEpicteteKeyPhrase',

    '"Pensées pour moi-même"': 'AppLocalizations.of(context)!.bookAureleTitle',
    '"Force mentale et Dialogue intérieur."': 'AppLocalizations.of(context)!.bookAureleTheme',
    '"Pour montrer que l\'Alpha doit être son propre juge le plus strict. Idéal pour garder le cap lors des entraînements solitaires."': 'AppLocalizations.of(context)!.bookAureleWhyRead',
    '"L’obstacle à l’action favorise l’action. Ce qui barre le chemin devient le chemin."': 'AppLocalizations.of(context)!.bookAureleKeyPhrase',

    '"De la brièveté de la vie"': 'AppLocalizations.of(context)!.bookSenequeTempsTitle',
    '"Gestion du temps et Philosophie de l\'action."': 'AppLocalizations.of(context)!.bookSenequeTempsTheme',
    '"Pour supprimer l\'excuse du \\"je n\'ai pas le temps\\". Ce livre motive à couper les distractions pour se consacrer à l\'essentiel."': 'AppLocalizations.of(context)!.bookSenequeTempsWhyRead',
    '"Ce n\'est pas que nous disposions de peu de temps, c\'est que nous en perdons beaucoup."': 'AppLocalizations.of(context)!.bookSenequeTempsKeyPhrase',

    '"De la tranquillité de l\'âme"': 'AppLocalizations.of(context)!.bookSenequeAmeTitle',
    '"Sérénité et Constance."': 'AppLocalizations.of(context)!.bookSenequeAmeTheme',
    '"Apprendre à rester stable émotionnellement même quand l\'entraînement est dur ou que les résultats tardent."': 'AppLocalizations.of(context)!.bookSenequeAmeWhyRead',
    '"Il faut s\'habituer à sa condition, s\'en plaindre le moins possible et saisir tous les avantages qu\'elle peut offrir."': 'AppLocalizations.of(context)!.bookSenequeAmeKeyPhrase',

    '"Consolation de la philosophie"': 'AppLocalizations.of(context)!.bookBoeceTitle',
    '"Résilience face à l\'adversité."': 'AppLocalizations.of(context)!.bookBoeceTheme',
    '"Écrit en prison, ce livre est l\'ultime leçon de force mentale : rien ni personne ne peut t\'enlever ta liberté intérieure."': 'AppLocalizations.of(context)!.bookBoeceWhyRead',
    '"La fortune ne t\'a point tout enlevé, puisque tu as encore l\'usage de ta raison."': 'AppLocalizations.of(context)!.bookBoeceKeyPhrase',

    // Summer Body
    '"Atomic Habits"': 'AppLocalizations.of(context)!.bookAtomicTitle',
    '"Productivité"': 'AppLocalizations.of(context)!.bookAtomicTag',
    '"Le pouvoir des petits changements."': 'AppLocalizations.of(context)!.bookAtomicTheme',
    '"Pour comprendre que le succès n\'est pas une question d\'intensité, mais de constance et de construction de systèmes viables."': 'AppLocalizations.of(context)!.bookAtomicWhyRead',
    '"On ne s\'élève pas au niveau de ses objectifs, on tombe au niveau de ses systèmes."': 'AppLocalizations.of(context)!.bookAtomicKeyPhrase',

    '"La Psychologie des foules"': 'AppLocalizations.of(context)!.bookLeBonTitle',
    '"Influence"': 'AppLocalizations.of(context)!.bookLeBonTag',
    '"Sociologie et Psychologie des groupes."': 'AppLocalizations.of(context)!.bookLeBonTheme',
    '"Indispensable pour comprendre comment influencer son entourage et devenir un leader charismatique."': 'AppLocalizations.of(context)!.bookLeBonWhyRead',
    '"L\'affirmation pure et simple, dégagée de tout raisonnement, est un des moyens les plus sûrs pour faire pénétrer une idée dans l\'esprit des foules."': 'AppLocalizations.of(context)!.bookLeBonKeyPhrase',

    '"L\'Art d\'avoir toujours raison"': 'AppLocalizations.of(context)!.bookSchopenhauerTitle',
    '"Rhétorique et Débat."': 'AppLocalizations.of(context)!.bookSchopenhauerTheme',
    '"Pour apprendre à défendre sa vision et son Arc face aux sceptiques. C\'est l\'armure intellectuelle de l\'Alpha."': 'AppLocalizations.of(context)!.bookSchopenhauerWhyRead',
    '"La vérité est que chaque homme veut avoir raison, par tous les moyens possibles."': 'AppLocalizations.of(context)!.bookSchopenhauerKeyPhrase',

    '"Les Caractères"': 'AppLocalizations.of(context)!.bookLaBruyereTitle',
    '"Observation humaine et Psychologie."': 'AppLocalizations.of(context)!.bookLaBruyereTheme',
    '"Pour développer une vision perçante. Apprendre à lire les gens comme on lit un itinéraire de course."': 'AppLocalizations.of(context)!.bookLaBruyereWhyRead',
    '"Tout est dit, et l\'on vient trop tard depuis sept mille ans qu\'il y a des hommes et qui pensent."': 'AppLocalizations.of(context)!.bookLaBruyereKeyPhrase',

    '"Maximes"': 'AppLocalizations.of(context)!.bookRochefoucauldTitle',
    '"Nature humaine et Réalisme."': 'AppLocalizations.of(context)!.bookRochefoucauldTheme',
    '"Des phrases courtes et percutantes (parfaites pour l\'UI de l\'app) qui révèlent les ressorts cachés de nos actions."': 'AppLocalizations.of(context)!.bookRochefoucauldWhyRead',
    '"Nos vertus ne sont, le plus souvent, que des vices déguisés."': 'AppLocalizations.of(context)!.bookRochefoucauldKeyPhrase',

    '"Traité de la vie élégante"': 'AppLocalizations.of(context)!.bookBalzacTitle',
    '"Style, Énergie et Présence sociale."': 'AppLocalizations.of(context)!.bookBalzacTheme',
    '"Pour l\'utilisateur qui cherche l\'excellence esthétique et le rayonnement en société après avoir forgé son corps."': 'AppLocalizations.of(context)!.bookBalzacWhyRead',
    '"L\'élégance est tout à la fois un art, une science, un goût, un enthousiasme."': 'AppLocalizations.of(context)!.bookBalzacKeyPhrase',

    // Royal Arc
    '"L\'Art de la Guerre"': 'AppLocalizations.of(context)!.bookArtOfWarTitle',
    '"48 Lois du Pouvoir"': 'AppLocalizations.of(context)!.bookArtOfWarTag',
    '"Stratégie et Maîtrise émotionnelle."': 'AppLocalizations.of(context)!.bookArtOfWarTheme',
    '"La bible de l\'efficacité. Apprendre à économiser ses forces pour frapper au moment opportun."': 'AppLocalizations.of(context)!.bookArtOfWarWhyRead',
    '"Le plus grand conquérant est celui qui sait vaincre sans bataille."': 'AppLocalizations.of(context)!.bookArtOfWarKeyPhrase',

    '"Le Prince"': 'AppLocalizations.of(context)!.bookMachiavelTitle',
    '"Leadership et Réalisme de pouvoir."': 'AppLocalizations.of(context)!.bookMachiavelTheme',
    '"Comprendre les dynamiques de groupe et la hiérarchie pour diriger son propre Clan dans Valérion."': 'AppLocalizations.of(context)!.bookMachiavelWhyRead',
    '"Il n\'y a pas d\'autre moyen de se garder de la flatterie que de faire comprendre aux hommes que dire la vérité ne vous offense pas."': 'AppLocalizations.of(context)!.bookMachiavelKeyPhrase',

    '"Traité des cinq roues"': 'AppLocalizations.of(context)!.bookMusashiTitle',
    '"Stratégie"': 'AppLocalizations.of(context)!.bookMusashiTag',
    '"Discipline martiale et Maîtrise totale."': 'AppLocalizations.of(context)!.bookMusashiTheme',
    '"Le plus grand samouraï explique comment appliquer la stratégie dans chaque petit geste. Parfait pour le Calisthenics technique."': 'AppLocalizations.of(context)!.bookMusashiWhyRead',
    '"D\'une chose, apprends-en dix mille."': 'AppLocalizations.of(context)!.bookMusashiKeyPhrase',

    '"Tao Te King"': 'AppLocalizations.of(context)!.bookLaoTseuTitle',
    '"Équilibre, Fluidité et Harmonie."': 'AppLocalizations.of(context)!.bookLaoTseuTheme',
    '"Pour contrebalancer la force brute. C\'est le livre qui aide à atteindre l\'Indice d\'Harmonie maximal."': 'AppLocalizations.of(context)!.bookLaoTseuWhyRead',
    '"Rien au monde n\'est plus souple et plus faible que l\'eau. Pourtant, pour attaquer ce qui est dur et fort, rien ne la surpasse."': 'AppLocalizations.of(context)!.bookLaoTseuKeyPhrase',

    '"Le Livre du Courtisan"': 'AppLocalizations.of(context)!.bookCastiglioneTitle',
    '"Maîtrise de soi et Sprezzatura (aisance)."': 'AppLocalizations.of(context)!.bookCastiglioneTheme',
    '"Pour cultiver cette aisance naturelle où l\'effort colossal derrière la performance ne doit jamais se voir."': 'AppLocalizations.of(context)!.bookCastiglioneWhyRead',
    '"Faire paraître sans effort ce qui a été accompli avec une grande peine."': 'AppLocalizations.of(context)!.bookCastiglioneKeyPhrase',
  };

  // Remove const keyword from BookEntity constructions since we are using AppLocalizations
  c = c.split('const BookEntity(').join('BookEntity(');

  for (const [key, value] of Object.entries(reps)) {
    c = c.split(key).join(value);
  }

  fs.writeFileSync(path, c);
  console.log('Updated ' + path);
}

function updateLibraryAudioEntity() {
  const path = 'lib/core/domain/entities/library_audio_entity.dart';
  let c = fs.readFileSync(path, 'utf8');

  if (!c.includes('app_localizations.dart')) {
    c = "import 'package:flutter/material.dart';\nimport 'package:valerion/l10n/app_localizations.dart';\n" + c;
  }

  c = c.replace('static const List<LibraryAudioEntity> catalogue = [', 'static List<LibraryAudioEntity> getCatalogue(BuildContext context) {\n    return [');
  c = c.replace('];\n}', '];\n  }\n}');

  c = c.split('LibraryAudioEntity(').join('LibraryAudioEntity(');

  const reps = {
    '"3 Minutes Pour Transformer Ta Vie"': 'AppLocalizations.of(context)!.audioTransformerTitle',
    '"3 min • Motivation"': 'AppLocalizations.of(context)!.audioTransformerSub',
    '"Si Tu Procrastines, Écoute Ça"': 'AppLocalizations.of(context)!.audioProcrastinesTitle',
    '"Motivation • Focus"': 'AppLocalizations.of(context)!.audioProcrastinesSub',
    '"Le Discours de Saitama"': 'AppLocalizations.of(context)!.audioSaitamaTitle',
    '"Détermination • Alpha"': 'AppLocalizations.of(context)!.audioSaitamaSub',
    '"Réveiller quelque chose en toi"': 'AppLocalizations.of(context)!.audioReveillerTitle',
    '"David Goggins • Interview"': 'AppLocalizations.of(context)!.audioReveillerSub',
    '"Ton Seul Obstacle, C’est TOI"': 'AppLocalizations.of(context)!.audioObstacleTitle',
    '"Mindset Alpha"': 'AppLocalizations.of(context)!.audioObstacleSub',
    '"L\'Art de Maîtriser Son Esprit"': 'AppLocalizations.of(context)!.audioMaîtriserTitle',
    '"David Goggins • Interview"': 'AppLocalizations.of(context)!.audioMaîtriserSub',
  };

  for (const [key, value] of Object.entries(reps)) {
    c = c.split(key).join(value);
  }

  fs.writeFileSync(path, c);
  console.log('Updated ' + path);
}

function updateLibraryScreen() {
  const path = 'lib/features/library/library_screen.dart';
  let c = fs.readFileSync(path, 'utf8');

  // Replace usage of static catalogs with dynamic catalogs
  c = c.split('libraryCatalog[').join('getLibraryCatalog(context)[');
  c = c.split('libraryCatalog.values').join('getLibraryCatalog(context).values');
  c = c.split('ValerionAudios.catalogue').join('ValerionAudios.getCatalogue(context)');

  // Replace hardcoded strings
  const reps = {
    '"Livres"': 'AppLocalizations.of(context)!.libraryTabLivres',
    '"Focus"': 'AppLocalizations.of(context)!.libraryTabFocus',
    '"Journal"': 'AppLocalizations.of(context)!.libraryTabJournal',
    '"Audio"': 'AppLocalizations.of(context)!.libraryTabAudio',
    '"Transmission Alpha calée sur : $arcId"': 'AppLocalizations.of(context)!.libraryTransmissionAlphaCalee + arcId',
    '"FICHE"': 'AppLocalizations.of(context)!.libraryFiche',
    '"LIRE"': 'AppLocalizations.of(context)!.libraryLire',
    '"LECTURE : ${_selectedBookForReading!.title.toUpperCase()}"': 'AppLocalizations.of(context)!.libraryLecturePrefix + _selectedBookForReading!.title.toUpperCase()',
    '"MODE IMMERSION"': 'AppLocalizations.of(context)!.libraryModeImmersion',
    '"$mins min"': 'mins.toString() + AppLocalizations.of(context)!.libraryMinutesSuffix',
    '"COMMENCER LA LECTURE"': 'AppLocalizations.of(context)!.libraryCommencerLecture',
    '"ARRÊTER L\'IMMERSION"': 'AppLocalizations.of(context)!.libraryArreterImmersion',
    '"COMMENCER L\'IMMERSION"': 'AppLocalizations.of(context)!.libraryCommencerImmersion',
    '"Leçon numéro un tirée de : ${_selectedBookForReading!.title}\\n"': 'AppLocalizations.of(context)!.libraryLeconNumeroUn + _selectedBookForReading!.title + "\\n"',
    '"par ${book.author}"': 'AppLocalizations.of(context)!.libraryParAuteur + book.author',
    '"FERMER"': 'AppLocalizations.of(context)!.libraryFermer',
  };

  for (const [key, value] of Object.entries(reps)) {
    c = c.split(key).join(value);
  }

  fs.writeFileSync(path, c);
  console.log('Updated ' + path);
}

updateBookEntity();
updateLibraryAudioEntity();
updateLibraryScreen();
