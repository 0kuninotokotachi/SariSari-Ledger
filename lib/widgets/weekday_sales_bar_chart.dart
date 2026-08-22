import 'package:flutter/material.dart';

/// A pedometer-style bar chart of average sales per day of the week
/// (Sun-Sat), used by `MonthlySalesSummaryScreen`.
class WeekdaySalesBarChart extends StatelessWidget {
  const WeekdaySalesBarChart({super.key, required this.weekdayAverages});

  /// Average sales amount keyed by `DateTime.weekday` (1 = Monday .. 7 =
  /// Sunday), covering every day of the month whether or not it had sales.
  final Map<int, double> weekdayAverages;

  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _weekdayOrder = [7, 1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    final maxAverage = weekdayAverages.values
        .fold<double>(0, (max, value) => value > max ? value : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < _weekdayOrder.length; i++)
          Expanded(
            child: _WeekdayBar(
              label: _labels[i],
              amount: weekdayAverages[_weekdayOrder[i]] ?? 0,
              maxAmount: maxAverage,
              isWeekend: _weekdayOrder[i] == DateTime.saturday ||
                  _weekdayOrder[i] == DateTime.sunday,
            ),
          ),
      ],
    );
  }
}

class _WeekdayBar extends StatelessWidget {
  const _WeekdayBar({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.isWeekend,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final bool isWeekend;

  static const double _chartHeight = 160;
  static const double _minBarHeight = 4;

  @override
  Widget build(BuildContext context) {
    final barColor = amount > 0 ? Colors.green.shade600 : Colors.grey.shade300;
    final labelColor = isWeekend ? Colors.red.shade400 : Colors.black87;
    final barHeight = maxAmount <= 0
        ? _minBarHeight
        : _minBarHeight + (amount / maxAmount) * (_chartHeight - _minBarHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount > 0 ? '₱${amount.toStringAsFixed(0)}' : '',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _chartHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 20,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: labelColor),
        ),
      ],
    );
  }
}
