
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In Anonymously (Guest)


  // Sign In with Email/Password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Register with Email/Password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Auth Errors (Centralized Translation)
  static String handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
      case 'user-disabled':
        return "บัญชีนี้ถูกระงับการใช้งาน";
      case 'too-many-requests':
        return "พยายามเข้าสู่ระบบมากเกินไป โปรดลองใหม่ในภายหลัง";
      case 'email-already-in-use':
        return "อีเมลนี้ถูกใช้งานแล้ว";
      case 'invalid-email':
        return "รูปแบบอีเมลไม่ถูกต้อง";
      case 'weak-password':
        return "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
      case 'operation-not-allowed':
        return "การสมัครสมาชิกทางอีเมลยังไม่เปิดใช้งาน";
      default:
        return "เกิดข้อผิดพลาดในการยืนยันตัวตน ($errorCode)";
    }
  }
}
