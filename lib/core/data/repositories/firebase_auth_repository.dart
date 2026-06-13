// lib/core/data/repositories/firebase_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Convertisseur (Mapper) d'un User de Firebase vers notre UserEntity pur.
  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      id: user.uid,
      username: user.displayName ?? "Alpha ${user.uid.substring(0, 4)}",
      email: user.email ?? "",
      level: 1, // Sera surchargé plus tard par Firestore
      xp: 0, // Sera surchargé plus tard par Firestore
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      profileImageUrl: user.photoURL,
      status: "online",
    );
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return _mapFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception(
          "Échec de la récupération de l'utilisateur après login",
        );
      }
      return _mapFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      // Gérer les codes d'erreur spécifiques de Firebase
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<UserEntity> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception(
          "Échec de la récupération de l'utilisateur après création",
        );
      }
      // Met à jour le profil avec le pseudo fourni par l'utilisateur
      await user.updateDisplayName(username);
      return _mapFirebaseUser(user).copyWith(username: username);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) throw Exception("Veuillez entrer une adresse email valide.");
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user != null) {
        return _mapFirebaseUser(user);
      }
      return null;
    });
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé pour cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Ce compte existe déjà.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'invalid-email':
        return 'Format d\'email invalide.';
      case 'invalid-credential':
        return 'Identifiants invalides (Email ou Mot de Passe incorrect).';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop d\'essais infructueux. Réessayez plus tard.';
      default:
        return 'Erreur d\'authentification : ${e.message}';
    }
  }
}
