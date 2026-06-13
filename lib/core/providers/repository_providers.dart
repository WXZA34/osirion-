// lib/core/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/auth_repository.dart';
import '../data/repositories/firebase_auth_repository.dart';
import '../domain/repositories/valerion_repository.dart';
import '../data/repositories/firebase_valerion_repository.dart';
import '../domain/entities/user_entity.dart';
import '../domain/entities/global_config_entity.dart';

// Imports des Clans
import '../domain/repositories/clan_repository.dart';
import '../data/repositories/firebase_clan_repository.dart';
import '../domain/entities/clan_entity.dart';
import '../domain/entities/clan_request_entity.dart';
import '../domain/entities/clan_message_entity.dart';
import '../data/services/storage_service.dart';

/// Ce fichier est le "cerveau" de notre Repository Pattern.
/// C'est ici que l'on décide quelle implémentation (Firebase ou Mock) est donnée au reste de l'application.

// 1. On instancie la vraie auth Firebase
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository();
  // Si demain on veut tester avec des fausses données, il suffit de changer cette ligne :
  // return MockAuthRepository();
});

// Provider pour Firebase Storage
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// 2. Stream continu de l'utilisateur connecté (pour rafraichir l'UI automatiquement au login/logout)
final authStateProvider = StreamProvider((ref) {
  // L'objet FirebaseAuth expose le stream natif
  // Dans une infra très stricte, ce stream serait exposé par l'IAuthRepository
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// --- VALERION DATA (Profil, XP, Niveau, etc.) ---

// 3. Provider statique pour l'accès aux méthodes (addXp, saveProfile)
final valerionRepositoryProvider = Provider<IValerionRepository>((ref) {
  return FirebaseValerionRepository() as IValerionRepository;
});

// 4. Provider dynamique qui écoute le profil actuel
// Il se base sur l'ID de l'utilisateur connecté via authStateProvider.
final userProfileProvider = StreamProvider<UserEntity?>((ref) {
  // On regarde d'abord qui est connecté (via Auth Firebase) et on écoute CHAQUE changement
  final authUser = ref.watch(authStateProvider).valueOrNull;

  if (authUser == null) {
    // Personne n'est connecté, ou l'état est en cours de chargement.
    return Stream.value(null);
  }

  // Si on a un UID valide, on écoute ses stats depuis Firestore
  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.listenUserProfile(authUser.id);
});

// 5. Provider pour le leaderboard du Panthéon
// Le String passé en paramètre (family) va déterminer le champ de tri ('xp', 'forceXp', 'wisdomXp')
final leaderboardProvider = FutureProvider.family<List<UserEntity>, String>((
  ref,
  sortBy,
) async {
  final repo = ref.read(valerionRepositoryProvider);
  return repo.getLeaderboard(sortBy: sortBy, limit: 50);
});

/// Provider pour obtenir le rang mondial personnel de l'utilisateur
final userRankProvider = FutureProvider.family<int, String>((ref, sortBy) async {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return 0;

  final repo = ref.read(valerionRepositoryProvider);
  num score = 0;
  
  if (sortBy == 'xp') score = user.xp;
  else if (sortBy == 'forceXp') score = user.forceXp;
  else if (sortBy == 'wisdomXp') score = user.wisdomXp;
  
  return repo.getUserRank(sortBy: sortBy, score: score);
});

// ==========================================
// --- CLANS DATA (Factions, Chat, Leaderboard) ---
// ==========================================

// 6. Provider statique pour l'accès aux méthodes du Clan Repository
final clanRepositoryProvider = Provider<IClanRepository>((ref) {
  return FirebaseClanRepository();
});

// 7. Provider pour récupérer les détails des clans actuels de l'utilisateur
final userClansProvider = StreamProvider<List<ClanEntity>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;

  if (user == null || user.clanIds.isEmpty) {
    return Stream.value([]);
  }

  final clanRepo = ref.read(clanRepositoryProvider);
  return clanRepo.listenUserClans(user.clanIds);
});

// 8. Provider pour obtenir le Leaderboard des Clans
final clansLeaderboardProvider = FutureProvider<List<ClanEntity>>((ref) async {
  final clanRepo = ref.read(clanRepositoryProvider);
  return clanRepo.getClansLeaderboard(limit: 20);
});

// 9. Provider pour écouter les invitations reçues par l'utilisateur
final userClanRequestsProvider = StreamProvider<List<ClanRequestEntity>>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final clanRepo = ref.read(clanRepositoryProvider);
  return clanRepo.listenUserClanRequests(user.id);
});

