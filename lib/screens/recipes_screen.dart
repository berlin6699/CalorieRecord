import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/transfer_service.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  static const _allCategories = -2;
  static const _uncategorized = -1;
  String _query = '';
  int _categoryFilter = _allCategories;

  @override
  Widget build(BuildContext context) {
    final desktop = useDesktopLayout(context);
    final data = ref.watch(appControllerProvider).requireValue;
    final filtered = data.recipes
        .where(
          (recipe) =>
              recipe.name.toLowerCase().contains(_query.toLowerCase()) &&
              (_categoryFilter == _allCategories ||
                  (_categoryFilter == _uncategorized &&
                      recipe.categoryId == null) ||
                  recipe.categoryId == _categoryFilter),
        )
        .toList();
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: const Text('我的菜谱'),
              actions: [
                IconButton(
                  tooltip: '管理分类',
                  onPressed: () => _manageCategories(context),
                  icon: const Icon(Icons.folder_outlined),
                ),
                IconButton(
                  tooltip: '导入菜谱 JSON',
                  onPressed: () => _importRecipes(context),
                  icon: const Icon(Icons.file_download_outlined),
                ),
                const SizedBox(width: 6),
              ],
            ),
      floatingActionButton: desktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editRecipe(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建菜谱'),
            ),
      body: Column(
        children: [
          if (desktop)
            DesktopPageHeader(
              title: '菜谱库',
              subtitle: '共 ${data.recipes.length} 份菜谱 · 集中维护每份餐食的营养数据',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _manageCategories(context),
                  icon: const Icon(Icons.folder_outlined, size: 19),
                  label: const Text('管理分类'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importRecipes(context),
                  icon: const Icon(Icons.file_download_outlined, size: 19),
                  label: const Text('导入 JSON'),
                ),
                FilledButton.icon(
                  onPressed: () => _editRecipe(context),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('新建菜谱'),
                ),
              ],
            ),
          Expanded(
            child: ContentFrame(
              maxWidth: 1240,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 28 : 18,
                      desktop ? 24 : 4,
                      desktop ? 28 : 18,
                      14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: desktop ? 460 : double.infinity,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: '按名称搜索菜谱',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (value) =>
                                setState(() => _query = value.trim()),
                          ),
                        ),
                        const SizedBox(height: 13),
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ChoiceChip(
                                label: Text('全部 ${data.recipes.length}'),
                                selected: _categoryFilter == _allCategories,
                                onSelected: (_) => setState(
                                  () => _categoryFilter = _allCategories,
                                ),
                              ),
                              const SizedBox(width: 8),
                              for (final category in data.recipeCategories) ...[
                                ChoiceChip(
                                  label: Text(
                                    '${category.name} ${data.recipes.where((recipe) => recipe.categoryId == category.id).length}',
                                  ),
                                  selected: _categoryFilter == category.id,
                                  onSelected: (_) => setState(
                                    () => _categoryFilter = category.id!,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              ChoiceChip(
                                label: Text(
                                  '未分类 ${data.recipes.where((recipe) => recipe.categoryId == null).length}',
                                ),
                                selected: _categoryFilter == _uncategorized,
                                onSelected: (_) => setState(
                                  () => _categoryFilter = _uncategorized,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? ListView(
                            padding: EdgeInsets.all(desktop ? 28 : 18),
                            children: [
                              EmptyState(
                                icon: Icons.menu_book_rounded,
                                title: data.recipes.isEmpty
                                    ? '还没有菜谱'
                                    : '当前分类没有匹配的菜谱',
                                message: data.recipes.isEmpty
                                    ? '手动新建，或导入标准 JSON 文件'
                                    : '换一个分类或关键词试试',
                                action: data.recipes.isEmpty
                                    ? FilledButton.tonalIcon(
                                        onPressed: () => _editRecipe(context),
                                        icon: const Icon(Icons.add_rounded),
                                        label: const Text('新建第一份菜谱'),
                                      )
                                    : null,
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (desktop || constraints.maxWidth >= 800) {
                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    desktop ? 28 : 18,
                                    0,
                                    desktop ? 28 : 18,
                                    desktop ? 36 : 110,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 520,
                                        mainAxisExtent: 140,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                      ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) => _RecipeCard(
                                    recipe: filtered[index],
                                    onEdit: () => _editRecipe(
                                      context,
                                      initial: filtered[index],
                                    ),
                                    onDelete: () =>
                                        _deleteRecipe(context, filtered[index]),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  110,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) => _RecipeCard(
                                  recipe: filtered[index],
                                  onEdit: () => _editRecipe(
                                    context,
                                    initial: filtered[index],
                                  ),
                                  onDelete: () =>
                                      _deleteRecipe(context, filtered[index]),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRecipe(BuildContext context, {Recipe? initial}) async {
    final data = ref.read(appControllerProvider).requireValue;
    final recipe = await showAdaptiveEditor<Recipe>(
      context: context,
      builder: (context) =>
          RecipeEditor(initial: initial, categories: data.recipeCategories),
    );
    if (recipe == null) return;
    try {
      await ref.read(appControllerProvider.notifier).saveRecipe(recipe);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(initial == null ? '菜谱已创建' : '菜谱已更新')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败：已有同名菜谱或数据不合法')));
      }
    }
  }

  Future<void> _manageCategories(BuildContext context) async {
    await showAdaptiveEditor<void>(
      context: context,
      desktopWidth: 520,
      builder: (context) => const _CategoryManager(),
    );
    if (mounted) setState(() => _categoryFilter = _allCategories);
  }

  Future<void> _deleteRecipe(BuildContext context, Recipe recipe) async {
    final confirmed = await confirmAction(
      context,
      title: '删除菜谱？',
      message: '删除“${recipe.name}”不会影响已经记录的历史餐食。',
      confirmText: '删除',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(appControllerProvider.notifier).deleteRecipe(recipe.id!);
    }
  }

  Future<void> _importRecipes(BuildContext context) async {
    try {
      final service = TransferService(ref.read(databaseProvider));
      final recipes = await service.pickRecipeFile();
      if (recipes == null || !context.mounted) return;
      if (recipes.isEmpty) {
        throw const FormatException('文件中没有菜谱');
      }
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导入 ${recipes.length} 份菜谱'),
          content: Text(
            '示例：${recipes.take(3).map((item) => item.name).join('、')}${recipes.length > 3 ? '…' : ''}\n\n遇到同名菜谱时如何处理？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('跳过同名'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('覆盖同名'),
            ),
          ],
        ),
      );
      if (overwrite == null) return;
      await ref
          .read(appControllerProvider.notifier)
          .importRecipes(recipes, overwrite: overwrite);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('菜谱导入完成，共读取 ${recipes.length} 条')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导入失败：$error')));
      }
    }
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.onEdit,
    required this.onDelete,
  });

  final Recipe recipe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 16, 8, 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 76,
                height: 88,
                child: recipe.imageBytes == null
                    ? const ColoredBox(
                        color: Color(0xFFFFF3D6),
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFF9A6800),
                          size: 28,
                        ),
                      )
                    : Image.memory(
                        recipe.imageBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFFFF3D6),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF9A6800),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.categoryName ?? '未分类'} · 每份 ${recipe.servingLabel} · ${_number(recipe.nutrition.energyKcal)} kcal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 10,
                    children: [
                      _Macro(label: '碳', value: recipe.nutrition.carbsG),
                      _Macro(label: '蛋白', value: recipe.nutrition.proteinG),
                      _Macro(label: '脂', value: recipe.nutrition.fatG),
                    ],
                  ),
                ],
              ),
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
      ),
    ),
  );
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Text(
    '$label ${_number(value)}g',
    style: const TextStyle(
      color: Color(0xFF6A766F),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class RecipeEditor extends StatefulWidget {
  const RecipeEditor({super.key, this.initial, required this.categories});
  final Recipe? initial;
  final List<RecipeCategory> categories;

  @override
  State<RecipeEditor> createState() => _RecipeEditorState();
}

class _RecipeEditorState extends State<RecipeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _serving;
  late final TextEditingController _energy;
  late final TextEditingController _carbs;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final recipe = widget.initial;
    _imageBytes = recipe?.imageBytes;
    _imageMimeType = recipe?.imageMimeType;
    _categoryId = recipe?.categoryId;
    _name = TextEditingController(text: recipe?.name ?? '');
    _serving = TextEditingController(text: recipe?.servingLabel ?? '1 份');
    _energy = TextEditingController(
      text: recipe == null ? '' : _number(recipe.nutrition.energyKcal),
    );
    _carbs = TextEditingController(
      text: recipe == null ? '' : _number(recipe.nutrition.carbsG),
    );
    _protein = TextEditingController(
      text: recipe == null ? '' : _number(recipe.nutrition.proteinG),
    );
    _fat = TextEditingController(
      text: recipe == null ? '' : _number(recipe.nutrition.fatG),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _serving,
      _energy,
      _carbs,
      _protein,
      _fat,
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
              widget.initial == null ? '新建菜谱' : '编辑菜谱',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: _imageBytes == null
                          ? const ColoredBox(
                              color: Color(0xFFFFF3D6),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Color(0xFF9A6800),
                                size: 30,
                              ),
                            )
                          : Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: Color(0xFFFFF3D6),
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _imageBytes == null ? '菜谱图片' : '已添加菜谱图片',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          '支持 JPG、PNG、WebP，最大 5 MB',
                          style: TextStyle(
                            color: Color(0xFF65726C),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 17,
                              ),
                              label: Text(_imageBytes == null ? '选择图片' : '更换'),
                            ),
                            if (_imageBytes != null)
                              TextButton(
                                onPressed: () => setState(() {
                                  _imageBytes = null;
                                  _imageMimeType = null;
                                }),
                                child: const Text('移除'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '菜谱名称'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _categoryId ?? -1,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '所属分类'),
              items: [
                const DropdownMenuItem(value: -1, child: Text('未分类')),
                ...widget.categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id!,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _categoryId = value == -1 ? null : value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serving,
              decoration: const InputDecoration(
                labelText: '每份说明',
                hintText: '例如：一碗、250 克、一盒',
              ),
              validator: _required,
            ),
            const SizedBox(height: 18),
            Text('每份营养', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            NumberField(controller: _energy, label: '能量', suffix: 'kcal'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _carbs,
                    label: '碳水',
                    suffix: 'g',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NumberField(
                    controller: _protein,
                    label: '蛋白质',
                    suffix: 'g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NumberField(controller: _fat, label: '脂肪', suffix: 'g'),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  Recipe(
                    id: widget.initial?.id,
                    name: _name.text.trim(),
                    servingLabel: _serving.text.trim(),
                    nutrition: Nutrition(
                      energyKcal: double.parse(_energy.text),
                      carbsG: double.parse(_carbs.text),
                      proteinG: double.parse(_protein.text),
                      fatG: double.parse(_fat.text),
                    ),
                    categoryId: _categoryId,
                    categoryName: _categoryName(_categoryId),
                    imageBytes: _imageBytes,
                    imageMimeType: _imageMimeType,
                  ),
                );
              },
              child: Text(widget.initial == null ? '创建菜谱' : '保存修改'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || !mounted) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法读取所选图片')));
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('图片不能超过 5 MB')));
      return;
    }
    final extension = file.extension?.toLowerCase();
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
    });
  }

  String? _categoryName(int? id) {
    if (id == null) return null;
    for (final category in widget.categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }
}

