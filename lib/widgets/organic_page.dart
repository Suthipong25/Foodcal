import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'decorative_elements.dart';
import 'glass_card.dart';

class OrganicPage extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const OrganicPage({
    super.key,
    required this.child,
    this.bottomPadding = 110,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
      child: Stack(
        children: [
          const OrganicCircleDecoration(
            alignment: Alignment.topLeft,
            color: AppTheme.warmPeach,
            size: 220,
            opacity: 0.45,
          ),
          const OrganicCircleDecoration(
            alignment: Alignment.bottomRight,
            color: AppTheme.warmMint,
            size: 260,
            opacity: 0.5,
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppTheme.maxContentWidth(width),
              ),
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: AppTheme.pageInsetsForWidth(
                  width,
                  top: 18,
                  bottom: bottomPadding,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrganicHeroPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;
  final List<Widget> footer;

  const OrganicHeroPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = AppTheme.primaryColor,
    this.trailing,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.2,
      padding: const EdgeInsets.all(22),
      gradient: AppTheme.glassGradient(opacity: 0.18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          OrganicCircleDecoration(
            alignment: Alignment.topRight,
            color: color.withValues(alpha: 0.55),
            size: 118,
            opacity: 0.2,
          ),
          const LeafDecoration(
            alignment: Alignment.bottomRight,
            color: AppTheme.leafGreen,
            size: 62,
            opacity: 0.13,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.55)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow(color),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: color,
                            fontSize: AppTheme.meta,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: AppTheme.body,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (footer.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: footer,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class OrganicPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const OrganicPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: AppTheme.pillRadius,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class OrganicActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const OrganicActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        opacity: 0.13,
        padding: const EdgeInsets.all(16),
        borderColor: color.withValues(alpha: 0.18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
