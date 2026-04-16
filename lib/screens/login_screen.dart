import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool loading = false;
  String? error;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('remembered_email') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
      return;
    }
    await prefs.remove('remembered_email');
    await prefs.setBool('remember_me', false);
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => error = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context);
    try {
      await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await _saveCredentials();
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
                            'ยินดีต้อนรับกลับ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เข้าสู่ระบบเพื่อติดตามอาหาร น้ำ และเป้าหมายของคุณ',
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
                          const SizedBox(height: 14),
                          InkWell(
                            borderRadius: AppTheme.innerRadius,
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppTheme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'จดจำการเข้าสู่ระบบ',
                                      style: TextStyle(
                                        color: AppTheme.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  loading ? null : () => _handleSubmit(context),
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
                                        Text('เข้าสู่ระบบ'),
                                        SizedBox(width: 8),
                                        Icon(LucideIcons.arrowRight, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'ยังไม่มีบัญชี? สมัครสมาชิก',
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
      decoration: AppTheme.tintedCard(AppTheme.secondaryColor),
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
                  'สุขภาพดี เริ่มต้นได้ที่นี่',
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
        border: Border.all(color: AppTheme.error.withOpacity(0.14)),
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
