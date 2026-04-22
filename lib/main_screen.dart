import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodcal/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'models/daily_log.dart';
import 'models/user_profile.dart';
import 'screens/admin_screen.dart';
import 'screens/content_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/weight_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _scanRequestVersion = 0;
  String? _lastSyncedVisitKey;
  bool _onboardingPushed = false;

  Stream<UserProfile?>? _userProfileStream;
  Stream<List<DailyLog>>? _dailyLogsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userProfileStream == null) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null) {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        _userProfileStream = firestoreService.streamUserProfile(user.uid);
        _dailyLogsStream = firestoreService.streamDailyLogs(user.uid, limit: 7);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (user == null || _userProfileStream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    return StreamBuilder<UserProfile?>(
      stream: _userProfileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'UID: ${user.uid}',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          // Navigate ด้วย Navigator แทนการ return ตรงๆ
          // เพื่อให้ OnboardingScreen มี state เป็นของตัวเอง ไม่ถูก reset เมื่อ StreamBuilder rebuild
          if (!_onboardingPushed) {
            _onboardingPushed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                  settings: const RouteSettings(name: '/onboarding'),
                ),
              );
            });
          }
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }
        // ถ้ามีข้อมูลโปรไฟล์แล้ว รีเซ็ต flag เผื่อออกจากระบบแล้วกลับมา
        _onboardingPushed = false;

        final userProfile = snapshot.data!;
        _syncDailyVisit(user.uid, firestoreService);

        // ถ้ายูสเซอร์เป็น Admin ให้เข้าหน้า Admin ทันที โดยไม่สนหน้าแท็บหลัก
        if (userProfile.role == 'admin') {
          return AdminScreen(profile: userProfile);
        }

        return StreamBuilder<List<DailyLog>>(
          stream: _dailyLogsStream,
          builder: (context, logsSnap) {
            final weeklyLogs = logsSnap.data ?? [];
            final dailyLog = weeklyLogs.isNotEmpty &&
                    weeklyLogs.first.date == FirestoreService.dateKey()
                ? weeklyLogs.first
                : null;

            final pages = <Widget>[
              DashboardScreen(
                profile: userProfile,
                log: dailyLog,
                weeklyLogs: weeklyLogs,
                onSwitchTab: (index) => setState(() => _currentIndex = index),
              ),
              TrackingScreen(
                log: dailyLog,
                profile: userProfile,
                scanRequestVersion: _scanRequestVersion,
              ),
              ContentScreen(log: dailyLog),
              ProfileScreen(profile: userProfile),
            ];

            return Scaffold(
              backgroundColor: AppTheme.pageBg,
              appBar: _currentIndex == 0 ? _buildHomeAppBar(userProfile) : null,
              body: SafeArea(
                bottom: false,
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
              bottomNavigationBar: _buildBottomBar(screenWidth),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildHomeAppBar(UserProfile profile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 0,
      titleSpacing: 16,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                  image: profile.photoUrl != null
                      ? DecorationImage(
                          image: profile.photoUrl!.startsWith('data:')
                              ? MemoryImage(
                                  base64Decode(profile.photoUrl!.split(',')[1]),
                                ) as ImageProvider
                              : NetworkImage(profile.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profile.photoUrl == null
                    ? Center(
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : 'F',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Foodcal',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'สวัสดี, คุณ${profile.name}',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blueGrey[300],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            LucideIcons.scale,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WeightScreen(profile: profile)),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            LucideIcons.history,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(LucideIcons.flame, color: Colors.orange[400], size: 16),
              const SizedBox(width: 4),
              Text(
                '${profile.streak} วัน',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(double screenWidth) {
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 6 : 12,
          isCompact ? 6 : 10,
          isCompact ? 6 : 12,
          isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                LucideIcons.activity,
                'หน้าหลัก',
                0,
                compact: isCompact,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                LucideIcons.utensils,
                'บันทึก',
                1,
                compact: isCompact,
              ),
            ),
            Expanded(child: _buildScanNavAction(isCompact)),
            Expanded(
              child: _buildNavItem(
                LucideIcons.play,
                'เรียนรู้',
                2,
                compact: isCompact,
              ),
            ),
            Expanded(
              child: _buildNavItem(
                LucideIcons.user,
                'โปรไฟล์',
                3,
                compact: isCompact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncDailyVisit(
    String uid,
    FirestoreService firestoreService,
  ) {
    final todayKey = FirestoreService.dateKey();
    if (_lastSyncedVisitKey == todayKey) return;

    _lastSyncedVisitKey = todayKey;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await firestoreService.updateLoginStreak(uid);
      } catch (error) {
        debugPrint('Unable to sync daily visit: $error');
        _lastSyncedVisitKey = null;
      }
    });
  }

  Widget _buildScanNavAction(bool compact) {
    final active = _currentIndex == 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = 1;
            _scanRequestVersion++;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: compact ? 44 : 54,
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? const [Color(0xFF1F6FEB), Color(0xFF3C8CFF)]
                  : const [Color(0xFF2E7CF6), Color(0xFF5DA7FF)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.camera, color: Colors.white, size: 18),
              if (!compact) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'สแกนอาหาร',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index, {
    required bool compact,
  }) {
    final active = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 6,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: active ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? Colors.blue[600] : Colors.blueGrey[200],
              size: compact ? 20 : 22,
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.blue[600] : Colors.blueGrey[200],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
