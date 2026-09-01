import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).requireValue;
    final controller = ref.read(appControllerProvider.notifier);
    final summary = data.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('能量收支'),
        actions: [
          IconButton(
            tooltip: '选择日期',
            onPressed: () => _pickDate(context, ref, data.selectedDate),
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ContentFrame(
        maxWidth: 1040,
        child: RefreshIndicator(
          onRefresh: () =>
              controller.reloadAll(selectedDate: data.selectedDate),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 34),
            children: [
              _DateStrip(
                selected: data.selectedDate,
                onPrevious: () => controller.selectDate(
                  data.selectedDate.subtract(const Duration(days: 1)),
                ),
                onNext: () => controller.selectDate(
                  data.selectedDate.add(const Duration(days: 1)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DayType>(
                  segments: DayType.values
                      .map(
                        (type) => ButtonSegment(
                          value: type,
                          label: Text(type.shortLabel),
                          icon: Icon(switch (type) {
                            DayType.cardio => Icons.directions_run_rounded,
                            DayType.strength => Icons.fitness_center_rounded,
                            DayType.rest => Icons.self_improvement_rounded,
                          }),
                        ),
                      )
                      .toList(),
                  selected: {data.day.type},
                  onSelectionChanged: (value) =>
                      controller.setDayType(value.first),
                ),
              ),
              const SizedBox(height: 18),
              _EnergyHero(summary: summary),
              const SizedBox(height: 18),
              _NutritionGrid(summary: summary),
              const SizedBox(height: 28),
              SectionHeader(
                title: '今日餐食',
                subtitle:
                    '${data.meals.length} 条记录 · ${_kcal(data.intake.energyKcal)} kcal',
                trailing: IconButton.filledTonal(
                  tooltip: '添加餐食',
                  onPressed: () => _addMeal(context, ref, data),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              if (data.meals.isEmpty)
                EmptyState(
                  icon: Icons.ramen_dining_rounded,
                  title: '还没有餐食记录',
                  message: data.recipes.isEmpty
                      ? '请先到“菜谱”页添加或导入菜谱'
                      : '从菜谱中选择一餐，输入实际份数',
                  action: data.recipes.isEmpty
                      ? null
                      : FilledButton.tonalIcon(
                          onPressed: () => _addMeal(context, ref, data),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('添加餐食'),
                        ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.meals.length; i++) ...[
                        _MealTile(
                          meal: data.meals[i],
                          onEdit: () => _editMeal(context, ref, data.meals[i]),
                          onDelete: () =>
                              _deleteMeal(context, ref, data.meals[i]),
                        ),
                        if (i != data.meals.length - 1)
                          const Divider(height: 1, indent: 70),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              SectionHeader(
                title: '今日运动',
                subtitle:
                    '${data.exercises.length} 条记录 · ${_kcal(data.exerciseKcal)} kcal',
                trailing: IconButton.filledTonal(
                  tooltip: '添加运动',
                  onPressed: () => _addExercise(context, ref, data),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              if (data.exercises.isEmpty)
                EmptyState(
                  icon: Icons.directions_run_rounded,
                  title: '还没有运动记录',
                  message: '记录运动项目和本次消耗的能量',
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addExercise(context, ref, data),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加运动'),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < data.exercises.length; i++) ...[
                        _ExerciseTile(
                          exercise: data.exercises[i],
                          onEdit: () =>
                              _editExercise(context, ref, data.exercises[i]),
                          onDelete: () =>
                              _deleteExercise(context, ref, data.exercises[i]),
                        ),
                        if (i != data.exercises.length - 1)
                          const Divider(height: 1, indent: 70),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '选择记录日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (date != null) {
      await ref.read(appControllerProvider.notifier).selectDate(date);
    }
  }

  Future<void> _addMeal(
    BuildContext context,
    WidgetRef ref,
    AppState data,
  ) async {
    if (data.recipes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先在“菜谱”页添加菜谱')));
      return;
    }
    final meal = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          MealEditor(date: data.selectedDate, recipes: data.recipes),
    );
    if (meal != null) {
      await ref.read(appControllerProvider.notifier).saveMeal(meal);
    }
  }

  Future<void> _editMeal(
    BuildContext context,
    WidgetRef ref,
    MealEntry meal,
  ) async {
    final updated = await showModalBottomSheet<MealEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          MealEditor(date: meal.date, recipes: const [], initial: meal),
    );
    if (updated != null) {
      await ref.read(appControllerProvider.notifier).saveMeal(updated);
    }
  }

  Future<void> _deleteMeal(
    BuildContext context,
    WidgetRef ref,
    MealEntry meal,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: '删除餐食记录？',
      message: '将删除“${meal.recipeName}”这条记录。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(appControllerProvider.notifier).deleteMeal(meal.id!);
    }
  }

  Future<void> _addExercise(
    BuildContext context,
    WidgetRef ref,
    AppState data,
  ) async {
    final exercise = await showModalBottomSheet<ExerciseEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ExerciseEditor(date: data.selectedDate),
    );
    if (exercise != null) {
      await ref.read(appControllerProvider.notifier).saveExercise(exercise);
    }
  }

  Future<void> _editExercise(
    BuildContext context,
    WidgetRef ref,
    ExerciseEntry exercise,
  ) async {
    final updated = await showModalBottomSheet<ExerciseEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          ExerciseEditor(date: exercise.date, initial: exercise),
    );
    if (updated != null) {
      await ref.read(appControllerProvider.notifier).saveExercise(updated);
    }
  }

  Future<void> _deleteExercise(
    BuildContext context,
    WidgetRef ref,
    ExerciseEntry exercise,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: '删除运动记录？',
      message: '将删除“${exercise.name}”这条记录。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await ref
          .read(appControllerProvider.notifier)
          .deleteExercise(exercise.id!);
    }
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selected,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final today = dateKey(selected) == dateKey(DateTime.now());
    final formatter = DateFormat('M月d日 EEEE', 'zh_CN');
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Column(
            children: [
              Text(
                today ? '今天' : formatter.format(selected),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (today)
                Text(
                  formatter.format(selected),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _EnergyHero extends StatelessWidget {
  const _EnergyHero({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final net = summary.netEnergy;
    final status = net < 0
        ? '热量缺口'
        : net > 0
        ? '热量增加'
        : '能量平衡';
    final signedNet = net < 0
        ? '−${_kcal(net.abs())}'
        : net > 0
        ? '+${_kcal(net)}'
        : '0';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF147553), Color(0xFF22A06B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322A06B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日净能量', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: net.abs()),
                duration: const Duration(milliseconds: 450),
                builder: (context, value, child) => Text(
                  signedNet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 43,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 7, bottom: 5),
                child: Text('kcal', style: TextStyle(color: Colors.white70)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _HeroMetric(label: '摄入', value: summary.intake.energyKcal),
              _HeroDivider(),
              _HeroMetric(
                label: '基础',
                value: summary.record.baselineKcal.toDouble(),
              ),
              _HeroDivider(),
              _HeroMetric(label: '运动', value: summary.exerciseKcal),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            net == 0 ? '今日净能量为 0 kcal' : '今日净能量为 $signedNet kcal（$status）',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 3),
        Text(
          _kcal(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white24,
  );
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.summary});
  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '碳水',
        summary.intake.carbsG,
        summary.record.target.carbsG,
        const Color(0xFF3B82F6),
      ),
      (
        '蛋白质',
        summary.intake.proteinG,
        summary.record.target.proteinG,
        const Color(0xFF8B5CF6),
      ),
      (
        '脂肪',
        summary.intake.fatG,
        summary.record.target.fatG,
        const Color(0xFFF59E0B),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: _NutrientCard(
              label: items[i].$1,
              actual: items[i].$2,
              target: items[i].$3,
              color: items[i].$4,
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.label,
    required this.actual,
    required this.target,
    required this.color,
  });

  final String label;
  final double actual;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gap = target - actual;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Text(
              '${_one(actual)}g',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '目标 ${_one(target)}g',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: target <= 0 ? 0 : (actual / target).clamp(0, 1),
              ),
              duration: const Duration(milliseconds: 450),
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gap >= 0 ? '还差 ${_one(gap)}g' : '超出 ${_one(gap.abs())}g',
              style: TextStyle(
                color: gap >= 0
                    ? const Color(0xFF65726C)
                    : const Color(0xFFD14343),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });
  final MealEntry meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFFFF3D6),
      foregroundColor: Color(0xFF9A6800),
      child: Icon(Icons.restaurant_rounded),
    ),
    title: Text(meal.recipeName),
    subtitle: Text('${_one(meal.servings)} × ${meal.servingLabel}'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_kcal(meal.total.energyKcal)} kcal',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('编辑份数')),
            PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ],
    ),
  );
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });
  final ExerciseEntry exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE7F5EE),
      foregroundColor: brandGreen,
      child: Icon(Icons.directions_run_rounded),
    ),
    title: Text(exercise.name),
    subtitle: const Text('运动消耗'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_kcal(exercise.energyKcal)} kcal',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('编辑')),
            PopupMenuItem(value: 'delete', child: Text('删除')),
          ],
        ),
      ],
    ),
  );
}

