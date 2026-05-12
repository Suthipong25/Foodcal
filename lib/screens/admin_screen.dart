import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../constants/enums.dart';
import '../models/daily_log.dart';
import '../models/feedback_log.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/glass_card.dart';

class AdminScreen extends StatelessWidget {
  final UserProfile profile;

  const AdminScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromString(profile.role) != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access')),
        body: const _AdminMessageState(
          icon: Icons.lock_outline_rounded,
          title: 'ไม่มีสิทธิ์เข้าถึง',
          message:
              'หน้านี้สำหรับผู้ดูแลระบบเท่านั้น\nกรุณาติดต่อผู้ดูแลหากคุณเชื่อว่านี่เป็นข้อผิดพลาด',
          accent: AppTheme.error,
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('แดชบอร์ดผู้ดูแล', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.logOut, color: AppTheme.error),
              tooltip: 'ออกจากระบบ',
              onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).signOut();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.mutedText,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(LucideIcons.barChart2), text: 'ข้อเสนอแนะ'),
              Tab(icon: Icon(LucideIcons.users), text: 'ผู้ใช้งาน'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
          child: const TabBarView(
            children: [_FeedbackTab(), _UsersTab()],
          ),
        ),
      ),
    );
  }
}

class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  late Future<List<FeedbackLog>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    setState(() {
      _feedbackFuture = firestore.getAllFeedback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    const topContentPadding = 16.0;

    return FutureBuilder<List<FeedbackLog>>(
      future: _feedbackFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}'));
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Center(child: Text('ยังไม่มี feedback'));
        }

        final avg = logs.map((e) => e.rating).reduce((a, b) => a + b) / logs.length;
        final counts = <String, int>{};
        for (final log in logs) {
          final key = log.favoriteFeature.isEmpty ? 'ไม่ระบุ' : log.favoriteFeature;
          counts[key] = (counts[key] ?? 0) + 1;
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView(
            padding: AppTheme.pageInsetsForWidth(
              width,
              top: topContentPadding,
              bottom: 24,
            ),
            children: [
              const _HeroCard(
                title: 'ภาพรวมผลตอบรับ',
                subtitle: 'ดูคะแนนเฉลี่ย ฟีเจอร์ที่ผู้ใช้ชอบ และความคิดเห็นล่าสุด',
                icon: LucideIcons.barChart2,
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _MetricCard(
                      label: 'คะแนนเฉลี่ย',
                      value: avg.toStringAsFixed(1),
                      icon: LucideIcons.star,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _MetricCard(
                      label: 'Feedback ทั้งหมด',
                      value: '${logs.length}',
                      icon: LucideIcons.messageSquare,
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _FeatureChartCard(data: counts),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'ความคิดเห็นล่าสุด',
                subtitle: 'แสดง feedback ล่าสุดจากผู้ใช้',
              ),
              const SizedBox(height: 14),
              ...logs.take(12).map(
                    (log) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: AppTheme.subtleCard(
                          background: Colors.white,
                          borderColor: const Color(0xFFDDE8F4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StatusPill(
                                  text: '${log.rating} ดาว',
                                  color: Colors.orange,
                                ),
                                const Spacer(),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(log.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              log.favoriteFeature.isEmpty
                                  ? 'ไม่ระบุฟีเจอร์โปรด'
                                  : log.favoriteFeature,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              log.comment.isEmpty
                                  ? 'ไม่มีความคิดเห็นเพิ่มเติม'
                                  : log.comment,
                              style: const TextStyle(
                                color: AppTheme.mutedText,
                                height: 1.45,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<UserProfile>> _usersFuture;
  static const String _unknownGoalKey = 'unknown';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    setState(() {
      _usersFuture = firestore.getAllUsers();
    });
  }

  String _normalizeGoal(String rawGoal) {
    switch (rawGoal.trim().toLowerCase()) {
      case 'lose':
        return HealthGoal.lose.value;
      case 'maintain':
        return HealthGoal.maintain.value;
      case 'gain':
        return HealthGoal.gain.value;
      default:
        return _unknownGoalKey;
    }
  }

  String _goalLabel(String rawGoal) {
    switch (_normalizeGoal(rawGoal)) {
      case 'lose':
        return 'ลดน้ำหนัก';
      case 'maintain':
        return 'รักษาน้ำหนัก';
      case 'gain':
        return 'เพิ่มน้ำหนัก';
      default:
        return 'ไม่ระบุ';
    }
  }

  Color _goalColor(String rawGoal) {
    switch (_normalizeGoal(rawGoal)) {
      case 'lose':
        return AppTheme.primaryColor;
      case 'maintain':
        return AppTheme.success;
      case 'gain':
        return AppTheme.warning;
      default:
        return AppTheme.mutedText;
    }
  }

  bool _hasMeaningfulLog(DailyLog log) {
    return log.caloriesIn > 0 ||
        log.waterGlasses > 0 ||
        log.foods.isNotEmpty ||
        log.workouts.isNotEmpty;
  }

  Future<Map<String, _GoalOutcome>> _loadGoalOutcomes(
    FirestoreService firestore,
    List<UserProfile> users,
  ) async {
    final entries = await Future.wait(
      users.map((user) async {
        final logs = await firestore.getRecentDailyLogs(user.uid, limit: 7);
        return MapEntry(user.uid, _evaluateGoalOutcome(user, logs));
      }),
    );
    return Map<String, _GoalOutcome>.fromEntries(entries);
  }

  _GoalOutcome _evaluateGoalOutcome(UserProfile user, List<DailyLog> logs) {
    final normalizedGoal = _normalizeGoal(user.goal);
    if (normalizedGoal == _unknownGoalKey) {
      return const _GoalOutcome(
        status: _GoalOutcomeStatus.unknown,
        label: 'ไม่ระบุเป้าหมาย',
        detail: 'ยังไม่สามารถประเมินผลย้อนหลัง 7 วันได้',
      );
    }

    final List<DailyLog> meaningfulLogs = logs.where(_hasMeaningfulLog).toList();
    if (meaningfulLogs.length < 4) {
      return _GoalOutcome(
        status: _GoalOutcomeStatus.insufficient,
        label: 'ข้อมูลไม่พอ',
        detail: 'มีข้อมูล ${meaningfulLogs.length}/7 วัน ยังประเมินไม่แม่นพอ',
      );
    }

    final totalCalories = meaningfulLogs.fold<int>(
      0,
      (sum, log) => sum + log.caloriesIn,
    );
    final avgCalories = totalCalories / meaningfulLogs.length;
    final target = user.targetCalories <= 0 ? 1 : user.targetCalories;

    bool metDay(DailyLog log) {
      switch (normalizedGoal) {
        case 'lose':
          return log.caloriesIn <= target * 1.05;
        case 'maintain':
          return (log.caloriesIn - target).abs() <= target * 0.08;
        case 'gain':
          return log.caloriesIn >= target * 0.95;
        default:
          return false;
      }
    }

    final metDays = meaningfulLogs.where(metDay).length;
    final successRate = metDays / meaningfulLogs.length;

    if (successRate >= 0.7) {
      return _GoalOutcome(
        status: _GoalOutcomeStatus.reached,
        label: 'ถึงเป้าหมาย',
        detail:
            '7 วันล่าสุดทำได้ $metDays/${meaningfulLogs.length} วัน ค่าเฉลี่ย ${avgCalories.toStringAsFixed(0)} kcal',
      );
    }

    if (successRate >= 0.4) {
      return _GoalOutcome(
        status: _GoalOutcomeStatus.close,
        label: 'ใกล้ถึงเป้าหมาย',
        detail:
            '7 วันล่าสุดทำได้ $metDays/${meaningfulLogs.length} วัน ค่าเฉลี่ย ${avgCalories.toStringAsFixed(0)} kcal',
      );
    }

    return _GoalOutcome(
      status: _GoalOutcomeStatus.notReached,
      label: 'ยังไม่ถึงเป้าหมาย',
      detail:
          '7 วันล่าสุดทำได้ $metDays/${meaningfulLogs.length} วัน ค่าเฉลี่ย ${avgCalories.toStringAsFixed(0)} kcal',
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final myUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final width = MediaQuery.sizeOf(context).width;
    const topContentPadding = 16.0;

    return FutureBuilder<List<UserProfile>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load users: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final admins = users.where((e) => UserRole.fromString(e.role) == UserRole.admin).length;
        final trackedUsers = users.where((e) => UserRole.fromString(e.role) == UserRole.user).toList();
        final goalCounts = <String, int>{
          HealthGoal.lose.value: 0,
          HealthGoal.maintain.value: 0,
          HealthGoal.gain.value: 0,
          _unknownGoalKey: 0,
        };

        for (final user in trackedUsers) {
          final normalizedGoal = _normalizeGoal(user.goal);
          goalCounts[normalizedGoal] = (goalCounts[normalizedGoal] ?? 0) + 1;
        }

        final goalOutcomesFuture = _loadGoalOutcomes(firestore, trackedUsers);

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView(
            padding: AppTheme.pageInsetsForWidth(width, top: topContentPadding, bottom: 24),
            children: [
              const _HeroCard(
                title: 'User management',
                subtitle: 'Review each user goal and check whether the latest 7-day result is on track',
                icon: LucideIcons.users,
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _MetricCard(
                      label: 'Users',
                      value: '${trackedUsers.length}',
                      icon: LucideIcons.user,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _MetricCard(
                      label: 'Admins',
                      value: '$admins',
                      icon: LucideIcons.shieldCheck,
                      color: const Color(0xFF8A5CF6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Goal summary',
                subtitle: 'Count current goals for active users and group invalid values as unknown',
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _MetricCard(
                      label: 'Lose',
                      value: '${goalCounts[HealthGoal.lose.value] ?? 0}',
                      icon: LucideIcons.trendingDown,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    _MetricCard(
                      label: 'Maintain',
                      value: '${goalCounts[HealthGoal.maintain.value] ?? 0}',
                      icon: LucideIcons.target,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    _MetricCard(
                      label: 'Gain',
                      value: '${goalCounts[HealthGoal.gain.value] ?? 0}',
                      icon: LucideIcons.trendingUp,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    _MetricCard(
                      label: 'Unknown',
                      value: '${goalCounts[_unknownGoalKey] ?? 0}',
                      icon: LucideIcons.helpCircle,
                      color: AppTheme.mutedText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'User progress',
                subtitle: 'Evaluate each user against the latest 7-day result',
              ),
              const SizedBox(height: 14),
              FutureBuilder<Map<String, _GoalOutcome>>(
                future: goalOutcomesFuture,
                builder: (context, outcomeSnapshot) {
                  if (outcomeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final outcomes = outcomeSnapshot.data ?? const <String, _GoalOutcome>{};

                  return Column(
                    children: trackedUsers.map((user) {
                      final outcome = outcomes[user.uid] ?? const _GoalOutcome(
                        status: _GoalOutcomeStatus.unknown,
                        label: 'Unknown',
                        detail: 'No 7-day data available',
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(18),
                          opacity: 0.1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name.isNotEmpty ? user.name : 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.ink,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Joined ${DateFormat('dd/MM/yyyy').format(user.joinedDate)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.mutedText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusPill(
                                    text: _goalLabel(user.goal),
                                    color: _goalColor(user.goal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: outcome.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: outcome.color.withValues(alpha: 0.20)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(LucideIcons.calendarDays, size: 16, color: outcome.color),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Last 7 days: ${outcome.label}',
                                          style: TextStyle(
                                            color: outcome.color,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      outcome.detail,
                                      style: const TextStyle(
                                        color: AppTheme.mutedText,
                                        fontSize: 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (user.uid == myUid)
                                const Center(
                                  child: Text(
                                    'Your account can be edited from the profile screen',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showRoleDialog(context, user, firestore, _loadData),
                                        icon: const Icon(LucideIcons.userCog, size: 16),
                                        label: const Text('Edit role', style: TextStyle(fontWeight: FontWeight.w700)),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: _dialogPrimaryButtonStyle(backgroundColor: AppTheme.error),
                                        onPressed: () => _showDeleteDialog(context, user, firestore, _loadData),
                                        icon: const Icon(LucideIcons.trash2, size: 16),
                                        label: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _GoalOutcomeStatus {
  reached,
  close,
  notReached,
  insufficient,
  unknown,
}

class _GoalOutcome {
  final _GoalOutcomeStatus status;
  final String label;
  final String detail;

  const _GoalOutcome({
    required this.status,
    required this.label,
    required this.detail,
  });

  Color get color {
    switch (status) {
      case _GoalOutcomeStatus.reached:
        return AppTheme.success;
      case _GoalOutcomeStatus.close:
        return AppTheme.warning;
      case _GoalOutcomeStatus.notReached:
        return AppTheme.error;
      case _GoalOutcomeStatus.insufficient:
      case _GoalOutcomeStatus.unknown:
        return AppTheme.mutedText;
    }
  }
}

class _FeatureChartCard extends StatelessWidget {
  final Map<String, int> data;

  const _FeatureChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppTheme.isCompactWidth(width);
    final keys = data.keys.toList();
    final maxVal = data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b).toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.subtleCard(
        background: Colors.white,
        borderColor: const Color(0xFFDDE8F4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ฟีเจอร์ที่ผู้ใช้ชอบ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: compact ? 240 : 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 1,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: !compact,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: compact ? 42 : 34,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= keys.length) {
                          return const SizedBox.shrink();
                        }
                        var title = keys[value.toInt()];
                        final maxLength = compact ? 8 : 10;
                        if (title.length > maxLength) {
                          title = '${title.substring(0, maxLength)}...';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedText,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: keys
                    .asMap()
                    .entries
                    .map(
                      (entry) => BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: data[entry.value]!.toDouble(),
                            width: compact ? 14 : 18,
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.secondaryColor,
                                AppTheme.primaryColor,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.subtleCard(
        background: Colors.white,
        borderColor: const Color(0xFFDDE8F4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 160,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.subtleCard(
          background: Colors.white,
          borderColor: color.withValues(alpha: 0.24),
          boxShadow: AppTheme.softShadow(color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

void _showRoleDialog(
  BuildContext context,
  UserProfile user,
  FirestoreService firestore,
  VoidCallback onSuccess,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final isAdmin = UserRole.fromString(user.role) == UserRole.admin;
      return AlertDialog(
        title: Text('เปลี่ยนสิทธิ์ของ ${user.name}'),
        content: Text(
          isAdmin
              ? 'ต้องการลดสิทธิ์บัญชีนี้กลับเป็นผู้ใช้ทั่วไปหรือไม่'
              : 'ต้องการเพิ่มสิทธิ์บัญชีนี้เป็นผู้ดูแลระบบหรือไม่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: _dialogGhostButtonStyle(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: _dialogPrimaryButtonStyle(),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await firestore.setAdminRole(user.uid, !isAdmin);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัปเดตสิทธิ์เรียบร้อยแล้ว')),
                  );
                  onSuccess();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('อัปเดตสิทธิ์ไม่สำเร็จ: $e')),
                  );
                }
              }
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      );
    },
  );
}

void _showDeleteDialog(
  BuildContext context,
  UserProfile user,
  FirestoreService firestore,
  VoidCallback onSuccess,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text(
        'ลบบัญชีผู้ใช้',
        style: TextStyle(color: AppTheme.error),
      ),
      content: Text(
        'ต้องการลบบัญชี ${user.name} อย่างถาวรใช่หรือไม่ การกระทำนี้ไม่สามารถย้อนกลับได้',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: _dialogGhostButtonStyle(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: _dialogPrimaryButtonStyle(backgroundColor: AppTheme.error),
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              await firestore.deleteUserAccount(user.uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบบัญชีเรียบร้อยแล้ว')),
                );
                onSuccess();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบบัญชีไม่สำเร็จ: $e')),
                );
              }
            }
          },
          child: const Text(
            'ลบถาวร',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

ButtonStyle _dialogGhostButtonStyle() {
  return TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    minimumSize: const Size(0, 40),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

ButtonStyle _dialogPrimaryButtonStyle({Color? backgroundColor}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor ?? AppTheme.primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

class _AdminMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  const _AdminMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          opacity: 0.15,
          borderColor: accent.withValues(alpha: 0.2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedText,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
