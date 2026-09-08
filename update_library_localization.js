const fs = require('fs');

const enFile = 'lib/l10n/app_en.arb';
const frFile = 'lib/l10n/app_fr.arb';

let enData = JSON.parse(fs.readFileSync(enFile, 'utf8'));
let frData = JSON.parse(fs.readFileSync(frFile, 'utf8'));

const translations = {
  // Library Screen
  "libraryTabLivres": {fr: "Livres", en: "Books"},
  "libraryTabFocus": {fr: "Focus", en: "Focus"},
  "libraryTabJournal": {fr: "Journal", en: "Journal"},
  "libraryTabAudio": {fr: "Audio", en: "Audio"},
  "libraryFiche": {fr: "FICHE", en: "INFO"},
  "libraryLire": {fr: "LIRE", en: "READ"},
  "libraryLecturePrefix": {fr: "LECTURE : ", en: "READING: "},
  "libraryModeImmersion": {fr: "MODE IMMERSION", en: "IMMERSION MODE"},
  "libraryCommencerLecture": {fr: "COMMENCER LA LECTURE", en: "START READING"},
  "libraryArreterImmersion": {fr: "ARRÊTER L'IMMERSION", en: "STOP IMMERSION"},
  "libraryCommencerImmersion": {fr: "COMMENCER L'IMMERSION", en: "START IMMERSION"},
  "libraryLeconNumeroUn": {fr: "Leçon numéro un tirée de : ", en: "Lesson number one from: "},
  "libraryParAuteur": {fr: "par ", en: "by "},
  "libraryFermer": {fr: "FERMER", en: "CLOSE"},
  "libraryTransmissionAlphaCalee": {fr: "Transmission Alpha calée sur : ", en: "Alpha Transmission tuned to: "},
  "libraryMinutesSuffix": {fr: " min", en: " min"},

  // Books (Winter Arc)
  "bookHagakureTitle": {fr: "Hagakure : Le Code du Samouraï", en: "Hagakure: The Book of the Samurai"},
  "bookHagakureTag": {fr: "Discipline", en: "Discipline"},
  "bookHagakureTheme": {fr: "Discipline absolue et résolution.", en: "Absolute discipline and resolve."},
  "bookHagakureWhyRead": {fr: "C'est un texte radical sur la voie du guerrier (Bushido). Il prône une discipline de chaque instant et une préparation mentale à l'épreuve de tout.", en: "A radical text on the warrior's way (Bushido). It advocates for constant discipline and mental preparation against everything."},
  "bookHagakureKeyPhrase": {fr: "La Voie du Samouraï se trouve dans la mort (le dépassement de soi).", en: "The Way of the Samurai is found in death (overcoming oneself)."},

  "bookObstacleTitle": {fr: "L'Obstacle est le Chemin", en: "The Obstacle is the Way"},
  "bookObstacleTag": {fr: "Stoïcisme", en: "Stoicism"},
  "bookObstacleTheme": {fr: "Transformer la difficulté en avantage.", en: "Turning difficulty into advantage."},
  "bookObstacleWhyRead": {fr: "Apprendre à voir les problèmes non pas comme des murs, mais comme des opportunités pour grow et devenir meilleur.", en: "Learn to see problems not as walls, but as opportunities to grow and become better."},
  "bookObstacleKeyPhrase": {fr: "Le but de l'obstacle n'est pas de t'arrêter, mais de te montrer à quel point tu désires avancer.", en: "The obstacle is not meant to stop you, but to show you how much you want to move forward."},

  "bookEpicteteTitle": {fr: "Le Manuel", en: "The Enchiridion"},
  "bookEpicteteTheme": {fr: "Stoïcisme Radical et Maîtrise de soi.", en: "Radical Stoicism and Self-mastery."},
  "bookEpicteteWhyRead": {fr: "La base absolue. Il apprend à ne plus gaspiller d'énergie sur ce qu'on ne controlle pas pour se concentrer uniquement sur son effort.", en: "The absolute foundation. It teaches not to waste energy on what we cannot control and to focus solely on our effort."},
  "bookEpicteteKeyPhrase": {fr: "Il y a des choses qui dépendent de nous, et d'autres qui n'en dépendent pas.", en: "Some things are within our control, and some things are not."},

  "bookAureleTitle": {fr: "Pensées pour moi-même", en: "Meditations"},
  "bookAureleTheme": {fr: "Force mentale et Dialogue intérieur.", en: "Mental strength and Inner dialogue."},
  "bookAureleWhyRead": {fr: "Pour montrer que l'Alpha doit être son propre juge le plus strict. Idéal pour garder le cap lors des entraînements solitaires.", en: "To show that an Alpha must be their own strictest judge. Ideal for staying the course during solitary training."},
  "bookAureleKeyPhrase": {fr: "L’obstacle à l’action favorise l’action. Ce qui barre le chemin devient le chemin.", en: "The impediment to action advances action. What stands in the way becomes the way."},

  "bookSenequeTempsTitle": {fr: "De la brièveté de la vie", en: "On the Shortness of Life"},
  "bookSenequeTempsTheme": {fr: "Gestion du temps et Philosophie de l'action.", en: "Time management and Philosophy of action."},
  "bookSenequeTempsWhyRead": {fr: "Pour supprimer l'excuse du \"je n'ai pas le temps\". Ce livre motive à couper les distractions pour se consacrer à l'essentiel.", en: "To eliminate the \"I don't have time\" excuse. This book motivates cutting out distractions to focus on what matters."},
  "bookSenequeTempsKeyPhrase": {fr: "Ce n'est pas que nous disposions de peu de temps, c'est que nous en perdons beaucoup.", en: "It is not that we have a short time to live, but that we waste a lot of it."},

  "bookSenequeAmeTitle": {fr: "De la tranquillité de l'âme", en: "On the Tranquility of the Mind"},
  "bookSenequeAmeTheme": {fr: "Sérénité et Constance.", en: "Serenity and Constancy."},
  "bookSenequeAmeWhyRead": {fr: "Apprendre à rester stable émotionnellement même quand l'entraînement est dur ou que les résultats tardent.", en: "Learn to stay emotionally stable even when training is hard or results are delayed."},
  "bookSenequeAmeKeyPhrase": {fr: "Il faut s'habituer à sa condition, s'en plaindre le moins possible et saisir tous les avantages qu'elle peut offrir.", en: "We must get used to our condition, complain about it as little as possible, and seize all the advantages it can offer."},

  "bookBoeceTitle": {fr: "Consolation de la philosophie", en: "The Consolation of Philosophy"},
  "bookBoeceTheme": {fr: "Résilience face à l'adversité.", en: "Resilience in the face of adversity."},
  "bookBoeceWhyRead": {fr: "Écrit en prison, ce livre est l'ultime leçon de force mentale : rien ni personne ne peut t'enlever ta liberté intérieure.", en: "Written in prison, this book is the ultimate lesson in mental strength: nothing and no one can take away your inner freedom."},
  "bookBoeceKeyPhrase": {fr: "La fortune ne t'a point tout enlevé, puisque tu as encore l'usage de ta raison.", en: "Fortune has not taken everything from you, since you still have the use of your reason."},

  // Summer Body
  "bookAtomicTitle": {fr: "Atomic Habits", en: "Atomic Habits"},
  "bookAtomicTag": {fr: "Productivité", en: "Productivity"},
  "bookAtomicTheme": {fr: "Le pouvoir des petits changements.", en: "The power of small changes."},
  "bookAtomicWhyRead": {fr: "Pour comprendre que le succès n'est pas une question d'intensité, mais de constance et de construction de systèmes viables.", en: "To understand that success is not a question of intensity, but of constancy and building viable systems."},
  "bookAtomicKeyPhrase": {fr: "On ne s'élève pas au niveau de ses objectifs, on tombe au niveau de ses systèmes.", en: "You do not rise to the level of your goals, you fall to the level of your systems."},

  "bookLeBonTitle": {fr: "La Psychologie des foules", en: "The Crowd: A Study of the Popular Mind"},
  "bookLeBonTag": {fr: "Influence", en: "Influence"},
  "bookLeBonTheme": {fr: "Sociologie et Psychologie des groupes.", en: "Sociology and Group Psychology."},
  "bookLeBonWhyRead": {fr: "Indispensable pour comprendre comment influencer son entourage et devenir un leader charismatique.", en: "Essential to understand how to influence your surroundings and become a charismatic leader."},
  "bookLeBonKeyPhrase": {fr: "L'affirmation pure et simple, dégagée de tout raisonnement, est un des moyens les plus sûrs pour faire pénétrer une idée dans l'esprit des foules.", en: "Pure and simple affirmation, free of all reasoning, is one of the surest ways of making an idea enter the minds of crowds."},

  "bookSchopenhauerTitle": {fr: "L'Art d'avoir toujours raison", en: "The Art of Being Right"},
  "bookSchopenhauerTheme": {fr: "Rhétorique et Débat.", en: "Rhetoric and Debate."},
  "bookSchopenhauerWhyRead": {fr: "Pour apprendre à défendre sa vision et son Arc face aux sceptiques. C'est l'armure intellectuelle de l'Alpha.", en: "To learn how to defend your vision and your Arc against skeptics. It is the intellectual armor of the Alpha."},
  "bookSchopenhauerKeyPhrase": {fr: "La vérité est que chaque homme veut avoir raison, par tous les moyens possibles.", en: "The truth is that every man wants to be right, by all possible means."},

  "bookLaBruyereTitle": {fr: "Les Caractères", en: "The Characters"},
  "bookLaBruyereTheme": {fr: "Observation humaine et Psychologie.", en: "Human Observation and Psychology."},
  "bookLaBruyereWhyRead": {fr: "Pour développer une vision perçante. Apprendre à lire les gens comme on lit un itinéraire de course.", en: "To develop a piercing vision. Learn to read people like you read a running route."},
  "bookLaBruyereKeyPhrase": {fr: "Tout est dit, et l'on vient trop tard depuis sept mille ans qu'il y a des hommes et qui pensent.", en: "Everything has been said, and we come too late after seven thousand years that there have been men who think."},

  "bookRochefoucauldTitle": {fr: "Maximes", en: "Maxims"},
  "bookRochefoucauldTheme": {fr: "Nature humaine et Réalisme.", en: "Human Nature and Realism."},
  "bookRochefoucauldWhyRead": {fr: "Des phrases courtes et percutantes (parfaites pour l'UI de l'app) qui révèlent les ressorts cachés de nos actions.", en: "Short, punchy sentences (perfect for the app UI) that reveal the hidden springs of our actions."},
  "bookRochefoucauldKeyPhrase": {fr: "Nos vertus ne sont, le plus souvent, que des vices déguisés.", en: "Our virtues are, most often, only vices in disguise."},

  "bookBalzacTitle": {fr: "Traité de la vie élégante", en: "Treatise on Elegant Living"},
  "bookBalzacTheme": {fr: "Style, Énergie et Présence sociale.", en: "Style, Energy and Social Presence."},
  "bookBalzacWhyRead": {fr: "Pour l'utilisateur qui cherche l'excellence esthétique et le rayonnement en société après avoir forgé son corps.", en: "For the user seeking aesthetic excellence and social radiance after forging their body."},
  "bookBalzacKeyPhrase": {fr: "L'élégance est tout à la fois un art, une science, un goût, un enthousiasme.", en: "Elegance is at once an art, a science, a taste, an enthusiasm."},

  // Royal Arc
  "bookArtOfWarTitle": {fr: "L'Art de la Guerre", en: "The Art of War"},
  "bookArtOfWarTag": {fr: "48 Lois du Pouvoir", en: "48 Laws of Power"},
  "bookArtOfWarTheme": {fr: "Stratégie et Maîtrise émotionnelle.", en: "Strategy and Emotional Mastery."},
  "bookArtOfWarWhyRead": {fr: "La bible de l'efficacité. Apprendre à économiser ses forces pour frapper au moment opportun.", en: "The bible of efficiency. Learn to conserve your strength to strike at the right moment."},
  "bookArtOfWarKeyPhrase": {fr: "Le plus grand conquérant est celui qui sait vaincre sans bataille.", en: "The greatest conqueror is the one who knows how to win without a battle."},

  "bookMachiavelTitle": {fr: "Le Prince", en: "The Prince"},
  "bookMachiavelTheme": {fr: "Leadership et Réalisme de pouvoir.", en: "Leadership and Realism of power."},
  "bookMachiavelWhyRead": {fr: "Comprendre les dynamiques de groupe et la hiérarchie pour diriger son propre Clan dans Valérion.", en: "Understand group dynamics and hierarchy to lead your own Clan in Valerion."},
  "bookMachiavelKeyPhrase": {fr: "Il n'y a pas d'autre moyen de se garder de la flatterie que de faire comprendre aux hommes que dire la vérité ne vous offense pas.", en: "There is no other way to guard against flattery than to make men understand that telling the truth does not offend you."},

  "bookMusashiTitle": {fr: "Traité des cinq roues", en: "The Book of Five Rings"},
  "bookMusashiTag": {fr: "Stratégie", en: "Strategy"},
  "bookMusashiTheme": {fr: "Discipline martiale et Maîtrise totale.", en: "Martial discipline and Total mastery."},
  "bookMusashiWhyRead": {fr: "Le plus grand samouraï explique comment appliquer la stratégie dans chaque petit geste. Parfait pour le Calisthenics technique.", en: "The greatest samurai explains how to apply strategy in every small gesture. Perfect for technical Calisthenics."},
  "bookMusashiKeyPhrase": {fr: "D'une chose, apprends-en dix mille.", en: "From one thing, know ten thousand things."},

  "bookLaoTseuTitle": {fr: "Tao Te King", en: "Tao Te Ching"},
  "bookLaoTseuTheme": {fr: "Équilibre, Fluidité et Harmonie.", en: "Balance, Fluidity and Harmony."},
  "bookLaoTseuWhyRead": {fr: "Pour contrebalancer la force brute. C'est le livre qui aide à atteindre l'Indice d'Harmonie maximal.", en: "To counterbalance brute force. It is the book that helps reach the maximum Harmony Index."},
  "bookLaoTseuKeyPhrase": {fr: "Rien au monde n'est plus souple et plus faible que l'eau. Pourtant, pour attaquer ce qui est dur et fort, rien ne la surpasse.", en: "Nothing in the world is more flexible and yielding than water. Yet, to attack what is hard and strong, nothing surpasses it."},

  "bookCastiglioneTitle": {fr: "Le Livre du Courtisan", en: "The Book of the Courtier"},
  "bookCastiglioneTheme": {fr: "Maîtrise de soi et Sprezzatura (aisance).", en: "Self-mastery and Sprezzatura (ease)."},
  "bookCastiglioneWhyRead": {fr: "Pour cultiver cette aisance naturelle où l'effort colossal derrière la performance ne doit jamais se voir.", en: "To cultivate that natural ease where the colossal effort behind the performance must never be seen."},
  "bookCastiglioneKeyPhrase": {fr: "Faire paraître sans effort ce qui a été accompli avec une grande peine.", en: "Make appear effortless what was accomplished with great pain."},

  // Audios
  "audioTransformerTitle": {fr: "3 Minutes Pour Transformer Ta Vie", en: "3 Minutes To Transform Your Life"},
  "audioTransformerSub": {fr: "3 min • Motivation", en: "3 min • Motivation"},
  "audioProcrastinesTitle": {fr: "Si Tu Procrastines, Écoute Ça", en: "If You Procrastinate, Listen To This"},
  "audioProcrastinesSub": {fr: "Motivation • Focus", en: "Motivation • Focus"},
  "audioSaitamaTitle": {fr: "Le Discours de Saitama", en: "Saitama's Speech"},
  "audioSaitamaSub": {fr: "Détermination • Alpha", en: "Determination • Alpha"},
  "audioReveillerTitle": {fr: "Réveiller quelque chose en toi", en: "Wake something up in you"},
  "audioReveillerSub": {fr: "David Goggins • Interview", en: "David Goggins • Interview"},
  "audioObstacleTitle": {fr: "Ton Seul Obstacle, C’est TOI", en: "Your Only Obstacle Is YOU"},
  "audioObstacleSub": {fr: "Mindset Alpha", en: "Alpha Mindset"},
  "audioMaîtriserTitle": {fr: "L'Art de Maîtriser Son Esprit", en: "The Art of Mastering Your Mind"},
  "audioMaîtriserSub": {fr: "David Goggins • Interview", en: "David Goggins • Interview"},
};

for (const key in translations) {
  enData[key] = translations[key].en;
  frData[key] = translations[key].fr;
}

fs.writeFileSync(enFile, JSON.stringify(enData, null, 2));
fs.writeFileSync(frFile, JSON.stringify(frData, null, 2));
console.log("ARB files updated.");
