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
    if (useDesktopLayout(context)) {
      return _buildDesktop(context, ref, data);
    }
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
              _NutritionGrid(summary: summary, meals: data.meals),
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
                      ? '可以直接记录临时餐食，不必先创建菜谱'
                      : '可以选择菜谱，也可以直接记录临时餐食',
                  action: FilledButton.tonalIcon(
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
                          recipe: _recipeForMeal(data.recipes, data.meals[i]),
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

  Widget _buildDesktop(BuildContext context, WidgetRef ref, AppState data) {
    final controller = ref.read(appControllerProvider.notifier);
    final summary = data.summary;
    final fullDate = DateFormat(
      'yyyy年M月d日 EEEE',
      'zh_CN',
    ).format(data.selectedDate);
    return Scaffold(
      body: Column(
        children: [
          DesktopPageHeader(
            title: '今日概览',
            subtitle: '$fullDate · 集中查看今天的能量与营养状态',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(context, ref, data.selectedDate),
                icon: const Icon(Icons.calendar_month_outlined, size: 19),
                label: const Text('选择日期'),
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _DateStrip(
                                selected: data.selectedDate,
                                onPrevious: () => controller.selectDate(
                                  data.selectedDate.subtract(
                                    const Duration(days: 1),
                                  ),
                                ),
                                onNext: () => controller.selectDate(
                                  data.selectedDate.add(
                                    const Duration(days: 1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 34,
                              color: const Color(0x14708078),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: SegmentedButton<DayType>(
                                segments: DayType.values
                                    .map(
                                      (type) => ButtonSegment(
                                        value: type,
                                        label: Text(type.shortLabel),
                                        icon: Icon(switch (type) {
                                          DayType.cardio =>
                                            Icons.directions_run_rounded,
                                          DayType.strength =>
                                            Icons.fitness_center_rounded,
                                          DayType.rest =>
                                            Icons.self_improvement_rounded,
                                        }),
                                      ),
                                    )
                                    .toList(),
                                selected: {data.day.type},
                                onSelectionChanged: (value) =>
                                    controller.setDayType(value.first),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _EnergyHero(summary: summary)),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: _DesktopNutritionPanel(
                            summary: summary,
                            meals: data.meals,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DesktopRecordsPanel(
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFF9A6800),
                            iconBackground: const Color(0xFFFFF3D6),
                            title: '今日餐食',
                            subtitle:
                                '${data.meals.length} 条 · ${_kcal(data.intake.energyKcal)} kcal',
                            actionLabel: '添加餐食',
                            onAdd: () => _addMeal(context, ref, data),
                            child: data.meals.isEmpty
                                ? _DesktopPanelEmpty(
                                    icon: Icons.ramen_dining_rounded,
                                    message: data.recipes.isEmpty
                                        ? '可直接记录临时餐食'
                                        : '可选择菜谱或记录临时餐食',
                                  )
                                : Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < data.meals.length;
                                        i++
                                      ) ...[
                                        _MealTile(
                                          meal: data.meals[i],
                                          recipe: _recipeForMeal(
                                            data.recipes,
                                            data.meals[i],
                                          ),
                                          onEdit: () => _editMeal(
                                            context,
                                            ref,
                                            data.meals[i],
                                          ),
                                          onDelete: () => _deleteMeal(
                                            context,
                                            ref,
                                            data.meals[i],
                                          ),
                                        ),
                                        if (i != data.meals.length - 1)
                                          const Divider(indent: 68),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _DesktopRecordsPanel(
                            icon: Icons.directions_run_rounded,
                            iconColor: brandGreen,
                            iconBackground: const Color(0xFFE7F5EE),
                            title: '今日运动',
                            subtitle:
                                '${data.exercises.length} 条 · ${_kcal(data.exerciseKcal)} kcal',
                            actionLabel: '添加运动',
                            onAdd: () => _addExercise(context, ref, data),
                            child: data.exercises.isEmpty
                                ? const _DesktopPanelEmpty(
                                    icon: Icons.directions_run_rounded,
                                    message: '今天还没有运动记录',
                                  )
                                : Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < data.exercises.length;
                                        i++
                                      ) ...[
                                        _ExerciseTile(
                                          exercise: data.exercises[i],
                                          onEdit: () => _editExercise(
                                            context,
                                            ref,
                                            data.exercises[i],
                                          ),
                                          onDelete: () => _deleteExercise(
                                            context,
                                            ref,
                                            data.exercises[i],
                                          ),
                                        ),
                                        if (i != data.exercises.length - 1)
                                          const Divider(indent: 68),
                                      ],
                                    ],
                                  ),
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
    final meal = await showAdaptiveEditor<MealEntry>(
      context: context,
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
    final updated = await showAdaptiveEditor<MealEntry>(
      context: context,
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
    final exercise = await showAdaptiveEditor<ExerciseEntry>(
      context: context,
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
    final updated = await showAdaptiveEditor<ExerciseEntry>(
      context: context,
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

class _DesktopNutritionPanel extends StatelessWidget {
  const _DesktopNutritionPanel({required this.summary, required this.meals});

  final DailySummary summary;
  final List<MealEntry> meals;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('营养目标', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5F0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '当日目标',
                  style: TextStyle(
                    color: deepGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _MealTypeLegend(),
          const SizedBox(height: 18),
          _DesktopNutrientRow(
            label: '碳水',
            actual: summary.intake.carbsG,
            target: summary.record.target.carbsG,
            breakdown: _mealBreakdown(meals, (value) => value.carbsG),
          ),
          const SizedBox(height: 16),
          _DesktopNutrientRow(
            label: '蛋白质',
            actual: summary.intake.proteinG,
            target: summary.record.target.proteinG,
            breakdown: _mealBreakdown(meals, (value) => value.proteinG),
          ),
          const SizedBox(height: 16),
          _DesktopNutrientRow(
            label: '脂肪',
            actual: summary.intake.fatG,
            target: summary.record.target.fatG,
            breakdown: _mealBreakdown(meals, (value) => value.fatG),
          ),
        ],
      ),
    ),
  );
}

class _DesktopNutrientRow extends StatelessWidget {
  const _DesktopNutrientRow({
    required this.label,
    required this.actual,
    required this.target,
    required this.breakdown,
  });

  final String label;
  final double actual;
  final double target;
  final Map<MealType, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final reached = target > 0 && actual >= target;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: _StackedNutritionBar(target: target, breakdown: breakdown),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 92,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_one(actual)}g',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' / ${_one(target)}g',
                      style: const TextStyle(
                        color: Color(0xFF7A857F),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              reached ? Icons.check_circle_rounded : Icons.timelapse_rounded,
              color: reached ? brandGreen : const Color(0xFF9AA49F),
              size: 18,
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopRecordsPanel extends StatelessWidget {
  const _DesktopRecordsPanel({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAdd,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
        const Divider(),
        child,
      ],
    ),
  );
}

class _DesktopPanelEmpty extends StatelessWidget {
  const _DesktopPanelEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 126,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFB3BDB8), size: 28),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
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
  const _NutritionGrid({required this.summary, required this.meals});
  final DailySummary summary;
  final List<MealEntry> meals;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '碳水',
        summary.intake.carbsG,
        summary.record.target.carbsG,
        _mealBreakdown(meals, (value) => value.carbsG),
      ),
      (
        '蛋白质',
        summary.intake.proteinG,
        summary.record.target.proteinG,
        _mealBreakdown(meals, (value) => value.proteinG),
      ),
      (
        '脂肪',
        summary.intake.fatG,
        summary.record.target.fatG,
        _mealBreakdown(meals, (value) => value.fatG),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MealTypeLegend(),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: _NutrientCard(
                  label: items[i].$1,
                  actual: items[i].$2,
                  target: items[i].$3,
                  breakdown: items[i].$4,
                ),
              ),
              if (i != items.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _MealTypeLegend extends StatelessWidget {
  const _MealTypeLegend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 7,
    children: [
      for (final type in MealType.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _mealTypeColor(type),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              type.label,
              style: const TextStyle(
                color: Color(0xFF65726C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
    ],
  );
}

class _StackedNutritionBar extends StatelessWidget {
  const _StackedNutritionBar({required this.target, required this.breakdown});

  final double target;
  final Map<MealType, double> breakdown;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final total = breakdown.values.fold<double>(
        0,
        (sum, value) => sum + value,
      );
      final scale = (total > target ? total : target)
          .clamp(1, double.infinity)
          .toDouble();
      var offset = 0.0;
      final segments = <Widget>[];
      for (final type in MealType.values) {
        final value = breakdown[type] ?? 0;
        if (value <= 0) continue;
        final width = constraints.maxWidth * value / scale;
        segments.add(
          Positioned(
            left: offset,
            top: 0,
            bottom: 0,
            width: width,
            child: ColoredBox(color: _mealTypeColor(type)),
          ),
        );
        offset += width;
      }
      final targetPosition = constraints.maxWidth * target / scale;
      return ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFE8ECEA)),
              ),
              ...segments,
              if (total > target && target > 0)
                Positioned(
                  left: (targetPosition - 1)
                      .clamp(0, constraints.maxWidth - 2)
                      .toDouble(),
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: const ColoredBox(color: Colors.white),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.label,
    required this.actual,
    required this.target,
    required this.breakdown,
  });

  final String label;
  final double actual;
  final double target;
  final Map<MealType, double> breakdown;

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
            _StackedNutritionBar(target: target, breakdown: breakdown),
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
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
  });
  final MealEntry meal;
  final Recipe? recipe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    isThreeLine: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 44,
        height: 44,
        child: recipe?.imageBytes == null
            ? _MealFallbackIcon(mealType: meal.mealType)
            : Image.memory(
                recipe!.imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _MealFallbackIcon(mealType: meal.mealType),
              ),
      ),
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            meal.recipeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_kcal(meal.total.energyKcal)} kcal',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _mealTypeColor(meal.mealType).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                meal.mealType.label,
                style: TextStyle(
                  color: _mealTypeColor(meal.mealType),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text('${_one(meal.servings)} × ${meal.servingLabel}'),
            if (meal.recipeId == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF7),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '临时',
                  style: TextStyle(
                    color: Color(0xFF53657C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '碳水 ${_one(meal.total.carbsG)}g · 蛋白 ${_one(meal.total.proteinG)}g · 脂肪 ${_one(meal.total.fatG)}g',
          style: const TextStyle(fontSize: 11, color: Color(0xFF65726C)),
        ),
      ],
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('编辑餐食')),
        PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    ),
  );
}

class _MealFallbackIcon extends StatelessWidget {
  const _MealFallbackIcon({required this.mealType});

  final MealType mealType;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _mealTypeColor(mealType).withValues(alpha: 0.14),
    child: Icon(_mealTypeIcon(mealType), color: _mealTypeColor(mealType)),
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

enum _MealInputMode { recipe, temporary }

class _MealEditorState extends State<MealEditor> {
  final _formKey = GlobalKey<FormState>();
  Recipe? _recipe;
  late final TextEditingController _servings;
  late final TextEditingController _name;
  late final TextEditingController _servingLabel;
  late final TextEditingController _energy;
  late final TextEditingController _carbs;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late MealType _mealType;
  late _MealInputMode _inputMode;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _recipe = initial == null && widget.recipes.isNotEmpty
        ? widget.recipes.first
        : null;
    _inputMode = initial == null
        ? (widget.recipes.isEmpty
              ? _MealInputMode.temporary
              : _MealInputMode.recipe)
        : (initial.recipeId == null
              ? _MealInputMode.temporary
              : _MealInputMode.recipe);
    _mealType = initial?.mealType ?? _defaultMealType();
    _servings = TextEditingController(
      text: initial == null ? '1' : _one(initial.servings),
    );
    _name = TextEditingController(text: initial?.recipeName ?? '');
    _servingLabel = TextEditingController(text: initial?.servingLabel ?? '一份');
    _energy = TextEditingController(
      text: initial == null ? '' : _one(initial.perServing.energyKcal),
    );
    _carbs = TextEditingController(
      text: initial == null ? '0' : _one(initial.perServing.carbsG),
    );
    _protein = TextEditingController(
      text: initial == null ? '0' : _one(initial.perServing.proteinG),
    );
    _fat = TextEditingController(
      text: initial == null ? '0' : _one(initial.perServing.fatG),
    );
  }

  @override
  void dispose() {
    _servings.dispose();
    _name.dispose();
    _servingLabel.dispose();
    _energy.dispose();
    _carbs.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final temporary = _inputMode == _MealInputMode.temporary;
    final name = temporary
        ? _name.text.trim()
        : editing
        ? widget.initial!.recipeName
        : _recipe?.name ?? '';
    final perServing = temporary
        ? _temporaryNutrition
        : editing
        ? widget.initial!.perServing
        : _recipe?.nutrition ?? const Nutrition();
    final count = double.tryParse(_servings.text) ?? 0;
    final servingLabel = temporary
        ? _servingLabel.text.trim()
        : editing
        ? widget.initial!.servingLabel
        : _recipe?.servingLabel ?? '';
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
              if (!editing && widget.recipes.isNotEmpty) ...[
                SegmentedButton<_MealInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: _MealInputMode.recipe,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('从菜谱选择'),
                    ),
                    ButtonSegment(
                      value: _MealInputMode.temporary,
                      icon: Icon(Icons.edit_note_rounded),
                      label: Text('临时餐食'),
                    ),
                  ],
                  selected: {_inputMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _inputMode = value.first),
                ),
                const SizedBox(height: 14),
              ],
              if (!editing && !temporary)
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
                  validator: (value) => value == null ? '请选择菜谱' : null,
                )
              else if (!temporary)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: const Text('历史营养快照保持不变'),
                )
              else ...[
                if (!editing && widget.recipes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('这条记录只计入当天，不会保存到菜谱库。'),
                  ),
                if (!editing && widget.recipes.isEmpty)
                  const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '餐食名称',
                    hintText: '例如：外出聚餐、临时盒饭',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _requiredMealText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _servingLabel,
                  decoration: const InputDecoration(
                    labelText: '每份说明',
                    hintText: '例如：一份、一碗、250 克',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _requiredMealText,
                ),
                const SizedBox(height: 16),
                Text('每份营养', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _temporaryNumberField(
                  controller: _energy,
                  label: '能量',
                  suffix: 'kcal',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _temporaryNumberField(
                        controller: _carbs,
                        label: '碳水',
                        suffix: 'g',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _temporaryNumberField(
                        controller: _protein,
                        label: '蛋白质',
                        suffix: 'g',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _temporaryNumberField(
                  controller: _fat,
                  label: '脂肪',
                  suffix: 'g',
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<MealType>(
                initialValue: _mealType,
                decoration: const InputDecoration(labelText: '餐次'),
                items: MealType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _mealTypeIcon(type),
                              size: 18,
                              color: _mealTypeColor(type),
                            ),
                            const SizedBox(width: 9),
                            Text(type.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _mealType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servings,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '本次份数',
                  suffixText: servingLabel,
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
                onPressed: _submit,
                child: Text(editing ? '保存修改' : '添加到当天'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Nutrition get _temporaryNutrition => Nutrition(
    energyKcal: double.tryParse(_energy.text.trim()) ?? 0,
    carbsG: double.tryParse(_carbs.text.trim()) ?? 0,
    proteinG: double.tryParse(_protein.text.trim()) ?? 0,
    fatG: double.tryParse(_fat.text.trim()) ?? 0,
  );

  Widget _temporaryNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    onChanged: (_) => setState(() {}),
    validator: (value) {
      final parsed = double.tryParse(value?.trim() ?? '');
      if (parsed == null) return '请输入有效数字';
      if (parsed < 0) return '不能小于 0';
      return null;
    },
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final initial = widget.initial;
    final temporary = _inputMode == _MealInputMode.temporary;
    final recipe = _recipe;
    Navigator.pop(
      context,
      MealEntry(
        id: initial?.id,
        date: widget.date,
        recipeId: temporary ? null : initial?.recipeId ?? recipe!.id,
        recipeName: temporary
            ? _name.text.trim()
            : initial?.recipeName ?? recipe!.name,
        servingLabel: temporary
            ? _servingLabel.text.trim()
            : initial?.servingLabel ?? recipe!.servingLabel,
        servings: double.parse(_servings.text.trim()),
        perServing: temporary
            ? _temporaryNutrition
            : initial?.perServing ?? recipe!.nutrition,
        mealType: _mealType,
        createdAt: initial?.createdAt ?? DateTime.now(),
      ),
    );
  }
}

String? _requiredMealText(String? value) =>
    value?.trim().isEmpty ?? true ? '不能为空' : null;

MealType _defaultMealType() {
  final hour = DateTime.now().hour;
  if (hour < 10) return MealType.breakfast;
  if (hour < 15) return MealType.lunch;
  if (hour < 21) return MealType.dinner;
  return MealType.snack;
}

Map<MealType, double> _mealBreakdown(
  List<MealEntry> meals,
  double Function(Nutrition value) select,
) => {
  for (final type in MealType.values)
    type: meals
        .where((meal) => meal.mealType == type)
        .fold<double>(0, (sum, meal) => sum + select(meal.total)),
};

Recipe? _recipeForMeal(List<Recipe> recipes, MealEntry meal) {
  if (meal.recipeId == null) return null;
  for (final recipe in recipes) {
    if (recipe.id == meal.recipeId) return recipe;
  }
  for (final recipe in recipes) {
    if (recipe.name == meal.recipeName) return recipe;
  }
  return null;
}

Color _mealTypeColor(MealType type) => switch (type) {
  MealType.breakfast => const Color(0xFFE9A023),
  MealType.lunch => const Color(0xFF3787E8),
  MealType.dinner => const Color(0xFF8B63D9),
  MealType.snack => const Color(0xFFE66E76),
};

IconData _mealTypeIcon(MealType type) => switch (type) {
  MealType.breakfast => Icons.free_breakfast_rounded,
  MealType.lunch => Icons.lunch_dining_rounded,
  MealType.dinner => Icons.dinner_dining_rounded,
  MealType.snack => Icons.cookie_rounded,
};

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
  Widget build(BuildContext context) => useDesktopLayout(context)
      ? const SizedBox(height: 6)
      : Center(
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
