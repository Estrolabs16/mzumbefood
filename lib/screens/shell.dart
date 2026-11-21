import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _expanded = false;

  static const _destinations = [
    (
      icon: Icons.history_rounded,
      label: S.history,
      path: '/history',
      center: false,
    ),
    (
      icon: Icons.account_balance_wallet_rounded,
      label: S.debts,
      path: '/debts',
      center: false,
    ),
    (
      icon: Icons.home_filled,
      label: S.home,
      path: '/home',
      center: true,
    ),
    (
      icon: Icons.bar_chart_rounded,
      label: S.analytics,
      path: '/analytics',
      center: false,
    ),
    (
      icon: Icons.person_outline,
      label: S.profile,
      path: '/profile',
      center: false,
    ),
  ];

  int get _index {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _destinations.indexWhere((item) => location.startsWith(item.path));
    return index < 0 ? 2 : index;
  }

  void _navigate(String path) {
    setState(() => _expanded = false);
    context.go(path);
  }

  void _selectTab(int index) {
    setState(() => _expanded = false);
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_expanded) ...[
            _MiniAction(
              label: '🍢 ${S.mishkaki}',
              icon: Icons.kebab_dining,
              top: 196,
              onTap: () => _navigate('/mishkaki'),
            ),
            _MiniAction(
              label: S.addExpense,
              icon: Icons.receipt_long,
              top: 134,
              onTap: () => _navigate('/add-expense'),
            ),
            _MiniAction(
              label: S.addSale,
              icon: Icons.add_shopping_cart,
              top: 72,
              onTap: () => _navigate('/add-sale'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: FloatingActionButton(
              heroTag: 'main-add',
              onPressed: () => setState(() => _expanded = !_expanded),
              child: AnimatedRotation(
                turns: _expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 220),
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _FloatingBottomBar(
        destinations: _destinations,
        currentIndex: _index,
        onTap: _selectTab,
      ),
    );
  }
}

class _FloatingBottomBar extends StatefulWidget {
  final List<({IconData icon, String label, String path, bool center})>
      destinations;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingBottomBar({
    required this.destinations,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_FloatingBottomBar> createState() => _FloatingBottomBarState();
}

class _FloatingBottomBarState extends State<_FloatingBottomBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    if (mounted) _bounce.forward(from: 0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: AnimatedBuilder(
          animation: _bounce,
          builder: (context, child) => Transform.scale(
            scale: 0.94 + (0.06 * _bounce.value),
            child: child,
          ),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(35),
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0x4DFFFFFF), width: 1),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
                BoxShadow(
                  color: Color(0x4DF26B35),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < widget.destinations.length; i++)
                    _BottomBarItem(
                      key: ValueKey(
                        'nav-${widget.destinations[i].label.toLowerCase()}',
                      ),
                      icon: widget.destinations[i].icon,
                      label: widget.destinations[i].label,
                      selected: i == widget.currentIndex,
                      center: widget.destinations[i].center,
                      onTap: () => _handleTap(i),
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

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool center;
  final VoidCallback onTap;

  const _BottomBarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.center,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                padding: EdgeInsets.all(center ? 9 : 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: center ? 28 : 23,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                  fontSize: center ? 10 : 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final double top;
  final VoidCallback onTap;

  const _MiniAction({
    required this.label,
    required this.icon,
    required this.top,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        right: 10,
        top: top,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton.small(
              heroTag: label,
              onPressed: onTap,
              child: Icon(icon),
            ),
          ],
        ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.3, duration: 180.ms),
      );
}
