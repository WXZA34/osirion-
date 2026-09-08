// lib/core/domain/repositories/auth_repository.dart
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  /// Retourne l'utilisateur actuellement connecté, ou null s'il n'y en a pas.
  Future<UserEntity?> getCurrentUser();

  /// Connecte un utilisateur avec email et mot de passe.
  Future<UserEntity> signInWithEmail(String email, String password);

  /// Crée un nouveau compte et retourne l'utilisateur créé.
  Future<UserEntity> signUpWithEmail(
    String email,
    String password,
    String username,
  );

  /// Connecte un utilisateur via Google (crée le compte Firebase s'il n'existe pas).
  /// Retourne un UserEntity. S'il s'agit d'un nouveau compte, le champ `username` 
  /// sera temporaire et devra être complété côté UI.
  Future<UserEntity> signInWithGoogle();

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut();

  /// Envoie un email de réinitialisation de mot de passe
  Future<void> sendPasswordResetEmail(String email);

  /// Écoute les changements d'état d'authentification (login, logout, token expiry).
  Stream<UserEntity?> authStateChanges();
}
