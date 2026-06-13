import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload une image de profil utilisateur depuis la mémoire
  Future<String> uploadUserProfileImage(
    String userId,
    Uint8List imageData,
  ) async {
    try {
      final ref = _storage.ref().child('users/$userId/avatar.jpg');

      // Ajout de metadata pour être sûr du type
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(imageData, metadata);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image de profil : $e');
    }
  }

  /// Upload un logo de clan depuis la mémoire
  Future<String> uploadClanLogo(String clanId, Uint8List imageData) async {
    try {
      final ref = _storage.ref().child('clans/$clanId/logo.jpg');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(imageData, metadata);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du logo du clan : $e');
    }
  }

  /// Upload un fichier générique vers Firebase Storage (ex: Audio, Performance Card)
  Future<String> uploadGenericFile(
    String destination,
    Uint8List data, {
    SettableMetadata? metadata,
  }) async {
    try {
      final ref = _storage.ref().child(destination);
      await ref.putData(data, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Erreur lors de l\'upload du fichier : $e');
    }
  }

  /// Supprime un fichier à partir de son URL de téléchargement
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // On ignore l'erreur si le fichier n'existe déjà plus (ou log)
      debugPrint('⚠️ [StorageService] Erreur suppression fichier: $e');
    }
  }
}
