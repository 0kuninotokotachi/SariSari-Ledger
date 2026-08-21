import 'package:flutter/material.dart';

import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

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

  /// `+` for money coming in (a new loan given, or a cash sale), `-` for
  /// money going out of the till/ledger (a payment reducing utang owed).
  String get _sign =>
      transaction.type == TransactionType.utangPayment ? '-' : '+';

  Color _color(BuildContext context) {
    switch (transaction.type) {
      case TransactionType.utangCredit:
        return Colors.red.shade700;
      case TransactionType.utangPayment:
        return Colors.green.shade700;
      case TransactionType.sale:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final sign = _sign;
    final isCredit = transaction.type == TransactionType.utangCredit;

    final subtitleParts = [
      if (transaction.description?.isNotEmpty ?? false) transaction.description!,
      if (isCredit && transaction.dueDate != null)
        'Due: ${_formatDate(transaction.dueDate!)}',
    ];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(
          transaction.type == TransactionType.utangPayment
              ? Icons.arrow_downward
              : Icons.arrow_upward,
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
