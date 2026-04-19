import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/feedback_log.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AdminScreen extends StatelessWidget {
  final UserProfile profile;

  const AdminScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Access')),
        body: const Center(child: Text('คุณไม่มีสิทธิ์เข้าถึงหน้านี้')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.pageBg,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.error),
              tooltip: 'ออกจากระบบ',
              onPressed: () async {
                await Provider.of<AuthService>(context, listen: false).signOut();
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.mutedText,
            tabs: [
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Feedback'),
              Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Users'),
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

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final width = MediaQuery.sizeOf(context).width;

    return StreamBuilder<List<FeedbackLog>>(
      stream: firestore.streamAllFeedback(),
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

        return ListView(
          padding: AppTheme.pageInsetsForWidth(width, top: 16, bottom: 24),
          children: [
            const _HeroCard(
              title: 'ภาพรวมผลตอบรับ',
              subtitle: 'ดูคะแนนเฉลี่ย ฟีเจอร์ที่ผู้ใช้ชอบ และความคิดเห็นล่าสุด',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'คะแนนเฉลี่ย',
                  value: avg.toStringAsFixed(1),
                  icon: Icons.star_rounded,
                  color: Colors.orange,
                ),
                _MetricCard(
                  label: 'feedback ทั้งหมด',
                  value: '${logs.length}',
                  icon: Icons.forum_outlined,
                  color: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FeatureChartCard(data: counts),
            const SizedBox(height: 16),
            const _SectionHeader(
              title: 'ความคิดเห็นล่าสุด',
              subtitle: 'แสดง feedback ล่าสุดจากผู้ใช้',
            ),
            const SizedBox(height: 12),
            ...logs.take(12).map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.elevatedCard(),
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
                                  fontSize: AppTheme.meta,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            log.favoriteFeature.isEmpty
                                ? 'ไม่ระบุฟีเจอร์โปรด'
                                : log.favoriteFeature,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log.comment.isEmpty
                                ? 'ไม่มีความคิดเห็นเพิ่มเติม'
                                : log.comment,
                            style: const TextStyle(
                              color: AppTheme.mutedText,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final myUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final width = MediaQuery.sizeOf(context).width;

    return StreamBuilder<List<UserProfile>>(
      stream: firestore.streamAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('โหลดผู้ใช้ไม่สำเร็จ: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final admins = users.where((e) => e.role == 'admin').length;

        return ListView(
          padding: AppTheme.pageInsetsForWidth(width, top: 16, bottom: 24),
          children: [
            const _HeroCard(
              title: 'จัดการผู้ใช้งาน',
              subtitle: 'ดูรายชื่อผู้ใช้ ปรับสิทธิ์ และลบบัญชีได้จากหน้านี้',
              icon: Icons.manage_accounts_outlined,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  label: 'ผู้ใช้ทั้งหมด',
                  value: '${users.length}',
                  icon: Icons.people_alt_outlined,
                  color: AppTheme.primaryColor,
                ),
                _MetricCard(
                  label: 'ผู้ดูแลระบบ',
                  value: '$admins',
                  icon: Icons.security_outlined,
                  color: const Color(0xFF8A5CF6),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionHeader(
              title: 'รายชื่อผู้ใช้',
              subtitle: 'คุณไม่สามารถลบบัญชีหรือลดสิทธิ์ของตัวเองได้',
            ),
            const SizedBox(height: 12),
            ...users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.elevatedCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.pageTintStrong,
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name.isNotEmpty ? user.name : 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'สมัครเมื่อ ${DateFormat('dd/MM/yyyy').format(user.joinedDate)}',
                                      style: const TextStyle(
                                        fontSize: AppTheme.meta,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusPill(
                                text: user.role.toUpperCase(),
                                color: user.role == 'admin'
                                    ? const Color(0xFF8A5CF6)
                                    : AppTheme.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (user.uid == myUid)
                            const Text(
                              'บัญชีนี้คือบัญชีของคุณ',
                              style: TextStyle(
                                fontSize: AppTheme.meta,
                                color: AppTheme.mutedText,
                              ),
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _showRoleDialog(context, user, firestore),
                                    icon: const Icon(Icons.manage_accounts),
                                    label: const Text('เปลี่ยนสิทธิ์'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: _dialogPrimaryButtonStyle(
                                      backgroundColor: AppTheme.error,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(context, user, firestore),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('ลบบัญชี'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
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
    final maxVal = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ฟีเจอร์ที่ผู้ใช้ชอบ',
            style: TextStyle(
              fontSize: AppTheme.title,
              fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.tintedCard(AppTheme.primaryColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppTheme.body,
                    color: AppTheme.mutedText,
                    height: 1.45,
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
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.elevatedCard(
          borderColor: color.withOpacity(0.14),
          boxShadow: AppTheme.softShadow(color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.meta,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
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
            fontSize: AppTheme.title,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: AppTheme.body,
            color: AppTheme.mutedText,
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
        color: color.withOpacity(0.10),
        borderRadius: AppTheme.pillRadius,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppTheme.meta,
          fontWeight: FontWeight.w700,
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
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final isAdmin = user.role == 'admin';
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
