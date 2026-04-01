import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../models/content_model.dart';
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'article_detail_screen.dart';

class ContentScreen extends StatefulWidget {
  final DailyLog? log;

  const ContentScreen({super.key, required this.log});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String filter = 'All';
  final Set<int> _submittingWorkoutIds = <int>{};
  final Map<int, DateTime> _workoutStartedAt = <int, DateTime>{};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var filteredVideos = WORKOUT_VIDEOS;
    if (filter != 'All') {
      filteredVideos = WORKOUT_VIDEOS.where((v) => v.level == filter).toList();
    }

    final completedCount = widget.log?.workouts.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(filteredVideos.length, completedCount),
          const SizedBox(height: AppTheme.sectionGap),
          _buildSectionHeader(
            'บทความน่าอ่าน',
            'สรุปสั้น อ่านง่าย และหยิบไปใช้ได้จริงในแต่ละวัน',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: EDUCATION_ARTICLES.length,
              separatorBuilder: (c, i) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final article = EDUCATION_ARTICLES[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          articles: EDUCATION_ARTICLES,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 228,
                    decoration: AppTheme.elevatedCard(
                      borderColor: AppTheme.pageTintStrong,
                      boxShadow: AppTheme.softShadow(AppTheme.secondaryColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: Image.network(
                            article.imageUrl,
                            height: 96,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 96,
                              color: AppTheme.pageTintStrong,
                              child: const Icon(
                                LucideIcons.image,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.macroBg(AppTheme.primaryColor),
                                  borderRadius: AppTheme.pillRadius,
                                ),
                                child: Text(
                                  article.category,
                                  style: const TextStyle(
                                    fontSize: AppTheme.meta,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                article.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.ink,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: const [
                                  Icon(
                                    LucideIcons.arrowUpRight,
                                    size: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'แตะเพื่ออ่านต่อ',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: AppTheme.meta,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.sectionGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildSectionHeader(
                  'คลังวิดีโอ',
                  'เลือกตามระดับความยาก แล้วบันทึกการออกกำลังกายได้ทันที',
                ),
              ),
              const SizedBox(width: 12),
              _buildFilterDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredVideos.map((video) {
            final isDone = widget.log?.workouts.any((w) => w.id == video.id) ?? false;
            final isSubmitting = _submittingWorkoutIds.contains(video.id);
            final videoId = _extractYoutubeVideoId(video.youtubeUrl);
            final thumbUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
            final fallbackThumbUrl = 'https://img.youtube.com/vi/$videoId/default.jpg';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: AppTheme.elevatedCard(
                borderColor: isDone
                    ? AppTheme.success.withOpacity(0.18)
                    : AppTheme.pageTintStrong,
                boxShadow: AppTheme.softShadow(
                  isDone ? AppTheme.success : AppTheme.primaryColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _workoutStartedAt.putIfAbsent(video.id, DateTime.now);
                      });
                      final url = Uri.parse(video.youtubeUrl);
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        debugPrint('Could not launch ${video.youtubeUrl}');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: AppTheme.innerRadius,
                          child: Image.network(
                            thumbUrl,
                            width: 126,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.network(
                              fallbackThumbUrl,
                              width: 126,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 126,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: AppTheme.pageTintStrong,
                                  borderRadius: AppTheme.innerRadius,
                                ),
                                child: const Icon(
                                  LucideIcons.image,
                                  color: AppTheme.secondaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                video.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppTheme.ink,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (isDone)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.macroBg(AppTheme.success),
                                  borderRadius: AppTheme.pillRadius,
                                ),
                                child: const Text(
                                  'ทำแล้ว',
                                  style: TextStyle(
                                    fontSize: AppTheme.meta,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPill(video.type, AppTheme.secondaryColor),
                            _buildPill(video.duration, AppTheme.warning),
                            _buildLevelPill(video.level),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _workoutHint(video),
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: AppTheme.body,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 110,
                    child: _buildWorkoutAction(
                      video,
                      isDone,
                      isSubmitting,
                      _canFinishWorkout(video),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroCard(int filteredCount, int completedCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.tintedCard(AppTheme.secondaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: AppTheme.pillRadius,
            ),
            child: const Text(
              'Learn and Move',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: AppTheme.meta,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'เรียนรู้ให้เข้าใจ แล้วลงมือทำได้ทันที',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'รวมบทความสุขภาพและวิดีโอออกกำลังกายที่หยิบใช้ได้ทุกวัน ทั้งอ่านสั้นและฝึกตามจริงในหน้าเดียว',
            style: TextStyle(
              fontSize: AppTheme.body,
              color: AppTheme.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  '$filteredCount คลิป',
                  'พร้อมสำหรับระดับที่เลือก',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroStat(
                  '$completedCount รายการ',
                  'workout ที่บันทึกวันนี้',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.meta,
              color: AppTheme.mutedText,
              height: 1.4,
            ),
          ),
        ],
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
            fontSize: AppTheme.body,
            color: AppTheme.mutedText,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: AppTheme.pageTintStrong),
      ),
      child: DropdownButton<String>(
        value: filter,
        underline: const SizedBox(),
        borderRadius: AppTheme.innerRadius,
        icon: const Icon(
          LucideIcons.chevronDown,
          size: 16,
          color: AppTheme.primaryColor,
        ),
        items: const ['All', 'Beginner', 'Intermediate', 'Expert']
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e == 'All' ? 'ทั้งหมด' : e,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => filter = v!),
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.macroBg(color),
        borderRadius: AppTheme.pillRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTheme.meta,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLevelPill(String level) {
    final color = switch (level) {
      'Beginner' => AppTheme.success,
      'Intermediate' => AppTheme.warning,
      _ => AppTheme.primaryColor,
    };
    return _buildPill(level, color);
  }

  Widget _buildWorkoutAction(
    WorkoutVideo video,
    bool isDone,
    bool isSubmitting,
    bool canFinish,
  ) {
    final started = _workoutStartedAt.containsKey(video.id);
    final label = isDone
        ? 'บันทึกแล้ว'
        : isSubmitting
            ? 'กำลังบันทึก'
            : canFinish
                ? 'จบ workout'
                : started
                    ? 'รอให้ครบเวลา'
                    : 'เริ่มก่อน';
    return GestureDetector(
      onTap: isDone || isSubmitting || !canFinish
          ? null
          : () async {
              final user = Provider.of<AuthService>(context, listen: false).currentUser;
              if (user != null) {
                setState(() => _submittingWorkoutIds.add(video.id));
                try {
                  await Provider.of<FirestoreService>(context, listen: false).finishWorkout(
                    user.uid,
                    WorkoutItem(
                      id: video.id,
                      title: video.title,
                      level: video.level,
                      duration: video.duration,
                      minutes: int.tryParse(
                            video.duration.replaceAll(RegExp(r'[^0-9]'), ''),
                          ) ??
                          0,
                      type: video.type,
                      completedAt: DateTime.now(),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _submittingWorkoutIds.remove(video.id));
                  }
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDone ? AppTheme.macroBg(AppTheme.success) : AppTheme.primaryColor,
          borderRadius: AppTheme.innerRadius,
          border: Border.all(
            color: isDone ? AppTheme.success.withOpacity(0.14) : AppTheme.primaryColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone
                  ? LucideIcons.checkCircle2
                  : isSubmitting
                      ? LucideIcons.loader2
                      : canFinish
                          ? LucideIcons.dumbbell
                          : LucideIcons.clock3,
              color: isDone ? AppTheme.success : Colors.white,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDone ? AppTheme.success : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _workoutHint(WorkoutVideo video) {
    return switch (video.type) {
      'Cardio' => 'เหมาะกับวันที่อยากขยับตัวและเร่งการเผาผลาญแบบต่อเนื่อง',
      'HIIT' => 'เหมาะกับวันที่มีเวลาน้อยแต่ต้องการความเข้มข้นสูง',
      'Yoga' => 'ช่วยยืดกล้ามเนื้อและเริ่มวันแบบเบาแต่ได้สมาธิ',
      'Pilates' => 'โฟกัสแกนกลางลำตัวและการควบคุมท่าทาง',
      'Stretch' => 'ใช้เป็น active recovery หรือคลายเมื่อยหลังนั่งนาน',
      _ => 'เพิ่มความแข็งแรงและช่วยรักษามวลกล้ามเนื้อในระยะยาว',
    };
  }

  bool _canFinishWorkout(WorkoutVideo video) {
    final startedAt = _workoutStartedAt[video.id];
    if (startedAt == null) return false;

    final totalMinutes =
        int.tryParse(video.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (totalMinutes <= 0) return false;

    final requiredMinutes = (totalMinutes * 0.6).ceil().clamp(1, totalMinutes);
    return DateTime.now().difference(startedAt).inMinutes >= requiredMinutes;
  }

  String _extractYoutubeVideoId(String url) {
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.group(7) != null && match.group(7)!.length == 11) {
      return match.group(7)!;
    }
    return '';
  }
}
