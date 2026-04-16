import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
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
  String _selectedGoal = 'maintain';
  bool _isUploading = false;
  String? _localPhotoUrl;
  Uint8List? _localImageBytes; // แสดงรูปจากเครื่องทันที ก่อน upload เสร็จ
  final ImagePicker _picker = ImagePicker();

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
                (DateTime.now().year - widget.profile.age))
            .toString());
    _selectedGoal = widget.profile.goal;
    _localPhotoUrl = widget.profile.photoUrl;
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

    final now = DateTime.now();
    int a = now.year - by;
    if (now.month < bm) a--;
    if (a <= 0) a = 1;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final stats = FirestoreService.calculateStats(
        w, h, a,
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
        photoUrl: widget.profile.photoUrl,
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
      debugPrint('Save profile error: $e');
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

    // Upload ใน background
    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final storage = Provider.of<StorageService>(context, listen: false);
      final photoUrl = await storage.uploadProfilePicture(widget.profile.uid, bytes);

      if (photoUrl == null) throw Exception('Upload failed.');

      await firestore.saveUserProfile(
        widget.profile.uid,
        widget.profile.copyWith(photoUrl: photoUrl),
      );

      if (mounted) {
        setState(() {
          _localPhotoUrl = photoUrl;
          _localImageBytes = null; // ใช้ URL จริงแทนแล้ว
        });
      }
    } catch (e) {
      debugPrint('Error saving profile picture: $e');
      if (mounted) {
        // ถ้า upload fail ให้ rollback รูปกลับ
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

    return Center(
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
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.1,
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
              _buildFeedbackCard(context),
              if (widget.profile.role == 'admin') ...[
                const SizedBox(height: 12),
                _buildAdminCard(context),
              ],
              const SizedBox(height: AppTheme.sectionGap),
              _buildLogoutCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.tintedCard(AppTheme.primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              _buildEditButton(),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        image: _localImageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(_localImageBytes!),
                                fit: BoxFit.cover,
                              )
                            : _localPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_localPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                        boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
                      ),
                      child: (_localImageBytes == null && _localPhotoUrl == null)
                          ? Center(
                              child: Text(
                                widget.profile.name.isNotEmpty
                                    ? widget.profile.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 34,
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
                            color: Colors.black.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: AppTheme.meta,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.profile.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'เป้าหมาย: ${_getGoalLabel(isEditing ? _selectedGoal : widget.profile.goal)}',
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: AppTheme.body,
                      ),
                    ),
                    if (!isEditing && widget.profile.estimatedGoalDays > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'คาดว่าจะถึงในอีก ${widget.profile.estimatedGoalDays} วัน',
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTheme.meta,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: AppTheme.innerRadius,
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _goalSummary(isEditing
                                  ? _selectedGoal
                                  : widget.profile.goal),
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: AppTheme.body,
                                fontWeight: FontWeight.w600,
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
                  (DateTime.now().year - widget.profile.age))
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
          color: Colors.white.withOpacity(0.9),
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

  Widget _buildMetricCard(
    String label,
    String value,
    String hint,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.elevatedCard(
        borderColor: color.withOpacity(0.14),
        boxShadow: AppTheme.softShadow(color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.macroBg(color),
              borderRadius: AppTheme.innerRadius,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.meta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
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
                    fontSize: AppTheme.title,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: AppTheme.pillRadius,
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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'ปรับค่านี้เพื่อให้ระบบคำนวณแคลอรี่และเป้าหมายรายวันได้แม่นยำขึ้น',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.body,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              isEditing
                  ? _buildEditCard('น้ำหนัก (kg)', _weightCtrl)
                  : _buildInfoCard('น้ำหนัก', '${widget.profile.weight} kg',
                      LucideIcons.scale),
              isEditing
                  ? _buildEditCard('ส่วนสูง (cm)', _heightCtrl)
                  : _buildInfoCard(
                      'ส่วนสูง',
                      '${widget.profile.height} cm',
                      LucideIcons.ruler,
                    ),
              if (isEditing) ...[
                _buildEditCard('เป้าหมาย (kg)', _targetWeightCtrl),
                _buildEditCard('เดือนเกิด (1-12)', _birthMonthCtrl),
                _buildEditCard('ปีเกิด (ค.ศ.)', _birthYearCtrl),
              ] else ...[
                _buildInfoCard(
                    'น้ำหนักในฝัน',
                    '${widget.profile.targetWeight ?? '-'} kg',
                    LucideIcons.target),
                _buildInfoCard(
                    'อายุ', '${widget.profile.age} ปี', LucideIcons.calendar),
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
        color: AppTheme.pageTint,
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.pageTintStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.innerRadius,
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
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
        color: AppTheme.macroBg(AppTheme.primaryColor),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextField(
            controller: ctrl,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: AppTheme.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: 'กรอกข้อมูล',
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
          color: AppTheme.macroBg(AppTheme.secondaryColor),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เป้าหมาย',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: AppTheme.meta,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedGoal,
              isExpanded: true,
              underline: const SizedBox(),
              borderRadius: AppTheme.innerRadius,
              items: ['lose', 'maintain', 'gain']
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        _getGoalLabel(g),
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w700,
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.macroBg(AppTheme.error),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: AppTheme.error.withOpacity(0.18)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.logOut, color: AppTheme.error),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'ใช้เมื่อต้องการเปลี่ยนบัญชีหรือหยุดใช้งานชั่วคราว',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: AppTheme.meta,
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.messageSquare, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ส่งข้อเสนอแนะ',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  SizedBox(height: 2),
                  Text('ช่วยเราปรับปรุงแอปให้ดีขึ้น',
                      style: TextStyle(
                          color: AppTheme.mutedText, fontSize: AppTheme.meta)),
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
          MaterialPageRoute(
              builder: (_) => AdminScreen(profile: widget.profile)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.shield, color: Colors.deepPurple),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  SizedBox(height: 2),
                  Text('ดูสถิติและข้อเสนอแนะบัญชีผู้ดูแล',
                      style: TextStyle(
                          color: AppTheme.mutedText, fontSize: AppTheme.meta)),
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
    if (g == 'lose') return 'ลดน้ำหนัก';
    if (g == 'gain') return 'เพิ่มกล้ามเนื้อ';
    return 'รักษาน้ำหนัก';
  }

  String _goalSummary(String goal) {
    if (goal == 'lose') {
      return 'โฟกัสขาดดุลพลังงานแบบพอดี เพื่อค่อยๆ ลดไขมันอย่างยั่งยืน';
    }
    if (goal == 'gain') {
      return 'โฟกัสพลังงานและโปรตีนให้พอ เพื่อเสริมการสร้างกล้ามเนื้อ';
    }
    return 'โฟกัสสมดุลพลังงาน เพื่อคงรูปร่างและสุขภาพโดยรวม';
  }
}
