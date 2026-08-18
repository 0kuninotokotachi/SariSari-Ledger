import 'package:flutter/material.dart';

import '../models/customer.dart';

class CustomerTile extends StatelessWidget {
  const CustomerTile({
    super.key,
    required this.customer,
    this.onTap,
    this.showPinButton = false,
    this.onPinToggle,
  });

  final Customer customer;
  final VoidCallback? onTap;

  /// When true, renders a leading pin/unpin icon button. Defaults to false
  /// so existing call sites (e.g. Home dashboard's full customer list) are
  /// unaffected.
  final bool showPinButton;
  final VoidCallback? onPinToggle;

  String get _formattedUtang => '₱${customer.totalUtang.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final hasUtang = customer.totalUtang > 0;
    final isPinned = customer.pinOrder != null;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: showPinButton
          ? IconButton(
              icon: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: isPinned ? 'Unpin customer' : 'Pin customer',
              onPressed: onPinToggle,
            )
          : null,
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
