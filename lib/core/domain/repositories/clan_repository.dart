// lib/core/domain/repositories/clan_repository.dart
import '../entities/clan_entity.dart';
import '../entities/clan_request_entity.dart';
import '../entities/clan_message_entity.dart';

abstract class IClanRepository {
  /// Crée un nouveau clan
  Future<ClanEntity> createClan({
    required String name,
    required String description,
    required String leaderId,
    required int initialXp,
  });

  /// Met à jour le logo d'un clan
  Future<void> updateClanLogo(String clanId, String logoUrl);

  /// Récupère les détails d'un clan
  Future<ClanEntity?> getClanDetails(String clanId);

  /// Écoute les détails d'un clan en temps réel
  Stream<ClanEntity?> listenClanDetails(String clanId);

  /// Écoute la liste des clans dont l'utilisateur fait partie
  Stream<List<ClanEntity>> listenUserClans(List<String> clanIds);

  /// Récupère le classement des clans par XP
  Future<List<ClanEntity>> getClansLeaderboard({int limit = 20});

  /// Récupère la liste des utilisateurs membres d'un clan
  Future<List<dynamic>> getClanMembers(String clanId);

  /// Envoie une invitation (Leader -> Joueur)
  Future<void> sendClanInvitation({
    required ClanEntity clan,
    required String targetUserId,
    required String targetUsername,
  });

  /// Envoie une demande pour rejoindre (Joueur -> Clan)
  Future<void> requestToJoinClan({
    required ClanEntity clan,
    required String userId,
    required String username,
  });

  /// Accepte une requête ou une invitation
  Future<void> acceptClanRequest(ClanRequestEntity request);

  /// Rejette une requête ou une invitation
  Future<void> rejectClanRequest(String requestId);

  /// Le chef de clan bannit un membre
  Future<void> kickMember({required String clanId, required String userId});

  /// Un membre quitte le clan volontairement
  Future<void> leaveClan({required String clanId, required String userId});

  /// Dissoudre complètement un clan (réservé au créateur)
  Future<void> deleteClan(String clanId);

  /// Écoute les requêtes concernant un utilisateur (ses invitations)
  Stream<List<ClanRequestEntity>> listenUserClanRequests(String userId);

  /// Écoute les requêtes concernant un clan (demandes pour rejoindre le clan)
  Stream<List<ClanRequestEntity>> listenClanRequestsForLeader(String clanId);

  /// Envoie un message dans le chat du clan
  Future<void> sendClanMessage({
    required String clanId,
    required String senderId,
    required String senderName,
    String? text,
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
    String type = 'text',
    List<String>? members,
  });

  /// Écoute les messages du chat du clan
  Stream<List<ClanMessageEntity>> listenClanMessages(String clanId);

  /// Supprime un message spécifique du chat du clan
  Future<void> deleteClanMessage(String clanId, String messageId, {String? audioUrl});

  /// Recherche des clans par nom
  Future<List<ClanEntity>> searchClans(String query);

  /// Marque tout le contenu d'un clan comme lu pour un utilisateur donné
  Future<void> markClanAsRead(String clanId, String userId);

  /// Écoute le nombre TOTAL de messages de clans non lus pour l'utilisateur
  Stream<int> listenTotalUnreadClansCount(String userId, List<String> clanIds);
}
