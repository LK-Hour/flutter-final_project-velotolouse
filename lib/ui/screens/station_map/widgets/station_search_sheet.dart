import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

typedef StationSearchQuery = List<Station> Function(String query);

class StationSearchSheet extends StatefulWidget {
  const StationSearchSheet({
    super.key,
    required this.onSearch,
    required this.onSelectStation,
    required this.isReturnMode,
  });

  final StationSearchQuery onSearch;
  final ValueChanged<String> onSelectStation;
  final bool isReturnMode;

  @override
  State<StationSearchSheet> createState() => _StationSearchSheetState();
}

class _StationSearchSheetState extends State<StationSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<Station> results = widget.onSearch(_query);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Search station',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('station-search-input'),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type station or address',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.baseSurface),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.warning),
                ),
              ),
              onChanged: (String value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Flexible(
              child: results.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No station found',
                          style: TextStyle(color: AppColors.neutralText),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final Station station = results[index];
                        return ListTile(
                          key: Key('search-result-${station.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: Icon(
                            widget.isReturnMode
                                ? Icons.keyboard_return_rounded
                                : Icons.directions_bike_rounded,
                            color: AppColors.slate,
                          ),
                          title: Text(
                            station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            station.address,
                            style: const TextStyle(
                              color: AppColors.neutralText,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            widget.isReturnMode
                                ? '${station.freeDocks} Docks'
                                : '${station.availableBikes} Bikes',
                            style: const TextStyle(
                              color: AppColors.slate,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => widget.onSelectStation(station.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
