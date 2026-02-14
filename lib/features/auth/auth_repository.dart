import 'package:firebase_auth/firebase_auth.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapSignInError(error));
    } catch (_) {
      throw const AuthFailure('Ocurrio un error inesperado. Intentalo de nuevo.');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (_) {
      throw const AuthFailure('No se pudo cerrar sesion. Intentalo de nuevo.');
    } catch (_) {
      throw const AuthFailure('No se pudo cerrar sesion. Intentalo de nuevo.');
    }
  }

  String _mapSignInError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electronico no es valido.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Credenciales incorrectas.';
      case 'user-disabled':
        return 'Tu cuenta fue deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexion. Verifica tu internet.';
      default:
        return 'No fue posible iniciar sesion. Intentalo de nuevo.';
    }
  }
}