class _CategoryManager extends ConsumerWidget {
  const _CategoryManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider).requireValue;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!useDesktopLayout(context))
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '管理菜谱分类',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '删除分类不会删除其中的菜谱',
                        style: TextStyle(color: Color(0xFF65726C)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: () => _editCategory(context, ref),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('新建分类'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: data.recipeCategories.isEmpty
                  ? const Center(child: Text('还没有分类'))
                  : ListView.separated(
                      itemCount: data.recipeCategories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = data.recipeCategories[index];
                        final count = data.recipes
                            .where((recipe) => recipe.categoryId == category.id)
                            .length;
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.folder_outlined),
                          ),
                          title: Text(category.name),
                          subtitle: Text('$count 份菜谱'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit'
                                ? _editCategory(context, ref, initial: category)
                                : _deleteCategory(
                                    context,
                                    ref,
                                    category,
                                    count,
                                  ),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('重命名')),
                              PopupMenuItem(value: 'delete', child: Text('删除')),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    WidgetRef ref, {
    RecipeCategory? initial,
  }) async {
    final controller = TextEditingController(text: initial?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(initial == null ? '新建分类' : '重命名分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(labelText: '分类名称'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    try {
      await ref
          .read(appControllerProvider.notifier)
          .saveRecipeCategory(
            RecipeCategory(
              id: initial?.id,
              name: name.trim(),
              createdAt: initial?.createdAt ?? DateTime.now(),
            ),
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存失败：分类名称不能为空或已经存在')));
      }
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    RecipeCategory category,
    int count,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: '删除“${category.name}”？',
      message: '$count 份菜谱会移到“未分类”，菜谱本身不会被删除。',
      confirmText: '删除分类',
      destructive: true,
    );
    if (confirmed) {
      await ref
          .read(appControllerProvider.notifier)
          .deleteRecipeCategory(category.id!);
    }
  }
}

String? _required(String? value) =>
    value?.trim().isEmpty ?? true ? '不能为空' : null;

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
