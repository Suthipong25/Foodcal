import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

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

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('ประวัติการออกกำลังกาย',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
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
                    completedAt: DateTime.tryParse(s['completedAt'] as String? ?? '') ?? DateTime.now(),
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
                        const SizedBox(height: 16),
                        _buildFilterRow(),
                        const SizedBox(height: 12),
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
    );
  }

  Widget _buildStats(int sessions, int minutes, int burned, int days) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: Colors.pinkAccent.withValues(alpha: 0.12),
        boxShadow: AppTheme.softShadow(Colors.pinkAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุปการออกกำลังกาย',
              style: TextStyle(
                  fontSize: AppTheme.title, fontWeight: FontWeight.w800, color: AppTheme.ink)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(LucideIcons.dumbbell, '$sessions ครั้ง', 'ทั้งหมด', Colors.pinkAccent),
              const SizedBox(width: 10),
              _statChip(LucideIcons.timer, '$minutes นาที', 'รวม', Colors.deepPurple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statChip(LucideIcons.flame, '$burned kcal', 'เผาผลาญ', AppTheme.warning),
              const SizedBox(width: 10),
              _statChip(LucideIcons.calendarCheck, '$days วัน', 'ที่ active', AppTheme.success),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: AppTheme.body, fontWeight: FontWeight.w800, color: color)),
                Text(label,
                    style: const TextStyle(fontSize: AppTheme.meta, color: AppTheme.mutedText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _allTypes.length,
        itemBuilder: (_, i) {
          final t = _allTypes[i];
          final selected = _filterType == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) => setState(() => _filterType = t),
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primaryColor : AppTheme.mutedText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.elevatedCard(color: Colors.white),
      child: const Center(
        child: Column(
          children: [
            Icon(LucideIcons.dumbbell, size: 48, color: AppTheme.mutedText),
            SizedBox(height: 12),
            Text('ไม่พบข้อมูลการออกกำลังกาย',
                style: TextStyle(color: AppTheme.mutedText, fontSize: AppTheme.body)),
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
      completedAt: completedAt ?? DateTime.now(),
    );
    final burned = FirestoreService.calculateWorkoutCalories(w);
    final levelColor = level == 'Expert'
        ? Colors.red
        : level == 'Intermediate'
            ? Colors.orange
            : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.elevatedCard(color: Colors.white),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.dumbbell, color: Colors.pinkAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: AppTheme.body, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _tag(type, Colors.pinkAccent),
                    _tag(level, levelColor),
                    _tag('$minutes นาที', AppTheme.mutedText),
                    _tag('$burned kcal', AppTheme.warning),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$dateLabel ${timeLabel.isNotEmpty ? "· $timeLabel" : ""}',
                    style: const TextStyle(fontSize: AppTheme.meta, color: AppTheme.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: AppTheme.meta, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
