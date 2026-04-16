import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ประวัติการบันทึก',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<DailyLog>>(
        stream: firestoreService.streamDailyLogs(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clipboardList,
                      size: 64, color: Colors.blueGrey[100]),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีข้อมูลการบันทึก',
                      style:
                          TextStyle(color: Colors.blueGrey[300], fontSize: 16)),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.maxContentWidth(screenWidth),
              ),
              child: ListView.builder(
                padding: AppTheme.pageInsetsForWidth(screenWidth),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildHistoryCard(context, log);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, DailyLog log) {
    DateTime date = DateTime.parse(log.date);
    String formattedDate = DateFormat('EEEEที่ d MMMM', 'th').format(date);

    // Quick macro targets from profile (simplified or passed down)
    // For now, let's just show absolute values as the profile targets might change daily.

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow(AppTheme.calorieColor),
        border: Border.all(color: AppTheme.calorieColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedDate,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.macroBg(AppTheme.calorieColor),
                  borderRadius: AppTheme.innerRadius,
                ),
                child: Text('${log.caloriesIn} kcal',
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMacroInfo('🥩', '${log.protein}g', AppTheme.proteinColor),
              const SizedBox(width: 12),
              _buildMacroInfo('🌾', '${log.carbs}g', AppTheme.carbsColor),
              const SizedBox(width: 12),
              _buildMacroInfo('🥑', '${log.fat}g', AppTheme.fatColor),
              const SizedBox(width: 12),
              _buildMacroInfo(
                  '💧', '${log.waterGlasses} แก้ว', AppTheme.waterColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.blueGrey[300])),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
