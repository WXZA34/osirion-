import '../../../features/home/models/arc_data.dart';
import '../../../features/arena/models/arena_models.dart';
import '../../../features/dojo/models/exercise_config.dart';
import '../entities/user_entity.dart';
import '../entities/clan_message_entity.dart';
import '../entities/global_config_entity.dart';
import '../entities/library_audio_entity.dart';
import '../../../features/library/models/journal_entry.dart';
import '../../../features/library/models/book_entity.dart';
import '../../../features/arsenal/models/relic.dart';

abstract class IValerionRepository {
  /// Récupère la liste des exercices depuis Firestore
  Stream<List<ExerciseConfig>> getDojoExercises();

  /// Fonction de migration initiale : Envoie le catalogue statique vers Firestore
  Future<void> uploadDefaultExercises(List<ExerciseConfig> defaultList);

  /// Purge la collection d'exercices
  Future<void> purgeExercises();

  /// Ajoute un exercice individuel à Firestore
  Future<void> addExercise(ExerciseConfig exercise);

  /// Récupère le profil complet d'un utilisateur depuis la base de données
  Future<UserEntity?> getUserProfile(String uid);

  /// Écoute en temps réel le profil complet d'un utilisateur depuis la base de données
  Stream<UserEntity?> listenUserProfile(String uid);

  /// Sauvegarde ou met à jour le profil d'un utilisateur
  Future<void> saveUserProfile(UserEntity user);

  /// Vérifie si le profil existe, sinon le crée (Auto-Healing)
  Future<void> ensureProfileExists(UserEntity user);

  /// Ajoute de l'XP à l'utilisateur et gère la montée de niveau
  Future<UserEntity> addXP(String uid, int xpToAdd);

  Future<UserEntity> addWorkoutResults(
    String uid,
    int pushups,
    int gainedXp,
    int earnedAether, {
    String? localDateStr,
    String? arcId,
  });

  /// Ajoute les résultats de l'Arène (Calculé côté serveur via distance/temps)
  Future<UserEntity> addArenaResults(
    String uid,
    double distanceKm,
    int durationSeconds,
  );

  /// Valide une quête quotidienne via le serveur (XP & Aether sécurisés)
  Future<UserEntity> completeQuest(String uid, String questId);

  /// Ajoute une récompense manuelle sécurisée (Journal, Focus Timer)
  Future<UserEntity> addManualReward(String uid, String rewardType);

  /// Met à jour la balance d'Aether (peut-être positif pour un gain, négatif pour un achat)
  Future<UserEntity> updateAetherBalance(String uid, int amount);

  /// Achète et équipe une relique si les fonds sont suffisants
  Future<UserEntity> buyRelic(
    String uid,
    String relicId,
    int cost,
    String relicType,
  );

  /// Écoute en temps réel les reliques de l'Arsenal
  Stream<List<Relic>> listenArsenalRelics();

  /// Ajoute une nouvelle relique à l'Arsenal
  Future<void> addRelic(Relic relic);

  /// Migration initiale pour les reliques
  Future<void> uploadDefaultRelics(List<Relic> relics);

  /// Purge la collection des reliques
  Future<void> purgeRelics();

  /// Récupère le classement des joueurs selon un critère donné
  Future<List<UserEntity>> getLeaderboard({
    required String sortBy,
    int limit = 50,
  });

  /// Met à jour uniquement le statut de l'utilisateur
  Future<void> updateUserStatus(String uid, String status);

  /// Recherche des utilisateurs par pseudo (recherche préfixe)
  Future<List<UserEntity>> searchUsersByUsername(String query);

  /// Récupère les profils d'une liste d'UIDs (amis ou requêtes)
  Future<List<UserEntity>> getFriendsProfiles(List<String> uids);

  /// Envoie une demande d'ami (fromUid -> toUid)
  Future<void> sendFriendRequest(String fromUid, String toUid);

  /// Accepte une demande d'ami
  Future<void> acceptFriendRequest(String uid, String friendId);

  /// Refuse une demande d'ami
  Future<void> declineFriendRequest(String uid, String friendId);

  /// Retire un ami (symétrique)
  Future<void> removeFriend(String uid, String friendId);

  /// Envoie un message privé à un ami
  Future<void> sendPrivateMessage({
    required String fromId,
    required String toId,
    required String senderName,
    String? text,
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
    String type = 'text',
  });

  /// Écoute les messages d'un chat privé
  Stream<List<ClanMessageEntity>> listenPrivateMessages(
    String uid1,
    String uid2,
  );

  /// Vérifie si un pseudonyme est disponible (unique)
  Future<bool> isUsernameAvailable(String username);

  /// Achète un item cosmétique de manière sécurisée (Transaction)
  Future<UserEntity> purchaseItem({
    required String uid,
    required String itemId,
    required int priceXp,
  });

  /// --- MODULE ESPRIT (JOURNAL) ---
  /// Sauvegarde une nouvelle pensée stoïcienne (immuable)
  Future<void> addJournalEntry(JournalEntry entry, {String? arcId});

  /// Écoute en temps réel l'ensemble des entrées de journal d'un utilisateur
  Stream<List<JournalEntry>> listenUserJournal(String uid);

