import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';
import '../widgets/recipe_picker.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).requireValue;
    final controller = ref.read(appControllerProvider.notifier);
    final desktop = useDesktopLayout(context);
    final isToday = dateKey(data.selectedDate) == dateKey(DateTime.now());
    final dayLabel = isToday ? '今日' : '当日';
    final indulgence = data.day.type == DayType.indulgence;
    final meals = _DesktopRecordsPanel(
      icon: Icons.restaurant_rounded,
      iconColor: warmColor,
      iconBackground: const Color(0xFFF6EFE1),
      title: '$dayLabel餐食',
      subtitle:
          '${data.meals.length} 条记录 · ${_kcal(data.intake.energyKcal)} kcal',
      actionLabel: '添加',
      onAdd: () => _addMeal(context, ref, data),
      child: data.meals.isEmpty
          ? const _DesktopPanelEmpty(
              icon: Icons.ramen_dining_rounded,
              message: '选择常吃的菜谱，或直接记一餐外食',
            )
          : Column(
              children: [
                for (final type in MealType.values)
                  if (data.meals.any((meal) => meal.mealType == type)) ...[
                    _MealGroupHeading(
                      type: type,
                      meals: data.meals
                          .where((meal) => meal.mealType == type)
                          .toList(),
                    ),
                    for (final meal in data.meals.where(
                      (meal) => meal.mealType == type,
                    ))
                      _MealTile(
                        meal: meal,
                        recipe: _recipeForMeal(data.recipes, meal),
                        onEdit: () => _editMeal(context, ref, meal),
                        onDelete: () => _deleteMeal(context, ref, meal),
                      ),
                  ],
                const SizedBox(height: 8),
              ],
            ),
    );
    final exercises = _DesktopRecordsPanel(
      icon: Icons.directions_run_rounded,
      iconColor: brandGreen,
      iconBackground: const Color(0xFFE7F1E9),
      title: '$dayLabel运动',
      subtitle:
          '${data.exercises.length} 条记录 · ${_kcal(data.exerciseKcal)} kcal',
      actionLabel: '添加',
      onAdd: () => _addExercise(context, ref, data),
      child: data.exercises.isEmpty
          ? const _DesktopPanelEmpty(
              icon: Icons.directions_run_rounded,
              message: '记录一次运动，为今天留个脚印',
            )
          : Column(
              children: [
                for (final exercise in data.exercises)
                  _ExerciseTile(
                    exercise: exercise,
                    onEdit: () => _editExercise(context, ref, exercise),
                    onDelete: () => _deleteExercise(context, ref, exercise),
                  ),
                const SizedBox(height: 8),
              ],
            ),
    );
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: Text(isToday ? '今日概览' : '每日记录'),
              actions: [
                if (!isToday)
                  TextButton(
                    onPressed: () => controller.selectDate(DateTime.now()),
                    child: const Text('回到今天'),
                  ),
                IconButton(
                  tooltip: '选择日期',
                  onPressed: () => _pickDate(context, ref, data.selectedDate),
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
      body: Column(
        children: [
          if (desktop)
            DesktopPageHeader(
              title: isToday ? '今日概览' : '每日记录',
              subtitle: isToday
                  ? '吃好每一餐，记录自己的节奏。'
                  : '正在查看 ${DateFormat('yyyy年M月d日').format(data.selectedDate)} 的记录',
              actions: [
                if (!isToday)
                  TextButton(
                    onPressed: () => controller.selectDate(DateTime.now()),
                    child: const Text('回到今天'),
                  ),
                if (!indulgence) ...[
                  OutlinedButton.icon(
                    onPressed: () => _addExercise(context, ref, data),
                    icon: const Icon(Icons.directions_run_rounded, size: 18),
                    label: const Text('记录运动'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _addMeal(context, ref, data),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('记录餐食'),
                  ),
                ],
              ],
            ),
          Expanded(
            child: ContentFrame(
              maxWidth: 1420,
              child: RefreshIndicator(
                onRefresh: () =>
                    controller.reloadAll(selectedDate: data.selectedDate),
                child: ListView(
                  key: const PageStorageKey('today-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 28 : 18,
                    desktop ? 24 : 4,
                    desktop ? 28 : 18,
                    32,
                  ),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: AdaptiveColumns(
                          breakpoint: 760,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _DateStrip(
                                selected: data.selectedDate,
                                onPick: () =>
                                    _pickDate(context, ref, data.selectedDate),
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
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: _DayTypeSelector(
                                selected: data.day.type,
                                onChanged: (type) =>
                                    _changeDayType(context, ref, data, type),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (indulgence)
                      _IndulgenceDayCard(
                        hasSavedEntries:
                            data.meals.isNotEmpty || data.exercises.isNotEmpty,
                        isToday: isToday,
                      )
                    else ...[
                      if (desktop)
                        AdaptiveColumns(
                          breakpoint: 900,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _EnergyHero(
                                summary: data.summary,
                                hasEntries:
                                    data.meals.isNotEmpty ||
                                    data.exercises.isNotEmpty,
                                isToday: isToday,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 4,
                              child: _DesktopNutritionPanel(
                                summary: data.summary,
                                meals: data.meals,
                              ),
                            ),
                          ],
                        ),
                      if (!desktop) ...[
                        _EnergyHero(
                          summary: data.summary,
                          hasEntries:
                              data.meals.isNotEmpty ||
                              data.exercises.isNotEmpty,
                          isToday: isToday,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _addMeal(context, ref, data),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('记录餐食'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _addExercise(context, ref, data),
                                icon: const Icon(
                                  Icons.directions_run_rounded,
                                  size: 18,
                                ),
                                label: const Text('记录运动'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _DesktopNutritionPanel(
                          summary: data.summary,
                          meals: data.meals,
                        ),
                      ],
                      const SizedBox(height: 22),
                      AdaptiveColumns(
                        breakpoint: 980,
                        children: [
                          Expanded(flex: 6, child: meals),
                          const SizedBox(width: 18),
                          Expanded(flex: 4, child: exercises),
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
  }

  Future<void> _changeDayType(
    BuildContext context,
    WidgetRef ref,
    AppState data,
    DayType type,
  ) async {
    if (type == data.day.type) return;
    try {
      await ref.read(appControllerProvider.notifier).setDayType(type);
      if (context.mounted &&
          (type == DayType.indulgence || data.day.type == DayType.indulgence)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == DayType.indulgence
                  ? '已设为放纵日：净收支记为 0，已有记录仍保留'
                  : '已恢复${type.label}，餐食与运动重新参与统计',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('切换失败，请重试')));
      }
    }
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
    if (meal != null && context.mounted) {
      await _recordAction(
        context,
        () => ref.read(appControllerProvider.notifier).saveMeal(meal),
        '已记录到 ${DateFormat('M月d日').format(meal.date)} · ${meal.mealType.label}',
      );
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
    if (updated != null && context.mounted) {
      await _recordAction(
        context,
        () => ref.read(appControllerProvider.notifier).saveMeal(updated),
        '餐食已更新',
      );
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
    if (confirmed && context.mounted) {
      await _recordAction(
        context,
        () => ref.read(appControllerProvider.notifier).deleteMeal(meal.id!),
        '餐食记录已删除',
      );
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
    if (exercise != null && context.mounted) {
      await _recordAction(
        context,
        () => ref.read(appControllerProvider.notifier).saveExercise(exercise),
        '运动已记录',
      );
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
    if (updated != null && context.mounted) {
      await _recordAction(
        context,
        () => ref.read(appControllerProvider.notifier).saveExercise(updated),
        '运动已更新',
      );
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
    if (confirmed && context.mounted) {
      await _recordAction(
        context,
        () => ref
            .read(appControllerProvider.notifier)
            .deleteExercise(exercise.id!),
        '运动记录已删除',
      );
    }
  }

  Future<void> _recordAction(
    BuildContext context,
    Future<void> Function() action,
    String message,
  ) async {
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('操作未完成，请重试')));
      }
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
    final status = target <= 0
        ? '未设目标'
        : actual >= target
        ? (actual == target ? '已达标' : '已达标 · 超出 ${_one(actual - target)}g')
        : '还差 ${_one(target - actual)}g';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_one(actual)} / ${_one(target)} g',
                style: const TextStyle(color: mutedColor, fontSize: 12),
              ),
            ),
            Text(
              status,
              style: TextStyle(
                fontSize: 11,
                color: actual >= target && target > 0 ? brandGreen : mutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Tooltip(
          message: MealType.values
              .map((type) => '${type.label} ${_one(breakdown[type] ?? 0)}g')
              .join(' · '),
          child: _StackedNutritionBar(target: target, breakdown: breakdown),
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

class _IndulgenceDayCard extends StatelessWidget {
  const _IndulgenceDayCard({
    required this.hasSavedEntries,
    required this.isToday,
  });

  final bool hasSavedEntries;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5DA), Color(0xFFFFE8B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0x33D58C18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18B7791F),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.celebration_rounded,
            color: Color(0xFFB56C08),
            size: 28,
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? '今天，给自己放个假' : '这一天是放纵日',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF71440B),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                '放纵日不统计饮食、营养或运动收支，净能量默认按 0 kcal 平衡记录。',
                style: TextStyle(color: Color(0xFF7A592D), height: 1.45),
              ),
              if (hasSavedEntries) ...[
                const SizedBox(height: 7),
                const Text(
                  '此前填写的餐食和运动仍然保留，但在放纵日状态下不参与统计。',
                  style: TextStyle(
                    color: Color(0xFF8B641F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB56C08).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '无需记录 · 默认平衡',
                  style: TextStyle(
                    color: Color(0xFF9B5A05),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.selected,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime selected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final today = dateKey(selected) == dateKey(DateTime.now());
    final formatter = DateFormat('M月d日 EEEE', 'zh_CN');
    return Row(
      children: [
        IconButton(
          tooltip: '前一天',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
          ),
        ),
        IconButton(
          tooltip: '后一天',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EnergyHero extends StatelessWidget {
  const _EnergyHero({
    required this.summary,
    required this.hasEntries,
    required this.isToday,
  });
  final DailySummary summary;
  final bool hasEntries;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final net = summary.netEnergy;
    final status = !hasEntries
        ? '等待记录'
        : net < 0
        ? '热量缺口'
        : net > 0
        ? '热量增加'
        : '能量平衡';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF204F40), Color(0xFF326F55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18204F40),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFD7E9A9),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isToday ? '今日净能量' : '当日净能量',
                  style: const TextStyle(
                    color: Color(0xFFD5E4D9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFFE5EFC5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: hasEntries ? net : 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      !hasEntries
                          ? '—'
                          : '${value < -.5
                                ? '−'
                                : value > .5
                                ? '+'
                                : ''}${value.abs().round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w600,
                        height: 1.06,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, bottom: 5),
                child: Text('kcal', style: TextStyle(color: Color(0xFFBED1C6))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasEntries ? '摄入 − 基础消耗 − 运动消耗' : '尚未记录 · 添加餐食或运动后计算收支',
            style: const TextStyle(color: Color(0xFFBED1C6), fontSize: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0x26FFFFFF)),
          ),
          Row(
            children: [
              _HeroMetric(label: '饮食摄入', value: summary.intake.energyKcal),
              _HeroDivider(),
              _HeroMetric(
                label: '基础消耗',
                value: summary.record.baselineKcal.toDouble(),
              ),
              _HeroDivider(),
              _HeroMetric(label: '运动消耗', value: summary.exerciseKcal),
            ],
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

class _MealGroupHeading extends StatelessWidget {
  const _MealGroupHeading({required this.type, required this.meals});
  final MealType type;
  final List<MealEntry> meals;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: _mealTypeColor(type),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          type.label,
          style: TextStyle(
            color: _mealTypeColor(type),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '${_kcal(meals.fold<double>(0, (sum, meal) => sum + meal.total.energyKcal))} kcal',
          style: const TextStyle(color: mutedColor, fontSize: 11),
        ),
      ],
    ),
  );
}

class _DayTypeSelector extends StatelessWidget {
  const _DayTypeSelector({required this.selected, required this.onChanged});
  final DayType selected;
  final ValueChanged<DayType> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4EF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        for (final type in DayType.values)
          Expanded(
            child: Semantics(
              selected: type == selected,
              button: true,
              child: Tooltip(
                message: type.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: type == selected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: type == selected
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D20362E),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            switch (type) {
                              DayType.cardio => Icons.directions_run_rounded,
                              DayType.strength => Icons.fitness_center_rounded,
                              DayType.rest => Icons.spa_outlined,
                              DayType.indulgence => Icons.celebration_outlined,
                            },
                            size: 16,
                            color: type == selected ? deepGreen : mutedColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            type.shortLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: type == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: type == selected ? deepGreen : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => InkWell(
    onTap: onEdit,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecipeThumbnail(bytes: recipe?.imageBytes, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.recipeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 3,
                  children: [
                    Text(
                      '${_kcal(meal.total.energyKcal)} kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: deepGreen,
                      ),
                    ),
                    Text(
                      '${_one(meal.servings)} × ${meal.servingLabel}',
                      style: const TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    if (meal.recipeId == null)
                      const Text(
                        '临时餐食',
                        style: TextStyle(fontSize: 11, color: warmColor),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 3,
                  children: [
                    Text(
                      '碳水 ${_one(meal.total.carbsG)}g',
                      style: const TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    Text(
                      '蛋白 ${_one(meal.total.proteinG)}g',
                      style: const TextStyle(fontSize: 11, color: mutedColor),
                    ),
                    Text(
                      '脂肪 ${_one(meal.total.fatG)}g',
                      style: const TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '餐食操作',
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑餐食')),
              PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
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
    onTap: onEdit,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE7F5EE),
      foregroundColor: brandGreen,
      child: Icon(Icons.directions_run_rounded),
    ),
    title: Text(exercise.name, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    this.initialRecipe,
  });

  final DateTime date;
  final List<Recipe> recipes;
  final MealEntry? initial;
  final Recipe? initialRecipe;

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
    _recipe = widget.initialRecipe;
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
    final count = _safeNumber(_servings.text);
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Handle(),
                    EditorHeading(
                      title: editing ? '编辑餐食' : '添加餐食',
                      subtitle:
                          '记录到 ${DateFormat('yyyy年M月d日').format(widget.date)}',
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
                      FormField<Recipe>(
                        validator: (_) => _recipe == null ? '请先选择一份菜谱' : null,
                        builder: (field) => InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final recipe = await showAdaptiveEditor<Recipe>(
                              context: context,
                              builder: (_) =>
                                  RecipePicker(recipes: widget.recipes),
                            );
                            if (recipe != null && mounted) {
                              setState(() => _recipe = recipe);
                              field.didChange(recipe);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: '选择菜谱',
                              errorText: field.errorText,
                            ),
                            child: Row(
                              children: [
                                RecipeThumbnail(
                                  bytes: _recipe?.imageBytes,
                                  size: 44,
                                  radius: 10,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _recipe?.name ?? '搜索或按分类选择',
                                    style: TextStyle(
                                      color: _recipe == null
                                          ? mutedColor
                                          : inkColor,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.search_rounded,
                                  color: mutedColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
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
                      Text(
                        '每份营养',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                        if (number == null || !number.isFinite || number <= 0) {
                          return '请输入大于 0 的份数';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final amount in [0.5, 1.0, 1.5, 2.0])
                          ChoiceChip(
                            label: Text('${_one(amount)} 份'),
                            selected: count == amount,
                            onSelected: (_) =>
                                setState(() => _servings.text = _one(amount)),
                          ),
                      ],
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
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(editing ? '保存修改' : '添加到当天'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Nutrition get _temporaryNutrition => Nutrition(
    energyKcal: _safeNumber(_energy.text),
    carbsG: _safeNumber(_carbs.text),
    proteinG: _safeNumber(_protein.text),
    fatG: _safeNumber(_fat.text),
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
      if (parsed == null || !parsed.isFinite) return '请输入有效数字';
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
                if (number == null || !number.isFinite || number <= 0) {
                  return '请输入大于 0 的能量';
                }
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

double _safeNumber(String text) {
  final value = double.tryParse(text.trim());
  return value != null && value.isFinite && value >= 0 ? value : 0;
}

String _kcal(double value) => value.isFinite ? value.round().toString() : '—';
String _one(double value) => !value.isFinite
    ? '—'
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
