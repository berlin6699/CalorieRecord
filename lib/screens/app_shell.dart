import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import '../widgets/common.dart';
import 'body_screen.dart';
import 'recipes_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'trends_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _pages = [
    TodayScreen(),
    RecipesScreen(),
    TrendsScreen(),
    BodyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return app.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text('数据加载失败'),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.read(appControllerProvider.notifier).reloadAll(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (data) {
        if (!data.profile.configured) return const FirstRunSetupScreen();
        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = useDesktopLayout(context);
            if (!desktop) {
              return Scaffold(
                body: IndexedStack(index: _index, children: _pages),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _selectPage,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today_rounded),
                      label: '今日',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.restaurant_menu_outlined),
                      selectedIcon: Icon(Icons.restaurant_menu_rounded),
                      label: '菜谱',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.flag_outlined),
                      selectedIcon: Icon(Icons.flag_rounded),
                      label: '计划',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.monitor_weight_outlined),
                      selectedIcon: Icon(Icons.monitor_weight_rounded),
                      label: '身体',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: '设置',
                    ),
                  ],
                ),
              );
            }
            return Scaffold(
              body: Row(
                children: [
                  _DesktopSidebar(
                    selectedIndex: _index,
                    onSelected: _selectPage,
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFFF2F5F3),
                      child: IndexedStack(index: _index, children: _pages),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectPage(int value) => setState(() => _index = value);
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, '今日概览'),
    (Icons.menu_book_outlined, Icons.menu_book_rounded, '我的菜谱'),
    (Icons.flag_outlined, Icons.flag_rounded, '训练计划'),
    (Icons.monitor_weight_outlined, Icons.monitor_weight_rounded, '身体数据'),
    (Icons.tune_outlined, Icons.tune_rounded, '个人与设置'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 248,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF123D30), Color(0xFF0D3026)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      right: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DesktopBrand(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            child: Text(
              '工作台',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
          ),
          for (var index = 0; index < _items.length; index++)
            _DesktopNavItem(
              icon: selectedIndex == index
                  ? _items[index].$2
                  : _items[index].$1,
              label: _items[index].$3,
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '数据保存在本机',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CalorieRecord v1.0.6',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DesktopBrand extends StatelessWidget {
  const _DesktopBrand();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 18, 32),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3DDC97), Color(0xFF22A06B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x553DDC97),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CalorieRecord',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '能量管理工作台',
                style: TextStyle(color: Color(0xFF8DB7A7), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.08))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? const Color(0xFF68E0AE)
                    : Colors.white.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.68),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF68E0AE),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 6, height: 6),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
