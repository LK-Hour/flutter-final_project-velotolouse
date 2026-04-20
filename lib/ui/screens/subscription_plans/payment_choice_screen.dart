import 'package:flutter/material.dart';

import 'instant_payment_screen.dart';
import 'passes/daily_pass_screen.dart';

class PaymentChoiceScreen extends StatelessWidget {
  const PaymentChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black87),
        title: const Text(
          'Station Info',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _MapPreview(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How would you like to pay?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One ride or a subscription — you choose.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  PaymentOptionTile(
                    icon: Icons.flash_on,
                    iconColor: Color(0xFFF39A4A),
                    title: 'Instant Payment',
                    subtitle: 'Pay just for this ride via your card or bank.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InstantPaymentScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  PaymentOptionTile(
                    icon: Icons.calendar_month,
                    iconColor: Color(0xFF6BA4FF),
                    title: 'Subscription Plan',
                    subtitle: 'Daily, monthly or annual — save up to 45%.',
                    showChevron: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DailyPassScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E5EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/images/map_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _StationChip(
              title: 'PP Central Station',
              subtitle: 'Narakom Blvd | Street 214',
            ),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: _MapActionButton(
              icon: Icons.my_location,
              background: Colors.white,
            ),
          ),
          Positioned(
            right: 16,
            top: 70,
            child: _MapActionButton(
              icon: Icons.layers,
              background: Colors.white,
            ),
          ),
          Positioned(
            left: 70,
            top: 150,
            child: _ParkingTag(
              label: 'P 4 Free',
              background: const Color(0xFF39A965),
            ),
          ),
          Positioned(
            right: 60,
            top: 200,
            child: Column(
              children: const [
                _ParkingTag(
                  label: 'P 8 Free',
                  background: Color(0xFFF28C2A),
                ),
                SizedBox(height: 6),
                _SmallChip(text: '2 min away'),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentOptionTile extends StatelessWidget {
  const PaymentOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (showChevron || onTap != null)
                const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationChip extends StatelessWidget {
  const _StationChip({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF47A1F),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParkingTag extends StatelessWidget {
  const _ParkingTag({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_parking, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.icon, required this.background});

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }
}
