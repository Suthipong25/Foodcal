import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../services/ai_service.dart';
import 'feedback_screen.dart';

import '../widgets/animated_page_wrapper.dart';
import '../widgets/decorative_elements.dart';
import '../widgets/glass_card.dart';

const Color _lightSurfaceInk = Color(0xFF111318);
const Color _lightSurfaceMuted = Color(0xFF667085);

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
              'ตอนนี้ยังไม่สามารถเชื่อมต่อ AI Coach ได้ กรุณาลองใหม่อีกครั้ง',
        });
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _messages.add({
          'role': 'error',
          'content': 'เกิดข้อผิดพลาด: $errorMsg',
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

    return AnimatedPageWrapper(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.ink),
            title: const Text(
              'AI Coach',
              style: TextStyle(
                fontWeight: FontWeight.w900,
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
            decoration: AppTheme.subtleCard(
              background: Colors.white.withValues(alpha: 0.96),
              borderColor: const Color(0xFFE7EDF4),
              boxShadow: const [],
            ).copyWith(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                          style: const TextStyle(
                            color: _lightSurfaceInk,
                            fontWeight: FontWeight.w600,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText:
                                'ถามเรื่องอาหาร การออกกำลังกาย หรือสุขภาพ...',
                            hintStyle: const TextStyle(
                              color: _lightSurfaceMuted,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE3EAF2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.28),
                              ),
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
                          gradient:
                              _isLoading ? null : AppTheme.primaryGradient,
                          color: _isLoading ? AppTheme.pageTintStrong : null,
                          shape: BoxShape.circle,
                          boxShadow: _isLoading
                              ? null
                              : AppTheme.softShadow(AppTheme.primaryColor),
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
    return GlassCard(
      padding: EdgeInsets.all(isCompact ? 18 : 20),
      opacity: 0.15,
      child: const Stack(
        clipBehavior: Clip.none,
        children: [
          SparkleDecoration(
            alignment: Alignment.topRight,
            color: AppTheme.aiColor,
            size: 76,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CoachIconCard(),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Coach ของคุณ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.ink,
                        height: 1.25,
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
                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      opacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เริ่มต้นถามได้ทันที',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กดเลือกหัวข้อด้านล่างเพื่อให้ AI Coach ช่วยวิเคราะห์สถานการณ์ได้เร็วขึ้น',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._quickPrompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _sendMessage(prompt),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: AppTheme.subtleCard(
                    background: Colors.white,
                    borderColor: const Color(0xFFE7EDF4),
                    boxShadow: const [],
                  ).copyWith(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: AppTheme.iconBubble(AppTheme.primaryColor),
                        child: const Icon(
                          LucideIcons.messageCircle,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            color: _lightSurfaceInk,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: _lightSurfaceMuted,
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
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppTheme.primaryGradient : null,
          color: isError
              ? AppTheme.error.withValues(alpha: 0.1)
              : !isUser
                  ? Colors.white
                  : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isError
                      ? AppTheme.error.withValues(alpha: 0.2)
                      : const Color(0xFFE7EDF4),
                ),
          boxShadow: isUser
              ? AppTheme.softShadow(AppTheme.primaryColor)
              : AppTheme.softShadow(AppTheme.aiColor),
        ),
        child: Text(
          msg['content'] ?? '',
          style: TextStyle(
            color: isError
                ? AppTheme.error
                : isUser
                    ? Colors.white
                    : _lightSurfaceInk,
            height: 1.5,
            fontWeight: isUser ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
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
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppTheme.aiGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow(AppTheme.aiColor),
      ),
      child: const Icon(
        LucideIcons.sparkles,
        color: Colors.white,
        size: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.aiColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.aiColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.aiColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.aiColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
