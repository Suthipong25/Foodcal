
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const ProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  String _selectedGoal = 'maintain';
  bool _isUploading = false;
  String? _localPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.profile.weight.toString());
    _heightCtrl = TextEditingController(text: widget.profile.height.toString());
    _ageCtrl = TextEditingController(text: widget.profile.age.toString());
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
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }
  
  // Update init state if profile changes? 
  // For now assume profile is key or won't change drastically without this widget rebuilding.
  
  Future<void> _save() async {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    final a = int.tryParse(_ageCtrl.text);
    
    if (w != null && h != null && a != null) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        // Recalculate stats
         final stats = FirestoreService.calculateStats(w, h, a, widget.profile.gender, widget.profile.activityLevel, _selectedGoal);
         
         final newProfile = UserProfile(
           uid: widget.profile.uid,
           name: widget.profile.name,
           gender: widget.profile.gender,
           age: a,
           height: h,
           weight: w,
           activityLevel: widget.profile.activityLevel,
           goal: _selectedGoal,
           tdee: stats['tdee']!,
           targetCalories: stats['targetCalories']!,
           targetProtein: stats['targetProtein']!,
           targetCarbs: stats['targetCarbs']!,
           targetFat: stats['targetFat']!,
           targetWaterGlasses: stats['targetWaterGlasses']!,
           joinedDate: widget.profile.joinedDate,
           streak: widget.profile.streak,
           photoUrl: widget.profile.photoUrl,
         );

        await Provider.of<FirestoreService>(context, listen: false).saveUserProfile(user.uid, newProfile);
        setState(() {
          isEditing = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 256, imageQuality: 50);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final firestore = Provider.of<FirestoreService>(context, listen: false);
        final bytes = await image.readAsBytes();
        
        // Encode to Base64
        final String base64String = base64Encode(bytes);
        final String dataUrl = 'data:image/jpeg;base64,$base64String';
        
        // Update Firestore
        final updatedProfile = widget.profile;
        updatedProfile.photoUrl = dataUrl;
        await firestore.saveUserProfile(widget.profile.uid, updatedProfile);
        
        if (mounted) {
          setState(() {
            _localPhotoUrl = dataUrl;
          });
        }
      } catch (e) {
        print('Error saving profile picture: $e');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppTheme.cardRadius,
              boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
            ),
            child: Column(
              children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     GestureDetector(
                       onTap: () {
                         if (isEditing) {
                            setState(() => isEditing = false);
                         } else {
                            // Reset values on edit start
                            _weightCtrl.text = widget.profile.weight.toString();
                            _heightCtrl.text = widget.profile.height.toString();
                            _ageCtrl.text = widget.profile.age.toString();
                            setState(() {
                              _selectedGoal = widget.profile.goal;
                              isEditing = true;
                            });
                         }
                       },
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                         child: Icon(isEditing ? LucideIcons.x : LucideIcons.edit2, color: Colors.white, size: 20),
                       ),
                     )
                   ],
                 ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                            image: _localPhotoUrl != null 
                              ? DecorationImage(
                                  image: _localPhotoUrl!.startsWith('data:') 
                                    ? MemoryImage(base64Decode(_localPhotoUrl!.split(',')[1])) as ImageProvider
                                    : NetworkImage(_localPhotoUrl!),
                                  fit: BoxFit.cover
                                )
                              : null,
                          ),
                          child: _localPhotoUrl == null 
                            ? Center(
                                child: Text(
                                  widget.profile.name.isNotEmpty ? widget.profile.name[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor.withOpacity(0.5)),
                                ),
                              )
                            : null,
                        ),
                        if (_isUploading)
                          const Positioned.fill(child: CircularProgressIndicator(color: Colors.white)),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(LucideIcons.camera, size: 14, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                 const SizedBox(height: 12),
                 Text(widget.profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                 
                 if (isEditing)
                   Container(
                     margin: const EdgeInsets.only(top: 8),
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                     decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                     child: DropdownButton<String>(
                       value: _selectedGoal,
                        dropdownColor: Colors.blue[600],
                       icon: const Icon(LucideIcons.chevronDown, color: Colors.white, size: 16),
                       underline: const SizedBox(),
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       onChanged: (v) {
                         if (v != null) setState(() => _selectedGoal = v);
                       },
                       items: ['lose', 'maintain', 'gain'].map((g) {
                         return DropdownMenuItem(value: g, child: Text(_getGoalLabel(g)));
                       }).toList(),
                     ),
                   )
                 else
                   Text('เป้าหมาย: ${_getGoalLabel(widget.profile.goal)}', style: TextStyle(color: Colors.blue[50], fontSize: 13, fontWeight: FontWeight.w500)),
                 
                 const SizedBox(height: 12),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Stats Card
          Container(
            padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.blue[50]!),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     const Text('ข้อมูลร่างกาย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     if(isEditing)
                       GestureDetector(
                         onTap: _save,
                          child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                             decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
                             child: const Row(children: [Icon(LucideIcons.save, size: 14, color: Colors.white), SizedBox(width:4), Text('บันทึก', style: TextStyle(color:Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]),
                          ),
                       )
                   ],
                ),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildInfoCard('เป้าหมาย', '${widget.profile.targetCalories} kcal', LucideIcons.target),
                    _buildInfoCard('อัตราเผาผลาญ', '${widget.profile.tdee} kcal', LucideIcons.flame),
                    isEditing 
                      ? _buildEditCard('น้ำหนัก (kg)', _weightCtrl)
                      : _buildInfoCard('น้ำหนัก', '${widget.profile.weight} kg', LucideIcons.activity),
                    isEditing 
                      ? _buildEditCard('ส่วนสูง (cm)', _heightCtrl)
                      : _buildInfoCard('ส่วนสูง', '${widget.profile.height} cm', LucideIcons.activity),
                    isEditing 
                      ? _buildEditCard('อายุ (ปี)', _ageCtrl)
                      : _buildInfoCard('อายุ', '${widget.profile.age} ปี', LucideIcons.calendar),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Menu
          GestureDetector(
            onTap: () async {
               await Provider.of<AuthService>(context, listen: false).signOut();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50], 
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.logOut, color: Colors.red),
                  SizedBox(width: 16),
                  Text('ออกจากระบบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              )
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEditCard(String label, TextEditingController ctrl) {
      return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.macroBg(AppTheme.primaryColor), borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
           TextField(
             controller: ctrl,
             textAlign: TextAlign.center,
             keyboardType: TextInputType.number,
             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
             decoration: const InputDecoration(border: InputBorder.none, isDense: true),
           )
        ],
      ),
    );
  }

  String _getGoalLabel(String g) {
    if (g == 'lose') return 'ลดน้ำหนัก';
    if (g == 'gain') return 'เพิ่มกล้ามเนื้อ';
    return 'รักษาน้ำหนัก';
  }
}
