import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import '../widgets/customer_tile.dart';
import '../widgets/pinned_customers_row.dart';
import '../widgets/utang_summary_card.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'customer_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SariSari Ledger')),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final summary = UtangSummaryCard(
            totalUtang: provider.totalUtang,
            customerCount: provider.customers.length,
            customersWithUtang: provider.customersWithUtangCount,
          );

          final listNavTile = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('View Customer List', style: TextStyle(fontSize: 18)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                ),
              ),
            ),
          );

          if (provider.customers.isEmpty) {
            return Column(
              children: [
                summary,
                listNavTile,
                const Expanded(
                  child: Center(
                    child: Text(
                      'No customers yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            );
          }

          final pinned = provider.pinnedCustomers;

          return Column(
            children: [
              summary,
              listNavTile,
              if (pinned.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pinned',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PinnedCustomersRow(
                    pinnedCustomers: pinned,
                    onReorder: provider.reorderPinnedCustomers,
                    onTapCustomer: (customer) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerDetailScreen(customerId: customer.id),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Customers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.customers.length,
                  itemBuilder: (context, index) {
                    final customer = provider.customers[index];
                    return CustomerTile(
                      customer: customer,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customerId: customer.id),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
