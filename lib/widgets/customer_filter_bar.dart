import 'package:flutter/material.dart';

import '../providers/customer_provider.dart';

/// Utang-status filter chips plus a sort selector, for [CustomerListScreen].
class CustomerFilterBar extends StatelessWidget {
  const CustomerFilterBar({
    super.key,
    required this.utangFilter,
    required this.sortMode,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final UtangFilter utangFilter;
  final CustomerSort sortMode;
  final ValueChanged<UtangFilter> onFilterChanged;
  final ValueChanged<CustomerSort> onSortChanged;

  static const _filterLabels = {
    UtangFilter.all: 'All',
    UtangFilter.hasUtang: 'Has Utang',
    UtangFilter.fullyPaid: 'Fully Paid',
  };

  static const _sortLabels = {
    CustomerSort.nameAsc: 'Name (A–Z)',
    CustomerSort.balanceHighToLow: 'Balance: High to Low',
    CustomerSort.balanceLowToHigh: 'Balance: Low to High',
    CustomerSort.recentlyAdded: 'Recently Added',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              for (final filter in UtangFilter.values)
                FilterChip(
                  label: Text(_filterLabels[filter]!),
                  selected: utangFilter == filter,
                  onSelected: (_) => onFilterChanged(filter),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<CustomerSort>(
          value: sortMode,
          items: [
            for (final sort in CustomerSort.values)
              DropdownMenuItem(
                value: sort,
                child: Text(_sortLabels[sort]!, style: const TextStyle(fontSize: 16)),
              ),
          ],
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
        ),
      ],
    );
  }
}