class MealEditor extends StatefulWidget {
  const MealEditor({
    super.key,
    required this.date,
    required this.recipes,
    this.initial,
  });

  final DateTime date;
  final List<Recipe> recipes;
  final MealEntry? initial;

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  final _formKey = GlobalKey<FormState>();
  Recipe? _recipe;
  late final TextEditingController _servings;

  @override
  void initState() {
    super.initState();
    _recipe = widget.initial == null ? widget.recipes.first : null;
    _servings = TextEditingController(
      text: widget.initial == null ? '1' : _one(widget.initial!.servings),
    );
  }

  @override
  void dispose() {
    _servings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final name = editing ? widget.initial!.recipeName : _recipe!.name;
    final perServing = editing
        ? widget.initial!.perServing
        : _recipe!.nutrition;
    final count = double.tryParse(_servings.text) ?? 0;
    return Padding(
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
              const _Handle(),
              Text(
                editing ? '编辑餐食' : '添加餐食',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              if (!editing)
                DropdownButtonFormField<Recipe>(
                  initialValue: _recipe,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '选择菜谱'),
                  items: widget.recipes
                      .map(
                        (recipe) => DropdownMenuItem(
                          value: recipe,
                          child: Text(recipe.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _recipe = value),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: const Text('历史营养快照保持不变'),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servings,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '本次份数',
                  suffixText: editing
                      ? widget.initial!.servingLabel
                      : _recipe!.servingLabel,
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  if (number == null || number <= 0) return '请输入大于 0 的份数';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '本次约 ${_kcal(perServing.energyKcal * count)} kcal · 碳水 ${_one(perServing.carbsG * count)}g · 蛋白 ${_one(perServing.proteinG * count)}g · 脂肪 ${_one(perServing.fatG * count)}g',
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final recipe = _recipe;
                  final initial = widget.initial;
                  Navigator.pop(
                    context,
                    MealEntry(
                      id: initial?.id,
                      date: widget.date,
                      recipeId: initial?.recipeId ?? recipe!.id,
                      recipeName: initial?.recipeName ?? recipe!.name,
                      servingLabel:
                          initial?.servingLabel ?? recipe!.servingLabel,
                      servings: double.parse(_servings.text),
                      perServing: initial?.perServing ?? recipe!.nutrition,
                      createdAt: initial?.createdAt ?? DateTime.now(),
                    ),
                  );
                },
                child: Text(editing ? '保存修改' : '添加到当天'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExerciseEditor extends StatefulWidget {
  const ExerciseEditor({super.key, required this.date, this.initial});
  final DateTime date;
  final ExerciseEntry? initial;

  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _energy;
  static const suggestions = ['健身', '跑步', '游泳', '羽毛球', '骑行', '快走'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name ?? '');
    _energy = TextEditingController(
      text: widget.initial == null ? '' : _one(widget.initial!.energyKcal),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _energy.dispose();
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
            const _Handle(),
            Text(
              widget.initial == null ? '添加运动' : '编辑运动',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '运动项目'),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? '请输入项目名称' : null,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: suggestions
                  .map(
                    (name) => ActionChip(
                      label: Text(name),
                      onPressed: () => setState(() => _name.text = name),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _energy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '本次消耗',
                suffixText: 'kcal',
              ),
              validator: (value) {
                final number = double.tryParse(value ?? '');
                if (number == null || number <= 0) return '请输入大于 0 的能量';
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  ExerciseEntry(
                    id: widget.initial?.id,
                    date: widget.date,
                    name: _name.text.trim(),
                    energyKcal: double.parse(_energy.text),
                    createdAt: widget.initial?.createdAt ?? DateTime.now(),
                  ),
                );
              },
              child: Text(widget.initial == null ? '添加到当天' : '保存修改'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Handle extends StatelessWidget {
  const _Handle();
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

String _kcal(double value) => value.round().toString();
String _one(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
