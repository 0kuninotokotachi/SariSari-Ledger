import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/transaction.dart';
import '../providers/customer_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final Id customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() {
    _transactionsFuture =
        context.read<TransactionProvider>().transactionsForCustomer(widget.customerId);
  }

  Future<void> _reloadAll() async {
    await context.read<CustomerProvider>().loadCustomers();
    setState(_refreshTransactions);
  }

  Customer? _findCustomer(CustomerProvider provider) {
    for (final customer in provider.customers) {
      if (customer.id == widget.customerId) return customer;
    }
    return null;
  }

  Future<void> _openEditDialog(Customer customer) async {
    final phoneController = TextEditingController(text: customer.phoneNumber);
    final addressController = TextEditingController(text: customer.address);
    final facebookController = TextEditingController(text: customer.facebookId);
    final emailController = TextEditingController(text: customer.email);
    final notesController = TextEditingController(text: customer.notes);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Contact Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: facebookController,
                decoration: const InputDecoration(labelText: 'Facebook ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    String? emptyToNull(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    await context.read<CustomerProvider>().updateCustomerInfo(
          widget.customerId,
          phoneNumber: emptyToNull(phoneController.text),
          address: emptyToNull(addressController.text),
          facebookId: emptyToNull(facebookController.text),
          email: emptyToNull(emailController.text),
          notes: emptyToNull(notesController.text),
        );
    await _reloadAll();
  }

  Future<void> _openTransactionDialog({required bool isCredit}) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? dueDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickDate({required bool forDueDate}) async {
            final picked = await showDatePicker(
              context: dialogContext,
              initialDate: forDueDate ? (dueDate ?? date) : date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setDialogState(() {
              if (forDueDate) {
                dueDate = picked;
              } else {
                date = picked;
              }
            });
          }

          String formatDate(DateTime d) =>
              '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: Text(isCredit ? 'Add Credit' : 'Record Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Amount (₱)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Date: ${formatDate(date)}'),
                    onTap: () => pickDate(forDueDate: false),
                  ),
                  if (isCredit)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        dueDate == null
                            ? 'Select due date'
                            : 'Due date: ${formatDate(dueDate!)}',
                      ),
                      onTap: () => pickDate(forDueDate: true),
                    ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) return;
                  if (isCredit && dueDate == null) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || !mounted) return;

    final amount = double.parse(amountController.text.trim());
    final description = descriptionController.text.trim();
    final transactionProvider = context.read<TransactionProvider>();

    if (isCredit) {
      await transactionProvider.addUtangCredit(
        widget.customerId,
        amount: amount,
        date: date,
        dueDate: dueDate!,
        description: description.isEmpty ? null : description,
      );
    } else {
      await transactionProvider.addUtangPayment(
        widget.customerId,
        amount: amount,
        date: date,
        description: description.isEmpty ? null : description,
      );
    }

    await _reloadAll();
  }

  Future<void> _togglePin(Customer customer) async {
    final provider = context.read<CustomerProvider>();
    try {
      if (customer.pinOrder != null) {
        await provider.unpinCustomer(customer.id);
      } else {
        await provider.pinCustomer(customer.id);
      }
    } on PinLimitExceededException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only pin up to ${e.limit} customers. Unpin one first.',
          ),
        ),
      );
    }
  }

  String _formattedUtang(double amount) => '₱${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final customer = _findCustomer(provider);

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Details')),
            body: const Center(child: Text('Customer not found.', style: TextStyle(fontSize: 18))),
          );
        }

        final hasUtang = customer.totalUtang > 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: Icon(
                  customer.pinOrder != null ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                tooltip: customer.pinOrder != null ? 'Unpin customer' : 'Pin customer',
                onPressed: () => _togglePin(customer),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit contact info',
                onPressed: () => _openEditDialog(customer),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _reloadAll,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Utang Balance'),
                        const SizedBox(height: 4),
                        Text(
                          _formattedUtang(customer.totalUtang),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: hasUtang ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ContactInfo(customer: customer),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openTransactionDialog(isCredit: false),
                        icon: const Icon(Icons.check),
                        label: const Text('Record Payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openTransactionDialog(isCredit: true),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Credit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                FutureBuilder<List<Transaction>>(
                  future: _transactionsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final transactions = snapshot.data!;
                    if (transactions.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No transactions yet.', style: TextStyle(fontSize: 16)),
                      );
                    }
                    return Column(
                      children: [
                        for (final transaction in transactions)
                          TransactionTile(transaction: transaction),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContactInfo extends StatelessWidget {
  const _ContactInfo({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final entries = <(IconData, String)>[
      if (customer.phoneNumber?.isNotEmpty ?? false) (Icons.phone, customer.phoneNumber!),
      if (customer.address?.isNotEmpty ?? false) (Icons.location_on, customer.address!),
      if (customer.facebookId?.isNotEmpty ?? false) (Icons.facebook, customer.facebookId!),
      if (customer.email?.isNotEmpty ?? false) (Icons.email, customer.email!),
      if (customer.notes?.isNotEmpty ?? false) (Icons.notes, customer.notes!),
    ];

    if (entries.isEmpty) {
      return const Text(
        'No contact info yet. Add some using the edit button above.',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final (icon, text) in entries)
              ListTile(
                leading: Icon(icon),
                title: Text(text, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
