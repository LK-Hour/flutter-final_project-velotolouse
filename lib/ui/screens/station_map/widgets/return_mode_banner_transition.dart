import 'package:flutter/material.dart';

import 'return_mode_banner.dart';

class ReturnModeBannerTransition extends StatelessWidget {
  const ReturnModeBannerTransition({
    super.key,
    required this.visible,
    this.onClose,
  });

  final bool visible;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: visible
          ? ReturnModeBanner(
              key: const ValueKey('return-mode-banner'),
              onClose: onClose,
            )
          : const SizedBox(key: ValueKey('return-mode-empty')),
    );
  }
}
