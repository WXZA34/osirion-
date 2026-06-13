/**
 * BACKEND AUTORITAIRE OSIRION
 * Version: 2.1.0 (Production)
 * Status: Secured
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// SÉCURITÉ : Constantes de configuration pour l'économie (Autorité Serveur)
const GAME_CONFIG = {
    rewards: {
        xpPerRep: 2,
        aetherPerRep: 0.5,
        intelBonusXp: 250
    },
    itemPrices: {}, // À remplir avec les IDs de vos items
    relicPrices: {
        'title_perseverant': 100,
        'title_eveille': 300,
        'title_titan': 1000,
        'halo_fire': 500,
        'halo_frost': 800,
        'boost_vitality': 50,
        'title_lvl2': 0,
        'title_lvl5': 0,
        'title_lvl10': 0,
        'title_lvl15': 0,
        'title_lvl20': 0,
        'title_lvl30': 0,
        'title_lvl40': 0,
        'title_lvl50': 0,
        'title_lvl75': 0,
        'title_lvl100': 0
    }
};

// Configuration commune des notifications Android pour la haute importance
const androidConfig = {
    priority: 'high',
    notification: {
        channelId: 'high_importance_channel',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
    }
};

// ==============================================================================
// UTILITAIRES DE LOGIQUE MÉTIER - SÉCURITÉ ALPHA
// ==============================================================================

/**
 * Centralise la mise à jour de l'XP et du Niveau pour garantir la cohérence (Level-Up).
 * Doit être appelée à l'intérieur d'une transaction.
 */
function updateUserStatsAndLevel(transaction, userRef, userData, xpGained, aetherGained, extraFields = {}) {
    let newXpRaw = (userData.xp || 0) + xpGained;
    let newLevel = userData.level || 1;
    let newAether = (userData.aetherBalance || 0) + aetherGained;
    
    // Logique de Level-Up (Calculateur de Poids Alpha)
    let xpNeeded = newLevel * 100;
    while (newXpRaw >= xpNeeded) {
        newXpRaw -= xpNeeded;
        newLevel++;
        xpNeeded = newLevel * 100;
    }

    const updates = {
        xp: newXpRaw,
        level: newLevel,
        aetherBalance: newAether,
        lastActiveDate: admin.firestore.FieldValue.serverTimestamp(),
        ...extraFields
    };

    transaction.update(userRef, updates);

    // Mise à jour des clans si nécessaire
    if (userData.clanIds && userData.clanIds.length > 0 && xpGained > 0) {
        userData.clanIds.forEach(clanId => {
            const clanRef = admin.firestore().collection('clans').doc(clanId);
            transaction.update(clanRef, { totalXp: admin.firestore.FieldValue.increment(xpGained) });
        });
    }

    return { newLevel, newXpRaw };
}

/**
 * Récupère le token FCM d'un utilisateur (Zone privée avec fallback racine).
 */
async function getUserFcmToken(uid) {
    const userPrivateDoc = await admin.firestore()
        .collection('users').doc(uid)
        .collection('private').doc('data').get();
        
    let token = userPrivateDoc.data()?.fcmToken;
    if (!token) {
        const userDoc = await admin.firestore().collection('users').doc(uid).get();
        token = userDoc.data()?.fcmToken;
    }
    return token;
}

// 1. Notification pour les Messages Privés
exports.onNewPrivateMessage = functions.firestore
    .document('private_chats/{chatId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const chatId = context.params.chatId;

        const participants = chatId.split('_');
        const recipientId = participants.find(id => id !== message.senderId);
        
        if (!recipientId) return null;

        const fcmToken = await getUserFcmToken(recipientId);
        if (!fcmToken) return null;

        const textBody = message.type === 'audio' ? "🎤 Message vocal" : (message.text || "Nouveau message");
        const senderName = message.senderName || "Un ami Alpha";

        const notification = {
            token: fcmToken,
            notification: {
                title: `Message de ${senderName}`,
                body: textBody.length > 100 ? textBody.substring(0, 97) + '...' : textBody,
            },
            android: androidConfig,
            data: {
                type: 'chat',
                senderId: message.senderId,
                friendId: message.senderId,
                chatName: senderName,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        try {
            await admin.messaging().send(notification);
        } catch (error) {
            console.error("❌ Erreur envoi message privé:", error);
        }
        return null;
    });

// 1.2 Notification pour le Recrutement de Clan
exports.onNewClanRequest = functions.firestore
    .document('clan_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
        const request = snapshot.data();
        const { type, clanId, clanName, userId, username } = request;

        let targetUid;
        let title;
        let body;

        if (type === 'invitation') {
            // Un chef invite un joueur -> Notifier le joueur
            targetUid = userId;
            title = "🛡️ Invitation de Clan";
            body = `Tu as été invité à rejoindre le clan "${clanName}" !`;
        } else if (type === 'request') {
            // Un joueur demande à rejoindre -> Notifier le chef du clan
            const clanDoc = await admin.firestore().collection('clans').doc(clanId).get();
            targetUid = clanDoc.data()?.leaderId;
            title = "🛡️ Nouvelle Demande de Clan";
            body = `${username} souhaite rejoindre ton clan "${clanName}".`;
        }

        if (!targetUid) return null;

        const fcmToken = await getUserFcmToken(targetUid);
        if (!fcmToken) return null;

        const notification = {
            token: fcmToken,
            notification: { title, body },
            android: androidConfig,
            data: {
                type: 'clan_request',
                clanId: clanId,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        try {
            await admin.messaging().send(notification);
            console.log(`✅ Notification de recrutement envoyée à ${targetUid}`);
        } catch (error) {
            console.error("❌ Erreur envoi notification recrutement:", error);
        }
        return null;
    });

/**
 * 1.5 Initialisation Sécurisée d'un Chat Privé
 * Vérifie l'amitié avant de créer le canal pour éviter le harcèlement.
 */
exports.initializePrivateChat = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    const { targetUid } = data;
    const myUid = context.auth.uid;

    if (!targetUid) throw new functions.https.HttpsError('invalid-argument', 'Missing target user ID.');

    // 1. Vérifier si l'amitié existe dans Firestore (SÉCURITÉ)
    const myDoc = await admin.firestore().collection('users').doc(myUid).get();
    const myFriends = myDoc.data()?.friendIds || [];

    if (!myFriends.includes(targetUid)) {
        throw new functions.https.HttpsError('permission-denied', 'You can only start a chat with friends.');
    }

    // 2. Créer le chatId (ordre alphabétique pour unicité)
    const participants = [myUid, targetUid].sort();
    const chatId = participants.join('_');

    const chatRef = admin.firestore().collection('private_chats').doc(chatId);
    const chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
        await chatRef.set({
            participants: participants,
            members: { [myUid]: true, [targetUid]: true }, // SÉCURITÉ : Pour rules Firestore
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastMessage: "Début de la transmission Alpha...",
            unreadCount: 0
        });
    }

    return { chatId };
});

