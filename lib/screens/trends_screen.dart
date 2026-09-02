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
  TrendMetric _metric = TrendMetric.net;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider).requireValue;
    final plan = data.selectedTrainingPlan;
    final items = data.trends;
    final averageNet = items.isEmpty
        ? 0.0
        : items.fold(0.0, (sum, item) => sum + item.netEnergy) / items.length;
    final net = items.fold(0.0, (sum, item) => sum + item.netEnergy);
    final deficitDays = items.where((item) => item.netEnergy < 0).length;

    if (useDesktopLayout(context)) {
      return _buildDesktop(
        context,
        data: data,
        plan: plan,
        items: items,
        averageNet: averageNet,
        net: net,
        deficitDays: deficitDays,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('训练计划'),
        actions: [
          IconButton(
            tooltip: '新建训练计划',
            onPressed: () => _editPlan(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ContentFrame(
        maxWidth: 1100,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 34),
          children: [
            _PlanOverview(
              plans: data.trainingPlans,
              selected: plan,
              onSelect: _selectPlan,
              onAdd: () => _editPlan(context),
              onEdit: plan == null ? null : () => _editPlan(context, plan),
              onDelete: plan == null ? null : () => _deletePlan(context, plan),
            ),
            if (plan != null) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: '计划日均净能量',
                      value:
                          '${averageNet > 0 ? '+' : ''}${averageNet.round()}',
                      unit: 'kcal',
                      icon: averageNet <= 0
                          ? Icons.south_east_rounded
                          : Icons.north_east_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryCard(
                      label: '本计划净收支',
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
              _trendSection(items),
              const SizedBox(height: 26),
              const SectionHeader(
                title: '营养达标概览',
                subtitle: '按当前训练计划内有记录的日期计算',
              ),
              _NutritionOverview(items: items),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required AppState data,
    required TrainingPlan? plan,
    required List<DailySummary> items,
    required double averageNet,
    required double net,
    required int deficitDays,
  }) => Scaffold(
    body: Column(
      children: [
        DesktopPageHeader(
          title: '训练计划与趋势',
          subtitle: '每段计划独立统计净能量、营养目标与运动数据',
          actions: [
            FilledButton.icon(
              onPressed: () => _editPlan(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建计划'),
            ),
          ],
        ),
        Expanded(
          child: ContentFrame(
            maxWidth: 1420,
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                children: [
                  _PlanOverview(
                    plans: data.trainingPlans,
                    selected: plan,
                    onSelect: _selectPlan,
                    onAdd: () => _editPlan(context),
                    onEdit: plan == null
                        ? null
                        : () => _editPlan(context, plan),
                    onDelete: plan == null
                        ? null
                        : () => _deletePlan(context, plan),
                  ),
                  if (plan != null) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: '计划日均净能量',
                            value:
                                '${averageNet > 0 ? '+' : ''}${averageNet.round()}',
                            unit: 'kcal',
                            icon: averageNet <= 0
                                ? Icons.south_east_rounded
                                : Icons.north_east_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            label: '本计划净收支',
                            value: '${net > 0 ? '+' : ''}${net.round()}',
                            unit: 'kcal',
                            icon: net <= 0
                                ? Icons.south_east_rounded
                                : Icons.north_east_rounded,
                          ),
                        ),
                        const SizedBox(width: 14),
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
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _trendSection(items)),
                        const SizedBox(width: 22),
                        SizedBox(
                          width: 320,
                          child: Column(
                            children: [
                              const SectionHeader(
                                title: '营养达标概览',
                                subtitle: '计划内有记录日期的平均完成度',
                              ),
                              _NutritionOverview(items: items),
                              const SizedBox(height: 16),
                              Card(
                                color: const Color(0xFFE8F4EF),
                                child: const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: deepGreen,
                                        size: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '计划类型只用于划分统计周期，不会自动修改每天的能量或营养目标。',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _trendSection(List<DailySummary> items) => Column(
    children: [
      SectionHeader(
        title: _metric.label,
        subtitle: _metric == TrendMetric.net
            ? '0 为平衡线，负数为缺口，正数为增加'
            : _metric == TrendMetric.exercise
            ? '当前计划共有 ${items.length} 个有记录日期'
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
            onChanged: (value) => setState(() => _metric = value ?? _metric),
          ),
        ),
      ),
      if (items.isEmpty)
        const EmptyState(
          icon: Icons.insights_rounded,
          title: '当前计划还没有数据',
          message: '计划日期内记录餐食或运动后，这里会展示变化趋势',
        )
      else
        _TrendChart(items: items, metric: _metric),
    ],
  );

  Future<void> _selectPlan(int id) async {
    await ref.read(appControllerProvider.notifier).selectTrainingPlan(id);
  }

  Future<void> _editPlan(BuildContext context, [TrainingPlan? initial]) async {
    final plan = await showAdaptiveEditor<TrainingPlan>(
      context: context,
      builder: (_) => _TrainingPlanEditor(initial: initial),
    );
    if (plan == null || !context.mounted) return;
    try {
      await ref.read(appControllerProvider.notifier).saveTrainingPlan(plan);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(initial == null ? '训练计划已创建' : '训练计划已更新')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _deletePlan(BuildContext context, TrainingPlan plan) async {
    final confirmed = await confirmAction(
      context,
      title: '删除训练计划？',
      message: '只会删除“${plan.name}”这段统计周期，不会删除餐食、运动或每日记录。',
      confirmText: '删除计划',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref
          .read(appControllerProvider.notifier)
          .deleteTrainingPlan(plan.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('训练计划已删除，历史记录保持不变')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _PlanOverview extends StatelessWidget {
  const _PlanOverview({
    required this.plans,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TrainingPlan> plans;
  final TrainingPlan? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final plan = selected;
    if (plan == null) {
      return EmptyState(
        icon: Icons.flag_outlined,
        title: '先建立一段训练计划',
        message: '例如“秋季减脂期”，设置开始日期和结束日期后，净能量只统计这段时间。',
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('新建训练计划'),
        ),
      );
    }

    final today = dayOnly(DateTime.now());
    final status = today.isBefore(dayOnly(plan.startDate))
        ? '未开始'
        : plan.endDate != null && today.isAfter(dayOnly(plan.endDate!))
        ? '已结束'
        : '进行中';
    final statusColor = switch (status) {
      '进行中' => brandGreen,
      '未开始' => const Color(0xFF3B82F6),
      _ => const Color(0xFF77827D),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 660;
            final identity = Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_planIcon(plan.type), color: brandGreen),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${plan.type.label} · ${_planDates(plan)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final selector = DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: plan.id,
                borderRadius: BorderRadius.circular(14),
                isExpanded: true,
                items: plans
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSelect(value);
                },
              ),
            );
            final controls = Row(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (plans.length > 1 && compact) Expanded(child: selector),
                if (plans.length > 1 && !compact)
                  SizedBox(width: 190, child: selector),
                if (plans.length > 1) const SizedBox(width: 8),
                IconButton(
                  tooltip: '编辑计划',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: '删除计划',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            );
            if (compact) {
              return Column(
                children: [identity, const Divider(height: 28), controls],
              );
            }
            return Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 20),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrainingPlanEditor extends StatefulWidget {
  const _TrainingPlanEditor({this.initial});

  final TrainingPlan? initial;

  @override
  State<_TrainingPlanEditor> createState() => _TrainingPlanEditorState();
}

class _TrainingPlanEditorState extends State<_TrainingPlanEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late TrainingPlanType _type;
  late DateTime _start;
  DateTime? _end;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TrainingPlanType.cutting;
    _start = dayOnly(initial?.startDate ?? DateTime.now());
    _end = initial?.endDate == null ? null : dayOnly(initial!.endDate!);
    _name = TextEditingController(text: initial?.name ?? _type.label);
  }

  @override
  void dispose() {
    _name.dispose();
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
            if (!useDesktopLayout(context))
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Text(
              widget.initial == null ? '新建训练计划' : '编辑训练计划',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '净能量与营养趋势将只统计这个日期范围。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '计划名称',
                hintText: '例如：秋季减脂',
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? '不能为空' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TrainingPlanType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '计划类型'),
              items: TrainingPlanType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final oldDefaultName = _type.label;
                setState(() {
                  _type = value;
                  if (_name.text.trim().isEmpty ||
                      _name.text.trim() == oldDefaultName) {
                    _name.text = value.label;
                  }
                });
              },
            ),
            const SizedBox(height: 18),
            Text('计划周期', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: '开始日期',
                    value: _start,
                    onTap: _pickStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: '结束日期',
                    value: _end,
                    placeholder: '进行中',
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),
            if (_dateError != null) ...[
              const SizedBox(height: 8),
              Text(
                _dateError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('持续进行中'),
              subtitle: const Text('暂不设置结束日期，统计到今天'),
              value: _end == null,
              onChanged: (ongoing) => setState(() {
                _end = ongoing ? null : _start.add(const Duration(days: 55));
                _dateError = null;
              }),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: deepGreen, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '计划类型用于标记训练阶段，不会自动更改你的每日目标。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? '创建计划' : '保存修改'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickStart() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (value == null) return;
    setState(() {
      _start = dayOnly(value);
      if (_end != null && _end!.isBefore(_start)) _end = _start;
      _dateError = null;
    });
  }

  Future<void> _pickEnd() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _end ?? _start.add(const Duration(days: 55)),
      firstDate: _start,
      lastDate: DateTime(2100, 12, 31),
    );
    if (value == null) return;
    setState(() {
      _end = dayOnly(value);
      _dateError = null;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_end != null && _end!.isBefore(_start)) {
      setState(() => _dateError = '结束日期不能早于开始日期');
      return;
    }
    Navigator.pop(
      context,
      TrainingPlan(
        id: widget.initial?.id,
        name: _name.text.trim(),
        type: _type,
        startDate: _start,
        endDate: _end,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? placeholder;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(
        value == null
            ? placeholder ?? '请选择'
            : DateFormat('yyyy/M/d').format(value!),
      ),
    ),
  );
}

class _NutritionOverview extends StatelessWidget {
  const _NutritionOverview({required this.items});

  final List<DailySummary> items;

  @override
  Widget build(BuildContext context) => Card(
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
  );
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

IconData _planIcon(TrainingPlanType type) => switch (type) {
  TrainingPlanType.cutting => Icons.trending_down_rounded,
  TrainingPlanType.maintaining => Icons.balance_rounded,
  TrainingPlanType.bulking => Icons.fitness_center_rounded,
  TrainingPlanType.custom => Icons.flag_rounded,
};

String _planDates(TrainingPlan plan) {
  final formatter = DateFormat('yyyy/M/d');
  final end = plan.endDate == null ? '持续进行' : formatter.format(plan.endDate!);
  return '${formatter.format(plan.startDate)} — $end';
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

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('操作失败：$error')));
}
