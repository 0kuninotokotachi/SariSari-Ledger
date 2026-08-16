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
        proxyDecorator: (child, index, animation) {
          // The default proxyDecorator wraps the dragged item in an opaque,
          // elevated Material, which has two problems: the opaque fill
          // paints over the Card's own margin and this row's item padding
          // as a visible white box, and Material's physically-modeled
          // elevation shadow is biased downward (more so at higher
          // elevation), so it visibly sits lower than the Card's own resting
          // shadow. Use a plain, unoffset BoxShadow instead so the "lifted"
          // shadow stays centered under the card, in the same place as its
          // resting shadow.
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final double t = Curves.easeInOut.transform(animation.value);
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3 * t),
                      blurRadius: 12 * t,
                      spreadRadius: 1 * t,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: child,
          );
        },
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
