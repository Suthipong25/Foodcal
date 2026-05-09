import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/datetime_utils.dart';
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  String _filterType = 'ทั้งหมด';
  static const _allTypes = ['ทั้งหมด', 'Cardio', 'HIIT', 'Strength', 'Yoga', 'Pilates', 'Stretch'];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AnimatedPageWrapper(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('ประวัติการออกกำลังกาย',
                style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900)),
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: user == null
                ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Provider.of<FirestoreService>(context, listen: false)
                        .streamWorkoutSessions(user.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                      }
                      final all = snap.data ?? [];
                      final sessions = _filterType == 'ทั้งหมด'
                          ? all
                          : all.where((s) => s['type'] == _filterType).toList();

                      // compute stats
                      final totalSessions = sessions.length;
                      int totalMinutes = 0;
                      int totalBurned = 0;
                      final Set<String> activeDays = {};
                      for (final s in all) {
                        final w = WorkoutItem(
                          id: (s['workoutId'] as num? ?? 0).toInt(),
                          title: s['title'] as String? ?? '',
                          level: s['level'] as String? ?? 'Beginner',
                          duration: s['duration'] as String? ?? '',
                          minutes: (s['minutes'] as num? ?? 0).toInt(),
                          type: s['type'] as String? ?? '',
                          completedAt: DateTime.tryParse(s['completedAt'] as String? ?? '') ?? DateTimeUtils.now(),
                        );
                        totalMinutes += w.minutes;
                        totalBurned += FirestoreService.calculateWorkoutCalories(w);
                        activeDays.add(s['dateKey'] as String? ?? '');
                      }

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(screenWidth)),
                          child: ListView(
                            padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 32),
                            children: [
                              _buildStats(totalSessions, totalMinutes, totalBurned, activeDays.length),
                              const SizedBox(height: 18),
                              _buildFilterRow(),
                              const SizedBox(height: 16),
                              if (sessions.isEmpty)
                                _buildEmpty()
                              else
                                ...sessions.map((s) => _buildSessionTile(s)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int sessions, int minutes, int burned, int days) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุปการออกกำลังกาย',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ink)),
          const SizedBox(height: 18),
          Row(
            children: [
              _statChip(LucideIcons.dumbbell, '$sessions ครั้ง', 'ทั้งหมด', Colors.pinkAccent),
              const SizedBox(width: 12),
              _statChip(LucideIcons.timer, '$minutes นาที', 'รวม', Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip(LucideIcons.flame, '$burned kcal', 'เผาผลาญ', AppTheme.warning),
              const SizedBox(width: 12),
              _statChip(LucideIcons.calendarCheck, '$days วัน', 'Active', AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.ink)),
                  Text(label,
                      style: const TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _allTypes.length,
        itemBuilder: (_, i) {
          final t = _allTypes[i];
          final selected = _filterType == t;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              selected: selected,
              onSelected: (_) => setState(() => _filterType = t),
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: selected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.3)),
              labelStyle: TextStyle(
                color: selected ? AppTheme.primaryColor : AppTheme.mutedText,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const GlassCard(
      padding: EdgeInsets.all(48),
      opacity: 0.08,
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.dumbbell, size: 48, color: AppTheme.mutedText),
            SizedBox(height: 16),
            Text('ไม่พบข้อมูลการออกกำลังกาย',
                style: TextStyle(color: AppTheme.mutedText, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> s) {
    final completedAt = DateTime.tryParse(s['completedAt'] as String? ?? '');
    final dateLabel = completedAt != null
        ? DateFormat('EEEEที่ d MMMM', 'th').format(completedAt.toLocal())
        : (s['dateKey'] as String? ?? '');
    final timeLabel =
        completedAt != null ? DateFormat('HH:mm', 'th').format(completedAt.toLocal()) : '';
    final title = s['title'] as String? ?? '';
    final level = s['level'] as String? ?? '';
    final type = s['type'] as String? ?? '';
    final minutes = (s['minutes'] as num? ?? 0).toInt();
    final w = WorkoutItem(
      id: (s['workoutId'] as num? ?? 0).toInt(),
      title: title,
      level: level,
      duration: '$minutes min',
      minutes: minutes,
      type: type,
      completedAt: completedAt ?? DateTimeUtils.now(),
    );
    final burned = FirestoreService.calculateWorkoutCalories(w);
    final levelColor = level == 'Expert'
        ? Colors.red
        : level == 'Intermediate'
            ? Colors.orange
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        opacity: 0.1,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.dumbbell, color: Colors.pinkAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _tag(type, Colors.pinkAccent),
                      _tag(level, levelColor),
                      _tag('$minutes นาที', AppTheme.primaryColor),
                      _tag('$burned kcal', AppTheme.warning),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$dateLabel · $timeLabel',
                      style: const TextStyle(fontSize: 11, color: AppTheme.mutedText, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800)),
    );
  }
}
