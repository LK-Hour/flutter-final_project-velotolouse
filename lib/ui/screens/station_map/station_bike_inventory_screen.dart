import 'package:final_project_velotolouse/data/repositories/bikes/firebase_station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/domain/model/stations/station.dart';
import 'package:final_project_velotolouse/domain/model/stations/station_bike_inventory_item.dart';
import 'package:final_project_velotolouse/domain/repositories/bikes/station_bike_inventory_repository.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/ui/widgets/animated_reveal_card.dart';
import 'package:flutter/material.dart';

class StationBikeInventoryScreen extends StatelessWidget {
  const StationBikeInventoryScreen({
    super.key,
    required this.station,
    this.repository,
  });

  final Station station;
  final StationBikeInventoryRepository? repository;

  @override
  Widget build(BuildContext context) {
    final StationBikeInventoryRepository bikeRepository =
        repository ?? FirebaseStationBikeInventoryRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Station Bikes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<List<StationBikeInventoryItem>>(
        future: bikeRepository.fetchBikesForStation(station.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unable to load bikes for ${station.name}.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final List<StationBikeInventoryItem> items =
              snapshot.data ?? const <StationBikeInventoryItem>[];
          final int availableCount = items
              .where((item) => item.isAvailable)
              .length;
          final int unavailableCount = items.length - availableCount;

          return RefreshIndicator(
            onRefresh: () async {
              (context as Element).markNeedsBuild();
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                AnimatedRevealCard(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bike inventory overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          station.name,
                          style: const TextStyle(
                            color: AppColors.neutralText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'Available',
                                value: '$availableCount',
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Unavailable',
                                value: '$unavailableCount',
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Total',
                                value: '${items.length}',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedRevealCard(
                  delay: const Duration(milliseconds: 120),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bike Slots',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${items.length} slots total',
                              style: const TextStyle(
                                color: AppColors.neutralText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          const Text(
                            'No bikes in this station.',
                            style: TextStyle(color: AppColors.neutralText),
                          )
                        else
                          ...items.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key == items.length - 1 ? 0 : 10,
                              ),
                              child: _BikeSlotRow(
                                item: entry.value,
                                delay: Duration(milliseconds: 35 * entry.key),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BikeSlotRow extends StatelessWidget {
  const _BikeSlotRow({required this.item, required this.delay});

  final StationBikeInventoryItem item;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item.isAvailable;
    final Color rowColor = isAvailable
        ? AppColors.success.withOpacity(0.10)
        : const Color(0xFFF1F1F1);
    final Color leadingColor = isAvailable
        ? AppColors.success
        : const Color(0xFFCFCFCF);

    return AnimatedRevealCard(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAvailable
                ? AppColors.success.withOpacity(0.16)
                : const Color(0xFFE3E3E3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: leadingColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                item.slotId.replaceAll(RegExp(r'[^0-9]'), ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.bikeCode ?? item.slotId,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isAvailable
                            ? Icons.electric_bike_rounded
                            : Icons.do_not_disturb_on_outlined,
                        size: 15,
                        color: isAvailable
                            ? AppColors.success
                            : AppColors.neutralText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAvailable ? 'Available' : 'Empty slot',
                        style: TextStyle(
                          color: isAvailable
                              ? AppColors.success
                              : AppColors.neutralText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isAvailable ? () {} : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF15B00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE1E1E1),
                disabledForegroundColor: const Color(0xFF9A9A9A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Scan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutralText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
