import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StationMapSearchField extends StatelessWidget {
  const StationMapSearchField({
    super.key,
    this.onTap,
    this.placeholderText = 'Find a station or destination...',
  });

  final VoidCallback? onTap;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                const Icon(Icons.search, color: AppColors.neutralText, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    placeholderText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.neutralText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.tune, color: AppColors.warning, size: 19),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StationMapModeButton extends StatelessWidget {
  const StationMapModeButton({
    super.key,
    this.onTap,
    this.isReturnMode = false,
  });

  final VoidCallback? onTap;
  final bool isReturnMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('mode-toggle-button'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 42,
        decoration: BoxDecoration(
          color: isReturnMode ? AppColors.warning : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.baseSurface),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.phone_iphone_rounded,
          color: isReturnMode ? Colors.white : AppColors.warning,
          size: 16,
        ),
      ),
    );
  }
}
