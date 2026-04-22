import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => error = 'กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => error = 'รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context);
    try {
      await auth.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = AuthService.handleAuthError(e.code));
    } catch (e) {
      setState(() => error = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.maxContentWidth(screenWidth),
              ),
              child: SingleChildScrollView(
                padding: AppTheme.pageInsetsForWidth(
                  screenWidth,
                  top: 20,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, size: 18),
                      label: const Text('กลับ'),
                    ),
                    const SizedBox(height: 8),
                    _buildHero(isCompact),
                    const SizedBox(height: 18),
                    Container(
                      padding: EdgeInsets.all(isCompact ? 20 : 28),
                      decoration: AppTheme.elevatedCard(
                        borderColor: const Color(0xFFE3ECFA),
                        boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'สร้างบัญชีใหม่',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เริ่มต้นติดตามเป้าหมายสุขภาพของคุณด้วยโปรไฟล์เดียว',
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: AppTheme.body,
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 18),
                            _buildErrorBanner(error!),
                          ],
                          const SizedBox(height: 22),
                          _buildLabel('อีเมล'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'hello@example.com',
                              prefixIcon: Icon(LucideIcons.mail, size: 18),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('รหัสผ่าน'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(LucideIcons.lock, size: 18),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('ยืนยันรหัสผ่าน'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(
                                LucideIcons.shieldCheck,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  loading ? null : () => _handleRegister(context),
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('สมัครสมาชิก'),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.userPlus, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      decoration: AppTheme.tintedCard(AppTheme.accentColor),
      child: Row(
        children: [
          Container(
            width: isCompact ? 72 : 84,
            height: isCompact ? 72 : 84,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow(AppTheme.secondaryColor),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/Gemini_Generated_Image_9log6n9log6n9log.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foodcal',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'เริ่มต้นวางเป้าหมายอาหาร น้ำ และการดูแลตัวเองในแอปเดียว',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: AppTheme.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedText,
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.macroBg(AppTheme.error),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 18,
            color: AppTheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
