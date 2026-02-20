
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister(BuildContext context) async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => error = "กรุณากรอกข้อมูลให้ครบถ้วน");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => error = "รหัสผ่านไม่ตรงกัน");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Success: AuthWrapper in main.dart will react and show MainScreen/Onboarding
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = AuthService.handleAuthError(e.code);
      });
    } catch (e) {
      setState(() => error = "เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20)]
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Gemini_Generated_Image_9log6n9log6n9log.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'สมัครสมาชิก',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 40),

              // Form Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.blue[50]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(error!, style: TextStyle(color: Colors.red[800], fontSize: 13))),
                          ],
                        ),
                      ),

                    // Email Input
                    Text('อีเมล', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[300])
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.mail, color: Colors.blueGrey, size: 20),
                        filled: true,
                        fillColor: Colors.blue[50]?.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'hello@example.com',
                        hintStyle: TextStyle(color: Colors.blueGrey[200]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Input
                    Text('รหัสผ่าน', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[300])
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.blueGrey, size: 20),
                        filled: true,
                        fillColor: Colors.blue[50]?.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: Colors.blueGrey[200]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Input
                    Text('ยืนยันรหัสผ่าน', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[300])
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.lock, color: Colors.blueGrey, size: 20),
                        filled: true,
                        fillColor: Colors.blue[50]?.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: Colors.blueGrey[200]),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: loading ? null : () => _handleRegister(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.innerRadius),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('สมัครสมาชิก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(width: 8),
                                Icon(LucideIcons.userPlus, size: 18),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                        style: TextStyle(color: Colors.blueAccent[100], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
