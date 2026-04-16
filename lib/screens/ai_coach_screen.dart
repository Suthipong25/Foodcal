import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../services/ai_service.dart';
import 'feedback_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const List<String> _quickPrompts = [
    'น้ำหนักคงที่ ควรทำอย่างไรต่อดี',
    'กินเกินเป้าหมายเมื่อวาน วันนี้ควรปรับยังไง',
    'อยากเพิ่มโปรตีนแบบไม่กินเยอะเกินไป',
    'ดื่มน้ำน้อย ทำยังไงให้ทำได้ต่อเนื่อง',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickPrompt]) async {
    final text = (quickPrompt ?? _msgCtrl.text).trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _msgCtrl.clear();

    try {
      final response = await AIService.askCoach(text, history: _messages);
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': response != null ? 'ai' : 'error',
          'content': response ??
              'ตอนนี้ยังไม่สามารถเชื่อมต่อ AI Coach ได้ กรุณาตรวจสอบการตั้งค่า AI_BACKEND_URL',
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'error',
          'content': 'เกิดข้อผิดพลาด: $e',
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppTheme.isCompactWidth(screenWidth);
    final contentWidth = AppTheme.maxContentWidth(screenWidth);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
        title: const Text(
          'AI Coach',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'ให้คะแนนความพึงพอใจ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackScreen()),
              );
            },
            icon: const Icon(
              LucideIcons.star,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: AppTheme.pageInsetsForWidth(
                        screenWidth,
                        top: 16,
                        bottom: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeroCard(isCompact),
                          const SizedBox(height: 18),
                          if (_messages.isEmpty)
                            _buildQuickPrompts()
                          else
                            ...List.generate(
                              _messages.length + (_isLoading ? 1 : 0),
                              (index) {
                                if (index == _messages.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return _buildMessageBubble(_messages[index]);
                              },
                            ),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              bottomInset > 0 ? 12 : 18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppTheme.pageTintStrong),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText:
                                'ถามเรื่องอาหาร การออกกำลังกาย หรือน้ำหนักคงที่ได้เลย',
                            hintStyle: const TextStyle(
                              color: AppTheme.mutedText,
                            ),
                            filled: true,
                            fillColor: AppTheme.pageTint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? AppTheme.pageTintStrong
                              : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon: Icon(
                            _isLoading ? LucideIcons.loader2 : LucideIcons.send,
                            color:
                                _isLoading ? AppTheme.mutedText : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 20),
      decoration: AppTheme.tintedCard(AppTheme.primaryColor),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CoachIconCard(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'โค้ชส่วนตัวสำหรับการกิน การดื่มน้ำ และการปรับแผนสุขภาพ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'พิมพ์ปัญหาที่เจอได้ตรง ๆ เช่น น้ำหนักคงที่ กินเกินเป้า หรืออยากเพิ่มโปรตีน แล้ว AI จะช่วยแนะนำแนวทางที่ทำต่อได้จริง',
            style: TextStyle(
              fontSize: AppTheme.body,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CoachPill(icon: LucideIcons.scale, label: 'น้ำหนักคงที่'),
              _CoachPill(icon: LucideIcons.beef, label: 'โปรตีนไม่ถึง'),
              _CoachPill(icon: LucideIcons.droplets, label: 'ดื่มน้ำน้อย'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: const Color(0xFFE4EEFB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เริ่มต้นถามได้ทันที',
            style: TextStyle(
              fontSize: AppTheme.title,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กดเลือกหัวข้อด้านล่างเพื่อให้ AI Coach ช่วยวิเคราะห์สถานการณ์ได้เร็วขึ้น',
            style: TextStyle(
              color: AppTheme.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ..._quickPrompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendMessage(prompt),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pageTint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.pageTintStrong),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.messageCircle,
                        color: AppTheme.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: AppTheme.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    final isError = msg['role'] == 'error';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isError
              ? AppTheme.error.withOpacity(0.08)
              : isUser
                  ? AppTheme.primaryColor
                  : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
            bottomLeft: !isUser ? Radius.zero : const Radius.circular(18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isError
                      ? AppTheme.error.withOpacity(0.2)
                      : AppTheme.pageTintStrong,
                ),
          boxShadow: isUser
              ? AppTheme.softShadow(AppTheme.primaryColor)
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(
            color: isError
                ? AppTheme.error
                : isUser
                    ? Colors.white
                    : AppTheme.ink,
            height: 1.5,
            fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CoachIconCard extends StatelessWidget {
  const _CoachIconCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        LucideIcons.sparkles,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

class _CoachPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CoachPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.pageTintStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
