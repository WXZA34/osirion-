import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/clan_message_entity.dart';
import '../../domain/repositories/valerion_repository.dart';
import '../../domain/entities/global_config_entity.dart';
import '../../domain/entities/library_audio_entity.dart';
import '../../../features/library/models/journal_entry.dart';
import '../../../features/home/models/arc_data.dart';
import '../../../features/arsenal/models/relic.dart';
import '../../../features/dojo/models/exercise_config.dart';
import '../../../features/library/models/book_entity.dart';
import '../../../features/arena/models/arena_models.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../services/storage_service.dart';

class FirebaseValerionRepository implements IValerionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Référence typée vers la collection 'users'
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _supportCol =>
      _firestore.collection('support_tickets');

  @override
  Future<UserEntity?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get().timeout(const Duration(seconds: 10));
      if (!doc.exists) return null;
      return UserEntity.fromMap(uid, doc.data()!);
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint(
          "⚠️ [Kill Switch-LITE] Accès refusé détecté en lecture. Vérifier firestore.rules.",
        );
        // await FirebaseAuth.instance.signOut(); // DÉSACTIVÉ POUR DÉPANNAGE
      }
      throw Exception('Erreur lors de la récupération du profil : $e');
    }
  }

  @override
  Stream<UserEntity?> listenUserProfile(String uid) {
    if (kDebugMode) {
      debugPrint("📡 [Firestore] Écoute du profil UID: $uid...");
    }
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint("⚠️ [Firestore] Le document /users/$uid n'existe pas !");
        }
        return null;
      }
      if (doc.data() == null) {
        if (kDebugMode) {
          debugPrint(
            "⚠️ [Firestore] Le document /users/$uid est vide (null) !",
          );
        }
        return null;
      }
      try {
        return UserEntity.fromMap(uid, doc.data()!);
      } catch (e) {
        debugPrint("❌ [Firestore] Erreur fatale de mapping pour $uid : $e");
        // On renvoie null pour ne pas faire crash l'app, mais on log l'erreur
        return null;
      }
    });
  }

  @override
  Future<void> saveUserProfile(UserEntity user) async {
    if (kDebugMode) {
      debugPrint(
        "🔥 [Firestore] Tentative de sauvegarde du profil : ${user.id}...",
      );
    }
    try {
      final Map<String, dynamic> dataToSave = user.toMap();

      // SÉCURITÉ : On retire systématiquement les champs gérés exclusivement par le serveur
      // pour éviter que Firestore ne rejette la requête (Missing Permissions).
      dataToSave.remove('xp');
      dataToSave.remove('level');
      dataToSave.remove('forceXp');
      dataToSave.remove('wisdomXp');
      dataToSave.remove('aetherBalance');
      dataToSave.remove('totalDistance');
      dataToSave.remove('gold');
      dataToSave.remove('inventory');
      dataToSave.remove('clanIds');
      dataToSave.remove('unlockedTitles');
      dataToSave.remove('createdAt');
      dataToSave.remove('email');
      dataToSave.remove('incomingRequestIds');
      dataToSave.remove('outgoingRequestIds');
      dataToSave.remove('friendIds');

      // Set avec merge pour ne pas écraser d'autres champs potentiels
      await _usersCol.doc(user.id).set(dataToSave, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint(
          "✅ [Firestore] Profil sauvegardé (champs non-critiques) pour ${user.username} !",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ [Firestore] ERREUR FATALE LORS DE LA SAUVEGARDE : $e");
      }
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint(
          "⚠️ [Kill Switch-LITE] Accès refusé détecté en écriture. Vérifier firestore.rules (le déni concerne peut-être un champ protégé).",
        );
        // await FirebaseAuth.instance.signOut(); // DÉSACTIVÉ POUR FACILITER LE DEBUG DES RÈGLES
      }
      throw Exception('Erreur lors de la sauvegarde du profil : $e');
    }
  }

  @override
  Future<void> ensureProfileExists(UserEntity user) async {
    try {
      final doc = await _usersCol.doc(user.id).get();
      if (!doc.exists) {
        if (kDebugMode) {
          debugPrint(
            "🛠️ [Firestore] Profil manquant pour ${user.id}. Création auto-healing...",
          );
        }
        final Map<String, dynamic> dataToCreate = user.toMap();
        // SÉCURITÉ : Forcer les valeurs de base pour la création via le client
        dataToCreate['xp'] = 0;
        dataToCreate['level'] = 1;
        dataToCreate['forceXp'] = 0;
        dataToCreate['wisdomXp'] = 0;
        dataToCreate['aetherBalance'] = 0;
        dataToCreate['gold'] = 0;
        dataToCreate['clanIds'] = []; 

        await _usersCol.doc(user.id).set(dataToCreate).timeout(const Duration(seconds: 10));
      }
      // Automatisme : Mettre à jour la série et la date d'activité à chaque vérification
      await updateStreak(user.id);
    } catch (e) {
      debugPrint("❌ [Firestore] Erreur ensureProfileExists : $e");
    }
  }

  @override
  @override
  Future<UserEntity> addXP(String uid, int xpToAdd) async {
    // SÉCURITÉ : La modification directe de l'XP est interdite par les règles Firestore.
    // Les gains doivent passer par les actions validées par le serveur (Dojo, Arène, Quêtes).
    throw UnsupportedError(
      "Sécurité : L'ajout d'XP manuel n'est plus autorisé. Le serveur gère les récompenses.",
    );
  }

  @override
  Future<UserEntity> completeQuest(String uid, String questId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'completeQuest',
      );
      // Envoi des données vitales au serveur
      await callable.call({
        'questId': questId,
      });
      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      throw Exception('Échec de la validation de la quête : $e');
    }
  }

  @override
  Future<UserEntity> addWorkoutResults(
    String uid,
    int pushups,
    int gainedXp,
    int earnedAether, {
    String? localDateStr,
    String? arcId,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'addWorkoutResults',
      );
      // Envoi des données vitales au serveur (dont l'Arc actuel)
      await callable.call({
        'reps': pushups,
        'localDateStr': localDateStr,
        'arcId': arcId,
      });
      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      throw Exception('Échec de la validation de l\'entraînement : $e');
    }
  }

  @override
  @override
  Future<UserEntity> addArenaResults(
    String uid,
    double distanceKm,
    int durationSeconds,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'addArenaResults',
      );
      await callable.call({
        'duelType': 'arena',
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
      });

      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      debugPrint("❌ Erreur addArenaResults: $e");
      throw Exception(
        'Lancer de duel impossible : Cooldown ou erreur serveur.',
      );
    }
  }


  @override
  Future<List<UserEntity>> getLeaderboard({
    required String sortBy,
    int limit = 50,
  }) async {
    try {
      final querySnapshot =
          await _usersCol.orderBy(sortBy, descending: true).limit(limit).get();

      return querySnapshot.docs.map((doc) {
        return UserEntity.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération du classement : $e');
    }
  }

  @override
  Future<void> updateUserStatus(String uid, String status) async {
    try {
      await _usersCol.doc(uid).update({'status': status});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut : $e');
    }
  }

  @override
  Future<List<UserEntity>> searchUsersByUsername(String query) async {
    try {
      // Recherche simple par préfixe (insensible à la casse si normalisé, ici simple startAt/endAt)
      final searchQuery = query.toLowerCase().trim();
      final querySnapshot =
          await _usersCol
              .where('usernameLower', isGreaterThanOrEqualTo: searchQuery)
              .where('usernameLower', isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .limit(10)
              .get();

      return querySnapshot.docs.map((doc) {
        return UserEntity.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs : $e');
    }
  }

  @override
  Future<List<UserEntity>> getFriendsProfiles(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    try {
      // Firestore 'whereIn' est limité à 10 ou 30 IDs selon la version,
      // ici on va faire simple pour le MVP.
      final querySnapshot =
          await _usersCol
              .where(FieldPath.documentId, whereIn: friendIds.take(10).toList())
              .limit(10)
              .get();

      return querySnapshot.docs.map((doc) {
        return UserEntity.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des amis : $e');
    }
  }

  @override
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendFriendRequest');
      await callable.call({'targetUid': toUid});
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de la demande d\'ami : $e');
    }
  }

  @override
  Future<void> acceptFriendRequest(String uid, String friendId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'acceptFriendRequest',
      );
      await callable.call({'targetUid': friendId});
    } catch (e) {
      debugPrint("❌ Erreur acceptFriendRequest: $e");
      throw Exception('Erreur lors de l\'acceptation de l\'ami : $e');
    }
  }

  @override
  Future<void> declineFriendRequest(String uid, String friendId) async {
    try {
      final batch = _firestore.batch();
      batch.update(_usersCol.doc(uid), {
        'incomingRequestIds': FieldValue.arrayRemove([friendId]),
      });
      batch.update(_usersCol.doc(friendId), {
        'outgoingRequestIds': FieldValue.arrayRemove([uid]),
      });
      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors du refus de l\'ami : $e');
    }
  }

  @override
  Future<void> removeFriend(String uid, String friendId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('removeFriend');
      await callable.call({'targetUid': friendId});
      if (kDebugMode) {
        debugPrint("✅ [Social] Ami $friendId supprimé via Cloud Function.");
      }
    } catch (e) {
      debugPrint("❌ Erreur removeFriend: $e");
      throw Exception('Erreur lors de la suppression de l\'ami : $e');
    }
  }

  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  @override
  Future<void> sendPrivateMessage({
    required String fromId,
    required String toId,
    required String senderName,
    String? text,
    String? audioUrl,
    String? imageUrl,
    String? videoUrl,
    String type = 'text',
  }) async {
    try {
      // 1. Vérifier si ils sont toujours amis (FORCE SERVER pour éviter le cache)
      final senderDoc = await _usersCol.doc(fromId).get(const GetOptions(source: Source.server));
      if (!senderDoc.exists)
        throw Exception("Utilisateur expéditeur introuvable.");

      final senderData = senderDoc.data()!;
      final friendIds = List<String>.from(senderData['friendIds'] ?? []);

      if (!friendIds.contains(toId)) {
        throw Exception(
          "BLOCK_DELETED:cet utlisateur vous as supprimer mais al seul manière de vous parler a nouveu serait de lui envoiyer une nouvelle invitation a discutée",
        );
      }

      final chatId = _getChatId(fromId, toId);

      // Note: initializePrivateChat est appelé UNE SEULE FOIS à l'ouverture du chat (côté UI)
      // Ici on écrit directement pour un envoi instantané.

      final batch = _firestore.batch();
      final chatRef = _firestore.collection('private_chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc();

      // Mise à jour sécurisée des métadonnées (L'update est autorisé si on est membre)
      batch.set(chatRef, {
        'lastMessage':
            type == 'audio'
                ? '🎤 Message vocal'
                : (type == 'image' ? '📸 Photo envoyée' : (type == 'video' ? '🎥 Vidéo envoyée' : text)),
        'lastUpdate': FieldValue.serverTimestamp(),
        'unreadCount': {toId: FieldValue.increment(1)},
        'participants': FieldValue.arrayUnion([fromId, toId]),
      }, SetOptions(merge: true));

      // Ajout du message
      batch.set(messageRef, {
        'senderId': fromId,
        'senderName': senderName,
        'text': text,
        'audioUrl': audioUrl,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      if (e.toString().contains("BLOCK_DELETED")) rethrow;
      throw Exception('Erreur lors de l\'envoi du message : $e');
    }
  }

  @override
  Stream<List<ClanMessageEntity>> listenPrivateMessages(
    String uid1,
    String uid2,
  ) {
    final chatId = _getChatId(uid1, uid2);
    return _firestore
        .collection('private_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            return ClanMessageEntity(
              id: doc.id,
              clanId:
                  chatId, // On réutilise le chatId comme Identifiant de contexte
              senderId: data['senderId'] as String,
              senderName: data['senderName'] as String,
              text: data['text'] as String?,
              audioUrl: data['audioUrl'] as String?,
              imageUrl: data['imageUrl'] as String?,
              videoUrl: data['videoUrl'] as String?,
              type: data['type'] as String? ?? 'text',
              timestamp:
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate()
                      : DateTime.now(),
            );
          }).toList();
        });
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot =
          await _usersCol
              .where('usernameLower', isEqualTo: username.toLowerCase().trim())
              .limit(1)
              .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du pseudonyme : $e');
    }
  }

  @override
  Future<UserEntity> purchaseItem({
    required String uid,
    required String itemId,
    required int priceXp,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('purchaseItem');
      // On ne passe plus priceXp, le serveur utilise son barème
      await callable.call({'itemId': itemId});
      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      throw Exception("Échec de l'achat : $e");
    }
  }

  @override
  Future<UserEntity> addManualReward(String uid, String rewardType) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'addManualReward',
      );
      await callable.call({'rewardType': rewardType});
      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      debugPrint("❌ Erreur addManualReward: $e");
      throw Exception('Échec de la récupération de la récompense : $e');
    }
  }

  @override
  Future<UserEntity> updateAetherBalance(String uid, int amount) async {
    // SÉCURITÉ : La modification libre d'Aether est dépréciée.
    // L'Aether est géré par les fonctions métiers du backend.
    throw UnsupportedError(
      "Sécurité : La manipulation de la balance d'Aether est verrouillée côté serveur.",
    );
  }

  @override
  Future<UserEntity> buyRelic(
    String uid,
    String relicId,
    int cost,
    String relicType,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('buyRelic');
      // On ne passe plus cost
      await callable.call({'relicId': relicId, 'relicType': relicType});
      final user = await getUserProfile(uid);
      if (user == null) throw Exception("Utilisateur introuvable.");
      return user;
    } catch (e) {
      throw Exception('Échec de l\'achat de la relique : $e');
    }
  }

  // --- MODULE ESPRIT (JOURNAL) ---

  @override
  Future<void> addJournalEntry(JournalEntry entry, {String? arcId}) async {
    try {
      if (kDebugMode) {
        debugPrint(
          "🔥 [Firestore] Ajout (immuable) d'une pensée dans le Journal (Arc: $arcId)...",
        );
      }
      // On sauvegarde dans une sous-collection "journal" de l'utilisateur
      await _usersCol
          .doc(entry.userId)
          .collection('journal')
          .doc(entry.id)
          .set(entry.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ [Firestore] ERREUR ajout journal : $e");
      }
      throw Exception('Erreur lors de la sauvegarde du contrat : $e');
    }
  }

  @override
  Stream<List<JournalEntry>> listenUserJournal(String uid) {
    return _usersCol
        .doc(uid)
        .collection('journal')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JournalEntry.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // --- CONFIGURATION GLOBALE ---
  @override
  Stream<GlobalConfigEntity?> listenGlobalConfig() {
    // On écoute la collection entière pour être robuste aux IDs mal formés (ex: avec espaces)
    return _firestore.collection('global_config').snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;

      // On cherche 'daily_content' (en ignorant les espaces éventuels) de manière sécurisée
      QueryDocumentSnapshot<Map<String, dynamic>>? targetDoc;
      for (var doc in snap.docs) {
        if (doc.id.trim() == 'daily_content') {
          targetDoc = doc;
          break;
        }
      }

      // Si non trouvé, on prend le premier par défaut
      final doc = targetDoc ?? snap.docs.first;
      return GlobalConfigEntity.fromMap(doc.data());
    });
  }

  @override
  Future<void> updateGlobalConfig(GlobalConfigEntity config) async {
    try {
      await _firestore
          .collection('global_config')
          .doc('daily_content')
          .set(config.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Erreur updateGlobalConfig: $e");
      throw Exception("Échec de la mise à jour de la configuration globale.");
    }
  }

  // --- MODULE SÉRIES & ACTIVITÉ (ARCS) ---

  @override
  Future<void> updateStreak(String uid) async {
    try {
      final userDoc = await _usersCol.doc(uid).get();
      if (!userDoc.exists) return;

      final user = UserEntity.fromMap(uid, userDoc.data()!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (user.lastActiveDate != null) {
        final lastActive = DateTime(
          user.lastActiveDate!.year,
          user.lastActiveDate!.month,
          user.lastActiveDate!.day,
        );

        final difference = today.difference(lastActive).inDays;

        if (difference == 1) {
          // Consécutif : Incrémenter
          await _usersCol.doc(uid).update({
            'streak': FieldValue.increment(1),
            'lastActiveDate': Timestamp.fromDate(now),
          });
        } else if (difference > 1) {
          // Rupture : Reset à 1
          await _usersCol.doc(uid).update({
            'streak': 1,
            'lastActiveDate': Timestamp.fromDate(now),
          });
        } else if (difference == 0) {
          // Déjà actif aujourd'hui : Ne rien faire sur le streak, juste update le timestamp précis
          await _usersCol.doc(uid).update({
            'lastActiveDate': Timestamp.fromDate(now),
          });
        }
      } else {
        // Premier jour : Initialiser à 1
        await _usersCol.doc(uid).update({
          'streak': 1,
          'lastActiveDate': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      debugPrint("❌ Erreur updateStreak: $e");
    }
  }

  @override
  Future<void> recordDailyActivity({
    required String uid,
    required String arcId,
    required int questsDone,
    required int totalQuests,
  }) async {
    // SÉCURITÉ : La mise à jour directe est désormais INTERDITE par les règles Firestore.
    // L'autorité est passée au serveur via la Cloud Function addWorkoutResults.
    debugPrint(
      "ℹ️ recordDailyActivity: Delegated to server-side workout registration.",
    );
  }

  @override
  Stream<Map<String, dynamic>> listenArcActivity(String uid, String arcId) {
    return _usersCol
        .doc(uid)
        .collection('arcs')
        .doc(arcId)
        .collection('daily_stats')
        .snapshots()
        .map((snapshot) {
          final Map<String, dynamic> history = {};
          for (var doc in snapshot.docs) {
            history[doc.id] = doc.data();
          }
          return history;
        });
  }

  @override
  Future<String> exportUserData(String uid) async {
    try {
      final exportData = <String, dynamic>{};

      // 1. Profil de base
      final userDoc = await _usersCol.doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          exportData['profile'] = userData;
        }
      }

      // 2. Journal Stoïcien
      final journalSnap = await _usersCol.doc(uid).collection('journal').get();
      exportData['journal'] = journalSnap.docs.map((d) => d.data()).toList();

      // 3. Arcs et Statistiques de Corrélation
      final arcsSnap = await _usersCol.doc(uid).collection('arcs').get();
      final arcsData = <String, dynamic>{};
      for (var arcDoc in arcsSnap.docs) {
        final statsSnap =
            await arcDoc.reference.collection('daily_stats').get();
        arcsData[arcDoc.id] = {
          'info': arcDoc.data(),
          'stats': statsSnap.docs.map((d) => d.data()).toList(),
        };
      }
      exportData['arcs'] = arcsData;

      // 4. Métadonnées d'exportation
      exportData['export_metadata'] = {
        'app_name': 'OSIRION',
        'export_version': '1.1.1',
        'generated_at': DateTime.now().toIso8601String(),
        'uid': uid,
        'description': 'Archive complète des données utilisateur (RGPD)',
      };

      // 5. Conversion récursive des Timestamps pour JSON
      final cleanData = _recursiveJsonCleanup(exportData);

      final encoder = const JsonEncoder.withIndent('  ');
      return encoder.convert(cleanData);
    } catch (e) {
      debugPrint("❌ Erreur exportUserData: $e");
      throw Exception("Échec de la génération de l'archive : $e");
    }
  }

  @override
  Future<void> sendSupportTicket(
    String uid,
    Map<String, dynamic> ticket,
  ) async {
    try {
      await _supportCol.add({
        ...ticket,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'OPEN',
      });
    } catch (e) {
      debugPrint("❌ Erreur sendSupportTicket: $e");
      throw Exception("Échec de l'envoi du ticket : $e");
    }
  }

  @override
  Future<Map<String, dynamic>> calculateArcRewards(
    String uid,
    ArcData arc,
  ) async {
    try {
      final String arcId = arc.arcType.name;
      final statsSnap =
          await _usersCol
              .doc(uid)
              .collection('arcs')
              .doc(arcId)
              .collection('daily_stats')
              .get();

      // 1. Compter les jours actifs (au moins une quête faite)
      int activeDays = 0;
      for (var doc in statsSnap.docs) {
        final questsDone = doc.data()['questsDone'] ?? 0;
        if (questsDone > 0) activeDays++;
      }

      // 2. Calculer la durée de l'Arc
      // En mode normal: mois/jours. En mode simulation: minutes.
      // On va utiliser le nombre de jours entre les deux dates
      int totalPeriodDays = arc.endDate.difference(arc.startDate).inDays;

      // Sécurité pour la simulation: si la durée est < 1 jour, on considère 1 jour comme unité de cohérence
      if (totalPeriodDays < 1) totalPeriodDays = 1;

      final double ratio = (activeDays / totalPeriodDays).clamp(0.0, 1.0);
      final int percentage = (ratio * 100).round();

      // 3. Déterminer les récompenses selon les paliers (Tiers)
      int aether;
      int xp;
      String tierTitle;
      String tierLetter;

      if (percentage >= 80) {
        tierLetter = "A";
        tierTitle = "LÉGENDE";
        aether = 1000;
        xp = 200;
      } else if (percentage >= 60) {
        tierLetter = "B";
        tierTitle = "MAÎTRE";
        aether = 750;
        xp = 150;
      } else if (percentage >= 40) {
        tierLetter = "C";
        tierTitle = "GUERRIER";
        aether = 500;
        xp = 100;
      } else if (percentage >= 20) {
        tierLetter = "D";
        tierTitle = "SURVIVANT";
        aether = 250;
        xp = 50;
      } else {
        tierLetter = "E";
        tierTitle = "INITIÉ";
        aether = 100;
        xp = 20;
      }

      // Construire le nom complet du titre (ex: LÉGENDE DE L'HIVER)
      String arcSuffix = "DE L'HIVER";
      if (arc.arcType == AlphaArc.summer) arcSuffix = "DE L'ÉTÉ";
      if (arc.arcType == AlphaArc.royal) arcSuffix = "ROYAL";

      final String fullTitle = "$tierTitle $arcSuffix";

      return {
        'ratio': ratio,
        'activeDays': activeDays,
        'aether': aether,
        'xp': xp,
        'title': fullTitle,
        'tier': tierLetter,
      };
    } catch (e) {
      debugPrint("❌ Erreur calculateArcRewards: $e");
      return {
        'ratio': 0.0,
        'activeDays': 0,
        'aether': 0,
        'xp': 0,
        'title': "Néant",
        'tier': 'E',
      };
    }
  }

  @override
  Future<void> claimArcRewards(
    String uid,
    String arcId,
    Map<String, dynamic> rewards,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'claimArcRewards',
      );
      await callable.call({'arcId': arcId});
    } catch (e) {
      debugPrint("❌ Erreur claimArcRewards: $e");
      throw Exception("Échec de la récupération des récompenses.");
    }
  }

  // --- MODULE BIBLIOTHÈQUE (AUDIOS) ---

  @override
  Stream<List<LibraryAudioEntity>> listenLibraryAudios() {
    return _firestore
        .collection('library_audios')
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LibraryAudioEntity.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Future<void> addLibraryAudio(LibraryAudioEntity audio) async {
    try {
      await _firestore
          .collection('library_audios')
          .doc(audio.id.isEmpty ? null : audio.id)
          .set(audio.toMap());
    } catch (e) {
      debugPrint("❌ Erreur addLibraryAudio: $e");
      throw Exception("Échec de l'ajout de l'audio : $e");
    }
  }

  @override
  Future<void> deleteLibraryAudio(String audioId) async {
    try {
      await _firestore.collection('library_audios').doc(audioId).delete();
    } catch (e) {
      debugPrint("❌ Erreur deleteLibraryAudio: $e");
      throw Exception("Échec de la suppression de l'audio : $e");
    }
  }

  @override
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      // SÉCURITÉ RGPD : On sauvegarde le token dans une sous-collection PRIVÉE
      // inaccessible aux autres utilisateurs via les règles Firestore.
      await _usersCol.doc(uid).collection('private').doc('data').set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint("✅ [FCM] Token sauvegardé dans la zone privée pour $uid");
      }
    } catch (e) {
      debugPrint("❌ [FCM] Erreur sauvegarde token privé : $e");
    }
  }

  @override
  Future<void> markPrivateChatAsRead(String chatId, String userId) async {
    try {
      if (kDebugMode) {
        debugPrint("💬 [Chat] Marquage comme lu pour $userId sur $chatId");
      }
      await _firestore.collection('private_chats').doc(chatId).set({
        'unreadCount': {userId: 0},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ [Chat] Erreur markPrivateChatAsRead : $e");
    }
  }

  @override
  Stream<Map<String, dynamic>> listenPrivateChatMetadata(String chatId) {
    return _firestore
        .collection('private_chats')
        .doc(chatId)
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }

  @override
  Stream<int> listenTotalUnreadPrivateCount(String userId) {
    return _firestore
        .collection('private_chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          int total = 0;
          for (var doc in snap.docs) {
            final data = doc.data();
            final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadMap != null) {
              total += (unreadMap[userId] ?? 0) as int;
            }
          }
          return total;
        });
  }

  @override
  Stream<List<ClanMessageEntity>> listenSystemAnnouncements() {
    return _firestore
        .collection('system_announcements')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            // Support du champ 'text' standard ou 'mise a jour' utilisé manuellement
            final messageText = data['text'] ?? data['mise a jour'] ?? "";

            return ClanMessageEntity(
              id: doc.id,
              clanId: 'system',
              senderId: 'system',
              senderName: 'SYSTÈME OSIRION',
              text: messageText.toString(),
              timestamp:
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate()
                      : DateTime.now(),
            );
          }).toList();
        });
  }

  @override
  Future<void> markSystemAnnouncementsAsRead(String userId) async {
    try {
      await _usersCol.doc(userId).update({
        'lastReadSystemTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Erreur markSystemAnnouncementsAsRead: $e");
    }
  }

  /// Convertit récursivement les objets non-JSON (comme Timestamp) en types primitifs
  dynamic _recursiveJsonCleanup(dynamic item) {
    if (item is Timestamp) {
      return item.toDate().toIso8601String();
    } else if (item is Map) {
      return item.map(
        (key, value) => MapEntry(key.toString(), _recursiveJsonCleanup(value)),
      );
    } else if (item is List) {
      return item.map((e) => _recursiveJsonCleanup(e)).toList();
    } else if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  // ----------------------------------------------------------------------
  // LE DOJO : EXERCICES DYNAMIQUES
  // ----------------------------------------------------------------------

  /// Récupère la liste des exercices depuis Firestore
  Stream<List<ExerciseConfig>> getDojoExercises() {
    return _firestore.collection('exercises').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExerciseConfig.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Fonction de migration initiale : Envoie le catalogue statique vers Firestore
  Future<void> uploadDefaultExercises(List<ExerciseConfig> defaultList) async {
    final batch = _firestore.batch();
    for (var exercise in defaultList) {
      final docRef = _firestore.collection('exercises').doc(exercise.id);
      batch.set(docRef, exercise.toMap());
    }

    // Ajouter un document "sentinelle" pour marquer la fin de la migration
    final sentinelRef = _firestore
        .collection('exercises')
        .doc('_migration_done');
    batch.set(sentinelRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'version': 1,
      'is_sentinel': true,
    });

    await batch.commit();
    debugPrint("✅ [Dojo] Migration des exercices statiques terminée !");
  }

  @override
  Future<void> addExercise(ExerciseConfig exercise) async {
    await _firestore
        .collection('exercises')
        .doc(exercise.id)
        .set(exercise.toMap());
  }

  // ----------------------------------------------------------------------
  // BIBLIOTHÈQUE : LIVRES ET AUDIOS DYNAMIQUES
  // ----------------------------------------------------------------------

  @override
  Stream<List<BookEntity>> listenLibraryBooks() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs
          .where(
            (doc) => !doc.id.startsWith('_'),
          ) // Ignorer les documents techniques
          .map((doc) => BookEntity.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<void> addBook(BookEntity book) async {
    await _firestore.collection('books').doc(book.id).set(book.toMap());
  }

  @override
  Future<void> uploadDefaultBooks(List<BookEntity> books) async {
    final batch = _firestore.batch();
    for (var book in books) {
      final docRef = _firestore.collection('books').doc(book.id);
      batch.set(docRef, book.toMap());
    }

    // Sentinelle pour les livres
    final sentinelRef = _firestore.collection('books').doc('_migration_done');
    batch.set(sentinelRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'version': 1,
    });

    await batch.commit();
    debugPrint("✅ [Library] Migration des livres terminée !");
  }

  @override
  Future<void> uploadDefaultLibraryAudios(
    List<LibraryAudioEntity> audios,
  ) async {
    final batch = _firestore.batch();
    for (var audio in audios) {
      final docRef = _firestore.collection('library_audios').doc(audio.id);
      batch.set(docRef, audio.toMap());
    }

    // Sentinelle pour les audios
    final sentinelRef = _firestore
        .collection('library_audios')
        .doc('_migration_done');
    batch.set(sentinelRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'version': 1,
    });

    await batch.commit();
    debugPrint("✅ [Library] Migration des audios terminée !");
  }

  @override
  Future<void> purgeLibraryBooks() async {
    final snapshot = await _firestore.collection('books').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint("🧹 [Library] Collection 'books' purgée.");
  }

  @override
  Future<void> purgeLibraryAudios() async {
    final snapshot = await _firestore.collection('library_audios').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint("🧹 [Library] Collection 'library_audios' purgée.");
  }

  // ----------------------------------------------------------------------
  // ARSENAL : RELIQUES DYNAMIQUES
  // ----------------------------------------------------------------------

  @override
  Stream<List<Relic>> listenArsenalRelics() {
    return _firestore.collection('relics').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => !doc.id.startsWith('_'))
          .map((doc) => Relic.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  @override
  Future<void> addRelic(Relic relic) async {
    await _firestore.collection('relics').doc(relic.id).set(relic.toMap());
  }

  @override
  Future<void> uploadDefaultRelics(List<Relic> relics) async {
    final batch = _firestore.batch();
    for (var relic in relics) {
      final docRef = _firestore.collection('relics').doc(relic.id);
      batch.set(docRef, relic.toMap());
    }

    // Sentinelle
    final sentinelRef = _firestore.collection('relics').doc('_migration_done');
    batch.set(sentinelRef, {
      'timestamp': FieldValue.serverTimestamp(),
      'version': 1,
    });

    await batch.commit();
    debugPrint("✅ [Arsenal] Migration des reliques terminée !");
  }

  @override
  Future<void> purgeRelics() async {
    final snapshot = await _firestore.collection('relics').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint("🧹 [Arsenal] Collection 'relics' purgée.");
  }

  @override
  Future<void> purgeExercises() async {
    final snapshot = await _firestore.collection('exercises').get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    debugPrint("🧹 [Dojo] Collection 'exercises' purgée.");
  }

  @override
  Future<void> deletePrivateMessage(
    String chatId,
    String messageId, {
    String? audioUrl,
  }) async {
    try {
      if (audioUrl != null) {
        await _storageService.deleteFile(audioUrl);
      }
      await _firestore
          .collection('private_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      debugPrint("❌ Erreur deletePrivateMessage: $e");
    }
  }

  @override
  Future<void> deletePrivateChatHistory(String chatId) async {
    try {
      final messages =
          await _firestore
              .collection('private_chats')
              .doc(chatId)
              .collection('messages')
              .get();
      final batch = _firestore.batch();

      for (var doc in messages.docs) {
        final data = doc.data();
        if (data['audioUrl'] != null) {
          await _storageService.deleteFile(data['audioUrl']);
        }
        batch.delete(doc.reference);
      }

      // On peut aussi supprimer le document parent du chat si nécessaire
      batch.delete(_firestore.collection('private_chats').doc(chatId));

      await batch.commit();
    } catch (e) {
      debugPrint("❌ Erreur deletePrivateChatHistory: $e");
    }
  }

  @override
  Future<void> addColosseumRun(ColosseumRunModel run) async {
    try {
      await _firestore
          .collection('colosseum_runs')
          .doc(run.id.isEmpty ? null : run.id)
          .set(run.toMap());
    } catch (e) {
      debugPrint("❌ Erreur addColosseumRun: $e");
      throw Exception("Échec de la gravure du défi : $e");
    }
  }

  @override
  Future<void> joinColosseumRun({required String runId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final callable = FirebaseFunctions.instance.httpsCallable('joinColosseumRun');
      await callable.call({'runId': runId});
    } catch (e) {
      debugPrint("❌ Erreur joinColosseumRun: $e");
      throw Exception('Échec de l\'inscription au défi : $e');
    }
  }

  @override
  Future<int> getUserRank({required String sortBy, required num score}) async {
    try {
      // Pour calculer le rang mondial :
      // On compte le nombre d'utilisateurs ayant un score STRICTEMENT supérieur
      // Le rang est count + 1.
      final query = _firestore
          .collection('users')
          .where(sortBy, isGreaterThan: score);
      
      final snapshot = await query.count().get();
      return snapshot.count! + 1;
    } catch (e) {
      debugPrint('❌ Erreur getUserRank: $e');
      return 0; // Retourne 0 en cas d'erreur pour éviter de bloquer l'UI
    }
  }

  @override
  Stream<List<ColosseumRunModel>> listenColosseumRuns() {
    return _firestore
        .collection('colosseum_runs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ColosseumRunModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Stream<BastionModel?> listenBastionMetadata(String bastionId) {
    final bastionRef = _firestore.collection('bastions').doc(bastionId);

    // On combine le document du bastion et sa sous-collection leaderboard
    return bastionRef.snapshots().asyncMap((bastionSnap) async {
      if (!bastionSnap.exists) return null;

      final leaderboardSnap =
          await bastionRef
              .collection('leaderboard')
              .orderBy('reps', descending: true)
              .limit(10)
              .get();

      final leaderboard =
          leaderboardSnap.docs
              .map((doc) => BastionLeaderboardEntry.fromMap(doc.data()))
              .toList();

      return BastionModel.fromMap(
        bastionSnap.id,
        bastionSnap.data()!,
        leaderboard: leaderboard,
      );
    });
  }

  @override
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
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('claimBastion');
      await callable.call({
        'bastionId': bastionId,
        'userLat': userLat,
        'userLng': userLng,
        'reps': reps,
        'dips': dips,
        'pullups': pullups,
        'pushups': pushups,
        'abs': abs,
        'pseudo': pseudo,
        'exerciseType': exerciseType,
      });
    } catch (e) {
      debugPrint("❌ Erreur claimBastion: $e");
      rethrow;
    }
  }

  @override
  Future<void> uploadBastionPhoto({
    required String bastionId,
    required String filePath,
    String? bastionName,
    double? lat,
    double? lng,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Utilisateur non connecté.");

      // SÉCURITÉ ANTI-DDOS : Vérification locale du cooldown avant l'upload Storage
      final userDoc = await _usersCol.doc(userId).get();
      if (userDoc.exists) {
        final lastIntelAt = userDoc.data()?['lastIntelAt'];
        if (lastIntelAt != null && lastIntelAt is Timestamp) {
          final diff = DateTime.now().difference(lastIntelAt.toDate());
          if (diff.inHours < 1) {
            throw Exception(
              "Reconnaissance déjà effectuée récemment. Attendez 1 heure.",
            );
          }
        }
      }

      // 1. Lire le fichier
      final bytes = await File(filePath).readAsBytes();

      // 2. Upload vers Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'bastions_intel/${bastionId}_$timestamp.jpg';
      final downloadUrl = await _storageService.uploadGenericFile(
        storagePath,
        bytes,
      );

      // 3. Appel Cloud Function pour enregistrer l'intel et donner l'XP
      final callable = FirebaseFunctions.instance.httpsCallable(
        'reportBastionIntel',
      );
      await callable.call({
        'bastionId': bastionId,
        'downloadUrl': downloadUrl,
        'bastionName': bastionName,
        'lat': lat,
        'lng': lng,
      });
    } catch (e) {
      debugPrint("❌ Erreur uploadBastionPhoto: $e");
      throw Exception("Échec du transfert du renseignement : $e");
    }
  }
}