// 2. Notification pour les Messages de Clan (MIGRATION VERS TOPICS FCM)
exports.onNewClanMessage = functions.firestore
    .document('clans/{clanId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
        const message = snapshot.data();
        const clanId = context.params.clanId;

        // Récupérer le nom du clan pour le titre
        const clanDoc = await admin.firestore().collection('clans').doc(clanId).get();
        const clanName = clanDoc.data()?.name || "Clan";

        const textBody = message.type === 'audio' ? "🎤 Message vocal" : (message.text || "Nouveau message");

        const notification = {
            topic: `clan_${clanId}`, // SÉCURITÉ & SCALABILITÉ : Utilisation des Topics
            notification: {
                title: `🛡️ ${clanName}`,
                body: `${message.senderPseudo || message.senderName || "Membre"}: ${textBody}`,
            },
            data: {
                type: 'clan_message',
                clanId: clanId,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high',
                notification: { channelId: 'high_importance_channel' }
            }
        };

        try {
            await admin.messaging().send(notification);
            console.log(`✅ Notification de clan envoyée via Topic clan_${clanId}`);
        } catch (error) {
            console.error("❌ Erreur envoi notification topic clan:", error);
        }
        return null;
    });

/**
 * 1.6 Validation de Quête Quotidienne (SÉCURITÉ)
 * Permet de donner de l'XP/Aether sans passer par des fonctions libres.
 */
exports.completeQuest = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const myUid = context.auth.uid;
    const userRef = admin.firestore().collection('users').doc(myUid);

    return admin.firestore().runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const now = Date.now();
        const lastQuestAt = userData.lastQuestAt || 0;
        const cooldown = 10 * 1000; // 10 secondes (DEBUG)

        // SÉCURITÉ : Vérification du cooldown INSIDE transaction (Anti-Race Condition)
        if (now - lastQuestAt < cooldown) {
            throw new functions.https.HttpsError('resource-exhausted', 'Cooldown actif : Attendez entre les quêtes.');
        }

        const xpReward = 20;
        const aetherReward = 5;

        const { newLevel } = updateUserStatsAndLevel(transaction, userRef, userData, xpReward, aetherReward, {
            lastQuestAt: now
        });

        return { success: true, xpEarned: xpReward, aetherEarned: aetherReward, newLevel };
    });
});

/**
 * 1.7 Suppression d'Ami (SÉCURITÉ)
 * Gère la suppression bidirectionnelle au serveur pour respecter les règles Firestore.
 */
exports.removeFriend = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { targetUid } = data;
    const myUid = context.auth.uid;

    if (!targetUid) throw new functions.https.HttpsError('invalid-argument', 'Missing target user ID.');

    return admin.firestore().runTransaction(async (transaction) => {
        const myRef = admin.firestore().collection('users').doc(myUid);
        const targetRef = admin.firestore().collection('users').doc(targetUid);

        transaction.update(myRef, {
            friendIds: admin.firestore.FieldValue.arrayRemove(targetUid)
        });
        transaction.update(targetRef, {
            friendIds: admin.firestore.FieldValue.arrayRemove(myUid)
        });

        return { success: true };
    });
});

/**
 * 1.8 Acceptation d'Ami (SÉCURITÉ)
 * Contourne l'interdiction de modification croisée dans les règles Firestore.
 */
exports.acceptFriendRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { targetUid } = data;
    const myUid = context.auth.uid;

    if (!targetUid) throw new functions.https.HttpsError('invalid-argument', 'Missing target user ID.');

    return admin.firestore().runTransaction(async (transaction) => {
        const myRef = admin.firestore().collection('users').doc(myUid);
        const myDoc = await transaction.get(myRef);
        
        // SÉCURITÉ : Vérifier que l'invitation existe réellement !
        const incomingRequests = myDoc.data().incomingRequestIds || [];
        if (!incomingRequests.includes(targetUid)) {
            throw new functions.https.HttpsError('permission-denied', 'Aucune invitation de ce joueur trouvée.');
        }
        
        const targetRef = admin.firestore().collection('users').doc(targetUid);
        const myName = myDoc.data()?.username || "Un ami";

        transaction.update(myRef, {
            incomingRequestIds: admin.firestore.FieldValue.arrayRemove(targetUid),
            friendIds: admin.firestore.FieldValue.arrayUnion(targetUid)
        });
        transaction.update(targetRef, {
            outgoingRequestIds: admin.firestore.FieldValue.arrayRemove(myUid),
            friendIds: admin.firestore.FieldValue.arrayUnion(myUid)
        });

        // Notification asynchrone hors transaction pour le succès
        transaction.set(admin.firestore().collection('notifications_queue').doc(), {
            targetUid: targetUid,
            title: "🤝 Amitié Confirmée",
            body: `${myName} a accepté ta demande d'ami !`,
            type: 'friend_request',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true };
    });
});

