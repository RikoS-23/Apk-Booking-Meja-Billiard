import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Future<User> register({
  required String nama,
  required String email,
  required String password,
}) async {
  try {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );

    final user = cred.user!;
    await _db.collection('users').doc(user.uid).set({
      'nama': nama.trim(),
      'email': email.trim().toLowerCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  } on FirebaseAuthException catch (e) {
    throw _mapAuthError(e);
  } catch (_) {
    await _auth.currentUser?.delete();
    throw Exception("Gagal menyimpan data pengguna");
  }
}
  /// =======================
  /// LOGIN
  /// =======================
  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }


  /// =======================
  /// LOGOUT
  /// =======================
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  /// =======================
  /// ERROR MAPPER
  /// =======================
  Exception _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception("Email sudah terdaftar");
      case 'invalid-email':
        return Exception("Format email tidak valid");
      case 'weak-password':
        return Exception("Password terlalu lemah");
      case 'user-not-found':
        return Exception("Akun tidak ditemukan");
      case 'wrong-password':
        return Exception("Password salah");
      default:
        return Exception("Terjadi kesalahan autentikasi");
    }
  }
}
