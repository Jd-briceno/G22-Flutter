import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 🔹 Crea documento base del usuario si no existe
  Future<void> _createUserDocIfNeeded(User user) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint("🆕 Creando documento Firestore inicial para ${user.email}");
        await docRef.set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'profileStage': 'created', // 👈 nueva bandera
        });

        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        debugPrint("📄 Documento Firestore ya existe para ${user.email}");
      }
    } catch (e, st) {
      debugPrint("❌ Error creando documento Firestore: $e\n$st");
    }
  }


  /// 🔹 Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user != null) await _createUserDocIfNeeded(user);

        debugPrint("✅ Google login (Web) completado: ${user?.email}");
        return user;
      } else {
        debugPrint("🚀 Iniciando Google Sign-In...");

        // 👇 Forzar limpieza previa
        await _googleSignIn.signOut();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint("⚠️ Usuario canceló el login o GoogleSignIn falló.");
          return null;
        }

        debugPrint("📧 Cuenta seleccionada: ${googleUser.email}");
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) await _createUserDocIfNeeded(user);

        debugPrint("✅ Firebase login completado: ${user?.email}");
        return user;
      }
    } catch (e, st) {
      debugPrint("❌ Error en Google Sign-In: $e\n$st");
      return null;
    }
  }

  /// 🔹 Simulación de login con Spotify (para pruebas)
  Future<User?> signInWithSpotifySimulated() async {
    try {
      final cred = await _auth.signInAnonymously();
      final user = cred.user;
      if (user != null) await _createUserDocIfNeeded(user);
      return user;
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
      final user = credential.user;
      if (user != null) await _createUserDocIfNeeded(user);
      return user;
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
      final user = credential.user;
      if (user != null) await _createUserDocIfNeeded(user);
      return user;
    } catch (e) {
      debugPrint("Error en registro Email: $e");
      return null;
    }
  }

  /// 🔹 Cierra sesión completamente (Firebase + Google)
  Future<void> signOut() async {
    try {
      final currentUser = _auth.currentUser;
      final providerIds = currentUser?.providerData.map((p) => p.providerId).toList() ?? [];

      if (providerIds.contains("google.com")) {
        try {
          if (await _googleSignIn.isSignedIn()) {
            await _googleSignIn.signOut();
          }
        } catch (e) {
          debugPrint("⚠️ Error cerrando sesión Google: $e");
        }
      }

      await _auth.signOut();
      debugPrint("✅ Usuario desconectado correctamente");
    } catch (e, st) {
      debugPrint("❌ Error al cerrar sesión: $e\n$st");
    }
  }

  /// 🔹 Stream para escuchar cambios en la sesión
  Stream<User?> get userStream => _auth.authStateChanges();

  /// 🔹 Getter rápido para obtener el usuario actual
  User? get currentUser => _auth.currentUser;
}
