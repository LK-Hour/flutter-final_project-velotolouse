import 'dart:ui';

import 'package:flutter/material.dart';

class PulsingHighlightCard extends StatefulWidget {
  const PulsingHighlightCard({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    required this.pulseColor,
    this.margin,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.animate = true,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color pulseColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool animate;
  final Duration duration;

  @override
  State<PulsingHighlightCard> createState() => _PulsingHighlightCardState();
}

class _PulsingHighlightCardState extends State<PulsingHighlightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingHighlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      if (widget.animate && !_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget card = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        final double scale = widget.animate ? lerpDouble(0.995, 1.01, t)! : 1;
        final double blur = widget.animate ? lerpDouble(8, 14, t)! : 10;
        final double opacity = widget.animate
            ? lerpDouble(0.12, 0.22, t)!
            : 0.14;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: widget.borderRadius,
              border: Border.all(color: widget.borderColor),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.pulseColor.withOpacity(opacity),
                  blurRadius: blur,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );

    if (widget.margin == null) {
      return card;
    }

    return Container(margin: widget.margin, child: card);
  }
}
