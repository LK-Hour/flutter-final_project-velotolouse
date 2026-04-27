import 'package:final_project_velotolouse/domain/model/subscription_plans/instant_payment_transaction.dart';
import 'package:final_project_velotolouse/domain/model/subscription_plans/subscription_transaction.dart';
import 'package:final_project_velotolouse/domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.repository,
  });

  final InstantPaymentRepository repository;

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<_HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<_HistoryEntry>> _loadHistory() async {
    final results = await Future.wait([
      widget.repository.fetchInstantPaymentTransactions(),
      widget.repository.fetchSubscriptionTransactions(),
    ]);

    final instantItems =
        (results[0] as List<InstantPaymentTransaction>).map(_HistoryEntry.fromInstant);
    final subscriptionItems =
        (results[1] as List<SubscriptionTransaction>).map(_HistoryEntry.fromSubscription);

    final merged = <_HistoryEntry>[
      ...instantItems,
      ...subscriptionItems,
    ];

    merged.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return merged;
  }

  Future<void> _refresh() async {
    final refreshed = _loadHistory();
    setState(() {
      _historyFuture = refreshed;
    });
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseSurfaceAlt,
      appBar: AppBar(
        backgroundColor: AppColors.baseSurfaceAlt,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<List<_HistoryEntry>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Failed to load payment history.',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? const <_HistoryEntry>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const <Widget>[
                  SizedBox(height: 180),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 44,
                    color: AppColors.neutralText,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No payment history yet.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Your instant and subscription payments will appear here.',
                      style: TextStyle(
                        color: AppColors.neutralText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _TransactionCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.typeLabel,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.amountUsd,
    required this.createdAt,
    this.amountKhr,
  });

  factory _HistoryEntry.fromInstant(InstantPaymentTransaction item) {
    return _HistoryEntry(
      typeLabel: 'Instant',
      badge: item.core.bankShortName,
      title: item.core.bankName,
      subtitle:
          'Instant payment - Duration: ${item.rideDetails.duration}, Distance: ${item.rideDetails.distanceKm.toStringAsFixed(1)} km',
      amountUsd: item.core.amountUsd,
      amountKhr: item.rideDetails.amountKhr,
      createdAt: item.core.createdAt,
    );
  }

  factory _HistoryEntry.fromSubscription(SubscriptionTransaction item) {
    return _HistoryEntry(
      typeLabel: 'Subscription',
      badge: item.core.bankShortName,
      title: item.planLabel,
      subtitle: '${item.planLabel} paid via ${item.core.bankName}',
      amountUsd: item.core.amountUsd,
      createdAt: item.core.createdAt,
    );
  }

  final String typeLabel;
  final String badge;
  final String title;
  final String subtitle;
  final double amountUsd;
  final int? amountKhr;
  final DateTime? createdAt;
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final _HistoryEntry item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.baseSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.typeLabel,
                style: const TextStyle(
                  color: AppColors.neutralText,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(
                  color: AppColors.neutralText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: AppColors.neutralText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                'Amount',
                style: TextStyle(
                  color: AppColors.neutralText,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '\$${item.amountUsd.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (item.amountKhr != null) ...[
                const SizedBox(width: 8),
                Text(
                  '(${item.amountKhr} KHR)',
                  style: const TextStyle(
                    color: AppColors.neutralText,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Pending';
    }

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