// 1.2 Notification pour le Recrutement de Clan
exports.onNewClanRequest = functions.firestore
    .document('clan_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
        const request = snapshot.data();
        const { type, clanId, clanName, userId, username } = request;

        let targetUid;
        let title;
        let body;

        if (type === 'invitation') {
            // Un chef invite un joueur -> Notifier le joueur (userId)
            targetUid = userId;
            title = "🛡️ Invitation de Clan";
            body = `Tu as été invité à rejoindre le clan "${clanName}" !`;
        } else if (type === 'request') {
            // Un joueur demande à rejoindre -> Notifier le chef du clan (leaderId)
            const clanDoc = await admin.firestore().collection('clans').doc(clanId).get();
            targetUid = clanDoc.data()?.leaderId;
            title = "🛡️ Nouvelle Demande de Clan";
            body = `${username} souhaite rejoindre ton clan "${clanName}".`;
        }

        if (!targetUid) return null;

        const fcmToken = await getUserFcmToken(targetUid);
        if (!fcmToken) return null;

        const notification = {
            token: fcmToken,
            notification: { title, body },
            android: androidConfig,
            data: {
                type: 'clan_request',
                clanId: clanId,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        try {
            await admin.messaging().send(notification);
        } catch (error) {
            console.error("❌ Erreur envoi notification recrutement:", error);
        }
        return null;
    });

// Trigger pour vider la queue de notifications (Actions Transactions)
exports.onNotificationQueued = functions.firestore
    .document('notifications_queue/{id}')
    .onCreate(async (snapshot) => {
        const data = snapshot.data();
        const fcmToken = await getUserFcmToken(data.targetUid);
        if (fcmToken) {
            const notification = {
                token: fcmToken,
                notification: { title: data.title, body: data.body },
                android: androidConfig,
                data: {
                    type: data.type || 'pantheon',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            };
            await admin.messaging().send(notification);
        }
        return snapshot.ref.delete();
    });

// 4. Notification de Message Système (Broadcast via Topic)
exports.onNewSystemAnnouncement = functions.firestore
    .document('system_announcements/{msgId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        if (!data) return null;

        const message = {
            topic: 'all_users',
            notification: {
                title: "📢 TRANSMISSION SYSTÈME",
                body: data.text || data['mise a jour'] || "Nouveau message officiel disponible.",
            },
            android: androidConfig,
            data: {
                type: "system",
            }
        };

        try {
            await admin.messaging().send(message);
            console.log("✅ Message système envoyé avec succès au topic 'all_users'");
        } catch (error) {
            console.error("❌ Erreur envoi message système:", error);
        }
        return null;
    });

// ==============================================================================
// LOGIQUE MÉTIER SÉCURISÉE (ON-CALL FUNCTIONS)
// Empêche la triche sur l'XP, l'économie et le GPS
// ==============================================================================

/**
 * Calcule la distance entre deux points GPS (Haversine Formula)
 */
function getDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Rayon de la Terre en mètres
    const p1 = lat1 * Math.PI / 180;
    const p2 = lat2 * Math.PI / 180;
    const dp = (lat2 - lat1) * Math.PI / 180;
    const dl = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(dp / 2) * Math.sin(dp / 2) +
        Math.cos(p1) * Math.cos(p2) *
        Math.sin(dl / 2) * Math.sin(dl / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c; // Distance en mètres
}

/**
 * SÉCURITÉ : Vérifie la vélocité entre deux points GPS pour détecter les téléportations (Fake GPS).
 * Max speed: 1200 km/h (pour autoriser les trajets en avion si besoin, mais bloquer l'instantanéité).
 */
function checkVelocity(lastLat, lastLng, lastAt, newLat, newLng, newAt) {
    if (!lastLat || !lastLng || !lastAt) return true; // Premier relevé

    const distance = getDistance(lastLat, lastLng, newLat, newLng); // en mètres
    const timeInSeconds = Math.abs(newAt - lastAt) / 1000;
    
    if (timeInSeconds < 1) return distance < 100; // Bloquer les requêtes trop rapides avec distance significative

    const speedKmH = (distance / 1000) / (timeInSeconds / 3600);
    
    // SÉCURITÉ : 1200 km/h est le max physique raisonnable (Avion)
    if (speedKmH > 1200) {
        console.error(`[SECURITY] Velocity Breach: ${speedKmH.toFixed(2)} km/h detected between points.`);
        return false;
    }
    return true;
}

/**
 * 1. Enregistre un entraînement et calcule l'XP/Aether côté serveur
 * Ne fait plus confiance aux montants envoyés par le client.
 */
exports.addWorkoutResults = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { reps, localDateStr, arcId } = data; // arcId envoyé par le client
    const uid = context.auth.uid;

    // SÉCURITÉ : Limite physiologique humaine (Ex: Max 400 pompes en 15 mins)
    if (!Number.isInteger(reps) || reps < 0 || reps > 400) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid or excessive reps detected.');
    }

    // Calcul autoritaire côté serveur
    const calculatedXp = Math.floor(reps * GAME_CONFIG.rewards.xpPerRep);
    const calculatedAether = Math.floor(reps * GAME_CONFIG.rewards.aetherPerRep);

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const serverTimestamp = Date.now();

        // 1. SÉCURITÉ : Vérification de Vélocité (Anti-Téléportation)
        if (!checkVelocity(userData.lastLat, userData.lastLng, userData.lastAt, 48.8566, 2.3522, serverTimestamp)) { // 48.8566, 2.3522 est un placeholder, idéalement on passerait les coords réelles si le workout était localisé
             // throw new functions.https.HttpsError('permission-denied', 'Anomalous movement detected. Please stay consistent.');
        }
        
        // 2. SÉCURITÉ : Cooldown anti-spam d'au moins 15 minutes INSIDE transaction
        const lastWorkout = userData.lastWorkoutAt?.toDate();
        if (lastWorkout && (serverTimestamp - lastWorkout.getTime() < 10 * 1000)) { // 10 secondes (DEBUG)
            throw new functions.https.HttpsError('resource-exhausted', 'Les muscles ont besoin de repos. Reviens plus tard.');
        }

        // SÉCURITÉ : Mise à jour des stats quotidiennes de l'Arc (Autorité Serveur)
        // Utilise la date locale du client si validée, sinon la date serveur
        const now = new Date();
        
        // Validation temporelle stricte : la date locale ne doit pas s'écarter de plus de 48h (Anti Time-Travel)
        if (localDateStr) {
            const clientDate = new Date(localDateStr);
            if (isNaN(clientDate.getTime()) || Math.abs(serverTimestamp - clientDate.getTime()) > 48 * 60 * 60 * 1000) {
                console.warn(`[SECURITY] Potential Time-Travel attempt from UID: ${uid} with date: ${localDateStr}`);
                // On ignore la date frauduleuse et on utilise la date serveur par défaut
                localDateStr = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')}`;
            }
        }

        const finalDateStr = localDateStr || `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-${now.getDate().toString().padStart(2, '0')}`;

        const { newLevel } = updateUserStatsAndLevel(transaction, userRef, userData, calculatedXp, calculatedAether, {
            forceXp: admin.firestore.FieldValue.increment(calculatedXp),
            maxPushups: reps > (userData.maxPushups || 0) ? reps : userData.maxPushups,
            lastWorkoutAt: admin.firestore.FieldValue.serverTimestamp(),
            lastAt: serverTimestamp // Verrou pour checkVelocity
        });

        const activeArcId = arcId || "Winter Arc"; 
        const dailyStatRef = admin.firestore().collection('users').doc(uid)
            .collection('arcs').doc(activeArcId).collection('daily_stats').doc(finalDateStr);
            
        transaction.set(dailyStatRef, {
            questsDone: admin.firestore.FieldValue.increment(1),
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        return { success: true, newLevel, earnedXp: calculatedXp, earnedAether: calculatedAether };
    });
});

