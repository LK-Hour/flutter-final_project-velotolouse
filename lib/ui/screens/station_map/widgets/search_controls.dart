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
                const Icon(
                  Icons.search,
                  color: AppColors.neutralText,
                  size: 20,
                ),
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
