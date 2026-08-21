import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  late DateTime _focusedMonth = _dateOnly(DateTime.now());
  late DateTime _selectedDay = _dateOnly(DateTime.now());

  Map<DateTime, double> _monthTotals = {};
  late Future<List<Transaction>> _dayFuture;

  @override
  void initState() {
    super.initState();
    _dayFuture = context.read<TransactionProvider>().salesForDay(_selectedDay);
    _loadMonthTotals();
  }

  Future<void> _loadMonthTotals() async {
    final totals =
        await context.read<TransactionProvider>().salesTotalsForMonth(_focusedMonth);
    if (!mounted) return;
    setState(() => _monthTotals = totals);
  }

  void _refreshDay() {
    _dayFuture = context.read<TransactionProvider>().salesForDay(_selectedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final day = _dateOnly(selectedDay);
    if (day == _selectedDay) return;
    final monthChanged =
        focusedDay.year != _focusedMonth.year || focusedDay.month != _focusedMonth.month;
    setState(() {
      _selectedDay = day;
      _focusedMonth = _dateOnly(focusedDay);
      _refreshDay();
    });
    if (monthChanged) _loadMonthTotals();
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() => _focusedMonth = _dateOnly(focusedDay));
    _loadMonthTotals();
  }

  double _totalFor(DateTime day) => _monthTotals[_dateOnly(day)] ?? 0;

  String _formatAmount(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  Future<void> _openAddSaleDialog() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime date = _selectedDay;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: dialogContext,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            setDialogState(() => date = _dateOnly(picked));
          }

          return AlertDialog(
            title: const Text('Add Sale'),
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
                    title: Text('Date: ${_formatDate(date)}'),
                    onTap: pickDate,
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

    await context.read<TransactionProvider>().addSale(
          amount: amount,
          date: date,
          description: description.isEmpty ? null : description,
        );

    if (!mounted) return;
    setState(() {
      _selectedDay = date;
      _focusedMonth = date;
      _refreshDay();
    });
    await _loadMonthTotals();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Sales')),
      body: Column(
        children: [
          TableCalendar<double>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedMonth,
            selectedDayPredicate: (day) => _dateOnly(day) == _selectedDay,
            eventLoader: (day) => _totalFor(day) > 0 ? [_totalFor(day)] : [],
            onDaySelected: _onDaySelected,
            onPageChanged: _onPageChanged,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(_selectedDay),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Total: ${_formatAmount(_totalFor(_selectedDay))}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _dayFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sales = snapshot.data!;
                if (sales.isEmpty) {
                  return const Center(
                    child: Text(
                      'No sales recorded for this day.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final sale in sales) TransactionTile(transaction: sale),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSaleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ),
    );
  }
}
