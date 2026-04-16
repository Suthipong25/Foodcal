import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/feedback_log.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  final UserProfile profile;
  const AdminScreen({super.key, required this.profile});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.profile.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
            child: Text('You do not have permission to view this page.')),
      );
    }

    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: StreamBuilder<List<FeedbackLog>>(
        stream: firestore.streamAllFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No feedback yet.'));
          }

          final avgRating =
              logs.map((l) => l.rating).reduce((a, b) => a + b) / logs.length;

          final featureCounts = <String, int>{};
          for (var l in logs) {
            featureCounts[l.favoriteFeature] =
                (featureCounts[l.favoriteFeature] ?? 0) + 1;
          }
          final topFeature = featureCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.maxContentWidth(screenWidth),
              ),
              child: ListView(
                padding: AppTheme.pageInsetsForWidth(screenWidth),
                children: [
                  _buildStatsCard(avgRating, topFeature, logs.length),
                  const SizedBox(height: 24),
                  const Text(
                    'Feedback Logs',
                    style: TextStyle(
                        fontSize: AppTheme.title,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  ...logs.map((log) => _buildFeedbackTile(log)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(
      double avgRating, String topFeature, int totalFeedback) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                  label: 'Avg Rating',
                  value: avgRating.toStringAsFixed(1),
                  icon: Icons.star,
                  color: Colors.orange),
              _StatItem(
                  label: 'Total Logs',
                  value: totalFeedback.toString(),
                  icon: Icons.people,
                  color: Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Top Feature: $topFeature',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.ink)),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(FeedbackLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.pageTintStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < log.rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 16,
                  );
                }),
              ),
              const Spacer(),
              Text(
                '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}',
                style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(log.comment.isEmpty ? '(No comment)' : log.comment),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.pageTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(log.favoriteFeature,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppTheme.ink)),
            Text(label,
                style:
                    const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
          ],
        )
      ],
    );
  }
}
