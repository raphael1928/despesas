import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionCard({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final dataAssinatura = subscription.isActive
        ? dateFormat.format(subscription.signUpDate)
        : '--/--/----';

    final dataRenovacao = subscription.isActive
        ? dateFormat.format(subscription.renewalDate)
        : '--/--/----';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SvgPicture.asset(
              subscription.iconPath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Data de Assinatura  $dataAssinatura'),
                Text('Data de Renovação   $dataRenovacao'),
              ],
            ),
          ),
          Icon(
            subscription.isActive ? Icons.check_circle : Icons.cancel,
            color: subscription.isActive ? Colors.green : Colors.red,
            size: 24,
          )
        ],
      ),
    );
  }
}
