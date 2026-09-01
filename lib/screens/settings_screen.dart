import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import '../data/transfer_service.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class FirstRunSetupScreen extends ConsumerWidget {
  const FirstRunSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appControllerProvider).requireValue.profile;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: brandGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '先认识一下你',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '这些数据只保存在你的设备上，用于计算每日基础消耗。稍后可以随时修改。',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  ProfileEditor(
                    initial: profile,
                    submitLabel: '保存并开始',
                    onSaved: (value) => ref
                        .read(appControllerProvider.notifier)
                        .saveProfile(value.copyWith(configured: true)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).requireValue;
    if (useDesktopLayout(context)) {
      return _buildDesktop(context, ref, data);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ContentFrame(
        maxWidth: 980,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            const SectionHeader(title: '个人与基础消耗', subtitle: '公式建议只在你主动采用时生效'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _IconTile(icon: Icons.person_rounded),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.profile.sex == Sex.male ? '男' : '女'} · ${data.profile.age} 岁 · ${_trim(data.profile.heightCm)} cm · ${_trim(data.profile.weightKg)} kg',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '当前基础消耗 ${data.profile.baselineKcal} kcal/天',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '编辑个人资料',
                          onPressed: () =>
                              _editProfile(context, ref, data.profile),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: brandGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '公式建议 ${data.profile.suggestedBaselineKcal} kcal/天',
                          ),
                        ),
                        TextButton(
                          onPressed:
                              data.profile.baselineKcal ==
                                  data.profile.suggestedBaselineKcal
                              ? null
                              : () => ref
                                    .read(appControllerProvider.notifier)
                                    .saveProfile(
                                      data.profile.copyWith(
                                        baselineKcal:
                                            data.profile.suggestedBaselineKcal,
                                      ),
                                    ),
                          child: const Text('采用'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: '日类型与营养目标', subtitle: '修改只影响未来新建的日期'),
            Card(
              child: Column(
                children: [
                  for (final type in DayType.values)
                    _GoalTile(
                      goal: data.goals[type]!,
                      isDefault: data.profile.defaultDayType == type,
                      onEdit: () => _editGoal(context, ref, data.goals[type]!),
                      onSetDefault: () => ref
                          .read(appControllerProvider.notifier)
                          .saveProfile(
                            data.profile.copyWith(defaultDayType: type),
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SectionHeader(title: '数据管理', subtitle: '备份包含个人资料、菜谱和全部历史'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const _IconTile(icon: Icons.ios_share_rounded),
                    title: const Text('导出完整备份'),
                    subtitle: const Text('保存或分享版本化 JSON 文件'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _export(context, ref),
                  ),
                  const Divider(indent: 72, height: 1),
                  ListTile(
                    leading: const _IconTile(
                      icon: Icons.settings_backup_restore,
                    ),
                    title: const Text('从备份恢复'),
                    subtitle: const Text('校验成功后替换当前全部数据'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _restore(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Card(
              color: const Color(0xFFEAF5F0),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  '计算说明\n净能量 = 饮食摄入 − 当日基础消耗 − 运动消耗。公式建议采用 Mifflin-St Jeor BMR × 1.2；修改身体数据后不会自动覆盖你正在使用的基础消耗。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    WidgetRef ref,
    AppState data,
  ) => Scaffold(
    body: Column(
      children: [
        const DesktopPageHeader(
          title: '个人与设置',
          subtitle: '管理基础消耗、训练日营养目标与本地数据',
        ),
        Expanded(
          child: ContentFrame(
            maxWidth: 1320,
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: '个人与基础消耗',
                              subtitle: '公式建议只在你主动采用时生效',
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const _IconTile(
                                          icon: Icons.person_rounded,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${data.profile.sex == Sex.male ? '男' : '女'} · ${data.profile.age} 岁 · ${_trim(data.profile.heightCm)} cm · ${_trim(data.profile.weightKg)} kg',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '当前基础消耗 ${data.profile.baselineKcal} kcal/天',
                                              ),
                                            ],
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _editProfile(
                                            context,
                                            ref,
                                            data.profile,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('编辑资料'),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: brandGreen,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'Mifflin-St Jeor 公式建议：${data.profile.suggestedBaselineKcal} kcal/天',
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              data.profile.baselineKcal ==
                                                  data
                                                      .profile
                                                      .suggestedBaselineKcal
                                              ? null
                                              : () => ref
                                                    .read(
                                                      appControllerProvider
                                                          .notifier,
                                                    )
                                                    .saveProfile(
                                                      data.profile.copyWith(
                                                        baselineKcal: data
                                                            .profile
                                                            .suggestedBaselineKcal,
                                                      ),
                                                    ),
                                          child: const Text('采用建议'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SectionHeader(
                              title: '日类型与营养目标',
                              subtitle: '修改只影响未来新建的日期',
                            ),
                            Card(
                              child: Column(
                                children: [
                                  for (final type in DayType.values)
                                    _GoalTile(
                                      goal: data.goals[type]!,
                                      isDefault:
                                          data.profile.defaultDayType == type,
                                      onEdit: () => _editGoal(
                                        context,
                                        ref,
                                        data.goals[type]!,
                                      ),
                                      onSetDefault: () => ref
                                          .read(appControllerProvider.notifier)
                                          .saveProfile(
                                            data.profile.copyWith(
                                              defaultDayType: type,
                                            ),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: '数据管理',
                              subtitle: '备份包含个人资料、菜谱和全部历史',
                            ),
                            Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 7,
                                    ),
                                    leading: const _IconTile(
                                      icon: Icons.save_alt_rounded,
                                    ),
                                    title: const Text('导出完整备份'),
                                    subtitle: const Text('保存为版本化 JSON 文件'),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => _export(context, ref),
                                  ),
                                  const Divider(indent: 72),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 7,
                                    ),
                                    leading: const _IconTile(
                                      icon: Icons.settings_backup_restore,
                                    ),
                                    title: const Text('从备份恢复'),
                                    subtitle: const Text('校验后替换当前全部数据'),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => _restore(context, ref),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SectionHeader(
                              title: '计算与隐私',
                              subtitle: '本地优先，不需要登录账户',
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SettingNote(
                                      icon: Icons.calculate_outlined,
                                      title: '净能量计算',
                                      message: '饮食摄入 − 当日基础消耗 − 运动消耗',
                                    ),
                                    const Divider(height: 28),
                                    const _SettingNote(
                                      icon: Icons.shield_outlined,
                                      title: '本地数据',
                                      message: '所有资料均保存在这台设备，不会自动上传',
                                    ),
                                    const Divider(height: 28),
                                    _SettingNote(
                                      icon: Icons.storage_outlined,
                                      title: '当前版本',
                                      message:
                                          'CalorieRecord v1.0.1 · Windows x64',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
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
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showAdaptiveEditor<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text('编辑个人资料', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              ProfileEditor(
                initial: profile,
                submitLabel: '保存修改',
                onSaved: (value) async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .saveProfile(value.copyWith(configured: true));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editGoal(
    BuildContext context,
    WidgetRef ref,
    DayGoal goal,
  ) async {
    final saved = await showAdaptiveEditor<DayGoal>(
      context: context,
      builder: (context) => GoalEditor(goal: goal),
    );
    if (saved != null) {
      await ref.read(appControllerProvider.notifier).saveGoal(saved);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      await TransferService(ref.read(databaseProvider)).exportBackup();
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final service = TransferService(ref.read(databaseProvider));
      final data = await service.pickJson();
      if (data == null || !context.mounted) return;
      final confirmed = await confirmAction(
        context,
        title: '替换当前全部数据？',
        message: '恢复会删除当前 App 内的数据并替换为备份内容。请确保已另行备份。',
        confirmText: '恢复',
        destructive: true,
      );
      if (!confirmed) return;
      await ref.read(databaseProvider).restoreAll(data);
      await ref.read(appControllerProvider.notifier).reloadAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('数据恢复完成')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.initial,
    required this.submitLabel,
    required this.onSaved,
  });

  final UserProfile initial;
  final String submitLabel;
  final Future<void> Function(UserProfile value) onSaved;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late Sex _sex;
  late DayType _defaultType;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _baseline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sex = widget.initial.sex;
    _defaultType = widget.initial.defaultDayType;
    _age = TextEditingController(text: widget.initial.age.toString());
    _height = TextEditingController(text: _trim(widget.initial.heightCm));
    _weight = TextEditingController(text: _trim(widget.initial.weightKg));
    _baseline = TextEditingController(
      text: widget.initial.baselineKcal.toString(),
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _baseline.dispose();
    super.dispose();
  }

  int _suggested() => calculateSedentaryTdee(
    sex: _sex,
    weightKg: double.tryParse(_weight.text) ?? widget.initial.weightKg,
    heightCm: double.tryParse(_height.text) ?? widget.initial.heightCm,
    age: int.tryParse(_age.text) ?? widget.initial.age,
  );

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<Sex>(
          segments: const [
            ButtonSegment(value: Sex.male, label: Text('男')),
            ButtonSegment(value: Sex.female, label: Text('女')),
          ],
          selected: {_sex},
          onSelectionChanged: (value) => setState(() => _sex = value.first),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: NumberField(
                controller: _age,
                label: '年龄',
                suffix: '岁',
                decimal: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NumberField(
                controller: _height,
                label: '身高',
                suffix: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        NumberField(controller: _weight, label: '体重', suffix: 'kg'),
        const SizedBox(height: 12),
        NumberField(
          controller: _baseline,
          label: '当前每日基础消耗',
          suffix: 'kcal',
          decimal: false,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _baseline.text = '$_suggested()'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('重新计算并填入'),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<DayType>(
          initialValue: _defaultType,
          decoration: const InputDecoration(labelText: '新日期默认类型'),
          items: DayType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) => _defaultType = value ?? _defaultType,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? '正在保存…' : widget.submitLabel),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.parse(_age.text);
    if (age < 12 || age > 120) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('年龄请输入 12–120 之间的数值')));
      return;
    }
    setState(() => _saving = true);
    final suggested = _suggested();
    await widget.onSaved(
      UserProfile(
        sex: _sex,
        age: age,
        heightCm: double.parse(_height.text),
        weightKg: double.parse(_weight.text),
        suggestedBaselineKcal: suggested,
        baselineKcal: int.parse(_baseline.text),
        defaultDayType: _defaultType,
        configured: widget.initial.configured,
      ),
    );
    if (mounted) setState(() => _saving = false);
  }
}

class GoalEditor extends StatefulWidget {
  const GoalEditor({super.key, required this.goal});

  final DayGoal goal;

  @override
  State<GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<GoalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _energy;
  late final TextEditingController _carbs;
  late final TextEditingController _protein;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    final n = widget.goal.target;
    _energy = TextEditingController(text: _trim(n.energyKcal));
    _carbs = TextEditingController(text: _trim(n.carbsG));
    _protein = TextEditingController(text: _trim(n.proteinG));
    _fat = TextEditingController(text: _trim(n.fatG));
  }

  @override
  void dispose() {
    for (final controller in [_energy, _carbs, _protein, _fat]) {
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
            const _SheetHandle(),
            Text(
              '${widget.goal.type.label}目标',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text('已存在日期保存的是历史快照，不会被此次修改覆盖。'),
            const SizedBox(height: 20),
            NumberField(controller: _energy, label: '能量', suffix: 'kcal'),
            const SizedBox(height: 12),
            NumberField(controller: _carbs, label: '碳水', suffix: 'g'),
            const SizedBox(height: 12),
            NumberField(controller: _protein, label: '蛋白质', suffix: 'g'),
            const SizedBox(height: 12),
            NumberField(controller: _fat, label: '脂肪', suffix: 'g'),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  DayGoal(
                    type: widget.goal.type,
                    target: Nutrition(
                      energyKcal: double.parse(_energy.text),
                      carbsG: double.parse(_carbs.text),
                      proteinG: double.parse(_protein.text),
                      fatG: double.parse(_fat.text),
                    ),
                  ),
                );
              },
              child: const Text('保存目标'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.isDefault,
    required this.onEdit,
    required this.onSetDefault,
  });

  final DayGoal goal;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: _IconTile(
      icon: switch (goal.type) {
        DayType.cardio => Icons.directions_run_rounded,
        DayType.strength => Icons.fitness_center_rounded,
        DayType.rest => Icons.self_improvement_rounded,
      },
    ),
    title: Row(
      children: [
        Text(goal.type.label),
        if (isDefault) ...[
          const SizedBox(width: 7),
          const Chip(label: Text('默认'), visualDensity: VisualDensity.compact),
        ],
      ],
    ),
    subtitle: Text(
      '${_trim(goal.target.energyKcal)} kcal · 碳 ${_trim(goal.target.carbsG)}g · 蛋白 ${_trim(goal.target.proteinG)}g · 脂 ${_trim(goal.target.fatG)}g',
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onSetDefault(),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('编辑目标')),
        if (!isDefault)
          const PopupMenuItem(value: 'default', child: Text('设为默认')),
      ],
    ),
  );
}

class _SettingNote extends StatelessWidget {
  const _SettingNote({
    required this.icon,
    required this.title,
    required this.message,
    this.color = brandGreen,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFE7F5EE),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: brandGreen, size: 22),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

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

String _trim(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('操作失败：$error')));
}
