import 'package:flutter/material.dart';

import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  bool get _isCredit => transaction.type == TransactionType.utangCredit;

  String get _label {
    switch (transaction.type) {
      case TransactionType.utangCredit:
        return 'Credit';
      case TransactionType.utangPayment:
        return 'Payment';
      case TransactionType.sale:
        return 'Sale';
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = _isCredit ? Colors.red.shade700 : Colors.green.shade700;
    final sign = _isCredit ? '+' : '-';

    final subtitleParts = [
      if (transaction.description?.isNotEmpty ?? false) transaction.description!,
      if (_isCredit && transaction.dueDate != null)
        'Due: ${_formatDate(transaction.dueDate!)}',
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          _isCredit ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(
        '$_label · ${_formatDate(transaction.date)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(subtitleParts.join(' · '), style: const TextStyle(fontSize: 14)),
      trailing: Text(
        '$sign₱${transaction.amount.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