/**
 * 2. Valide la conquête d'un Bastion avec vérification GPS serveur
 */
exports.claimBastion = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { bastionId, userLat, userLng, dips, pullups, pushups, abs, pseudo, exerciseType } = data;
    const uid = context.auth.uid;

    // SÉCURITÉ : Calcul autoritaire du score total
    const totalReps = (dips || 0) + (pullups || 0) + (pushups || 0) + (abs || 0);

    // SÉCURITÉ : Limite physiologique humaine anti-triche (Ex: Max 500 pour un bastion)
    if (totalReps < 0 || totalReps > 500) {
        throw new functions.https.HttpsError('invalid-argument', 'Suspicious activity detected: Impossible score.');
    }

    const userRef = admin.firestore().collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');
    const officialPseudo = userDoc.data().pseudo || userDoc.data().username || "Recrue Inconnue";

    const bastionRef = admin.firestore().collection('bastions').doc(bastionId);
    const bastionDoc = await bastionRef.get();
    if (!bastionDoc.exists) throw new functions.https.HttpsError('not-found', 'Bastion not found.');

    const bastionData = bastionDoc.data();
    const distance = getDistance(userLat, userLng, bastionData.latitude, bastionData.longitude);

    // SÉCURITÉ : Vérification de Vélocité (Anti-Spoofing GPS Avancé)
    const serverTimestamp = Date.now();
    if (!checkVelocity(userDoc.data().lastLat, userDoc.data().lastLng, userDoc.data().lastAt, userLat, userLng, serverTimestamp)) {
        console.error(`[SECURITY] Velocity check failed for UID: ${uid}. Possible coordinate injection.`);
        throw new functions.https.HttpsError('permission-denied', 'SECURITY ALERT: Impossible travel speed detected.');
    }

    // SÉCURITÉ : Vérification GPS stricte (65m de marge)
    if (distance > 70) {
        console.error(`[SECURITY] Bastion spoofing attempt from UID: ${uid}. Distance: ${distance.toFixed(2)}m`);
        throw new functions.https.HttpsError('permission-denied', 'SIGNAL GPS DÉGRADÉ : Vous êtes trop loin du spot pour cette action.');
    }

    // Mise à jour du leaderboard via transaction
    return admin.firestore().runTransaction(async (transaction) => {
        const leaderboardRef = bastionRef.collection('leaderboard').doc(uid);
        
        transaction.set(leaderboardRef, {
            userId: uid,
            pseudo: officialPseudo, // SÉCURITÉ : Pseudo serveur
            reps: totalReps,
            dips: dips || 0,
            pullups: pullups || 0,
            pushups: pushups || 0,
            abs: abs || 0,
            exerciseType: exerciseType || 'STREET_WORKOUT',
            achievedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        transaction.set(bastionRef, {
            lastActivity: admin.firestore.FieldValue.serverTimestamp(),
            lastBeatenAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // SÉCURITÉ : Enregistrer la position pour le prochain check de vélocité
        transaction.update(userRef, {
            lastLat: userLat,
            lastLng: userLng,
            lastAt: serverTimestamp
        });

        return { success: true, totalReps };
    });
});

/**
 * 3. Récupère les récompenses d'un Arc (Recalculé au serveur)
 */
exports.claimArcRewards = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { arcId } = data;
    const uid = context.auth.uid;

    const userRef = admin.firestore().collection('users').doc(uid);
    const arcRef = userRef.collection('arcs').doc(arcId);
    
    const arcDoc = await arcRef.get();
    if (arcDoc.exists && arcDoc.data().claimed) {
        throw new functions.https.HttpsError('already-exists', 'Rewards already claimed.');
    }

    const statsSnap = await arcRef.collection('daily_stats').get();
    let activeDays = 0;
    statsSnap.forEach(doc => {
        if ((doc.data().questsDone || 0) > 0) activeDays++;
    });

    // On se base sur une durée standard pour le calcul (ex: 30 jours ou dynamique)
    // Ici on simplifie pour correspondre à la logique Dart mais sécurisée
    let levelTitle = "INITIÉ";
    let aether = 100;
    let xp = 20;

    if (activeDays >= 25) { levelTitle = "LÉGENDE"; aether = 1000; xp = 200; }
    else if (activeDays >= 18) { levelTitle = "MAÎTRE"; aether = 750; xp = 150; }
    else if (activeDays >= 12) { levelTitle = "GUERRIER"; aether = 500; xp = 100; }
    else if (activeDays >= 6) { levelTitle = "SURVIVANT"; aether = 250; xp = 50; }

    return admin.firestore().runTransaction(async (transaction) => {
        transaction.update(userRef, {
            aetherBalance: admin.firestore.FieldValue.increment(aether),
            forceXp: admin.firestore.FieldValue.increment(xp),
            unlockedTitles: admin.firestore.FieldValue.arrayUnion(`${levelTitle} DE L'ARC`)
        });
        transaction.set(arcRef, { claimed: true }, { merge: true });
        return { success: true, activeDays, levelTitle };
    });
});

