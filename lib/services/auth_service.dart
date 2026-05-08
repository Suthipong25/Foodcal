import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
  );

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In with Email/Password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with Email/Password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      return _auth.signInWithPopup(provider);
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(code: 'sign-in-cancelled');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return _auth.signInWithCredential(credential);
      default:
        throw FirebaseAuthException(code: 'google-sign-in-not-supported');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut().catchError((_) => null);
    await _auth.signOut();
  }

  // Handle Auth Errors (Centralized Translation)
  static String handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบมากเกินไป โปรดลองใหม่ในภายหลัง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'operation-not-allowed':
        return 'ระบบยังไม่เปิดใช้งานช่องทางเข้าสู่ระบบนี้ (โปรดตั้งค่าใน Firebase Console)';
      case 'network-request-failed':
        return 'เชื่อมต่อเครือข่ายไม่สำเร็จ ลองใหม่อีกครั้ง';
      case 'account-exists-with-different-credential':
        return 'อีเมลนี้มีบัญชีอยู่แล้ว โปรดเข้าสู่ระบบด้วยวิธีเดิมก่อน';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'sign-in-cancelled':
        return 'ยกเลิกการเข้าสู่ระบบด้วย Google';
      case 'google-sign-in-not-supported':
        return 'แพลตฟอร์มนี้ยังไม่รองรับ Google Sign-In';
      case 'invalid-action-code':
        return 'ลิงก์หรือคำขอรีเซ็ตรหัสผ่านไม่ถูกต้องหรือหมดอายุ';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน ($errorCode)';
    }
  }
}
