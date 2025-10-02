import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 🔹 Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      debugPrint("Error en Google Sign-In: $e");
      return null;
    }
  }

  /// 🔹 Login con Apple
  /*
  Future<User?> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) return null;

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Error en Apple Sign-In: $e");
      return null;
    }
  }*/

  /// 🔹 Simulación de login con Spotify (para pruebas, usa Firebase Anónimo)
  Future<User?> signInWithSpotifySimulated() async {
    try {
      final cred = await _auth.signInAnonymously();
      return cred.user;
    } catch (e) {
      debugPrint("Error en Spotify Simulado: $e");
      return null;
    }
  }

  /// 🔹 Login con Email/Password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint("Error en Email Sign-In: $e");
      return null;
    }
  }

  /// 🔹 Registro con Email/Password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint("Error en registro Email: $e");
      return null;
    }
  }

  /// 🔹 Logout
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// 🔹 Stream de usuario
  Stream<User?> get userStream => _auth.authStateChanges();
}
