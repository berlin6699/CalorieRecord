import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

enum TrendMetric { net, carbs, protein, fat, exercise }

extension on TrendMetric {
  String get label => switch (this) {
    TrendMetric.net => '净能量',
    TrendMetric.carbs => '碳水',
    TrendMetric.protein => '蛋白质',
    TrendMetric.fat => '脂肪',
    TrendMetric.exercise => '运动消耗',
  };

  String get unit => switch (this) {
    TrendMetric.carbs || TrendMetric.protein || TrendMetric.fat => 'g',
    _ => 'kcal',
  };
}

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  int _days = 7;
  TrendMetric _metric = TrendMetric.net;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(appControllerProvider).requireValue.trends;
    final cutoff = dayOnly(DateTime.now()).subtract(Duration(days: _days - 1));
    final items = all
        .where((item) => !item.record.date.isBefore(cutoff))
        .toList();
    final averageNet = items.isEmpty
        ? 0.0
        : items.fold(0.0, (sum, item) => sum + item.netEnergy) / items.length;
    final net = items.fold(0.0, (sum, item) => sum + item.netEnergy);
    final deficitDays = items.where((item) => item.netEnergy < 0).length;
    return Scaffold(
      appBar: AppBar(title: const Text('趋势')),
      body: ContentFrame(
        maxWidth: 1100,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 34),
          children: [
            Center(
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 天')),
                  ButtonSegment(value: 30, label: Text('30 天')),
                  ButtonSegment(value: 90, label: Text('90 天')),
                ],
                selected: {_days},
                onSelectionChanged: (value) =>
                    setState(() => _days = value.first),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: '日均净能量',
                    value: '${averageNet > 0 ? '+' : ''}${averageNet.round()}',
                    unit: 'kcal',
                    icon: averageNet <= 0
                        ? Icons.south_east_rounded
                        : Icons.north_east_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '累计净收支',
                    value: '${net > 0 ? '+' : ''}${net.round()}',
                    unit: 'kcal',
                    icon: net <= 0
                        ? Icons.south_east_rounded
                        : Icons.north_east_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '热量缺口天数',
                    value: '$deficitDays',
                    unit: '天',
                    icon: Icons.calendar_view_week_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: _metric.label,
              subtitle: _metric == TrendMetric.net
                  ? '0 为平衡线，负数为缺口，正数为增加'
                  : _metric == TrendMetric.exercise
                  ? '共 ${items.length} 个有记录的日期'
                  : '实际摄入与每天保存的目标快照对比',
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<TrendMetric>(
                  value: _metric,
                  borderRadius: BorderRadius.circular(14),
                  items: TrendMetric.values
                      .map(
                        (metric) => DropdownMenuItem(
                          value: metric,
                          child: Text(metric.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _metric = value ?? _metric),
                ),
              ),
            ),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.insights_rounded,
                title: '还没有趋势数据',
                message: '开始记录餐食或运动后，这里会展示变化趋势',
              )
            else
              _TrendChart(items: items, metric: _metric),
            const SizedBox(height: 26),
            const SectionHeader(title: '营养达标概览', subtitle: '按所选周期内有记录的日期计算'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _AttainmentRow(
                      label: '碳水',
                      color: const Color(0xFF3B82F6),
                      value: _averageRatio(
                        items,
                        (x) => x.intake.carbsG,
                        (x) => x.record.target.carbsG,
                      ),
                    ),
                    _AttainmentRow(
                      label: '蛋白质',
                      color: const Color(0xFF8B5CF6),
                      value: _averageRatio(
                        items,
                        (x) => x.intake.proteinG,
                        (x) => x.record.target.proteinG,
                      ),
                    ),
                    _AttainmentRow(
                      label: '脂肪',
                      color: const Color(0xFFF59E0B),
                      value: _averageRatio(
                        items,
                        (x) => x.intake.fatG,
                        (x) => x.record.target.fatG,
                      ),
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items, required this.metric});

  final List<DailySummary> items;
  final TrendMetric metric;

  double _actual(DailySummary item) => switch (metric) {
    TrendMetric.net => item.netEnergy,
    TrendMetric.carbs => item.intake.carbsG,
    TrendMetric.protein => item.intake.proteinG,
    TrendMetric.fat => item.intake.fatG,
    TrendMetric.exercise => item.exerciseKcal,
  };

  double? _target(DailySummary item) => switch (metric) {
    TrendMetric.carbs => item.record.target.carbsG,
    TrendMetric.protein => item.record.target.proteinG,
    TrendMetric.fat => item.record.target.fatG,
    TrendMetric.net => 0,
    TrendMetric.exercise => null,
  };

  @override
  Widget build(BuildContext context) {
    final actual = [
      for (var i = 0; i < items.length; i++)
        FlSpot(i.toDouble(), _actual(items[i])),
    ];
    final targets = [
      for (var i = 0; i < items.length; i++)
        if (_target(items[i]) != null) FlSpot(i.toDouble(), _target(items[i])!),
    ];
    final allValues = [...actual.map((x) => x.y), ...targets.map((x) => x.y)];
    var minY = allValues.reduce(math.min);
    var maxY = allValues.reduce(math.max);
    final padding = math.max(10.0, (maxY - minY).abs() * 0.15);
    minY = metric == TrendMetric.net
        ? minY - padding
        : math.max(0, minY - padding);
    maxY += padding;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Legend(
                  color: brandGreen,
                  label: metric == TrendMetric.net
                      ? '实际净能量'
                      : metric == TrendMetric.exercise
                      ? '实际消耗'
                      : '实际摄入',
                ),
                if (targets.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _Legend(
                    color: const Color(0xFFB7C3BD),
                    label: metric == TrendMetric.net ? '平衡线（0）' : '当日目标',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, items.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFE8ECEA), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          value.round().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: math
                            .max(1, (items.length / 4).floor())
                            .toDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > items.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final index = value.round().clamp(
                            0,
                            items.length - 1,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('M/d')
                                  .format(items[index].record.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(spot.y.abs() < 100 ? 1 : 0)} ${metric.unit}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    if (targets.isNotEmpty)
                      LineChartBarData(
                        spots: targets,
                        color: const Color(0xFFB7C3BD),
                        barWidth: 2,
                        dashArray: [6, 5],
                        dotData: const FlDotData(show: false),
                      ),
                    LineChartBarData(
                      spots: actual,
                      color: brandGreen,
                      barWidth: 3,
                      isCurved: items.length > 2,
                      curveSmoothness: 0.25,
                      belowBarData: BarAreaData(
                        show: true,
                        color: brandGreen.withValues(alpha: 0.1),
                      ),
                      dotData: FlDotData(show: items.length <= 14),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandGreen, size: 20),
          const SizedBox(height: 11),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ),
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    ),
  );
}

class _AttainmentRow extends StatelessWidget {
  const _AttainmentRow({
    required this.label,
    required this.color,
    required this.value,
    this.isLast = false,
  });
  final String label;
  final Color color;
  final double value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
    child: Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: LinearProgressIndicator(
            value: value.clamp(0, 1.25) / 1.25,
            minHeight: 9,
            borderRadius: BorderRadius.circular(99),
            color: value > 1.1 ? Theme.of(context).colorScheme.error : color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 46,
          child: Text(
            '${(value * 100).round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

double _attainment(double actual, double target) =>
    target <= 0 ? 0 : actual / target;

double _averageRatio(
  List<DailySummary> items,
  double Function(DailySummary) actual,
  double Function(DailySummary) target,
) {
  if (items.isEmpty) return 0;
  return items.fold(
        0.0,
        (sum, item) => sum + _attainment(actual(item), target(item)),
      ) /
      items.length;
}