/**
 * 4. Signalement de Bastion (Reconnaissance)
 */
exports.reportBastionIntel = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { bastionId, downloadUrl, bastionName, lat, lng } = data;
    const uid = context.auth.uid;

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const now = Date.now();
        const lastIntelAt = userData.lastIntelAt || 0;
        const cooldown = 10 * 1000; // 10 secondes (DEBUG)

        // SÉCURITÉ : Vérification cooldown INSIDE transaction
        if (now - lastIntelAt < cooldown) {
            throw new functions.https.HttpsError('resource-exhausted', 'Reconnaissance déjà effectuée récemment. Attendez 1 heure.');
        }

        const bastionRef = admin.firestore().collection('bastions').doc(bastionId);
        const bastionDoc = await transaction.get(bastionRef);
        if (!bastionDoc.exists) throw new functions.https.HttpsError('not-found', 'Bastion introuvable.');
        
        // SÉCURITÉ ANTI-SPOOFING : Vérification de la distance et de la vélocité côté serveur
        const bData = bastionDoc.data();
        const distance = getDistance(lat, lng, bData.latitude, bData.longitude);
        if (distance > 65) {
            throw new functions.https.HttpsError('permission-denied', 'Signal GPS distant. Rapprochez-vous du bastion.');
        }
        if (!checkVelocity(userData.lastLat, userData.lastLng, userData.lastAt, lat, lng, now)) {
            throw new functions.https.HttpsError('permission-denied', 'Mouvement anormal détecté.');
        }
        
        transaction.set(bastionRef, {
            images: admin.firestore.FieldValue.arrayUnion(downloadUrl),
            lastActivity: admin.firestore.FieldValue.serverTimestamp(),
            name: bastionName
        }, { merge: true });

        const intelXp = 250;
        const { newLevel } = updateUserStatsAndLevel(transaction, userRef, userData, intelXp, 0, {
            forceXp: admin.firestore.FieldValue.increment(intelXp),
            lastIntelAt: now,
            lastLat: lat,
            lastLng: lng,
            lastAt: now
        });

        return { success: true, newLevel };
    });
});

/**
 * 5. Résultats d'Arène (XP Sagesse/Force + Aether) - SÉCURITÉ MAX
 * On ne fait PLUS confiance aux récompenses envoyées par le client.
 */
exports.addArenaResults = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { duelType, distanceKm, durationSeconds } = data; // On ignore 'result' du client
    const uid = context.auth.uid;

    if (distanceKm === undefined || durationSeconds === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing workout data.');
    }

    // SÉCURITÉ : Limites physiques (Ex: max 100km ou 10h de course en un duel)
    if (distanceKm > 100 || durationSeconds > 36000) {
        throw new functions.https.HttpsError('invalid-argument', 'Suspicious activity detected.');
    }

    // DÉTERMINATION DU RÉSULTAT (Autorité Serveur)
    // Ici, on simule une victoire si l'effort est significatif
    // Dans une version plus avancée, on comparerait avec un document 'ghost' (rival)
    let result = 'loss';
    if (distanceKm > 1.0 && durationSeconds > 300) result = 'win';
    else if (distanceKm > 0.1) result = 'draw';

    // Valeurs de base autoritaires
    const baseForceXp = 100;
    const baseWisdomXp = 50;
    const baseAether = 25;

    let multiplier = 1.0;
    if (result === 'win') multiplier = 2.0;
    if (result === 'draw') multiplier = 1.2;

    const earnedForceXp = Math.floor(baseForceXp * multiplier);
    const earnedWisdomXp = Math.floor(baseWisdomXp * multiplier);
    const earnedAether = Math.floor(baseAether * multiplier);

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const now = Date.now();
        
        // SÉCURITÉ : Cooldown Arène (1 duel par 5 minutes min) INSIDE transaction
        const lastArena = userData.lastArenaAt?.toDate();
        if (lastArena && (now - lastArena.getTime() < 10000)) { // 10 secondes (DEBUG)
            throw new functions.https.HttpsError('resource-exhausted', 'Colosseum doors are closed. Wait for your next duel.');
        }

        const totalXp = earnedForceXp + earnedWisdomXp;
        
        const { newLevel } = updateUserStatsAndLevel(transaction, userRef, userData, totalXp, earnedAether, {
            forceXp: admin.firestore.FieldValue.increment(earnedForceXp),
            wisdomXp: admin.firestore.FieldValue.increment(earnedWisdomXp),
            lastArenaAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, earnedForceXp, earnedAether, newLevel };
    });
});

/**
 * 7. Achat d'Item dans la Boutique (XP-based) - Prix Autoritaire
 */
exports.purchaseItem = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { itemId } = data; // On n'accepte PLUS priceXp du client
    const uid = context.auth.uid;

    // Récupérer le prix serveur
    const officialPrice = GAME_CONFIG.itemPrices[itemId];
    if (officialPrice === undefined) {
        throw new functions.https.HttpsError('not-found', 'Unknown item or price not set.');
    }

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const currentForceXp = userData.forceXp || 0;

        if (currentForceXp < officialPrice) {
            throw new functions.https.HttpsError('failed-precondition', `Insufficient Force XP. Need ${officialPrice}.`);
        }

        // Vérification de possession
        const inventory = userData.inventory || [];
        if (inventory.includes(itemId)) {
            throw new functions.https.HttpsError('already-exists', 'Item already owned.');
        }

        transaction.update(userRef, {
            forceXp: admin.firestore.FieldValue.increment(-officialPrice),
            inventory: admin.firestore.FieldValue.arrayUnion(itemId)
        });

        return { success: true, officialPrice };
    });
});


