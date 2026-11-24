import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = S.thisWeek;
  static const periods = [S.thisWeek, S.thisMonth, '6 months', S.bySack];

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final points = _points(data);
    final hasData = points.any((point) =>
        point.totals.revenue > 0 ||
        point.totals.expenses > 0 ||
        point.totals.orders > 0);
    final range = _range(data, points);
    final salesInRange = data.sales
        .where((sale) =>
            Fmt.inRange(sale.date, range.$1, range.$2) ||
            (points.isEmpty && Fmt.inRange(sale.date, range.$1, range.$2)))
        .toList();
    final expensesInRange = data.expenses
        .where((expense) => Fmt.inRange(expense.date, range.$1, range.$2))
        .toList();
    final stats = foodStats(salesInRange);
    final breakdown = expenseBreakdown(expensesInRange);
    final allTotals = points.fold(
      const Totals(),
      (sum, point) => Totals(
        revenue: sum.revenue + point.totals.revenue,
        ingredientCost: sum.ingredientCost + point.totals.ingredientCost,
        expenses: sum.expenses + point.totals.expenses,
        orders: sum.orders + point.totals.orders,
      ),
    );
    final sticks = data.mishkakiSales
        .where((item) => Fmt.inRange(item.date, range.$1, range.$2))
        .fold<double>(0, (sum, item) => sum + item.sticksSold);

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.analytics,
                    subtitle: 'See how your business is doing',
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: periods
                            .map(
                              (period) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(period),
                                  selected: _period == period,
                                  onSelected: (_) =>
                                      setState(() => _period = period),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
                if (!hasData)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.insert_chart,
                      title: 'No numbers yet',
                      message: S.noAnalytics,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  label: S.revenue,
                                  value: allTotals.revenue,
                                  icon: Icons.attach_money,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SummaryCard(
                                  label: S.profit,
                                  value: allTotals.netProfit,
                                  icon: Icons.trending_up,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Revenue vs expenses vs profit'),
                                const SizedBox(height: 8),
                                _Legend(),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 220,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: _maxY(points),
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem:
                                              (group, groupIndex, rod, rodIndex) {
                                            final labels = [
                                              S.revenue,
                                              S.expenses,
                                              S.profit
                                            ];
                                            return BarTooltipItem(
                                              '${labels[rodIndex]}\n${Fmt.money(rod.toY)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 46,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) => Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Text(
                                                points[value.toInt()].label,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.muted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: const FlGridData(show: false),
                                      barGroups: List.generate(points.length, (index) {
                                        final totals = points[index].totals;
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: totals.revenue,
                                              color: AppColors.primaryDark,
                                              width: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            BarChartRodData(
                                              toY: totals.expenses,
                                              color: AppColors.accent,
                                              width: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            BarChartRodData(
                                              toY: totals.netProfit < 0
                                                  ? 0
                                                  : totals.netProfit,
                                              color: AppColors.success,
                                              width: 8,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ).animate().fadeIn(duration: 340.ms),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Orders per day'),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 130,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: List.generate(points.length, (index) {
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: points[index].totals.orders.toDouble(),
                                              color: AppColors.primary,
                                              width: 14,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ],
                                        );
                                      }),
                                      titlesData: const FlTitlesData(show: false),
                                      borderData: FlBorderData(show: false),
                                      gridData: const FlGridData(show: false),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Totals'),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _TotalChip('Orders', Fmt.number(allTotals.orders.toDouble())),
                                    _TotalChip('Mishkaki sticks', Fmt.number(sticks)),
                                    ...stats.take(6).map(
                                          (stat) => _TotalChip(
                                            stat.name,
                                            Fmt.number(stat.units),
                                          ),
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Food demand ranking'),
                                const SizedBox(height: 8),
                                if (stats.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No food sales in this period.'),
                                  )
                                else
                                  ...List.generate(stats.length, (index) {
                                    final stat = stats[index];
                                    final previous = index + 1 < stats.length
                                        ? stats[index + 1]
                                        : null;
                                    final arrow = previous == null
                                        ? '→'
                                        : stat.units > previous.units
                                            ? '↑'
                                            : stat.units < previous.units
                                                ? '↓'
                                                : '→';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${index + 1}. ${stat.emoji}',
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  stat.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                                Text(
                                                  '${Fmt.number(stat.units)} sold • ${Fmt.money(stat.revenue)} • ${Fmt.money(stat.profit)} profit',
                                                  style: const TextStyle(
                                                    color: AppColors.muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            arrow,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(title: 'Expense breakdown'),
                                const SizedBox(height: 12),
                                if (breakdown.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No expenses in this period.'),
                                  )
                                else
                                  ...breakdown.entries.map((entry) {
                                    final max = breakdown.values.first;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(entry.key),
                                              Text(
                                                Fmt.money(entry.value),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          LinearProgressIndicator(
                                            value: max <= 0
                                                ? 0
                                                : (entry.value / max).clamp(0, 1),
                                            minHeight: 8,
                                            color: AppColors.accent,
                                            backgroundColor: AppColors.accentSoft,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  List<({String label, Totals totals})> _points(DataProvider data) {
    final now = DateTime.now();
    final args = (
      sales: data.sales,
      expenses: data.expenses,
      mishkaki: data.mishkakiSales,
      payments: data.debtPayments,
    );
    if (_period == S.thisWeek) {
      return dailyPoints(
        start: Fmt.startOfWeek(now),
        days: 7,
        sales: args.sales,
        expenses: args.expenses,
        mishkaki: args.mishkaki,
        payments: args.payments,
      ).map((point) => (label: point.label, totals: point.totals)).toList();
    }
    if (_period == S.thisMonth) {
      return List.generate(4, (index) {
        final start = DateTime(now.year, now.month, 1 + index * 7);
        final end = DateTime(start.year, start.month, start.day + 7);
        return (
          label: 'W${index + 1}',
          totals: totalsFor(
            sales: args.sales,
            expenses: args.expenses,
            mishkaki: args.mishkaki,
            payments: args.payments,
            from: start,
            to: end,
          ),
        );
      });
    }
    if (_period == '6 months') {
      return List.generate(6, (index) {
        final month = DateTime(now.year, now.month - 5 + index, 1);
        final next = DateTime(month.year, month.month + 1, 1);
        return (
          label: Fmt.shortDate(month).replaceAll(' ', ''),
          totals: totalsFor(
            sales: args.sales,
            expenses: args.expenses,
            mishkaki: args.mishkaki,
            payments: args.payments,
            from: month,
            to: next,
          ),
        );
      });
    }
    final sacks = data.sacks.take(6).toList();
    if (sacks.isEmpty) {
      return [
        (
          label: 'No sacks',
          totals: totalsFor(
            sales: args.sales,
            expenses: args.expenses,
            mishkaki: args.mishkaki,
            payments: args.payments,
          ),
        ),
      ];
    }
    return sacks.map((sack) {
      final end = sack.finishedDate ?? now.add(const Duration(days: 1));
      return (
        label: sack.product.length > 5 ? '${sack.product.substring(0, 5)}.' : sack.product,
        totals: totalsFor(
          sales: args.sales,
          expenses: args.expenses,
          mishkaki: args.mishkaki,
          payments: args.payments,
          from: sack.boughtDate,
          to: end.add(const Duration(days: 1)),
        ),
      );
    }).toList();
  }

  (DateTime, DateTime) _range(
    DataProvider data,
    List<({String label, Totals totals})> points,
  ) {
    final now = DateTime.now();
    if (_period == S.thisWeek) {
      return (Fmt.startOfWeek(now), Fmt.endOfWeek(now));
    }
    if (_period == S.thisMonth) {
      return (Fmt.startOfMonth(now), Fmt.endOfMonth(now));
    }
    if (_period == '6 months') {
      return (
        DateTime(now.year, now.month - 5, 1),
        Fmt.endOfMonth(now)
      );
    }
    if (data.sacks.isEmpty) {
      return (DateTime(2020), now.add(const Duration(days: 1)));
    }
    final first = data.sacks.last.boughtDate;
    final last = data.sacks.first.finishedDate ?? now.add(const Duration(days: 1));
    return (first, last.add(const Duration(days: 1)));
  }

  double _maxY(List<({String label, Totals totals})> points) {
    var max = 1000.0;
    for (final point in points) {
      max = max > point.totals.revenue ? max : point.totals.revenue;
      max = max > point.totals.expenses ? max : point.totals.expenses;
    }
    return max * 1.25;
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: 14,
        children: [
          _LegendItem(AppColors.primaryDark, S.revenue),
          _LegendItem(AppColors.accent, S.expenses),
          _LegendItem(AppColors.success, S.profit),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String value;

  const _TotalChip(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                )),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      );
}
