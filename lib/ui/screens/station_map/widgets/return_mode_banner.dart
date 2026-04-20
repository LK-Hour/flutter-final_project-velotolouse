import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ReturnModeBanner extends StatelessWidget {
  const ReturnModeBanner({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.directions_bike_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Returning Mode ON',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Showing Free Docks nearby',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('return-mode-banner-close'),
            onPressed: onClose,
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
