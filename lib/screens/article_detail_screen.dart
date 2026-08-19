import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../models/content_model.dart';

const Color _articleSurface = Color(0xFFF8FAFC);
const Color _articleInk = Color(0xFF111318);
const Color _articleMuted = Color(0xFF566070);

class ArticleDetailScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleDetailScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final PageController _pageController;

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
      backgroundColor: AppTheme.pageBg,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.articles.length,
          itemBuilder: (context, index) {
            return _buildArticlePage(widget.articles[index]);
          },
        ),
      ),
    );
  }

  Widget _buildArticlePage(Article article) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = AppTheme.horizontalPaddingForWidth(screenWidth);
    final maxContentWidth = AppTheme.maxContentWidth(screenWidth);
    final heroHeight = screenWidth < 380 ? 260.0 : 300.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: heroHeight,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          surfaceTintColor: Colors.transparent,
          leadingWidth: 160,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
            child: _BackLabelButton(
              label: article.category,
              onTap: () => Navigator.pop(context),
            ),
          ),
          titleSpacing: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.pageTintStrong,
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.image,
                      color: AppTheme.secondaryColor,
                      size: 40,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Color(0x4010233F),
                        Color(0xE6F8FAFC),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildArticleCard(article),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(Article article) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _articleSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.pillRadius,
            ),
            child: Text(
              article.category,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _articleInk,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: LucideIcons.clock3,
                label: 'อ่าน 3 นาที',
                color: AppTheme.primaryColor,
              ),
              _MetaPill(
                icon: LucideIcons.sparkles,
                label: 'สรุปสั้น เข้าใจง่าย',
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          ..._buildBodyContent(article.body),
        ],
      ),
    );
  }

  List<Widget> _buildBodyContent(String body) {
    final blocks = body
        .trim()
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty)
        .toList();

    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final lines = block
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        continue;
      }

      final title = lines.first;
      final remaining = lines.skip(1).toList();
      final isSection = remaining.isNotEmpty && !_isListLine(title);

      if (isSection) {
        widgets.add(
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _articleInk,
              height: 1.3,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 12));
        widgets.addAll(_buildLines(remaining));
      } else {
        widgets.addAll(_buildLines(lines));
      }

      if (i != blocks.length - 1) {
        widgets.add(const SizedBox(height: 22));
      }
    }

    return widgets;
  }

  List<Widget> _buildLines(List<String> lines) {
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isListLine = _isListLine(line);

      widgets.add(
        isListLine
            ? _ArticleListRow(text: _stripListPrefix(line))
            : Text(
                line,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.8,
                  color: _articleMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
      );

      if (i != lines.length - 1) {
        widgets.add(SizedBox(height: isListLine ? 10 : 14));
      }
    }

    return widgets;
  }

  bool _isListLine(String line) {
    return RegExp(r'^(-|\d+\.)\s+').hasMatch(line);
  }

  String _stripListPrefix(String line) {
    return line.replaceFirst(RegExp(r'^(-|\d+\.)\s+'), '');
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleListRow extends StatelessWidget {
  final String text;

  const _ArticleListRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: AppTheme.macroBg(AppTheme.primaryColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            LucideIcons.check,
            size: 14,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: _articleMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BackLabelButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BackLabelButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: AppTheme.innerRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.innerRadius,
        child: SizedBox(
          width: 136,
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.chevronLeft,
                  color: _articleInk,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