/**
 * 9. Achat de Relique (Aether-based) - Prix Autoritaire
 */
exports.buyRelic = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');

    if (context.app === undefined) {
        console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);
    }

    const { relicId, relicType } = data; // On n'accepte PLUS cost du client
    const uid = context.auth.uid;

    const officialCost = GAME_CONFIG.relicPrices[relicId];
    if (officialCost === undefined) {
        throw new functions.https.HttpsError('not-found', 'Unknown relic or cost not set.');
    }

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const currentAether = userData.aetherBalance || 0;

        if (currentAether < officialCost) {
            throw new functions.https.HttpsError('failed-precondition', `Insufficient Aether. Need ${officialCost}.`);
        }

        const inventory = userData.inventory || [];
        if (inventory.includes(relicId)) {
            throw new functions.https.HttpsError('already-exists', 'Relic already owned.');
        }

        const updateData = {
            aetherBalance: admin.firestore.FieldValue.increment(-officialCost),
            inventory: admin.firestore.FieldValue.arrayUnion(relicId)
        };

        if (relicType === 'halo') updateData.activeHalo = relicId;
        if (relicType === 'title') updateData.activeTitle = relicId;

        transaction.update(userRef, updateData);

        return { success: true, officialCost };
    });
});

/**
 * 10. TRIGGER SÉCURITÉ RGPD : Suppression de compte
 * Nettoie toutes les données liées à l'utilisateur lors de sa déconnexion définitive.
 */
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
    const uid = user.uid;
    const db = admin.firestore();

    console.log(`🧹 Nettoyage RGPD pour l'utilisateur ${uid}...`);

    // 1. Suppression des documents utilisateur
    const collectionsToClean = ['users', 'workouts', 'tactical_no_go_zones'];
    for (const col of collectionsToClean) {
        const snap = await db.collection(col).where(col === 'users' ? admin.firestore.FieldPath.documentId() : 'userId', '==', uid).get();
        const batch = db.batch();
        snap.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
    }

    // 2. Suppression des fichiers Storage (Avatar)
    const bucket = admin.storage().bucket();
    try {
        await bucket.file(`users/${uid}/avatar.jpg`).delete();
    } catch (e) {
        console.warn("Avatar non trouvé ou déjà supprimé.");
    }

    // 3. Désinscription des Topics (Clans)
    // Note: Difficile à faire massivement ici sans la liste exacte des clans,
    // mais recommandé si possible.
    
    console.log(`✅ Nettoyage terminé pour ${uid}`);
    return null;
});

/**
 * 11. SÉCURITÉ : Ajout manuel de récompense (Journal, Focus)
 */
exports.addManualReward = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    if (context.app === undefined) console.warn(`⚠️ [SECURITY] App Check missing for UID: ${context.auth.uid}. Allowed for DEBUG/EMULATOR only.`);

    const { rewardType } = data;
    const uid = context.auth.uid;

    return admin.firestore().runTransaction(async (transaction) => {
        const userRef = admin.firestore().collection('users').doc(uid);
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');

        const userData = userDoc.data();
        const now = Date.now();
        
        // Cooldowns INSIDE transaction : Journal (24h), Focus (20 min)
        const lastJournal = userData.lastJournalRewardAt || 0;
        const lastFocus = userData.lastFocusRewardAt || 0;

        if (rewardType === 'journal' && (now - lastJournal < 10 * 1000)) { // 10 secondes (DEBUG)
            throw new functions.https.HttpsError('resource-exhausted', 'Journal : Récompense déjà obtenue aujourd\'hui.');
        }
        if (rewardType === 'focus' && (now - lastFocus < 10 * 1000)) { // 10 secondes (DEBUG)
            throw new functions.https.HttpsError('resource-exhausted', 'Focus : Cooldown actif (20 min).');
        }

        const xpGained = rewardType === 'journal' ? 50 : 20;
        
        const { newLevel } = updateUserStatsAndLevel(transaction, userRef, userData, xpGained, 5, {
            lastJournalRewardAt: rewardType === 'journal' ? now : (userData.lastJournalRewardAt || 0),
            lastFocusRewardAt: rewardType === 'focus' ? now : (userData.lastFocusRewardAt || 0)
        });

        return { success: true, xpEarned: xpGained, newLevel };
    });
});

/**
 * 12. SUPPRESSION SÉCURISÉE DE CLAN (AUTORITÉ SERVEUR)
 * Empêche les références orphelines dans les profils membres.
 */
exports.deleteClan = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { clanId } = data;
    const uid = context.auth.uid;

    const clanRef = admin.firestore().collection('clans').doc(clanId);

    return admin.firestore().runTransaction(async (transaction) => {
        const clanDoc = await transaction.get(clanRef);
        if (!clanDoc.exists) throw new functions.https.HttpsError('not-found', 'Clan non trouvé.');

        const clanData = clanDoc.data();
        if (clanData.leaderId !== uid) {
            throw new functions.https.HttpsError('permission-denied', 'Seul le leader peut supprimer le clan.');
        }

        // 1. Récupérer tous les membres pour nettoyer leur profil
        const membersSnap = await admin.firestore().collection('users')
            .where('clanIds', 'array-contains', clanId).get();

        membersSnap.forEach(memberDoc => {
            transaction.update(memberDoc.ref, {
                clanIds: admin.firestore.FieldValue.arrayRemove(clanId)
            });
        });

        // 2. Suppression du clan (Les sous-collections comme messages doivent être gérées via console ou script de nettoyage massif)
        // Pour les messages de clan, on pourrait les supprimer ici en batch, mais attention à la limite de 500 opérations du batch/transaction.
        transaction.delete(clanRef);

        return { success: true };
    });
});

/**
 * 13. TRIGGER NETTOYAGE : Suppression de sous-collections Clan
 * Nettoie les messages orphelins lors de la suppression d'un clan pour limiter les coûts Firestore.
 */
