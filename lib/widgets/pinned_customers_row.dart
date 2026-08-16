import 'package:flutter/material.dart';

import '../models/customer.dart';
import 'pinned_customer_card.dart';

/// Horizontal, drag-to-reorder row of [PinnedCustomerCard]s for the Home
/// dashboard. Presentational only — forwards `onReorder`'s raw indices to
/// the caller, which is expected to wire them to
/// `CustomerProvider.reorderPinnedCustomers`.
class PinnedCustomersRow extends StatelessWidget {
  const PinnedCustomersRow({
    super.key,
    required this.pinnedCustomers,
    required this.onReorder,
    required this.onTapCustomer,
  });

  final List<Customer> pinnedCustomers;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Customer customer) onTapCustomer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: pinnedCustomers.length,
        onReorderItem: onReorder,
        itemBuilder: (context, index) {
          final customer = pinnedCustomers[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(customer.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PinnedCustomerCard(
                customer: customer,
                onTap: () => onTapCustomer(customer),
              ),
            ),
          );
        },
      ),
    );
  }
}
