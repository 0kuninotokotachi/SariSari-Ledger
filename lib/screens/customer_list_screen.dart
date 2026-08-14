import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import '../widgets/customer_tile.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

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

          return ListView.separated(
            itemCount: provider.customers.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
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
          );
        },
      ),
    );
  }
}
