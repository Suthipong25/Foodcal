
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lucide_icons/lucide_icons.dart'; 
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart'; 

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 1;
  final _nameController = TextEditingController();
  String gender = 'male';
  int age = 25;
  double height = 170;
  double weight = 60;
  String activityLevel = 'moderate';
  String goal = 'maintain'; // Default goal
  bool loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = auth.currentUser;

      if (user != null) {
        // Pass the selected goal
        final stats = FirestoreService.calculateStats(weight, height, age, gender, activityLevel, goal);
        
        final profile = UserProfile(
          uid: user.uid,
          name: _nameController.text.isEmpty ? 'User' : _nameController.text,
          gender: gender,
          age: age,
          height: height,
          weight: weight,
          activityLevel: activityLevel,
          goal: goal,
          tdee: stats['tdee']!,
          targetCalories: stats['targetCalories']!,
          targetProtein: stats['targetProtein']!,
          targetCarbs: stats['targetCarbs']!,
          targetFat: stats['targetFat']!,
          targetWaterGlasses: stats['targetWaterGlasses']!,
          joinedDate: DateTime.now(),
          lastLoginDate: DateTime.now(),
          streak: 1,
        );

        await firestore.saveUserProfile(user.uid, profile);
        debugPrint('Profile saved successfully for ${user.uid}');
      } else {
        throw Exception('User is null');
      }
    } on FirebaseException catch (e) {
      debugPrint('Error saving profile: ${e.code} - ${e.message}');
      if (mounted) {
        String message = 'เกิดข้อผิดพลาด: ${e.message}';
        if (e.code == 'permission-denied') {
          message = 'ไม่มีสิทธิ์บันทึกข้อมูล (Permission Denied) กรุณาตรวจสอบ Security Rules';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดไม่ทราบสาเหตุ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _nextStep() {
    if (step < 4) { // Increase total steps to 4
      setState(() => step++);
    } else {
      _handleSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 8,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100 * (step / 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'ยินดีต้อนรับ!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: -1),
              ),
              const SizedBox(height: 8),
              Text(
                'เรามาตั้งค่าเป้าหมายสุขภาพของคุณกันเถอะ',
                style: TextStyle(color: Colors.blueGrey[300], fontSize: 16),
              ),
              const SizedBox(height: 48),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (step == 1) ...[
                        _buildLabel('ชื่อเล่น'),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.white, 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: BorderSide(color: Colors.blue[50]!)
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20), 
                              borderSide: BorderSide(color: Colors.blue[50]!)
                            ),
                            hintText: 'ชื่อของคุณ',
                            hintStyle: TextStyle(color: Colors.blueGrey[100]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('เพศ'),
                        Row(
                          children: [
                            Expanded(child: _buildSelectButton('male', 'ชาย', gender == 'male', () => setState(() => gender = 'male'))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSelectButton('female', 'หญิง', gender == 'female', () => setState(() => gender = 'female'))),
                          ],
                        ),
                      ] else if (step == 2) ...[
                        Row(
                          children: [
                            Expanded(child: _buildNumberInput('อายุ (ปี)', age.toString(), (v) => setState(() => age = int.tryParse(v) ?? age))),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberInput('ส่วนสูง (ซม.)', height.toString(), (v) => setState(() => height = double.tryParse(v) ?? height))),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildNumberInput('น้ำหนัก (กก.)', weight.toString(), (v) => setState(() => weight = double.tryParse(v) ?? weight)),
                      ] else if (step == 3) ...[
                        _buildLabel('ระดับกิจกรรมของคุณ'),
                        _buildActivityOption('sedentary', 'นั่งทำงานเป็นหลัก', 'ออกกำลังกายน้อยมาก'),
                        _buildActivityOption('light', 'เคลื่อนไหวบ้าง', 'ออกกำลังกาย 1-3 วัน/สัปดาห์'),
                        _buildActivityOption('moderate', 'ปานกลาง', 'ออกกำลังกาย 3-5 วัน/สัปดาห์'),
                        _buildActivityOption('active', 'หนัก', 'ออกกำลังกาย 6-7 วัน/สัปดาห์'),
                      ] else if (step == 4) ...[
                        _buildLabel('เป้าหมายของคุณ'),
                        _buildGoalOption('lose', 'ลดน้ำหนัก', 'ลดไขมัน เน้นแคลอรี่ต่ำ'),
                        _buildGoalOption('maintain', 'รักษาน้ำหนัก', 'กินเท่าที่ใช้ ไม่เพิ่มไม่ลด'),
                        _buildGoalOption('gain', 'เพิ่มกล้ามเนื้อ', 'เพิ่มน้ำหนักและกล้ามเนื้อ'),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.all(18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: loading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(step == 4 ? 'เริ่มต้นใช้งาน' : 'ถัดไป', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Align(alignment: Alignment.centerLeft, child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 16))),
  );

  Widget _buildSelectButton(String value, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.blue[50]!),
          boxShadow: [
            if (selected) BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.blueGrey[400], fontWeight: FontWeight.bold, fontSize: 16))),
      ),
    );
  }

  Widget _buildNumberInput(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: value,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: Colors.blue[50]!)
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: Colors.blue[50]!)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(String id, String label, String sub) {
    final selected = activityLevel == id;
    return GestureDetector(
      onTap: () => setState(() => activityLevel = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.blue[50]!),
          boxShadow: [
            if (selected) BoxShadow(color: Colors.blueAccent.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: selected ? Colors.white : Colors.blueGrey[800])),
            Text(sub, style: TextStyle(fontSize: 13, color: selected ? Colors.white.withOpacity(0.8) : Colors.blueGrey[200])),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String id, String label, String sub) {
    final selected = goal == id;
    return GestureDetector(
      onTap: () => setState(() => goal = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.blue[50]!),
          boxShadow: [
            if (selected) BoxShadow(color: Colors.blueAccent.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: selected ? Colors.white : Colors.blueGrey[800])),
            Text(sub, style: TextStyle(fontSize: 13, color: selected ? Colors.white.withOpacity(0.8) : Colors.blueGrey[200])),
          ],
        ),
      ),
    );
  }
}
