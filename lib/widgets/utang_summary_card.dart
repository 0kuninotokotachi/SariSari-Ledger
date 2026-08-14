import 'package:flutter/material.dart';

/// Dashboard header showing the store's total outstanding utang and
/// how many customers currently owe money.
class UtangSummaryCard extends StatelessWidget {
  const UtangSummaryCard({
    super.key,
    required this.totalUtang,
    required this.customerCount,
    required this.customersWithUtang,
  });

  final double totalUtang;
  final int customerCount;
  final int customersWithUtang;

  String get _formattedTotal => '₱${totalUtang.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Utang (Unpaid)',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formattedTotal,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$customersWithUtang of $customerCount customers owe you',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
