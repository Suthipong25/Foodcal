import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class WeightScreen extends StatefulWidget {
  final UserProfile profile;

  const WeightScreen({super.key, required this.profile});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? get _uid =>
      Provider.of<AuthService>(context, listen: false).currentUser?.uid;

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w == null || w <= 0 || w > 500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกน้ำหนักให้ถูกต้อง (kg)'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .logWeight(uid, w, note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim());
      _weightCtrl.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('บันทึกน้ำหนักเรียบร้อย ✓'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String dateKey) async {
    final uid = _uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบข้อมูลน้ำหนัก?'),
        content: Text('ต้องการลบข้อมูลวันที่ $dateKey ใช่หรือไม่'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await Provider.of<FirestoreService>(context, listen: false).deleteWeightLog(uid, dateKey);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('น้ำหนัก',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<List<WeightLog>>(
              stream: Provider.of<FirestoreService>(context, listen: false)
                  .streamWeightLogs(uid),
              builder: (context, snap) {
                final logs = snap.data ?? [];
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(screenWidth)),
                    child: ListView(
                      padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 32),
                      children: [
                        _buildLogCard(),
                        const SizedBox(height: 16),
                        if (logs.length >= 2) ...[
                          _buildChart(logs),
                          const SizedBox(height: 16),
                        ],
                        _buildHistory(logs),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLogCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: AppTheme.success.withValues(alpha: 0.12),
        boxShadow: AppTheme.softShadow(AppTheme.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.scale, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text('บันทึกน้ำหนักวันนี้',
                  style: TextStyle(
                      fontSize: AppTheme.title,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ชั่งน้ำหนักตอนเช้าก่อนกินข้าวเพื่อความแม่นยำ',
            style: TextStyle(fontSize: AppTheme.body, color: AppTheme.mutedText),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'น้ำหนัก (kg) เช่น 65.5',
              filled: true,
              fillColor: AppTheme.macroBg(AppTheme.success),
              border: const OutlineInputBorder(
                  borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              hintText: 'โน้ต (ไม่บังคับ) เช่น หลังกีฬา',
              filled: true,
              fillColor: AppTheme.pageTint,
              border: OutlineInputBorder(
                  borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                shape: const RoundedRectangleBorder(borderRadius: AppTheme.innerRadius),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<WeightLog> logs) {
    // logs are newest-first; we need oldest-first for chart
    final sorted = logs.reversed.toList();
    final target = widget.profile.targetWeight;
    final spots = sorted.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();
    final allWeights = sorted.map((l) => l.weightKg).toList();
    if (target != null) allWeights.add(target);
    final minY = (allWeights.reduce(math.min) - 2).clamp(0, double.infinity).toDouble();
    final maxY = allWeights.reduce(math.max) + 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: const Color(0xFFE3ECFA),
        boxShadow: AppTheme.softShadow(AppTheme.success),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('แนวโน้มน้ำหนัก',
              style: TextStyle(fontSize: AppTheme.title, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text('เป้าหมาย: $target kg',
                style: const TextStyle(fontSize: AppTheme.body, color: AppTheme.mutedText)),
          ],
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.8,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppTheme.pageTintStrong, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: AppTheme.mutedText),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                        final d = DateTime.tryParse(sorted[idx].date);
                        if (d == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat('d/M').format(d),
                              style: const TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: target != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: target,
                          color: AppTheme.warning.withValues(alpha: 0.5),
                          strokeWidth: 1.5,
                          dashArray: [5, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            labelResolver: (_) => 'เป้า',
                            style: const TextStyle(fontSize: 10, color: AppTheme.warning),
                          ),
                        ),
                      ])
                    : null,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppTheme.success,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppTheme.success,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.success.withValues(alpha: 0.15), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(List<WeightLog> logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.elevatedCard(color: Colors.white),
        child: const Center(
          child: Column(
            children: [
              Icon(LucideIcons.scale, size: 48, color: AppTheme.mutedText),
              SizedBox(height: 12),
              Text('ยังไม่มีข้อมูลน้ำหนัก',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: AppTheme.body)),
              SizedBox(height: 4),
              Text('บันทึกน้ำหนักวันแรกด้านบนได้เลย',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: AppTheme.meta)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: AppTheme.elevatedCard(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ประวัติน้ำหนัก',
              style: TextStyle(fontSize: AppTheme.title, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          const SizedBox(height: 12),
          ...logs.map((log) => _buildLogTile(log)),
        ],
      ),
    );
  }

  Widget _buildLogTile(WeightLog log) {
    final date = DateTime.tryParse(log.date);
    final label = date != null ? DateFormat('EEEEที่ d MMMM yyyy', 'th').format(date) : log.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.pageTint,
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.scale, color: AppTheme.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: AppTheme.body, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(log.note!,
                      style: const TextStyle(fontSize: AppTheme.meta, color: AppTheme.mutedText)),
                ],
              ],
            ),
          ),
          Text('${log.weightKg.toStringAsFixed(1)} kg',
              style: const TextStyle(
                  fontSize: AppTheme.title,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success)),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.mutedText),
            onPressed: () => _delete(log.date),
          ),
        ],
      ),
    );
  }
}
