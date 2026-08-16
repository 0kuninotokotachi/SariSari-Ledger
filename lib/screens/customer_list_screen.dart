import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_filter_bar.dart';
import '../widgets/customer_search_bar.dart';
import '../widgets/customer_tile.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  Future<void> _togglePin(BuildContext context, Customer customer) async {
    final provider = context.read<CustomerProvider>();
    try {
      if (customer.pinOrder != null) {
        await provider.unpinCustomer(customer.id);
      } else {
        await provider.pinCustomer(customer.id);
      }
    } on PinLimitExceededException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only pin up to ${e.limit} customers. Unpin one first.',
          ),
        ),
      );
    }
  }

  void _clearSearchAndFilters(CustomerProvider provider) {
    provider.setSearchQuery('');
    provider.setUtangFilter(UtangFilter.all);
    provider.setSortMode(CustomerSort.nameAsc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer List')),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.customers.isEmpty) {
            return const Center(
              child: Text(
                'No customers yet.',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          final filtered = provider.filteredCustomers;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CustomerSearchBar(
                  initialQuery: provider.searchQuery,
                  onChanged: provider.setSearchQuery,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomerFilterBar(
                  utangFilter: provider.utangFilter,
                  sortMode: provider.sortMode,
                  onFilterChanged: provider.setUtangFilter,
                  onSortChanged: provider.setSortMode,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No customers match your search or filter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => _clearSearchAndFilters(provider),
                                child: const Text('Clear Search & Filters'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return CustomerTile(
                            customer: customer,
                            showPinButton: true,
                            onPinToggle: () => _togglePin(context, customer),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customerId: customer.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
