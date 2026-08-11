import 'package:flutter/material.dart';

import '../models/customer.dart';

class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.customer});

  final Customer customer;

  String get _formattedUtang => '₱${customer.totalUtang.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasUtang = customer.totalUtang > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(
        customer.name,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      subtitle: customer.phoneNumber != null
          ? Text(customer.phoneNumber!, style: const TextStyle(fontSize: 16))
          : null,
      trailing: Text(
        _formattedUtang,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: hasUtang ? Colors.red.shade700 : Colors.green.shade700,
        ),
      ),
    );
  }
}
