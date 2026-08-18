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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final filter in UtangFilter.values) ...[
              Flexible(
                child: FilterChip(
                  label: Text(
                    _filterLabels[filter]!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  showCheckmark: false,
                  selected: utangFilter == filter,
                  onSelected: (_) => onFilterChanged(filter),
                ),
              ),
              if (filter != UtangFilter.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<CustomerSort>(
                      value: sortMode,
                      borderRadius: BorderRadius.circular(16),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
