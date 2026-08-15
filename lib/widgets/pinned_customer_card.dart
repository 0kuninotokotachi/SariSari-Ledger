import 'package:flutter/material.dart';

import '../models/customer.dart';

/// Fixed-width card for the Home dashboard's pinned-customers row.
class PinnedCustomerCard extends StatelessWidget {
  const PinnedCustomerCard({super.key, required this.customer, this.onTap});

  final Customer customer;
  final VoidCallback? onTap;

  String get _formattedUtang => '₱${customer.totalUtang.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasUtang = customer.totalUtang > 0;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _formattedUtang,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasUtang ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
