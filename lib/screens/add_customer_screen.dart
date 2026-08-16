import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _facebookController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _loanDate = DateTime.now();
  DateTime? _dueDate;
  bool _showDetails = false;
  bool _isSaving = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _facebookController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDueDate}) async {
    final initial = isDueDate ? (_dueDate ?? _loanDate) : _loanDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDueDate) {
        _dueDate = picked;
      } else {
        _loanDate = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _nameError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }

    final provider = context.read<CustomerProvider>();
    final name = _nameController.text.trim();

    setState(() => _isSaving = true);
    try {
      await provider.addCustomerWithInitialUtang(
        name: name,
        amount: double.parse(_amountController.text.trim()),
        loanDate: _loanDate,
        dueDate: _dueDate!,
        phoneNumber: _emptyToNull(_phoneController.text),
        address: _emptyToNull(_addressController.text),
        facebookId: _emptyToNull(_facebookController.text),
        email: _emptyToNull(_emailController.text),
        notes: _emptyToNull(_notesController.text),
        description: _emptyToNull(_descriptionController.text),
      );
      if (mounted) Navigator.of(context).pop();
    } on DuplicateCustomerNameException {
      setState(() {
        _nameError = 'This name is already registered';
        _isSaving = false;
      });
    } catch (_) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: 'Name *',
                errorText: _nameError,
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(labelText: 'Amount (₱) *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final amount = double.tryParse((value ?? '').trim());
                if (amount == null || amount <= 0) return 'Please enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Date Created (Loan Date) *',
              date: _loanDate,
              formatDate: _formatDate,
              onTap: () => _pickDate(isDueDate: false),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Due Date *',
              date: _dueDate,
              formatDate: _formatDate,
              onTap: () => _pickDate(isDueDate: true),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add Details', style: TextStyle(fontSize: 18)),
              value: _showDetails,
              onChanged: (value) => setState(() => _showDetails = value),
            ),
            if (_showDetails) ...[
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _facebookController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Facebook ID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(labelText: 'Loan Description'),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.formatDate,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          date == null ? 'Please select' : formatDate(date!),
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
