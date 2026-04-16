import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/feedback_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  String _selectedFeature = 'สแกนอาหาร';
  bool _isLoading = false;

  final List<String> _features = const [
    'สแกนอาหาร',
    'บันทึกแคลอรี่รายวัน',
    'AI Coach',
    'แผนสุขภาพส่วนตัว',
    'การใช้งานโดยรวม',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาให้คะแนนความพึงพอใจก่อนส่ง'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final log = FeedbackLog(
        id: '',
        uid: user?.uid ?? 'anonymous',
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        favoriteFeature: _selectedFeature,
        createdAt: DateTime.now(),
      );

      await firestore.submitFeedback(log);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ขอบคุณสำหรับความคิดเห็นของคุณ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = AppTheme.maxContentWidth(screenWidth);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text(
          'ให้คะแนนความพึงพอใจ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SingleChildScrollView(
            padding: AppTheme.pageInsetsForWidth(
              screenWidth,
              bottom: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 18),
                _buildRatingCard(screenWidth),
                const SizedBox(height: 18),
                _buildFeatureCard(),
                const SizedBox(height: 18),
                _buildCommentCard(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ส่งความคิดเห็น',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.tintedCard(AppTheme.primaryColor),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.heartHandshake,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ทุกคะแนนช่วยให้เราปรับ Foodcal ได้ดีขึ้น',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'บอกเราว่าคุณชอบอะไร ใช้ฟีเจอร์ไหนบ่อย และอยากให้ปรับตรงไหน เพื่อให้แอปใช้งานง่ายขึ้นสำหรับทุกคน',
            style: TextStyle(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(double screenWidth) {
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'คุณพึงพอใจกับการใช้งานแอปมากแค่ไหน',
            style: TextStyle(
              fontSize: AppTheme.title,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _rating == 0 ? 'แตะที่ดาวเพื่อให้คะแนน' : _ratingLabel(_rating),
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final isSelected = ratingValue <= _rating;

              return GestureDetector(
                onTap: () => setState(() => _rating = ratingValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isCompact ? 48 : 54,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFF4DA)
                        : AppTheme.pageTint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFC95A)
                          : AppTheme.pageTintStrong,
                    ),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        isSelected ? Colors.orangeAccent : Colors.grey.shade400,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ฟีเจอร์ที่คุณชอบมากที่สุด',
            style: TextStyle(
              fontSize: AppTheme.title,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เลือกได้ 1 อย่างที่คุณรู้สึกว่าใช้งานแล้วคุ้มที่สุดในตอนนี้',
            style: TextStyle(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _features.map((feature) {
              final isSelected = _selectedFeature == feature;

              return ChoiceChip(
                label: Text(feature),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFeature = feature);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.14),
                backgroundColor: AppTheme.pageTint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : AppTheme.pageTintStrong,
                  ),
                ),
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppTheme.primaryColor : AppTheme.mutedText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'อยากให้เราปรับอะไรเพิ่ม',
            style: TextStyle(
              fontSize: AppTheme.title,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'พิมพ์สั้น ๆ ได้เลย เช่น อยากให้ AI ตอบละเอียดขึ้น หรืออยากให้หน้าบันทึกอาหารใช้ง่ายขึ้น',
            style: TextStyle(
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.pageTint,
              hintText: 'แชร์ความคิดเห็นของคุณที่นี่...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return '1 ดาว - ยังไม่ค่อยตรงกับที่ต้องการ';
      case 2:
        return '2 ดาว - ใช้งานได้บ้าง แต่ยังติดขัด';
      case 3:
        return '3 ดาว - ใช้งานได้ปกติ';
      case 4:
        return '4 ดาว - ประทับใจและใช้ง่าย';
      case 5:
        return '5 ดาว - ชอบมาก อยากใช้งานต่อ';
      default:
        return '';
    }
  }
}
