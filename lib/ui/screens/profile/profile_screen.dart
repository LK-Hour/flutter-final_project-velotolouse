import 'package:final_project_velotolouse/domain/repositories/subscription_plans/instant_payment_repository.dart';
import 'package:final_project_velotolouse/domain/model/subscription_plans/subscription_transaction.dart';
import 'package:final_project_velotolouse/ui/screens/profile/payment_history_screen.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/passes/annual_pass_screen.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/passes/daily_pass_screen.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/passes/monthly_pass_screen.dart';
import 'package:final_project_velotolouse/ui/screens/subscription_plans/state/subscription_refresh_notifier.dart';
import 'package:final_project_velotolouse/ui/theme/app_theme.dart';
import 'package:final_project_velotolouse/ui/widgets/pulsing_highlight_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingSubscription = true;
  bool _isCancelingSubscription = false;
  SubscriptionTransaction? _activeSubscription;
  SubscriptionRefreshNotifier? _subscriptionRefreshNotifier;

  @override
  void initState() {
    super.initState();
    _loadActiveSubscription();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = _maybeReadSubscriptionRefreshNotifier();
    if (!identical(_subscriptionRefreshNotifier, notifier)) {
      _subscriptionRefreshNotifier?.removeListener(
        _onSubscriptionRefreshChanged,
      );
      _subscriptionRefreshNotifier = notifier;
      _subscriptionRefreshNotifier?.addListener(_onSubscriptionRefreshChanged);
    }
  }

  SubscriptionRefreshNotifier? _maybeReadSubscriptionRefreshNotifier() {
    try {
      return context.read<SubscriptionRefreshNotifier>();
    } catch (_) {
      return null;
    }
  }

  void _onSubscriptionRefreshChanged() {
    if (!mounted) return;
    _loadActiveSubscription();
  }

  @override
  void dispose() {
    _subscriptionRefreshNotifier?.removeListener(_onSubscriptionRefreshChanged);
    super.dispose();
  }

  Future<void> _loadActiveSubscription() async {
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final repository = context.read<InstantPaymentRepository>();
      final transactions = await repository.fetchSubscriptionTransactions();
      final active = transactions.where((tx) => tx.status == 'active').toList();

      if (!mounted) return;
      setState(() {
        _activeSubscription = active.isNotEmpty ? active.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeSubscription = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingSubscription = false;
      });
    }
  }

  void _openSubscriptionPlan(BuildContext context) {
    final planId = _activeSubscription?.planId.toLowerCase();
    Widget destination;

    switch (planId) {
      case 'monthly':
        destination = const MonthlyPassScreen();
        break;
      case 'annual':
        destination = const AnnualPassScreen();
        break;
      case 'daily':
      default:
        destination = const DailyPassScreen();
        break;
    }

    Navigator.of(context)
        .push<SubscriptionTransaction>(
          MaterialPageRoute<SubscriptionTransaction>(
            builder: (_) => destination,
          ),
        )
        .then((result) async {
          if (!mounted) return;

          if (result is SubscriptionTransaction) {
            setState(() {
              _activeSubscription = result;
              _isLoadingSubscription = false;
            });
            return;
          }

          await _loadActiveSubscription();
        });
  }

  Future<void> _cancelActiveSubscription() async {
    if (_activeSubscription == null || _isCancelingSubscription) return;

    setState(() {
      _isCancelingSubscription = true;
    });

    try {
      final repository = context.read<InstantPaymentRepository>();
      await repository.cancelSubscriptionTransaction(_activeSubscription!.id);
      await _loadActiveSubscription();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription canceled successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel subscription.')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCancelingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baseSurfaceAlt,
      appBar: AppBar(
        backgroundColor: AppColors.baseSurfaceAlt,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
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
              child: const Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.baseSurface,
                    child: Icon(Icons.person, color: AppColors.slate, size: 28),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ronan The Best',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'The Best of the Best',
                          style: TextStyle(
                            color: AppColors.neutralText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingSubscription)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(
                    color: AppColors.warning,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            if (!_isLoadingSubscription && _activeSubscription != null)
              PulsingHighlightCard(
                margin: const EdgeInsets.only(bottom: 14),
                backgroundColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                pulseColor: const Color(0xFF15803D),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF15803D),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Subscription',
                            style: TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _activeSubscription!.planLabel,
                            style: const TextStyle(
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _isCancelingSubscription
                            ? null
                            : _cancelActiveSubscription,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(
                            color: Color(0xFFDC2626),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isCancelingSubscription
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFDC2626),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Account',
              style: TextStyle(
                color: AppColors.neutralText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            _ProfileActionTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Subscription Plans',
              subtitle: _activeSubscription != null
                  ? 'Current: ${_activeSubscription!.planLabel}'
                  : 'Daily, monthly, and annual passes',
              onTap: () => _openSubscriptionPlan(context),
            ),
            const SizedBox(height: 10),
            _ProfileActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Payment History',
              subtitle: 'View your recent ride transactions',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaymentHistoryScreen(
                      repository: context.read<InstantPaymentRepository>(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      shadowColor: const Color(0x12000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.baseSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.slate),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.neutralText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutralText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
