
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_model.dart';
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'article_detail_screen.dart';

class ContentScreen extends StatefulWidget {
  final DailyLog? log;
  const ContentScreen({Key? key, required this.log}) : super(key: key);

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    List<WorkoutVideo> filteredVideos = WORKOUT_VIDEOS;
    if (filter != 'All') {
      filteredVideos = WORKOUT_VIDEOS.where((v) => v.level == filter).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education Section
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: EDUCATION_ARTICLES.length,
              separatorBuilder: (c, i) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final article = EDUCATION_ARTICLES[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArticleDetailScreen(
                          articles: EDUCATION_ARTICLES,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[50]!),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.network(
                            article.imageUrl,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              height: 80,
                              color: Colors.blue[50],
                              child: Icon(LucideIcons.image, color: Colors.blue[200]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[400], letterSpacing: 1.2)),
                              const SizedBox(height: 2),
                              Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),

          // Workouts Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('คลังวิดีโอ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: filter,
                underline: const SizedBox(),
                items: ['All', 'Beginner', 'Intermediate', 'Expert']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e == 'All' ? 'ทั้งหมด' : e)))
                    .toList(),
                onChanged: (v) => setState(() => filter = v!),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Workout List
          ...filteredVideos.map((video) {
            final isDone = widget.log?.workouts.any((w) => w.id == video.id) ?? false;
            // Improved robust Video ID extraction
            String videoId = '';
            final regExp = RegExp(r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*');
            final match = regExp.firstMatch(video.youtubeUrl);
            if (match != null && match.group(7) != null && match.group(7)!.length == 11) {
              videoId = match.group(7)!;
            }
            
            // Use mqdefault as primary because hqdefault doesn't exist for all videos
            final thumbUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
            final fallbackThumbUrl = 'https://img.youtube.com/vi/$videoId/default.jpg';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final Uri url = Uri.parse(video.youtubeUrl);
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                         debugPrint('Could not launch ${video.youtubeUrl}');
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            thumbUrl,
                            width: 120, height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.network(
                              fallbackThumbUrl,
                              width: 120, height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 120, height: 68, 
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(LucideIcons.image, color: Colors.grey[300], size: 20),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9), 
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                          ),
                          child: const Icon(LucideIcons.play, color: Colors.white, size: 14),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                              child: Text(video.duration, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: video.level == 'Beginner' ? Colors.blue[50] : Colors.orange[50], 
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(video.level, style: TextStyle(fontSize: 10, color: video.level == 'Beginner' ? Colors.blue[600] : Colors.orange[800])),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: isDone ? null : () async {
                      final user = Provider.of<AuthService>(context, listen: false).currentUser;
                      if (user != null) {
                        await Provider.of<FirestoreService>(context, listen: false).finishWorkout(
                          user.uid, 
                          WorkoutItem(
                            id: video.id,
                            title: video.title,
                            level: video.level,
                            duration: video.duration,
                            type: video.type,
                            completedAt: DateTime.now(),
                          ));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDone ? Colors.blue[50] : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isDone ? LucideIcons.checkCircle : LucideIcons.dumbbell, 
                        color: isDone ? Colors.blueAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