// 10. Provider pour écouter les demandes d'adhésion au clan (pour les leaders)
// Note : Actuellement simplifié pour écouter le premier clan de l'utilisateur.
// À terme, prévoir de filtrer uniquement les requêtes des clans dont le user est leader.
final clanJoinRequestsProvider = StreamProvider<List<ClanRequestEntity>>((ref) {
  final clans = ref.watch(userClansProvider).valueOrNull;
  if (clans == null || clans.isEmpty) return Stream.value([]);

  final clanRepo = ref.read(clanRepositoryProvider);
  // Retourne les requêtes pour son premier clan (TODO: Gérer le multi-lead)
  return clanRepo.listenClanRequestsForLeader(clans.first.id);
});

// 11. Provider pour écouter la messagerie du clan
final clanMessagesProvider =
    StreamProvider.family<List<ClanMessageEntity>, String>((ref, clanId) {
      final clanRepo = ref.read(clanRepositoryProvider);
      return clanRepo.listenClanMessages(clanId);
    });

// 12. Provider pour la recherche de clans
final clanSearchProvider =
    FutureProvider.family<List<ClanEntity>, String>((ref, query) async {
      if (query.isEmpty) return [];
      final clanRepo = ref.read(clanRepositoryProvider);
      return clanRepo.searchClans(query);
    });

// ==========================================
// --- FRIENDS & CONNECT DATA ---
// ==========================================

/// Provider pour récupérer les profils des amis de l'utilisateur
final userFriendsProvider = FutureProvider<List<UserEntity>>((ref) async {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null || user.friendIds.isEmpty) return [];

  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.getFriendsProfiles(user.friendIds);
});

/// Provider pour la recherche d'utilisateurs par pseudo
final userSearchProvider = FutureProvider.family<List<UserEntity>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.searchUsersByUsername(query);
});

/// Provider pour récupérer le profil de n'importe quel utilisateur (par son UID)
final otherUserProfileProvider = FutureProvider.family<UserEntity?, String>((ref, uid) async {
  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.getUserProfile(uid);
});

/// Provider pour récupérer les profils des personnes ayant envoyé une demande d'ami
final userFriendRequestsProvider = FutureProvider<List<UserEntity>>((
  ref,
) async {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null || user.incomingRequestIds.isEmpty) return [];

  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.getFriendsProfiles(user.incomingRequestIds);
});

/// Provider pour écouter les messages d'un chat privé (1-à-1)
final privateMessagesProvider =
    StreamProvider.family<List<ClanMessageEntity>, String>((ref, friendId) {
      final user = ref.watch(userProfileProvider).valueOrNull;
      if (user == null) return Stream.value([]);

      final valerionRepo = ref.read(valerionRepositoryProvider);
      return valerionRepo.listenPrivateMessages(user.id, friendId);
    });

/// Provider pour écouter les métadonnées (unreadCount, etc.) d'un chat privé
final privateChatMetadataProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, chatId) {
      final valerionRepo = ref.read(valerionRepositoryProvider);
      return valerionRepo.listenPrivateChatMetadata(chatId);
    });

/// Provider pour écouter les annonces système globales
final systemAnnouncementsProvider = StreamProvider<List<ClanMessageEntity>>((ref) {
  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.listenSystemAnnouncements();
});

// ==========================================
// --- AGGREGATED NOTIFICATIONS (BADGES) ---
// ==========================================

/// Provider pour le nombre total de messages PRIVÉS non lus
final totalPrivateUnreadProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  final repo = ref.read(valerionRepositoryProvider);
  return repo.listenTotalUnreadPrivateCount(user.id);
});

/// Provider pour le nombre total de messages de CLANS non lus
final totalClanUnreadProvider = StreamProvider<int>((ref) {
  final user = ref.watch(userProfileProvider).valueOrNull;
  if (user == null || user.clanIds.isEmpty) return Stream.value(0);
  final repo = ref.read(clanRepositoryProvider);
  return repo.listenTotalUnreadClansCount(user.id, user.clanIds);
});

/// Provider COMBINÉ pour le badge de l'onglet "Clans"
final totalUnreadCountProvider = Provider<int>((ref) {
  final privateCount = ref.watch(totalPrivateUnreadProvider).valueOrNull ?? 0;
  final clanCount = ref.watch(totalClanUnreadProvider).valueOrNull ?? 0;
  return privateCount + clanCount;
});

// ==========================================
// --- GLOBAL CONFIG (Vidéo du jour, etc.) ---
// ==========================================

/// Provider dynamique qui écoute les paramètres de l'application depuis Firestore.
final globalConfigProvider = StreamProvider<GlobalConfigEntity?>((ref) {
  final valerionRepo = ref.read(valerionRepositoryProvider);
  return valerionRepo.listenGlobalConfig();
});

