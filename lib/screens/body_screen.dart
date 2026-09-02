import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

enum BodyMetric {
  height,
  weight,
  bmi,
  bodyFat,
  visceralFat,
  subcutaneousFat,
  muscle,
  boneMass,
  water,
  protein,
  bmr,
}

extension BodyMetricX on BodyMetric {
  String get label => switch (this) {
    BodyMetric.height => '裸足身高',
    BodyMetric.weight => '体重',
    BodyMetric.bmi => 'BMI',
    BodyMetric.bodyFat => '体脂率',
    BodyMetric.visceralFat => '内脏脂肪',
    BodyMetric.subcutaneousFat => '皮下脂肪率',
    BodyMetric.muscle => '肌肉率',
    BodyMetric.boneMass => '骨量',
    BodyMetric.water => '水分率',
    BodyMetric.protein => '蛋白质率',
    BodyMetric.bmr => '基础代谢',
  };

  String get unit => switch (this) {
    BodyMetric.height => 'cm',
    BodyMetric.weight || BodyMetric.boneMass => 'kg',
    BodyMetric.bodyFat ||
    BodyMetric.subcutaneousFat ||
    BodyMetric.muscle ||
    BodyMetric.water ||
    BodyMetric.protein => '%',
    BodyMetric.bmr => 'kcal',
    BodyMetric.bmi || BodyMetric.visceralFat => '',
  };

  double valueOf(BodyMeasurement item) => switch (this) {
    BodyMetric.height => item.heightCm,
    BodyMetric.weight => item.weightKg,
    BodyMetric.bmi => item.bmi,
    BodyMetric.bodyFat => item.bodyFatPercent,
    BodyMetric.visceralFat => item.visceralFatLevel,
    BodyMetric.subcutaneousFat => item.subcutaneousFatPercent,
    BodyMetric.muscle => item.musclePercent,
    BodyMetric.boneMass => item.boneMassKg,
    BodyMetric.water => item.waterPercent,
    BodyMetric.protein => item.proteinPercent,
    BodyMetric.bmr => item.bmrKcal,
  };
}

