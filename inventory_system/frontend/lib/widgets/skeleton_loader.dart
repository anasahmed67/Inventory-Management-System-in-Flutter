import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable skeleton loading placeholder that displays a shifting gradient (shimmer) animation.
/// Used to indicate that a layout structural element is fetching data.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius = 4,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final baseColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE8E8EE);
    final shimmerColor = isDark ? const Color(0xFF3A3A50) : const Color(0xFFF5F5FA);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, shimmerColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton card that mimics the product card layout.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final borderCol = AppTheme.borderColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 52,
            height: 52,
            borderRadius: AppTheme.radiusMd,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 180,
                  height: 16,
                  borderRadius: AppTheme.radiusSm,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 100,
                  height: 12,
                  borderRadius: AppTheme.radiusSm,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonLoader(
                      width: 60,
                      height: 22,
                      borderRadius: AppTheme.radiusMd,
                    ),
                    const SizedBox(width: 8),
                    SkeletonLoader(
                      width: 80,
                      height: 22,
                      borderRadius: AppTheme.radiusMd,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton card for stat cards on the dashboard.
class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final borderCol = AppTheme.borderColor(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderCol, width: AppTheme.borderWidth),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 54,
            height: 54,
            borderRadius: AppTheme.radiusMd,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 100,
                  height: 14,
                  borderRadius: AppTheme.radiusSm,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 70,
                  height: 26,
                  borderRadius: AppTheme.radiusSm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
