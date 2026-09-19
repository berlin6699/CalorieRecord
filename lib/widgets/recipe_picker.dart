import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../data/models.dart';
import 'common.dart';

class RecipePicker extends StatefulWidget {
  const RecipePicker({super.key, required this.recipes});
  final List<Recipe> recipes;

  @override
  State<RecipePicker> createState() => _RecipePickerState();
}

class _RecipePickerState extends State<RecipePicker> {
  final _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.recipes
        .map((r) => r.categoryName ?? '未分类')
        .toSet()
        .toList();
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.recipes
        .where(
          (r) =>
              r.name.toLowerCase().contains(query) &&
              (_category == null || (r.categoryName ?? '未分类') == _category),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: SizedBox(
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditorHeading(title: '选择一份菜谱', subtitle: '按名称查找，或从分类里挑选'),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '搜索菜谱',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清空搜索',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final category in categories) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('没有匹配的菜谱，试试其他名称或分类'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 68),
                      itemBuilder: (context, index) {
                        final recipe = filtered[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          leading: RecipeThumbnail(
                            bytes: recipe.imageBytes,
                            size: 50,
                          ),
                          title: Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${recipe.servingLabel} · ${recipe.categoryName ?? '未分类'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                          trailing: Text(
                            '${recipe.nutrition.energyKcal.round()}\nkcal',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: deepGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, recipe),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
