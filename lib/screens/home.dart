import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selected = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _selected = picked);
  }

  void _shiftDate(int days) =>
      setState(() => _selected = _selected.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final daySales = data.sales.where((e) => Fmt.sameDay(e.date, _selected)).toList();
    final dayExpenses =
        data.expenses.where((e) => Fmt.sameDay(e.date, _selected)).toList();
    final dayMishkaki =
        data.mishkakiSales.where((e) => Fmt.sameDay(e.date, _selected)).toList();
    final dayPayments = data.debtPayments
        .where((e) => Fmt.sameDay(e.date, _selected))
        .toList();
    final totals = totalsFor(
      sales: daySales,
      expenses: dayExpenses,
      mishkaki: dayMishkaki,
      payments: dayPayments,
    );
    final now = DateTime.now();
    final week = totalsFor(
      sales: data.sales,
      expenses: data.expenses,
      mishkaki: data.mishkakiSales,
      payments: data.debtPayments,
      from: Fmt.startOfWeek(now),
      to: Fmt.endOfWeek(now),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => data.retry(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 130),
          children: [
            GradientHeader(
              title: S.home,
              subtitle: Fmt.date(_selected),
              showLogo: true,
              actions: [
                IconButton(
                  tooltip: 'Pick another day',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                ),
              ],
              child: Row(
                children: [
                  _DateArrow(icon: Icons.chevron_left, onTap: () => _shiftDate(-1)),
                  Expanded(
                    child: Text(
                      Fmt.sameDay(_selected, DateTime.now())
                          ? S.today
                          : Fmt.date(_selected),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  _DateArrow(icon: Icons.chevron_right, onTap: () => _shiftDate(1)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (data.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: ShimmerList(count: 3),
              )
            else if (data.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: ErrorBanner(message: data.error!, onRetry: data.retry),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    SummaryCard(
                      label: S.revenue,
                      value: totals.revenue,
                      icon: Icons.attach_money,
                      color: AppColors.primaryDark,
                    ),
                    SummaryCard(
                      label: S.expenses,
                      value: totals.expenses,
                      icon: Icons.receipt_long,
                      color: AppColors.accent,
                    ),
                    SummaryCard(
                      label: S.profit,
                      value: totals.netProfit,
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                    SummaryCard(
                      label: S.orders,
                      value: totals.orders.toDouble(),
                      icon: Icons.shopping_bag,
                      color: AppColors.primary,
                    ).animate().fadeIn(delay: 120.ms, duration: 260.ms),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: S.thisWeek),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _WeekValue(Fmt.money(week.revenue), S.revenue,
                              AppColors.primaryDark),
                          _WeekValue(Fmt.money(week.expenses), S.expenses,
                              AppColors.accent),
                          _WeekValue(Fmt.money(week.netProfit), S.profit,
                              AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 160.ms, duration: 260.ms).slideY(
                      begin: 0.05,
                      duration: 260.ms,
                    ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: PressScale(
                  onTap: () => context.push('/mishkaki'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFFFB15C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Text('🍢', style: TextStyle(fontSize: 46)),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mishkaki corner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Beef, chicken and more. Tap to track sticks.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: S.addSale,
                        icon: Icons.add_shopping_cart,
                        onPressed: () => context.push('/add-sale'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/add-expense'),
                        child: const Text(S.addExpense),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionTitle(
                  title: '${S.sales} (${daySales.length})',
                  action: TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text('See all'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: daySales.isEmpty
                    ? SoftCard(
                        child: EmptyState(
                          icon: Icons.restaurant,
                          title: 'No sales yet',
                          message: S.noSales,
                          actionLabel: S.addSale,
                          onAction: () => context.push('/add-sale'),
                        ),
                      )
                    : Column(
                        children: daySales.take(6).map((sale) {
                          final index = daySales.indexOf(sale);
                          return _SaleRow(sale: sale)
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: index * 45))
                              .slideX(begin: 0.05, duration: 240.ms);
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionTitle(title: '${S.expenses} (${dayExpenses.length})'),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: dayExpenses.isEmpty
                    ? SoftCard(
                        child: EmptyState(
                          icon: Icons.receipt_long,
                          title: 'No expenses yet',
                          message: S.noExpenses,
                          actionLabel: S.addExpense,
                          onAction: () => context.push('/add-expense'),
                        ),
                      )
                    : Column(
                        children: dayExpenses.map((expense) {
                          return _ExpenseRow(expense: expense);
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Ingredient cost ${Fmt.money(totals.ingredientCost)} • Net profit ${Fmt.money(totals.netProfit)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DateArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
      );
}

class _WeekValue extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _WeekValue(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      );
}

class _SaleRow extends StatelessWidget {
  final Sale sale;

  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => context.push('/add-sale?id=${sale.id}'),
        child: Row(
          children: [
            Hero(
              tag: 'sale-${sale.id}',
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                alignment: Alignment.center,
                child: const Text('🍽️', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.itemSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${Fmt.date(sale.date)}${sale.note.isEmpty ? '' : ' • ${sale.note}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.money(sale.total),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final confirm = await confirmAction(
                  context,
                  title: S.confirmDelete,
                  message: 'This sale will be removed from your records.',
                );
                if (confirm && context.mounted) {
                  await context.read<DataStore>().deleteSale(sale.id);
                }
              },
            ),
          ],
        ),
      );
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;

  const _ExpenseRow({required this.expense});

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => context.push('/add-expense?id=${expense.id}'),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.receipt_long, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    Fmt.date(expense.date),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.money(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () async {
                final confirm = await confirmAction(
                  context,
                  title: S.confirmDelete,
                  message: 'This expense will be removed from your records.',
                );
                if (confirm && context.mounted) {
                  await context.read<DataStore>().deleteExpense(expense.id);
                }
              },
            ),
          ],
        ),
      );
}
