
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'models/user_profile.dart';
import 'models/daily_log.dart';
import 'screens/home_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/content_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/history_screen.dart';
import 'package:foodcal/app_theme.dart';
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) {
      // Should handle by AuthWrapper, but safe check
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<UserProfile?>(
      stream: firestoreService.streamUserProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('UID: ${user.uid}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Retry manually if needed, or just let stream retry? Stream might not retry automatically.
                        // For now just allow user to see the error.
                        setState(() {}); 
                      },
                      child: const Text('ลองใหม่'),
                    )
                  ],
                ),
              ),
            ),
          );
        }
        
        // If no profile, show Onboarding
        if (!snapshot.hasData || snapshot.data == null) {
          return const OnboardingScreen();
        }

        final userProfile = snapshot.data!;

        return StreamBuilder<List<DailyLog>>(
          stream: firestoreService.streamDailyLogs(user.uid, limit: 7),
          builder: (context, logsSnap) {
            final weeklyLogs = logsSnap.data ?? [];
            final dailyLog = weeklyLogs.isNotEmpty &&
                    weeklyLogs.first.date == FirestoreService.utcDateKey()
                ? weeklyLogs.first 
                : null;
            
            final List<Widget> pages = [
              DashboardScreen(
                profile: userProfile, 
                log: dailyLog,
                weeklyLogs: weeklyLogs,
                onSwitchTab: (index) => setState(() => _currentIndex = index)
              ),
              TrackingScreen(log: dailyLog, profile: userProfile),
              ContentScreen(log: dailyLog),
              ProfileScreen(profile: userProfile),
            ];

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: _currentIndex == 0 ? _buildHomeAppBar(userProfile) : null, // Custom AppBar for Home only or simplify
              body: SafeArea(
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
              floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
                ? FloatingActionButton.extended(
                    onPressed: () {
                      // Navigate to tracking tab and trigger scan
                      setState(() => _currentIndex = 1);
                      // How to trigger scan? Maybe use a notification or a key.
                      // For now, just switch to tab and notify the user.
                    },
                    backgroundColor: AppTheme.primaryColor,
                    icon: const Icon(LucideIcons.camera, color: Colors.white),
                    label: const Text('สแกนอาหาร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : null,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(LucideIcons.activity, 'หน้าหลัก', 0),
                    _buildNavItem(LucideIcons.utensils, 'บันทึก', 1),
                    _buildNavItem(LucideIcons.play, 'เรียนรู้', 2),
                    _buildNavItem(LucideIcons.user, 'โปรไฟล์', 3),
                  ],
                ),
              ),
            );
          }
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
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                  image: profile.photoUrl != null
                    ? DecorationImage(
                        image: profile.photoUrl!.startsWith('data:')
                          ? MemoryImage(base64Decode(profile.photoUrl!.split(',')[1])) as ImageProvider
                          : NetworkImage(profile.photoUrl!), 
                        fit: BoxFit.cover
                      )
                    : null,
                ),
                child: profile.photoUrl == null
                  ? Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'F',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    )
                  : null,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Foodcal', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          Text('สวัสดี, คุณ${profile.name}', style: TextStyle(fontSize: 10, color: Colors.blueGrey[300]), overflow: TextOverflow.ellipsis),
        ],
      ) as Widget, // Explicit cast in case of weird inference
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.history, color: Colors.blueAccent),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50], 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4)]
          ),
          child: Row(
            children: [
              Icon(LucideIcons.flame, color: Colors.orange[400], size: 16),
              const SizedBox(width: 4),
              Text('${profile.streak} วัน', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[900])),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.blue[600] : Colors.blueGrey[200], size: 24),
            Text(label, style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: active ? Colors.blue[600] : Colors.blueGrey[200]
            )),
          ],
        ),
      ),
    );
  }
}
