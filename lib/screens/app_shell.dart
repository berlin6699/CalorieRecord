import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
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
    SettingsScreen(),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today_rounded),
      label: Text('今日'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu_rounded),
      label: Text('菜谱'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights_rounded),
      label: Text('趋势'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune_rounded),
      label: Text('设置'),
    ),
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
            final desktop = constraints.maxWidth >= 760;
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
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights_rounded),
                      label: '趋势',
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
            final extended = constraints.maxWidth >= 1120;
            return Scaffold(
              body: Row(
                children: [
                  SafeArea(
                    right: false,
                    child: NavigationRail(
                      extended: extended,
                      minExtendedWidth: 210,
                      selectedIndex: _index,
                      onDestinationSelected: _selectPage,
                      groupAlignment: -0.55,
                      leading: _AppBrand(extended: extended),
                      destinations: _railDestinations,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: IndexedStack(index: _index, children: _pages),
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

class _AppBrand extends StatelessWidget {
  const _AppBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12, 14, extended ? 22 : 12, 34),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF147553), Color(0xFF2AB77C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3022A06B),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CalorieRecord',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 1),
              Text(
                '能量与营养记录',
                style: TextStyle(fontSize: 11, color: Color(0xFF718078)),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
