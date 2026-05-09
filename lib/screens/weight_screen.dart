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
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';

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

    return AnimatedPageWrapper(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('น้ำหนัก',
                style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900)),
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: uid == null
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
                              const SizedBox(height: 18),
                              if (logs.length >= 2) ...[
                                _buildChart(logs),
                                const SizedBox(height: 18),
                              ],
                              _buildHistory(logs),
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

  Widget _buildLogCard() {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.scale, color: AppTheme.success, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('บันทึกน้ำหนักวันนี้',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ชั่งน้ำหนักตอนเช้าเพื่อความแม่นยำที่สุด',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'น้ำหนัก (kg) เช่น 65.5',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              hintText: 'โน้ตสั้น ๆ (ถ้ามี)',
            ),
          ),
          const SizedBox(height: 20),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('บันทึกข้อมูล', style: TextStyle(fontWeight: FontWeight.w800)),
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

    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('แนวโน้มน้ำหนัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ink)),
          if (target != null) ...[
            const SizedBox(height: 6),
            Text('เป้าหมายของคุณคือ $target kg',
                style: const TextStyle(fontSize: 13, color: AppTheme.mutedText, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 22),
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
                      const FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w700),
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
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat('d/M').format(d),
                              style: const TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w700)),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: target != null
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                          y: target,
                          color: AppTheme.warning.withValues(alpha: 0.4),
                          strokeWidth: 2,
                          dashArray: [8, 6],
                          label: HorizontalLineLabel(
                            show: true,
                            labelResolver: (_) => 'เป้าหมาย',
                            style: const TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ])
                    : null,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppTheme.success,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 5,
                        color: AppTheme.success,
                        strokeWidth: 3,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.success.withValues(alpha: 0.2), Colors.transparent],
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
      return const GlassCard(
        padding: EdgeInsets.all(40),
        opacity: 0.08,
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.scale, size: 48, color: AppTheme.mutedText),
              SizedBox(height: 16),
              Text('ยังไม่มีข้อมูลน้ำหนัก',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 15, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('บันทึกน้ำหนักวันแรกด้านบนได้เลย',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(22),
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ประวัติน้ำหนัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ink)),
          const SizedBox(height: 16),
          ...logs.map((log) => _buildLogTile(log)),
        ],
      ),
    );
  }

  Widget _buildLogTile(WeightLog log) {
    final date = DateTime.tryParse(log.date);
    final label = date != null ? DateFormat('EEEEที่ d MMMM yyyy', 'th').format(date) : log.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.scale, color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink)),
                if (log.note != null && log.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(log.note!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.mutedText, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          Text(log.weightKg.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.success)),
          const SizedBox(width: 4),
          const Text('kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.success)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.mutedText),
            onPressed: () => _delete(log.date),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
