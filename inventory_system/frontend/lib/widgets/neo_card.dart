import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A neo-brutalist card with a satisfying press effect.
/// On press, the shadow collapses and the card shifts down-right,
/// giving the illusion of being "pushed into" the surface.
class NeoCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const NeoCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding,
    this.width,
  });

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final borderCol = AppTheme.borderColor(context);
    final shadowList = _pressed ? <BoxShadow>[] : AppTheme.adaptiveShadow(context);
    final bgColor = widget.color ?? AppTheme.cardColor(context);

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppTheme.quickAnim,
        curve: Curves.easeOut,
        width: widget.width,
        transform: Matrix4.translationValues(
          _pressed ? 4 : 0,
          _pressed ? 4 : 0,
          0,
        ),
        padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark ? borderCol : Colors.black,
            width: AppTheme.borderWidth,
          ),
          boxShadow: shadowList,
        ),
        child: widget.child,
      ),
    );
  }
}
