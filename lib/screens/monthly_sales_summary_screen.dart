import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/weekday_sales_bar_chart.dart';

/// Shows a month's total sales plus a pedometer-style bar chart of average
/// sales per day of the week, to help an owner spot their best/worst
/// selling weekdays at a glance.
class MonthlySalesSummaryScreen extends StatefulWidget {
  const MonthlySalesSummaryScreen({super.key, required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<MonthlySalesSummaryScreen> createState() => _MonthlySalesSummaryScreenState();
}

class _MonthlySalesSummaryScreenState extends State<MonthlySalesSummaryScreen> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late DateTime _focusedMonth =
      DateTime(widget.initialMonth.year, widget.initialMonth.month);

  bool _loading = true;
  double _monthTotal = 0;
  Map<int, double> _weekdayAverages = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final totals =
        await context.read<TransactionProvider>().salesTotalsForMonth(_focusedMonth);

    final weekdaySums = <int, double>{for (var w = 1; w <= 7; w++) w: 0};
    final weekdayCounts = <int, int>{for (var w = 1; w <= 7; w++) w: 0};
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    var monthTotal = 0.0;
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final amount = totals[day] ?? 0;
      weekdaySums[day.weekday] = weekdaySums[day.weekday]! + amount;
      weekdayCounts[day.weekday] = weekdayCounts[day.weekday]! + 1;
      monthTotal += amount;
    }

    if (!mounted) return;
    setState(() {
      _monthTotal = monthTotal;
      _weekdayAverages = {
        for (var w = 1; w <= 7; w++)
          w: weekdayCounts[w]! > 0 ? weekdaySums[w]! / weekdayCounts[w]! : 0,
      };
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta));
    _load();
  }

  String get _monthLabel => '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';

  String _formatAmount(double amount) => '₱${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Sales Summary')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        _monthLabel,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Sales', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          _formatAmount(_monthTotal),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _monthTotal > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Average sales by day of week',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  WeekdaySalesBarChart(weekdayAverages: _weekdayAverages),
                ],
              ),
            ),
    );
  }
}
