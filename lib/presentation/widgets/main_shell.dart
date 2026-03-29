import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'glass/glass_scaffold.dart';
import 'ssu_logo.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (path: '/home', icon: Icons.dashboard_outlined, label: AppStrings.navHome),
    (path: '/daily', icon: Icons.check_circle_outline, label: AppStrings.navDailyTodo),
    (path: '/stats', icon: Icons.bar_chart_outlined, label: '통계'),
    (path: '/settings', icon: Icons.settings_outlined, label: AppStrings.navSettings),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _destinations.indexWhere((d) => location.startsWith(d.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final currentIndex = _currentIndex(context);

    if (isDesktop) {
      return GlassScaffold(
        navigationRail: _DarkNavigationRail(
          currentIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_destinations[i].path),
          destinations: _destinations,
        ),
        body: child,
      );
    }

    return GlassScaffold(
      body: child,
      bottomNavigationBar: _DarkBottomBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_destinations[i].path),
        destinations: _destinations,
      ),
    );
  }
}

class _DarkNavigationRail extends StatelessWidget {
  const _DarkNavigationRail({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<({String path, IconData icon, String label})> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(right: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const SsuLogo(size: 44),
          const SizedBox(height: 32),
          ...destinations.asMap().entries.map((e) {
            final isSelected = e.key == currentIndex;
            return _RailItem(
              icon: e.value.icon,
              label: e.value.label,
              isSelected: isSelected,
              onTap: () => onDestinationSelected(e.key),
            );
          }),
          const Spacer(),
          _NewTaskButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.mediumBlue.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: AppColors.mediumBlue.withValues(alpha: 0.4))
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.lightBlue : AppColors.textHint,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkBottomBar extends StatelessWidget {
  const _DarkBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({String path, IconData icon, String label})> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...destinations.asMap().entries.map((e) {
                final isSelected = e.key == currentIndex;
                return InkWell(
                  onTap: () => onTap(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: AppColors.mediumBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          e.value.icon,
                          color: isSelected ? AppColors.lightBlue : AppColors.textHint,
                          size: 22,
                        ),
                        Text(
                          e.value.label,
                          style: TextStyle(
                            color: isSelected ? AppColors.lightBlue : AppColors.textHint,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              _NewTaskButton(small: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTaskButton extends StatelessWidget {
  const _NewTaskButton({this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.navNewTask,
      child: InkWell(
        onTap: () => context.push('/task/new'),
        borderRadius: BorderRadius.circular(small ? 20 : 12),
        child: Container(
          width: small ? 40 : 52,
          height: small ? 40 : 52,
          decoration: BoxDecoration(
            color: AppColors.mediumBlue,
            borderRadius: BorderRadius.circular(small ? 20 : 12),
          ),
          child: Icon(Icons.add, color: Colors.white, size: small ? 20 : 24),
        ),
      ),
    );
  }
}
