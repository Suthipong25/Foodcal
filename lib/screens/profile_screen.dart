import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../constants/enums.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_logger.dart';
import '../utils/datetime_utils.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/glass_card.dart';
import 'admin_screen.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _birthMonthCtrl;
  late TextEditingController _birthYearCtrl;
  String _selectedGoal = HealthGoal.maintain.value;
  bool _isUploading = false;
  String? _localPhotoUrl;
  Uint8List? _localImageBytes; // แสดงรูปจากเครื่องทันที ก่อน upload เสร็จ
  final ImagePicker _picker = ImagePicker();

  Map<String, bool> _reminderSettings = {
    'water': true,
    'food': true,
    'weight': true,
  };

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.profile.weight.toString());
    _targetWeightCtrl = TextEditingController(
        text:
            (widget.profile.targetWeight ?? widget.profile.weight).toString());
    _heightCtrl = TextEditingController(text: widget.profile.height.toString());
    _birthMonthCtrl = TextEditingController(
        text: (widget.profile.birthMonth ?? 1).toString());
    _birthYearCtrl = TextEditingController(
        text: (widget.profile.birthYear ??
                (DateTimeUtils.now().year - widget.profile.age))
            .toString());
    _selectedGoal = widget.profile.goal;
    _localPhotoUrl = widget.profile.photoUrl;

    ReminderService.getSettings().then((s) {
      if (mounted) setState(() => _reminderSettings = s);
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.photoUrl != oldWidget.profile.photoUrl) {
      setState(() {
        _localPhotoUrl = widget.profile.photoUrl;
      });
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _heightCtrl.dispose();
    _birthMonthCtrl.dispose();
    _birthYearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final tw = double.tryParse(_targetWeightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final bm = int.tryParse(_birthMonthCtrl.text);
    final by = int.tryParse(_birthYearCtrl.text);

    if (w == null || tw == null || h == null || bm == null || by == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบและถูกต้อง')),
      );
      return;
    }

    final now = DateTimeUtils.now();
    int a = now.year - by;
    if (now.month < bm) a--;
    if (a <= 0) a = 1;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final stats = FirestoreService.calculateStats(
        w,
        h,
        a,
        widget.profile.gender,
        widget.profile.activityLevel,
        _selectedGoal,
      );

      final newProfile = UserProfile(
        uid: widget.profile.uid,
        name: widget.profile.name,
        gender: widget.profile.gender,
        birthMonth: bm,
        birthYear: by,
        legacyAge: a,
        height: h,
        weight: w,
        targetWeight: tw,
        activityLevel: widget.profile.activityLevel,
        goal: _selectedGoal,
        tdee: stats['tdee']!,
        targetCalories: stats['targetCalories']!,
        targetProtein: stats['targetProtein']!,
        targetCarbs: stats['targetCarbs']!,
        targetFat: stats['targetFat']!,
        targetWaterGlasses: stats['targetWaterGlasses']!,
        joinedDate: widget.profile.joinedDate,
        lastLoginDate: widget.profile.lastLoginDate,
        streak: widget.profile.streak,
        photoUrl: _localPhotoUrl ?? widget.profile.photoUrl,
      );

      await Provider.of<FirestoreService>(context, listen: false)
          .saveUserProfile(user.uid, newProfile);

      if (mounted) {
        setState(() => isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ ✓')),
        );
      }
    } catch (e) {
      AppLogger.error('Save profile error', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 72,
    );
    if (image == null) return;
    if (!mounted) return;

    final bytes = await image.readAsBytes();

    // แสดงรูปจากเครื่องทันที — ผู้ใช้ไม่ต้องรอ upload
    setState(() {
      _localImageBytes = bytes;
      _isUploading = true;
    });

    if (!mounted) return;

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final base64Image = base64Encode(bytes);
      final photoUrl = 'data:image/jpeg;base64,$base64Image';

      await firestore.updateProfilePicture(widget.profile.uid, photoUrl);

      if (mounted) {
        setState(() {
          _localPhotoUrl = photoUrl;
          _localImageBytes = null;
        });
      }
    } catch (e) {
      AppLogger.error('Error saving profile picture', e);
      if (mounted) {
        setState(() => _localImageBytes = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ กรุณาลองอีกครั้ง')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AppTheme.maxContentWidth(screenWidth),
          ),
          child: SingleChildScrollView(
            padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: AppTheme.sectionGap),
                _buildSectionHeader(
                  'ภาพรวมของคุณ',
                  'โปรไฟล์นี้สรุปเป้าหมายและค่าที่ใช้คำนวณแผนรายวันของแอป',
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.05,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildMetricCard(
                      'เป้าหมายแคลอรี่',
                      '${widget.profile.targetCalories}',
                      'kcal ต่อวัน',
                      LucideIcons.target,
                      AppTheme.primaryColor,
                    ),
                    _buildMetricCard(
                      'อัตราเผาผลาญ',
                      '${widget.profile.tdee}',
                      'kcal โดยประมาณ',
                      LucideIcons.flame,
                      AppTheme.warning,
                    ),
                    _buildMetricCard(
                      'ดื่มน้ำ',
                      '${widget.profile.targetWaterGlasses}',
                      'แก้วต่อวัน',
                      LucideIcons.droplets,
                      AppTheme.waterColor,
                    ),
                    _buildMetricCard(
                      'สตรีก',
                      '${widget.profile.streak}',
                      'วันต่อเนื่อง',
                      LucideIcons.badgeCheck,
                      AppTheme.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sectionGap),
                _buildEditPanel(),
                const SizedBox(height: AppTheme.sectionGap),
                _buildReminderSettings(),
                const SizedBox(height: AppTheme.sectionGap),
                _buildFeedbackCard(context),
                if (UserRole.fromString(widget.profile.role) == UserRole.admin) ...[
                  const SizedBox(height: 12),
                  _buildAdminCard(context),
                ],
                const SizedBox(height: AppTheme.sectionGap),
                _buildLogoutCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              _buildEditButton(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                        image: _localImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_localImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : _localPhotoUrl != null
                                ? DecorationImage(
                                    image: _localPhotoUrl!.startsWith('data:')
                                        ? MemoryImage(base64Decode(_localPhotoUrl!.split(',')[1])) as ImageProvider
                                        : NetworkImage(_localPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
                      ),
                      child: (_localImageBytes == null && _localPhotoUrl == null)
                          ? Center(
                              child: Text(
                                widget.profile.name.isNotEmpty ? widget.profile.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profile.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เป้าหมาย: ${_getGoalLabel(isEditing ? _selectedGoal : widget.profile.goal)}',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isEditing && widget.profile.estimatedGoalDays > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'คาดว่าจะถึงในอีก ${widget.profile.estimatedGoalDays} วัน',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      opacity: 0.1,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _goalSummary(isEditing ? _selectedGoal : widget.profile.goal),
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        if (isEditing) {
          setState(() => isEditing = false);
        } else {
          _weightCtrl.text = widget.profile.weight.toString();
          _targetWeightCtrl.text =
              (widget.profile.targetWeight ?? widget.profile.weight).toString();
          _heightCtrl.text = widget.profile.height.toString();
          _birthMonthCtrl.text = (widget.profile.birthMonth ?? 1).toString();
          _birthYearCtrl.text = (widget.profile.birthYear ??
                  (DateTimeUtils.now().year - widget.profile.age))
              .toString();
          setState(() {
            _selectedGoal = widget.profile.goal;
            isEditing = true;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: AppTheme.pillRadius,
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEditing ? LucideIcons.x : LucideIcons.pencil,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'ยกเลิก' : 'แก้ไขข้อมูล',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.title,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: AppTheme.body,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String hint, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      opacity: 0.08,
      borderColor: color.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPanel() {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ข้อมูลร่างกาย',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: AppTheme.pillRadius,
                      boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.save, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'บันทึก',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'ปรับค่านี้เพื่อให้ระบบคำนวณเป้าหมายรายวันได้แม่นยำขึ้น',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.body,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              isEditing
                  ? _buildEditCard('น้ำหนัก (kg)', _weightCtrl)
                  : _buildInfoCard('น้ำหนัก', '${widget.profile.weight} kg', LucideIcons.scale),
              isEditing
                  ? _buildEditCard('ส่วนสูง (cm)', _heightCtrl)
                  : _buildInfoCard(
                      'ส่วนสูง',
                      '${widget.profile.height} cm',
                      LucideIcons.ruler,
                    ),
              if (isEditing) ...[
                _buildEditCard('เป้าหมาย (kg)', _targetWeightCtrl),
                _buildEditCard('ปีเกิด (ค.ศ.)', _birthYearCtrl),
              ] else ...[
                _buildInfoCard('น้ำหนักเป้าหมาย', '${widget.profile.targetWeight ?? '-'} kg', LucideIcons.target),
                _buildInfoCard('อายุ', '${widget.profile.age} ปี', LucideIcons.calendar),
              ],
              _buildGoalCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 16),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard(String label, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          TextField(
            controller: ctrl,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: AppTheme.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '0',
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    if (isEditing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เป้าหมาย',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedGoal,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(LucideIcons.chevronDown, size: 16),
              borderRadius: AppTheme.innerRadius,
              items: HealthGoal.values
                  .map((goal) => goal.value)
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        _getGoalLabel(g),
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedGoal = v);
              },
            ),
          ],
        ),
      );
    }

    return _buildInfoCard(
      'เป้าหมาย',
      _getGoalLabel(widget.profile.goal),
      LucideIcons.target,
    );
  }

  Widget _buildLogoutCard() {
    return GestureDetector(
      onTap: () async {
        await Provider.of<AuthService>(context, listen: false).signOut();
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        opacity: 0.1,
        borderColor: AppTheme.error.withValues(alpha: 0.2),
        child: const Row(
          children: [
            Icon(LucideIcons.logOut, color: AppTheme.error),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ต้องการหยุดใช้งานชั่วคราว?',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
        );
      },
      child: const GlassCard(
        padding: EdgeInsets.all(20),
        opacity: 0.08,
        child: Row(
          children: [
            Icon(LucideIcons.messageSquare, color: AppTheme.primaryColor),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ส่งข้อเสนอแนะ', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('ช่วยเราปรับปรุงแอปให้ดีขึ้น', style: TextStyle(color: AppTheme.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppTheme.mutedText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminScreen(profile: widget.profile)),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        opacity: 0.08,
        borderColor: Colors.deepPurple.withValues(alpha: 0.2),
        child: const Row(
          children: [
            Icon(LucideIcons.shield, color: Colors.deepPurple),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('จัดการระบบและข้อมูลผู้ใช้', style: TextStyle(color: AppTheme.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: AppTheme.mutedText, size: 20),
          ],
        ),
      ),
    );
  }

  String _getGoalLabel(String g) {
    return HealthGoal.fromString(g).displayName;
  }

  String _goalSummary(String goal) {
    if (goal == HealthGoal.lose.value) {
      return 'ลดน้ำหนักแบบยั่งยืน';
    }
    if (goal == HealthGoal.gain.value) {
      return 'เน้นการสร้างกล้ามเนื้อ';
    }
    return 'เน้นสุขภาพและสมดุล';
  }

  Widget _buildReminderSettings() {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การแจ้งเตือนในแอป',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'เลือกเปิด/ปิดแบนเนอร์แจ้งเตือนในหน้าแรก',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildToggle('เตือนดื่มน้ำ', 'water', LucideIcons.droplet, AppTheme.waterColor),
          const Divider(height: 24),
          _buildToggle('เตือนบันทึกอาหาร', 'food', LucideIcons.utensils, AppTheme.primaryColor),
          const Divider(height: 24),
          _buildToggle('เตือนชั่งน้ำหนัก', 'weight', LucideIcons.scale, AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String key, IconData icon, Color color) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink, fontSize: 15)),
        ],
      ),
      value: _reminderSettings[key] ?? true,
      activeThumbColor: color,
      onChanged: (val) async {
        setState(() => _reminderSettings[key] = val);
        await ReminderService.setSetting(key, val);
      },
    );
  }
}