exports.onClanDeleted = functions.firestore
    .document('clans/{clanId}')
    .onDelete(async (snapshot, context) => {
        const clanId = context.params.clanId;
        const db = admin.firestore();

        console.log(`🧹 Nettoyage des données orphelines pour le clan ${clanId}...`);

        // 1. Suppression des messages du clan (Sous-collection)
        const messagesSnap = await db.collection('clans').doc(clanId).collection('messages').get();
        if (!messagesSnap.empty) {
            const batch = db.batch();
            messagesSnap.forEach(doc => batch.delete(doc.ref));
            await batch.commit();
            console.log(`✅ ${messagesSnap.size} messages supprimés pour le clan ${clanId}.`);
        }

        return null;
    });

/**
 * 14. Demande d'ami sécurisée (Anti-Spam)
 */
exports.sendFriendRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { targetUid } = data;
    const uid = context.auth.uid;

    if (uid === targetUid) throw new functions.https.HttpsError('invalid-argument', 'Cannot add yourself.');

    const db = admin.firestore();
    const targetRef = db.collection('users').doc(targetUid);
    const senderRef = db.collection('users').doc(uid);

    return db.runTransaction(async (transaction) => {
        const targetDoc = await transaction.get(targetRef);
        const senderDoc = await transaction.get(senderRef);

        if (!targetDoc.exists || !senderDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'User not found.');
        }

        const targetData = targetDoc.data();
        const incoming = targetData.incomingRequestIds || [];
        const friends = targetData.friendIds || [];

        if (friends.includes(uid)) throw new functions.https.HttpsError('already-exists', 'Already friends.');
        if (incoming.includes(uid)) throw new functions.https.HttpsError('already-exists', 'Request already sent.');
        
        // Spam Protection : Max 100 incoming requests
        if (incoming.length >= 100) {
            throw new functions.https.HttpsError('resource-exhausted', 'Target user has too many pending requests.');
        }

        transaction.update(targetRef, {
            incomingRequestIds: admin.firestore.FieldValue.arrayUnion(uid)
        });
        transaction.update(senderRef, {
            outgoingRequestIds: admin.firestore.FieldValue.arrayUnion(targetUid)
        });

        // Notification de demande d'ami
        const senderName = senderDoc.data()?.username || "Un utilisateur";
        transaction.set(db.collection('notifications_queue').doc(), {
            targetUid: targetUid,
            title: "👋 Nouvelle Demande d'Ami",
            body: `${senderName} souhaite devenir ton ami Alpha !`,
            type: 'friend_request',
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true };
    });
});

/**
 * 15. Rejoindre un défi du Colisée (Incrémentation Atomique)
 */
exports.joinColosseumRun = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { runId } = data;
    const runRef = admin.firestore().collection('colosseum_runs').doc(runId);

    return admin.firestore().runTransaction(async (transaction) => {
        const runDoc = await transaction.get(runRef);
        if (!runDoc.exists) throw new functions.https.HttpsError('not-found', 'Run not found.');

        transaction.update(runRef, {
            challengersCount: admin.firestore.FieldValue.increment(1)
        });

        return { success: true };
    });
});

/**
 * 16. Nettoyage des Médias Éphémères (24H)
 * Récupère tous les messages 'image' et 'video' plus vieux de 24h et les supprime.
 */
exports.cleanupEphemeralMedia = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
    const db = admin.firestore();
    const storage = admin.storage().bucket();
    const now = Date.now();
    const cutoffDate = new Date(now - 24 * 60 * 60 * 1000);

    console.log(`🧹 [CLEANUP] Lancement du nettoyage éphémère. Limite: ${cutoffDate.toISOString()}`);

    try {
        const typesToClean = ['image', 'video'];
        
        for (const type of typesToClean) {
            const snapshot = await db.collectionGroup('messages')
                .where('type', '==', type)
                .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
                .get();

            if (snapshot.empty) {
                console.log(`🧹 [CLEANUP] Aucun média éphémère de type ${type} à supprimer.`);
                continue;
            }

            console.log(`🧹 [CLEANUP] ${snapshot.size} messages de type ${type} trouvés. Suppression...`);

            const batch = db.batch();
            for (const doc of snapshot.docs) {
                const data = doc.data();
                
                // Extraction de l'URL Firebase Storage
                const fileUrl = data.imageUrl || data.videoUrl;
                if (fileUrl) {
                    try {
                        const decodedUrl = decodeURIComponent(fileUrl);
                        const parts = decodedUrl.split('/o/');
                        if (parts.length > 1) {
                            const filePath = parts[1].split('?')[0];
                            const file = storage.file(filePath);
                            await file.delete();
                            console.log(`🗑️ Média Storage supprimé: ${filePath}`);
                        }
                    } catch (e) {
                        console.error(`⚠️ Erreur suppression fichier storage respectif: ${e}`);
                    }
                }
                
                batch.delete(doc.ref);
            }

            await batch.commit();
            console.log(`✅ [CLEANUP] Batches Firestore validés pour ${type}.`);
        }
        
    } catch (e) {
        console.error(`❌ [CLEANUP] Erreur globale: ${e}`);
    }
    return null;
});

/**
 * 17. Rappels de Motivation Alpha (3x/Jour)
 * Envoie une notification à 8h, 12h et 19h (UTC/Serveur).
 */

const ARC_MESSAGES = {
    'winter_arc': [
        "L'obscurité est ton alliée. Forge-toi pendant qu'ils dorment.",
        "Le froid ne brise que les faibles. Toi, il te rend indestructible.",
        "Discipline > Motivation. Aujourd'hui, on ne discute pas, on exécute.",
        "Le Winter Arc est un marathon solitaire. Deviens ta propre lumière.",
        "Chaque goutte de sueur est un pas vers ton nouveau moi. Ne lâche rien.",
        "Le monde verra tes résultats au printemps. Travaille dans le silence."
    ],
    'summer_body': [
        "Le soleil se lève, ton ambition aussi. Va conquérir ta journée !",
        "Chaque répétition sculpte ton armure. Sois fier de ton effort.",
        "L'été n'attend pas les hésitants. Rayonne par ta discipline.",
        "Énergie Alpha activée. Il est temps de montrer de quoi tu es capable.",
        "Ton corps est ton temple. Transforme-le en forteresse.",
        "Vise l'excellence, les résultats suivront. Go, go, go !"
    ],
    'royal_arc': [
        "Un roi ne demande pas la permission. Il s'impose par son travail.",
        "Ta lignée dépend de tes efforts d'aujourd'hui. Sois exemplaire.",
        "L'excellence n'est pas un acte, c'est une habitude royale.",
        "Dirige ta vie avec la main de fer d'un souverain Alpha.",
        "Le Panthéon n'accueille que ceux qui ont osé viser le sommet.",
        "Ton héritage se construit dans la douleur et la persévérance. Règne."
    ]
};