class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  BodyMetric _metric = BodyMetric.weight;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).requireValue;
    final measurements = data.bodyMeasurements;
    if (useDesktopLayout(context)) {
      return _buildDesktop(context, data, measurements);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('身体数据'),
        actions: [
          IconButton(
            tooltip: '记录身体数据',
            onPressed: () => _editMeasurement(context, data),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ContentFrame(
        maxWidth: 1100,
        child: measurements.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
                child: _emptyState(context, data),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 34),
                children: [
                  _LatestMeasurementCard(measurement: measurements.first),
                  const SizedBox(height: 26),
                  _trendSection(measurements),
                  const SizedBox(height: 26),
                  const SectionHeader(
                    title: '测量历史',
                    subtitle: '同一天保留一条记录，可随时修改',
                  ),
                  for (final measurement in measurements) ...[
                    _MeasurementHistoryCard(
                      measurement: measurement,
                      onEdit: () =>
                          _editMeasurement(context, data, measurement),
                      onDelete: () => _deleteMeasurement(context, measurement),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    AppState data,
    List<BodyMeasurement> measurements,
  ) => Scaffold(
    body: Column(
      children: [
        DesktopPageHeader(
          title: '身体数据',
          subtitle: '记录体成分测量结果，观察身体变化而不只关注体重',
          actions: [
            FilledButton.icon(
              onPressed: () => _editMeasurement(context, data),
              icon: const Icon(Icons.add_rounded),
              label: const Text('记录测量'),
            ),
          ],
        ),
        Expanded(
          child: ContentFrame(
            maxWidth: 1420,
            child: measurements.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: _emptyState(context, data),
                  )
                : Scrollbar(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                      children: [
                        _LatestMeasurementCard(measurement: measurements.first),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _trendSection(measurements)),
                            const SizedBox(width: 22),
                            SizedBox(
                              width: 410,
                              child: Column(
                                children: [
                                  const SectionHeader(
                                    title: '测量历史',
                                    subtitle: '点击展开查看全部指标',
                                  ),
                                  for (final measurement in measurements) ...[
                                    _MeasurementHistoryCard(
                                      measurement: measurement,
                                      onEdit: () => _editMeasurement(
                                        context,
                                        data,
                                        measurement,
                                      ),
                                      onDelete: () => _deleteMeasurement(
                                        context,
                                        measurement,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState(BuildContext context, AppState data) => EmptyState(
    icon: Icons.monitor_weight_outlined,
    title: '还没有身体测量记录',
    message: '记录一次体重、体脂、肌肉、水分和基础代谢等指标后，即可查看变化趋势。',
    action: FilledButton.icon(
      onPressed: () => _editMeasurement(context, data),
      icon: const Icon(Icons.add_rounded),
      label: const Text('记录第一次测量'),
    ),
  );

  Widget _trendSection(List<BodyMeasurement> measurements) => Column(
    children: [
      SectionHeader(
        title: '${_metric.label}趋势',
        subtitle: measurements.length < 2
            ? '再记录一次即可对比变化'
            : '按测量日期展示，共 ${measurements.length} 次',
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<BodyMetric>(
            value: _metric,
            borderRadius: BorderRadius.circular(14),
            items: BodyMetric.values
                .map(
                  (metric) => DropdownMenuItem(
                    value: metric,
                    child: Text(metric.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _metric = value ?? _metric),
          ),
        ),
      ),
      _BodyTrendChart(measurements: measurements, metric: _metric),
    ],
  );

  Future<void> _editMeasurement(
    BuildContext context,
    AppState data, [
    BodyMeasurement? initial,
  ]) async {
    final measurement = await showAdaptiveEditor<BodyMeasurement>(
      context: context,
      desktopWidth: 720,
      builder: (_) => _BodyMeasurementEditor(
        initial: initial,
        defaultHeightCm: data.profile.heightCm,
      ),
    );
    if (measurement == null || !context.mounted) return;
    try {
      await ref
          .read(appControllerProvider.notifier)
          .saveBodyMeasurement(measurement);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(initial == null ? '身体数据已记录' : '身体数据已更新')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _deleteMeasurement(
    BuildContext context,
    BodyMeasurement measurement,
  ) async {
    final date = DateFormat('yyyy年M月d日').format(measurement.date);
    final confirmed = await confirmAction(
      context,
      title: '删除身体记录？',
      message: '将删除 $date 的身体测量数据，此操作不会影响饮食和运动记录。',
      confirmText: '删除记录',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(appControllerProvider.notifier)
          .deleteBodyMeasurement(measurement.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('身体测量记录已删除')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _LatestMeasurementCard extends StatelessWidget {
  const _LatestMeasurementCard({required this.measurement});

  final BodyMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('BMI', _trim(measurement.bmi), ''),
      ('体脂率', _trim(measurement.bodyFatPercent), '%'),
      ('内脏脂肪', _trim(measurement.visceralFatLevel), ''),
      ('皮下脂肪', _trim(measurement.subcutaneousFatPercent), '%'),
      ('肌肉率', _trim(measurement.musclePercent), '%'),
      ('骨量', _trim(measurement.boneMassKg), 'kg'),
      ('水分率', _trim(measurement.waterPercent), '%'),
      ('蛋白质率', _trim(measurement.proteinPercent), '%'),
      ('基础代谢', _trim(measurement.bmrKcal), 'kcal'),
      ('裸足身高', _trim(measurement.heightCm), 'cm'),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF123D30), Color(0xFF1B5945)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 720;
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近一次 · ${DateFormat('yyyy年M月d日').format(measurement.date)}',
                  style: const TextStyle(
                    color: Color(0xFF9BC7B5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _trim(measurement.weightKg),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        'kg',
                        style: TextStyle(color: Color(0xFFB9D7CC)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('体重', style: TextStyle(color: Color(0xFFB9D7CC))),
              ],
            );
            final details = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in values)
                  _LatestMetricTile(
                    label: item.$1,
                    value: item.$2,
                    unit: item.$3,
                  ),
              ],
            );
            if (desktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 190, child: summary),
                  Container(
                    width: 1,
                    height: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  Expanded(child: details),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 20), details],
            );
          },
        ),
      ),
    );
  }
}

class _LatestMetricTile extends StatelessWidget {
  const _LatestMetricTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value${unit.isEmpty ? '' : ' $unit'}',
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA6CABC), fontSize: 11),
        ),
      ],
    ),
  );
}

class _BodyTrendChart extends StatelessWidget {
  const _BodyTrendChart({required this.measurements, required this.metric});

  final List<BodyMeasurement> measurements;
  final BodyMetric metric;

  @override
  Widget build(BuildContext context) {
    final ordered = measurements.reversed.toList();
    final spots = [
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), metric.valueOf(ordered[i])),
    ];
    final values = spots.map((spot) => spot.y);
    final rawMin = values.reduce(math.min);
    final rawMax = values.reduce(math.max);
    final padding = math.max(
      _minimumChartPadding(metric),
      rawMin == rawMax ? rawMax.abs() * 0.04 : (rawMax - rawMin).abs() * 0.18,
    );
    final minY = math.max(0.0, rawMin - padding);
    final maxY = rawMax + padding;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 22, 18, 12),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(1, ordered.length - 1).toDouble(),
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
                    reservedSize: 46,
                    getTitlesWidget: (value, meta) => Text(
                      _chartNumber(value, metric),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: math
                        .max(1, (ordered.length / 4).floor())
                        .toDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > ordered.length - 1) {
                        return const SizedBox.shrink();
                      }
                      final index = value.round().clamp(0, ordered.length - 1);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('M/d').format(ordered[index].date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touched) => touched
                      .map(
                        (spot) => LineTooltipItem(
                          '${_trim(spot.y)}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
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
                LineChartBarData(
                  spots: spots,
                  color: brandGreen,
                  barWidth: 3,
                  isCurved: spots.length > 2,
                  curveSmoothness: 0.24,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: brandGreen.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 400),
          ),
        ),
      ),
    );
  }
}

class _MeasurementHistoryCard extends StatelessWidget {
  const _MeasurementHistoryCard({
    required this.measurement,
    required this.onEdit,
    required this.onDelete,
  });

  final BodyMeasurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: ExpansionTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: brandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.monitor_weight_outlined, color: brandGreen),
      ),
      title: Text(
        DateFormat('yyyy年M月d日').format(measurement.date),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${_trim(measurement.weightKg)} kg · 体脂 ${_trim(measurement.bodyFatPercent)}% · BMI ${_trim(measurement.bmi)}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final metric in BodyMetric.values)
              _HistoryValue(
                label: metric.label,
                value:
                    '${_trim(metric.valueOf(measurement))}${metric.unit.isEmpty ? '' : ' ${metric.unit}'}',
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('编辑'),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('删除'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HistoryValue extends StatelessWidget {
  const _HistoryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F6F4),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text.rich(
      TextSpan(
        text: '$label  ',
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: deepGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BodyMeasurementEditor extends StatefulWidget {
  const _BodyMeasurementEditor({required this.defaultHeightCm, this.initial});

  final double defaultHeightCm;
  final BodyMeasurement? initial;

  @override
  State<_BodyMeasurementEditor> createState() => _BodyMeasurementEditorState();
}

class _BodyMeasurementEditorState extends State<_BodyMeasurementEditor> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _bmi;
  late final TextEditingController _bodyFat;
  late final TextEditingController _visceralFat;
  late final TextEditingController _subcutaneousFat;
  late final TextEditingController _muscle;
  late final TextEditingController _boneMass;
  late final TextEditingController _water;
  late final TextEditingController _protein;
  late final TextEditingController _bmr;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _date = dayOnly(initial?.date ?? DateTime.now());
    _height = TextEditingController(
      text: _initialNumber(initial?.heightCm ?? widget.defaultHeightCm),
    );
    _weight = TextEditingController(text: _initialNumber(initial?.weightKg));
    _bmi = TextEditingController(text: _initialNumber(initial?.bmi));
    _bodyFat = TextEditingController(
      text: _initialNumber(initial?.bodyFatPercent),
    );
    _visceralFat = TextEditingController(
      text: _initialNumber(initial?.visceralFatLevel),
    );
    _subcutaneousFat = TextEditingController(
      text: _initialNumber(initial?.subcutaneousFatPercent),
    );
    _muscle = TextEditingController(
      text: _initialNumber(initial?.musclePercent),
    );
    _boneMass = TextEditingController(
      text: _initialNumber(initial?.boneMassKg),
    );
    _water = TextEditingController(text: _initialNumber(initial?.waterPercent));
    _protein = TextEditingController(
      text: _initialNumber(initial?.proteinPercent),
    );
    _bmr = TextEditingController(text: _initialNumber(initial?.bmrKcal));
  }

  @override
  void dispose() {
    for (final controller in [
      _height,
      _weight,
      _bmi,
      _bodyFat,
      _visceralFat,
      _subcutaneousFat,
      _muscle,
      _boneMass,
      _water,
      _protein,
      _bmr,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!useDesktopLayout(context)) const _SheetHandle(),
            Text(
              widget.initial == null ? '记录身体数据' : '编辑身体数据',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '按体测设备显示的数值填写，同一天只保留一条记录。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            _DateInput(date: _date, onTap: _pickDate),
            const SizedBox(height: 18),
            _EditorSection(
              title: '基础指标',
              children: [
                _MetricField(
                  controller: _height,
                  label: '裸足身高',
                  suffix: 'cm',
                  min: 50,
                  max: 260,
                ),
                _MetricField(
                  controller: _weight,
                  label: '体重',
                  suffix: 'kg',
                  min: 1,
                  max: 500,
                ),
                _MetricField(
                  controller: _bmi,
                  label: 'BMI',
                  suffix: '',
                  min: 5,
                  max: 100,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _calculateBmi,
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('根据身高体重计算 BMI'),
              ),
            ),
            const SizedBox(height: 8),
            _EditorSection(
              title: '脂肪指标',
              children: [
                _MetricField(
                  controller: _bodyFat,
                  label: '体脂率',
                  suffix: '%',
                  max: 100,
                ),
                _MetricField(
                  controller: _visceralFat,
                  label: '内脏脂肪',
                  suffix: '',
                  max: 100,
                ),
                _MetricField(
                  controller: _subcutaneousFat,
                  label: '皮下脂肪率',
                  suffix: '%',
                  max: 100,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _EditorSection(
              title: '身体组成',
              children: [
                _MetricField(
                  controller: _muscle,
                  label: '肌肉率',
                  suffix: '%',
                  max: 100,
                ),
                _MetricField(
                  controller: _boneMass,
                  label: '骨量',
                  suffix: 'kg',
                  max: 20,
                ),
                _MetricField(
                  controller: _water,
                  label: '水分率',
                  suffix: '%',
                  max: 100,
                ),
                _MetricField(
                  controller: _protein,
                  label: '蛋白质率',
                  suffix: '%',
                  max: 100,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _EditorSection(
              title: '代谢',
              children: [
                _MetricField(
                  controller: _bmr,
                  label: '基础代谢',
                  suffix: 'kcal',
                  min: 100,
                  max: 10000,
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? '保存记录' : '保存修改'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date != null) setState(() => _date = dayOnly(date));
  }

  void _calculateBmi() {
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    if (height == null || height <= 0 || weight == null || weight <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写有效的身高和体重')));
      return;
    }
    final meters = height / 100;
    _bmi.text = (weight / (meters * meters)).toStringAsFixed(1);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      BodyMeasurement(
        id: widget.initial?.id,
        date: _date,
        heightCm: double.parse(_height.text),
        weightKg: double.parse(_weight.text),
        bmi: double.parse(_bmi.text),
        bodyFatPercent: double.parse(_bodyFat.text),
        visceralFatLevel: double.parse(_visceralFat.text),
        subcutaneousFatPercent: double.parse(_subcutaneousFat.text),
        musclePercent: double.parse(_muscle.text),
        boneMassKg: double.parse(_boneMass.text),
        waterPercent: double.parse(_water.text),
        proteinPercent: double.parse(_protein.text),
        bmrKcal: double.parse(_bmr.text),
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 3 : 2;
          final gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: 10,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      ),
    ],
  );
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.min = 0,
    this.max,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double? max;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix.isEmpty ? null : suffix,
    ),
    validator: (value) {
      final parsed = double.tryParse(value?.trim() ?? '');
      if (parsed == null || !parsed.isFinite) return '请输入数字';
      if (parsed < min) return '不能小于 ${_trim(min)}';
      if (max != null && parsed > max!) return '不能大于 ${_trim(max!)}';
      return null;
    },
  );
}

class _DateInput extends StatelessWidget {
  const _DateInput({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: '测量日期',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
      child: Text(DateFormat('yyyy年M月d日').format(date)),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(99),
      ),
    ),
  );
}

double _minimumChartPadding(BodyMetric metric) => switch (metric) {
  BodyMetric.height => 1,
  BodyMetric.weight => 1,
  BodyMetric.bmi => 0.5,
  BodyMetric.bodyFat ||
  BodyMetric.subcutaneousFat ||
  BodyMetric.muscle ||
  BodyMetric.water ||
  BodyMetric.protein => 1,
  BodyMetric.visceralFat => 0.5,
  BodyMetric.boneMass => 0.2,
  BodyMetric.bmr => 20,
};

String _chartNumber(double value, BodyMetric metric) => metric == BodyMetric.bmr
    ? value.round().toString()
    : value.toStringAsFixed(1);

String _initialNumber(double? value) => value == null ? '' : _trim(value);

String _trim(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

void _showError(BuildContext context, Object error) {
  final message = error is StateError
      ? error.message.toString()
      : '保存失败：$error';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
