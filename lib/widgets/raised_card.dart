import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// A soft, raised surface: a light edge on the top left and a deep shadow on
/// the bottom right. It presses in slightly when tapped.
class RaisedCard extends StatefulWidget {
  const RaisedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.highlighted = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final double radius;
  final bool highlighted;

  @override
  State<RaisedCard> createState() => _RaisedCardState();
}

class _RaisedCardState extends State<RaisedCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [OrdoColors.surfaceHigh, OrdoColors.surface],
            ),
            border: Border.all(
              color: widget.highlighted
                  ? OrdoColors.accent
                  : OrdoColors.outline,
              width: widget.highlighted ? 1.5 : 1,
            ),
            boxShadow: _pressed
                ? const []
                : const [
                    BoxShadow(
                      color: Color(0x0FFFFFFF),
                      offset: Offset(-3, -3),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Color(0xB3000000),
                      offset: Offset(6, 8),
                      blurRadius: 18,
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
