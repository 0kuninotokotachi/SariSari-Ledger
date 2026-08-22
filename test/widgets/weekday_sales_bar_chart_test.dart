import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/widgets/weekday_sales_bar_chart.dart';

Future<void> _pump(WidgetTester tester, Map<int, double> weekdayAverages) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: WeekdaySalesBarChart(weekdayAverages: weekdayAverages)),
    ),
  );
}

Container _barContainer(Column bar) =>
    ((bar.children[2] as SizedBox).child! as Align).child! as Container;

void main() {
  testWidgets(
      'renders Sun-Sat in order with rising bars, weekend labels colored differently',
      (tester) async {
    await _pump(tester, {
      DateTime.sunday: 10,
      DateTime.monday: 20,
      DateTime.tuesday: 30,
      DateTime.wednesday: 40,
      DateTime.thursday: 50,
      DateTime.friday: 60,
      DateTime.saturday: 70,
    });

    final bars = tester.widgetList<Column>(find.byType(Column)).toList();
    expect(bars.length, 7);

    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const amounts = [10, 20, 30, 40, 50, 60, 70];

    double? previousHeight;
    for (var i = 0; i < 7; i++) {
      final amountText = bars[i].children[0] as Text;
      final labelText = bars[i].children[4] as Text;
      expect(amountText.data, '₱${amounts[i]}', reason: 'bar $i amount label');
      expect(labelText.data, labels[i], reason: 'bar $i weekday label');
      expect(
        labelText.style!.color,
        i == 0 || i == 6 ? Colors.red.shade400 : Colors.black87,
        reason: '${labels[i]} label color',
      );

      final height = _barContainer(bars[i]).constraints!.maxHeight;
      if (previousHeight != null) {
        expect(height, greaterThan(previousHeight), reason: 'bar $i taller than bar ${i - 1}');
      }
      previousHeight = height;
    }

    // The highest average (Saturday, the last/max value) fills the full chart height.
    expect(_barContainer(bars.last).constraints!.maxHeight, 160.0);
  });

  testWidgets('a zero-average weekday shows a gray stub with no amount label',
      (tester) async {
    await _pump(tester, {
      DateTime.sunday: 0,
      DateTime.monday: 100,
      DateTime.tuesday: 0,
      DateTime.wednesday: 0,
      DateTime.thursday: 0,
      DateTime.friday: 0,
      DateTime.saturday: 0,
    });

    final bars = tester.widgetList<Column>(find.byType(Column)).toList();

    final sunAmount = bars[0].children[0] as Text;
    expect(sunAmount.data, '');
    final sunColor = (_barContainer(bars[0]).decoration! as BoxDecoration).color;
    expect(sunColor, Colors.grey.shade300);

    final monAmount = bars[1].children[0] as Text;
    expect(monAmount.data, '₱100');
    final monColor = (_barContainer(bars[1]).decoration! as BoxDecoration).color;
    expect(monColor, Colors.green.shade600);
  });

  testWidgets('an all-zero month renders every bar at the minimum height, no NaN/crash',
      (tester) async {
    await _pump(tester, {for (var w = 1; w <= 7; w++) w: 0.0});

    final bars = tester.widgetList<Column>(find.byType(Column)).toList();
    for (final bar in bars) {
      final height = _barContainer(bar).constraints!.maxHeight;
      expect(height, 4.0);
      expect(height.isNaN, isFalse);
    }
  });

  testWidgets('missing weekday keys default to a zero-average stub bar', (tester) async {
    await _pump(tester, {DateTime.wednesday: 50});

    final bars = tester.widgetList<Column>(find.byType(Column)).toList();
    // Sunday (index 0) has no entry in the map at all.
    final sunAmount = bars[0].children[0] as Text;
    expect(sunAmount.data, '');
    expect(_barContainer(bars[0]).constraints!.maxHeight, 4.0);
  });
}
