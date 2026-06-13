// lib/core/data/repositories/firebase_clan_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/clan_repository.dart';
import '../../domain/entities/clan_entity.dart';
import '../../domain/entities/clan_request_entity.dart';
import '../../domain/entities/clan_message_entity.dart';
import '../services/storage_service.dart';

class FirebaseClanRepository implements IClanRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Collections references
  CollectionReference get _clansCol => _firestore.collection('clans');
  CollectionReference get _requestsCol =>
      _firestore.collection('clan_requests');
  CollectionReference get _usersCol => _firestore.collection('users');

  @override
  Future<ClanEntity> createClan({
    required String name,
    required String description,
    required String leaderId,
    required int initialXp,
  }) async {
    try {
      final docRef = _clansCol.doc();
      final now = DateTime.now();

      final clanData = {
        'name': name,
        'description': description,
        'leaderId': leaderId,
        'membersCount': 1,
        'totalXp': initialXp,
        'createdAt': FieldValue.serverTimestamp(),
        'logoUrl': null,
        'members': [leaderId],
      };

      // Création du clan en même temps que la mise à jour de l'utilisateur (transaction/batch)
      final batch = _firestore.batch();
      batch.set(docRef, clanData);

      final userRef = _usersCol.doc(leaderId);
      batch.update(userRef, {
        'clanIds': FieldValue.arrayUnion([docRef.id]),
      });

      await batch.commit();

      return ClanEntity(
        id: docRef.id,
        name: name,
        description: description,
        leaderId: leaderId,
        membersCount: 1,
        totalXp: initialXp,
        createdAt: now,
      );
    } catch (e) {
      throw Exception('Erreur création clan : $e');
    }
  }

  @override
  Future<void> updateClanLogo(String clanId, String logoUrl) async {
    try {
      await _clansCol.doc(clanId).update({'logoUrl': logoUrl});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du logo : $e');
    }
  }

  @override
  Future<ClanEntity?> getClanDetails(String clanId) async {
    try {
      final doc = await _clansCol.doc(clanId).get();
      if (!doc.exists) return null;
      return _mapToClanEntity(doc);
    } catch (e) {
      throw Exception('Erreur lecture clan : $e');
    }
  }

  @override
  Stream<ClanEntity?> listenClanDetails(String clanId) {
    return _clansCol.doc(clanId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _mapToClanEntity(doc);
    });
  }

  @override
  Stream<List<ClanEntity>> listenUserClans(List<String> clanIds) {
    if (clanIds.isEmpty) return Stream.value([]);

    // Firestore whereIn est limité à 10 éléments, mais on suppose ici
    // qu'un joueur ne fais pas partie de plus de 10 clans simultanément.
    return _clansCol
        .where(FieldPath.documentId, whereIn: clanIds)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _mapToClanEntity(doc)).toList());
  }

  @override
  Future<List<ClanEntity>> getClansLeaderboard({int limit = 20}) async {
    try {
      final querySnapshot =
          await _clansCol
              .orderBy('totalXp', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs.map((doc) => _mapToClanEntity(doc)).toList();
    } catch (e) {
      throw Exception('Erreur classement clans : $e');
    }
  }

  @override
  Future<List<dynamic>> getClanMembers(String clanId) async {
    try {
      final querySnapshot =
          await _usersCol.where('clanIds', arrayContains: clanId).get();

      // On retourne une liste de Maps (données brutes) ou la vraie entité
      // si l'import était possible. L'UI se débrouillera avec le Map.
      return querySnapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    } catch (e) {
      throw Exception('Erreur récupération membres : $e');
    }
  }

  // --- REQUÊTES / INVITATIONS ---

  @override
  Future<void> sendClanInvitation({
    required ClanEntity clan,
    required String targetUserId,
    required String targetUsername,
  }) async {
    final docRef = _requestsCol.doc();
    await docRef.set({
      'clanId': clan.id,
      'clanName': clan.name,
      'userId': targetUserId,
      'username': targetUsername,
      'type': 'invitation',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> requestToJoinClan({
    required ClanEntity clan,
    required String userId,
    required String username,
  }) async {
    final docRef = _requestsCol.doc();
    await docRef.set({
      'clanId': clan.id,
      'clanName': clan.name,
      'userId': userId,
      'username': username,
      'type': 'request',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> acceptClanRequest(ClanRequestEntity request) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('acceptClanRequest');
      await callable.call({
        'requestId': request.id,
        'clanId': request.clanId,
        'userId': request.userId,
      });
    } catch (e) {
      throw Exception('Erreur acceptation requête : $e');
    }
  }

  @override
  Future<void> rejectClanRequest(String requestId) async {
    await _requestsCol.doc(requestId).update({'status': 'rejected'});
  }

  @override
  Future<void> kickMember({
    required String clanId,
    required String userId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('kickMember');
      await callable.call({
        'clanId': clanId,
        'userId': userId,
      });
    } catch (e) {
      throw Exception('Erreur bannissement membre : $e');
    }
  }

  @override
  Future<void> leaveClan({
    required String clanId,
    required String userId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('leaveClan');
      await callable.call({
        'clanId': clanId,
        'userId': userId,
      });
    } catch (e) {
      throw Exception('Erreur départ du clan : $e');
    }
  }

  @override
  Future<void> deleteClan(String clanId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deleteClan');
      await callable.call({'clanId': clanId});
    } catch (e) {
      throw Exception('Erreur lors de la dissolution du clan : $e');
    }
  }

  @override
  Stream<List<ClanRequestEntity>> listenUserClanRequests(String userId) {
    return _requestsCol
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'invitation')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _mapToClanRequest(doc)).toList());
  }

  @override
  Stream<List<ClanRequestEntity>> listenClanRequestsForLeader(String clanId) {
    return _requestsCol
        .where('clanId', isEqualTo: clanId)
        .where('type', isEqualTo: 'request')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => _mapToClanRequest(doc)).toList());
  }

  // --- MESSAGERIE DE CLAN ---

  @override
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
  }) async {
    List<String> activeMembers = members ?? [];
    
    // Si on n'a pas passé les membres, on va les chercher (Fallback)
    if (activeMembers.isEmpty) {
      final clanDoc = await _clansCol.doc(clanId).get();
      final data = clanDoc.data() as Map<String, dynamic>?;
      activeMembers = List<String>.from(data?['members'] ?? []);

      // Auto-migration : si 'members' est absent (anciens clans), on l'initialise
      if (activeMembers.isEmpty && data != null) {
        final leaderId = data['leaderId'] as String?;
        if (leaderId != null) {
          activeMembers = [leaderId];
          // On persiste la mise à jour pour les prochains accès
          _clansCol.doc(clanId).update({'members': activeMembers}).catchError(
            (e) => debugPrint('⚠️ Auto-migration members: $e'),
          );
        }
      }
    }

    final batch = _firestore.batch();
    final msgRef = _clansCol.doc(clanId).collection('messages').doc();
    
    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Incrémenter le compteur pour tous les membres sauf l'expéditeur
    final Map<String, dynamic> unreadUpdates = {};
    for (var memberId in activeMembers) {
      if (memberId != senderId) {
        unreadUpdates['unreadCount.$memberId'] = FieldValue.increment(1);
      }
    }
    
    if (unreadUpdates.isNotEmpty) {
      batch.update(_clansCol.doc(clanId), unreadUpdates);
    }

    await batch.commit();
  }

  @override
  Stream<List<ClanMessageEntity>> listenClanMessages(String clanId) {
    return _clansCol
        .doc(clanId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            return ClanMessageEntity(
              id: doc.id,
              clanId: clanId,
              senderId: data['senderId'],
              senderName: data['senderName'],
              text: data['text'],
              audioUrl: data['audioUrl'],
              imageUrl: data['imageUrl'],
              videoUrl: data['videoUrl'],
              type: data['type'] ?? 'text',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();
        });
  }

  // --- HELPERS (MAPPERS) ---

  ClanEntity _mapToClanEntity(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClanEntity(
      id: doc.id,
      name: data['name'],
      description: data['description'] ?? '',
      leaderId: data['leaderId'],
      membersCount: data['membersCount'] ?? 1,
      totalXp: data['totalXp'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      logoUrl: data['logoUrl'] as String?,
      unreadCounts: (data['unreadCount'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
    );
  }

  ClanRequestEntity _mapToClanRequest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClanRequestEntity(
      id: doc.id,
      clanId: data['clanId'],
      clanName: data['clanName'],
      userId: data['userId'],
      username: data['username'],
      type:
          data['type'] == 'invitation'
              ? ClanRequestType.invitation
              : ClanRequestType.request,
      status: _stringToStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<void> deleteClanMessage(String clanId, String messageId, {String? audioUrl}) async {
    try {
      if (audioUrl != null) {
        await _storageService.deleteFile(audioUrl);
      }
      await _clansCol.doc(clanId).collection('messages').doc(messageId).delete();
    } catch (e) {
      debugPrint("❌ Erreur deleteClanMessage: $e");
    }
  }

  @override
  Future<List<ClanEntity>> searchClans(String query) async {
    try {
      final snap = await _clansCol
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      return snap.docs.map((doc) => _mapToClanEntity(doc)).toList();
    } catch (e) {
      throw Exception('Erreur recherche clans : $e');
    }
  }

  @override
  Future<void> markClanAsRead(String clanId, String userId) async {
    try {
      await _clansCol.doc(clanId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint("❌ Erreur markClanAsRead: $e");
    }
  }

  @override
  Stream<int> listenTotalUnreadClansCount(String userId, List<String> clanIds) {
    if (clanIds.isEmpty) return Stream.value(0);
    
    return _clansCol
        .where(FieldPath.documentId, whereIn: clanIds)
        .snapshots()
        .map((snap) {
          int total = 0;
          for (var doc in snap.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadMap != null) {
              total += (unreadMap[userId] ?? 0) as int;
            }
          }
          return total;
        });
  }

  ClanRequestStatus _stringToStatus(String? status) {
    switch (status) {
      case 'accepted':
        return ClanRequestStatus.accepted;
      case 'rejected':
        return ClanRequestStatus.rejected;
      default:
        return ClanRequestStatus.pending;
    }
  }
}