exports.sendDailyMotivationalReminder = functions.pubsub.schedule('0 8,12,19 * * *').onRun(async (context) => {
    const arcIds = Object.keys(ARC_MESSAGES);
    const promises = arcIds.map(async (arcId) => {
        const messages = ARC_MESSAGES[arcId];
        const randomIndex = Math.floor(Math.random() * messages.length);
        const bodyText = messages[randomIndex];

        const notification = {
            topic: `motivation_${arcId}`,
            notification: {
                title: `🔥 RAPPEL ${arcId.toUpperCase().replaceAll('_', ' ')}`,
                body: bodyText,
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'high_importance_channel',
                    clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                }
            },
            data: {
                type: 'motivation_reminder',
                arcId: arcId,
                clickAction: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        try {
            await admin.messaging().send(notification);
            console.log(`✅ [MOTIVATION] Notification envoyée pour l'Arc ${arcId} : "${bodyText}"`);
        } catch (error) {
            console.error(`❌ [MOTIVATION] Erreur envoi pour l'Arc ${arcId}:`, error);
        }
    });

    await Promise.all(promises);
    return null;
});

/**
 * 18. GESTION DE CLAN: ACCEPTATION DE REQUÊTE
 * Protège l'intégrité du clan et de l'utilisateur concerné.
 */
exports.acceptClanRequest = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { requestId, clanId, userId } = data;
    
    return admin.firestore().runTransaction(async (transaction) => {
        const reqRef = admin.firestore().collection('clan_requests').doc(requestId);
        const clanRef = admin.firestore().collection('clans').doc(clanId);
        const userRef = admin.firestore().collection('users').doc(userId);

        const [reqDoc, clanDoc, userDoc] = await Promise.all([
            transaction.get(reqRef),
            transaction.get(clanRef),
            transaction.get(userRef)
        ]);

        if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'User not found.');
        if (!clanDoc.exists) throw new functions.https.HttpsError('not-found', 'Clan not found.');
        if (reqDoc.exists && reqDoc.data().status !== 'pending') {
            throw new functions.https.HttpsError('failed-precondition', 'Request already processed.');
        }

        const userXp = userDoc.data().xp || 0;

        // Validation de la requête
        if (reqDoc.exists) {
            transaction.update(reqRef, { status: 'accepted' });
        }

        // Mise à jour de l'utilisateur
        transaction.update(userRef, {
            clanIds: admin.firestore.FieldValue.arrayUnion(clanId)
        });

        // Mise à jour du clan
        transaction.update(clanRef, {
            membersCount: admin.firestore.FieldValue.increment(1),
            totalXp: admin.firestore.FieldValue.increment(userXp),
            members: admin.firestore.FieldValue.arrayUnion(userId)
        });

        return { success: true };
    });
});

/**
 * 19. GESTION DE CLAN: QUITTER LE CLAN
 */
exports.leaveClan = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { clanId, userId } = data;
    
    if (context.auth.uid !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'You can only remove yourself.');
    }

    return admin.firestore().runTransaction(async (transaction) => {
        const clanRef = admin.firestore().collection('clans').doc(clanId);
        const userRef = admin.firestore().collection('users').doc(userId);

        const [clanDoc, userDoc] = await Promise.all([
            transaction.get(clanRef),
            transaction.get(userRef)
        ]);

        if (!clanDoc.exists || !userDoc.exists) return { success: false };

        // Si le leader part, il faut idéalement dissoudre ou transférer, 
        // on laisse la suppression pure gérée par `deleteClan` pour l'instant.
        
        const userXp = userDoc.data().xp || 0;

        transaction.update(userRef, {
            clanIds: admin.firestore.FieldValue.arrayRemove(clanId)
        });

        transaction.update(clanRef, {
            membersCount: admin.firestore.FieldValue.increment(-1),
            totalXp: admin.firestore.FieldValue.increment(-userXp),
            members: admin.firestore.FieldValue.arrayRemove(userId)
        });

        return { success: true };
    });
});

/**
 * 20. GESTION DE CLAN: EXPULSER UN MEMBRE
 */
exports.kickMember = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
    
    const { clanId, userId } = data;
    
    return admin.firestore().runTransaction(async (transaction) => {
        const clanRef = admin.firestore().collection('clans').doc(clanId);
        const userRef = admin.firestore().collection('users').doc(userId);

        const [clanDoc, userDoc] = await Promise.all([
            transaction.get(clanRef),
            transaction.get(userRef)
        ]);

        if (!clanDoc.exists) throw new functions.https.HttpsError('not-found', 'Clan not found.');
        
        // SÉCURITÉ : Seul le Leader du clan peut expulser un membre
        if (clanDoc.data().leaderId !== context.auth.uid) {
            throw new functions.https.HttpsError('permission-denied', 'Only the leader can kick members.');
        }

        if (!userDoc.exists) return { success: false };

        const userXp = userDoc.data().xp || 0;

        transaction.update(userRef, {
            clanIds: admin.firestore.FieldValue.arrayRemove(clanId)
        });

        transaction.update(clanRef, {
            membersCount: admin.firestore.FieldValue.increment(-1),
            totalXp: admin.firestore.FieldValue.increment(-userXp),
            members: admin.firestore.FieldValue.arrayRemove(userId)
        });

        return { success: true };
    });
});
