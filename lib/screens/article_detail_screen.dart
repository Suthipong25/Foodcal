import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/content_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleDetailScreen({Key? key, required this.articles, required this.initialIndex}) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.articles.length,
        itemBuilder: (context, index) {
          final article = widget.articles[index];
          return _buildArticlePage(article);
        },
      ),
    );
  }

  Widget _buildArticlePage(Article article) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(article.category, style: TextStyle(color: Colors.blue[800], fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          pinned: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 16),
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.clock, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text('อ่าน 3 นาที', style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  article.body,
                  style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                ),
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }
}