  /// --- CONFIGURATION GLOBALE ---
  /// Écoute les paramètres globaux de l'application (ex: Vidéo du Jour)
  Stream<GlobalConfigEntity?> listenGlobalConfig();

  /// --- MODULE SÉRIES & ACTIVITÉ (ARCS) ---
  /// Met à jour la série (streak) de l'utilisateur selon sa dernière activité
  Future<void> updateStreak(String uid);

  /// Enregistre l'activité quotidienne pour un Arc spécifique
  Future<void> recordDailyActivity({
    required String uid,
    required String arcId,
    required int questsDone,
    required int totalQuests,
  });

  /// Écoute l'historique d'activité pour un Arc spécifique
  Stream<Map<String, dynamic>> listenArcActivity(String uid, String arcId);

  /// Exporte l'intégralité des données de l'utilisateur (Profil, Journal, Arcs) en JSON
  Future<String> exportUserData(String uid);

  /// Envoie un ticket de support (Bug ou Suggestion) dans Firestore
  Future<void> sendSupportTicket(String uid, Map<String, dynamic> ticket);

  /// Calcule les récompenses de fin d'Arc basées sur la corrélation (Calendrier de Cohérence)
  Future<Map<String, dynamic>> calculateArcRewards(String uid, ArcData arc);

  /// Enregistre les récompenses réclamées dans le profil utilisateur
  Future<void> claimArcRewards(
    String uid,
    String arcId,
    Map<String, dynamic> rewards,
  );

  /// --- MODULE BIBLIOTHÈQUE (AUDIOS) ---
  /// Écoute en temps réel les audios de la bibliothèque
  Stream<List<LibraryAudioEntity>> listenLibraryAudios();

  /// Ajoute un nouvel audio à la bibliothèque
  Future<void> addLibraryAudio(LibraryAudioEntity audio);

  /// Supprime un audio de la bibliothèque
  Future<void> deleteLibraryAudio(String audioId);

  /// Écoute en temps réel les livres de la bibliothèque
  Stream<List<BookEntity>> listenLibraryBooks();

  /// Ajoute un nouveau livre à la bibliothèque
  Future<void> addBook(BookEntity book);

  /// Fonction de migration initiale pour les livres
  Future<void> uploadDefaultBooks(List<BookEntity> books);

  /// Fonction de migration initiale pour les audios de la bibliothèque
  Future<void> uploadDefaultLibraryAudios(List<LibraryAudioEntity> audios);

  /// Met à jour la configuration globale (ex: pour l'initialisation)
  Future<void> updateGlobalConfig(GlobalConfigEntity config);

  /// Enregistre le token FCM de l'utilisateur pour les notifications
  Future<void> saveFcmToken(String uid, String token);

  /// Marque une conversation privée comme lue pour un utilisateur donné
  Future<void> markPrivateChatAsRead(String chatId, String userId);

  /// Écoute les métadonnées d'un chat privé (compteurs, dernier message)
  Stream<Map<String, dynamic>> listenPrivateChatMetadata(String chatId);

  /// Écoute le nombre TOTAL de messages privés non lus pour un utilisateur donné
  Stream<int> listenTotalUnreadPrivateCount(String userId);

  /// Écoute les annonces système globales
  Stream<List<ClanMessageEntity>> listenSystemAnnouncements();

  /// Marque les annonces système comme lues pour l'utilisateur
  Future<void> markSystemAnnouncementsAsRead(String userId);

  /// Purge tous les livres de la collection Firestore (Utilité Admin/Debug)
  Future<void> purgeLibraryBooks();

  /// Purge tous les audios de la collection Firestore (Utilité Admin/Debug)
  Future<void> purgeLibraryAudios();

  /// Supprime un message privé spécifique
  Future<void> deletePrivateMessage(
    String chatId,
    String messageId, {
    String? audioUrl,
  });

  /// Supprime tout l'historique d'un chat privé
  Future<void> deletePrivateChatHistory(String chatId);

  /// --- MODULE COLISÉE (RIVAUX / GHOST RUNS) ---
  /// Ajoute un nouveau record (Défi) au Colisée
  Future<void> addColosseumRun(ColosseumRunModel run);

  /// Rejoindre un défi du Colisée (Incrémentation sécurisée)
  Future<void> joinColosseumRun({required String runId});

  /// Récupère le rang mondial d'un utilisateur pour une catégorie donnée
  Future<int> getUserRank({required String sortBy, required num score});

  /// Écoute les défis disponibles dans le Colisée
  Stream<List<ColosseumRunModel>> listenColosseumRuns();

  /// --- MODULE BASTIONS (SPOTS DE WORKOUT) ---
  /// Écoute les métadonnées tactiques d'un bastion (stats, failedAttempts, photo)
  Stream<BastionModel?> listenBastionMetadata(String bastionId);

  /// Tente de conquérir un bastion ou de battre le record actuel
  Future<void> claimBastion({
    required String bastionId,
    required String bastionName,
    required String userId,
    required String pseudo,
    required int reps,
    int dips = 0,
    int pullups = 0,
    int pushups = 0,
    int abs = 0,
    required String exerciseType,
    required double userLat,
    required double userLng,
  });

  Future<void> uploadBastionPhoto({
    required String bastionId,
    required String filePath,
    String? bastionName,
    double? lat,
    double? lng,
  });
}
