import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import '../widgets/customer_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final provider = context.read<CustomerProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Customer'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              await provider.addCustomer(name);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SariSari Ledger')),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.customers.isEmpty) {
            return const Center(
              child: Text(
                'No customers yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.customers.length,
            itemBuilder: (context, index) {
              return CustomerTile(customer: provider.customers[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }
}
