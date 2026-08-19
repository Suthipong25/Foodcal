import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodcal/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'models/daily_log.dart';
import 'constants/enums.dart';
import 'models/user_profile.dart';
import 'screens/admin_screen.dart';
import 'screens/content_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tracking_screen.dart';
import 'widgets/glass_card.dart';
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
    final avatarImage = profile.photoUrl == null
        ? null
        : (profile.photoUrl!.startsWith('data:')
            ? MemoryImage(base64Decode(profile.photoUrl!.split(',')[1]))
                as ImageProvider
            : NetworkImage(profile.photoUrl!));

    return AppBar(
      toolbarHeight: 94,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8DF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
              image: avatarImage == null
                  ? null
                  : DecorationImage(image: avatarImage, fit: BoxFit.cover),
            ),
            child: avatarImage == null
                ? Center(
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'F',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี, คุณ${profile.name}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ยินดีต้อนรับกลับมาดูแลตัวเอง',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildTopAction(
          icon: LucideIcons.history,
          tooltip: 'ประวัติ',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        const SizedBox(width: 4),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 18, 16, 18),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF2DF), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.warning),
            boxShadow: AppTheme.softShadow(AppTheme.warning),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.flame, color: AppTheme.warning, size: 16),
              const SizedBox(width: 6),
              Text(
                '${profile.streak} วัน',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5F0DE)),
        boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppTheme.primaryColor, size: 18),
      ),
    );
  }

  Widget _buildBottomBar(double screenWidth) {
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 10 : 14,
          0,
          isCompact ? 10 : 14,
          isCompact ? 10 : 14,
        ),
        child: GlassCard(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 8 : 12,
            isCompact ? 8 : 10,
            isCompact ? 8 : 12,
            isCompact ? 8 : 12,
          ),
          opacity: 0.95,
          borderRadius: BorderRadius.circular(24),
          borderColor: const Color(0xFFE5F0DE),
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
    final active = _currentIndex == 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = 1;
            _scanRequestVersion++;
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabel = !compact && constraints.maxWidth >= 88;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: compact ? 50 : 58,
              padding: EdgeInsets.symmetric(horizontal: showLabel ? 14 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: active
                      ? const [Color(0xFF23A36E), Color(0xFF77D99C)]
                      : const [Color(0xFF77D99C), Color(0xFFEAF5E4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.camera,
                    color: active ? Colors.white : AppTheme.primaryColor,
                    size: 18,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'สแกน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active ? Colors.white : AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
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
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF5E4) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 20 : 0,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Icon(
              icon,
              color: active ? AppTheme.primaryColor : AppTheme.mutedText,
              size: compact ? 20 : 22,
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
