import 'package:flutter/material.dart';
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
    (icon: Icons.home_rounded, label: S.home, path: '/home'),
    (icon: Icons.history_rounded, label: S.history, path: '/history'),
    (icon: Icons.account_balance_wallet_outlined, label: S.debts, path: '/debts'),
    (icon: Icons.bar_chart_rounded, label: S.analytics, path: '/analytics'),
    (icon: Icons.person_outline, label: S.profile, path: '/profile'),
  ];

  int get _index {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _destinations.indexWhere((item) => location.startsWith(item.path));
    return index < 0 ? 0 : index;
  }

  void _navigate(String path) {
    setState(() => _expanded = false);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final index = _index;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: widget.child,
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_expanded) ...[
            _MiniAction(
              label: '🍢 ${S.mishkaki}',
              icon: Icons.kebab_dining,
              top: 204,
              onTap: () => _navigate('/mishkaki'),
            ),
            _MiniAction(
              label: S.addExpense,
              icon: Icons.receipt_long,
              top: 142,
              onTap: () => _navigate('/add-expense'),
            ),
            _MiniAction(
              label: S.addSale,
              icon: Icons.add_shopping_cart,
              top: 80,
              onTap: () => _navigate('/add-sale'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 84),
            child: FloatingActionButton(
              heroTag: 'main-add',
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 6,
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
      bottomNavigationBar: SizedBox(
        height: 78,
        child: Stack(
          children: [
            BottomNavigationBar(
              currentIndex: index,
              onTap: (value) => _navigate(_destinations[value].path),
              items: _destinations
                  .map(
                    (item) => BottomNavigationBarItem(
                      icon: Icon(item.icon, size: 24),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
            Positioned(
              bottom: 0,
              left: (width / 5) * index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                width: width / 5,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              onPressed: onTap,
              child: Icon(icon),
            ),
          ],
        ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.3, duration: 180.ms),
      );
}
