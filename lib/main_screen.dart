import 'package:flutter/material.dart';
import 'package:foodcal/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'models/daily_log.dart';
import 'constants/enums.dart';
import 'models/user_profile.dart';
import 'screens/admin_screen.dart';
import 'screens/content_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tracking_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/app_logger.dart';

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
        final firestoreService =
            Provider.of<FirestoreService>(context, listen: false);
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
        backgroundColor: AppTheme.pageBg,
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
            backgroundColor: AppTheme.pageBg,
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
            backgroundColor: AppTheme.pageBg,
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
        if (UserRole.fromString(userProfile.role) == UserRole.admin) {
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
              appBar: null,
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

  Widget _buildBottomBar(double screenWidth) {
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 10 : 16,
          0,
          isCompact ? 10 : 16,
          isCompact ? 10 : 16,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 8 : 10,
            isCompact ? 8 : 10,
            isCompact ? 8 : 10,
            isCompact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.softShadow(AppTheme.ink),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  LucideIcons.home,
                  'หน้าแรก',
                  0,
                  compact: isCompact,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  LucideIcons.bookOpen,
                  'บันทึก',
                  1,
                  compact: isCompact,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
                child: _buildScanNavAction(isCompact),
              ),
              Expanded(
                child: _buildNavItem(
                  LucideIcons.bookMarked,
                  'เนื้อหา',
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
        AppLogger.warn('Unable to sync daily visit: $error');
        _lastSyncedVisitKey = null;
      }
    });
  }

  Widget _buildScanNavAction(bool compact) {
    return Transform.translate(
      offset: const Offset(0, -8),
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
          width: compact ? 50 : 54,
          height: compact ? 50 : 54,
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.32),
                blurRadius: 18,
                spreadRadius: -6,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.scan,
            color: Colors.white,
            size: 24,
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
          vertical: compact ? 8 : 9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 38,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: AppTheme.innerRadius,
              ),
              child: Icon(
                icon,
                color: active ? AppTheme.primaryColor : AppTheme.mutedText,
                size: compact ? 19 : 21,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active ? AppTheme.primaryColor : AppTheme.mutedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
