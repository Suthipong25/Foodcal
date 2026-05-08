import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  bool _emailLoading = false;
  bool _googleLoading = false;
  String? error;
  bool _rememberMe = false;

  bool get _supportsGoogleSignIn =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

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
    if (!mounted) return;

    setState(() {
      _emailController.text = prefs.getString('remembered_email') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveCredentials({String? emailOverride}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(
        'remembered_email',
        (emailOverride ?? _emailController.text).trim(),
      );
      await prefs.setBool('remember_me', true);
      return;
    }

    await prefs.remove('remembered_email');
    await prefs.setBool('remember_me', false);
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => error = 'รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }

    setState(() {
      _emailLoading = true;
      error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context);
    try {
      await auth.signInWithEmailAndPassword(email, password);
      await _saveCredentials(emailOverride: email);
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = AuthService.handleAuthError(e.code));
    } catch (e) {
      setState(() => error = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _emailLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (!_supportsGoogleSignIn || _emailLoading || _googleLoading) {
      return;
    }

    setState(() {
      _googleLoading = true;
      error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    final navigator = Navigator.of(context);

    try {
      final credential = await auth.signInWithGoogle();
      final googleEmail = credential.user?.email;
      if (googleEmail != null && googleEmail.isNotEmpty) {
        _emailController.text = googleEmail;
      }
      await _saveCredentials(emailOverride: googleEmail);
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = AuthService.handleAuthError(e.code));
    } catch (e) {
      setState(() => error = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (!mounted || email == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $email แล้ว'),
      ),
    );
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
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _emailLoading || _googleLoading
                                  ? null
                                  : _showForgotPasswordDialog,
                              child: const Text('ลืมรหัสผ่าน?'),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                              onPressed: _emailLoading || _googleLoading
                                  ? null
                                  : () => _handleSubmit(context),
                              child: _emailLoading
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
                          const SizedBox(height: 18),
                          const _DividerLabel(label: 'หรือ'),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _supportsGoogleSignIn &&
                                      !_emailLoading &&
                                      !_googleLoading
                                  ? () => _handleGoogleSignIn(context)
                                  : null,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                  AppTheme.buttonHeight,
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: _googleLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _GoogleBadge(),
                                        const SizedBox(width: 12),
                                        Text(
                                          _supportsGoogleSignIn
                                              ? 'เข้าสู่ระบบด้วย Google'
                                              : 'Google Sign-In ยังไม่รองรับบนอุปกรณ์นี้',
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _emailLoading || _googleLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
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

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.pageTintStrong),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    return trimmed.isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'กรุณากรอกอีเมล');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _error = 'รูปแบบอีเมลไม่ถูกต้อง');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      await auth.sendPasswordResetEmail(email);
      if (mounted) {
        Navigator.of(context).pop(email);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.handleAuthError(e.code));
    } catch (e) {
      setState(() => _error = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text(
        'ลืมรหัสผ่าน',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppTheme.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กรอกอีเมลที่ใช้สมัคร แล้วเราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ให้',
            style: TextStyle(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'hello@example.com',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
            onSubmitted: (_) => _loading ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('ส่งลิงก์รีเซ็ต'),
        ),
      ],
    );
  }
}
