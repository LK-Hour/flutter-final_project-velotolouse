import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

typedef SuggestionLabelBuilder = String Function(Station station);

class StationRerouteAlert extends StatelessWidget {
  const StationRerouteAlert({
    super.key,
    required this.selectedStation,
    required this.suggestedStation,
    required this.onReroute,
    required this.onClose,
    this.title = 'Destination Full',
    this.description,
    this.noSuggestionMessage = 'No nearby station with free docks found.',
    this.suggestionLabelBuilder,
    this.rerouteButtonText = 'Reroute to Free Dock',
  });

  final Station selectedStation;
  final Station? suggestedStation;
  final VoidCallback onReroute;
  final VoidCallback onClose;
  final String title;
  final String? description;
  final String noSuggestionMessage;
  final SuggestionLabelBuilder? suggestionLabelBuilder;
  final String rerouteButtonText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.neutralText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description ??
                'Your selected station ${selectedStation.name} has no available docks.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'SUGGESTED ALTERNATIVE',
            style: TextStyle(
              color: AppColors.neutralText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 8),
          if (suggestedStation == null)
            Text(
              noSuggestionMessage,
              style: TextStyle(
                color: AppColors.neutralText,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            )
          else
            Row(
              children: <Widget>[
                const Icon(Icons.place_outlined, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        suggestedStation!.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        suggestionLabelBuilder?.call(suggestedStation!) ??
                            '${suggestedStation!.freeDocks} spots open',
                        style: const TextStyle(
                          color: AppColors.neutralText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: suggestedStation == null ? null : onReroute,
              child: Text(rerouteButtonText),
            ),
          ),
        ],
      ),
    );
  }
}
