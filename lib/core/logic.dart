import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/models/models.dart';

class Totals {
  final double revenue;
  final double ingredientCost;
  final double expenses;
  final int orders;

  const Totals({
    this.revenue = 0,
    this.ingredientCost = 0,
    this.expenses = 0,
    this.orders = 0,
  });

  double get netProfit => revenue - ingredientCost - expenses;

  Totals copyWith({
    double? revenue,
    double? ingredientCost,
    double? expenses,
    int? orders,
  }) =>
      Totals(
        revenue: revenue ?? this.revenue,
        ingredientCost: ingredientCost ?? this.ingredientCost,
        expenses: expenses ?? this.expenses,
        orders: orders ?? this.orders,
      );
}

bool _matches(DateTime date, DateTime? from, DateTime? to) =>
    (from == null || !date.isBefore(from)) &&
    (to == null || date.isBefore(to));

Totals totalsFor({
  required Iterable<Sale> sales,
  required Iterable<Expense> expenses,
  required Iterable<MishkakiSale> mishkaki,
  required Iterable<DebtPayment> payments,
  DateTime? from,
  DateTime? to,
}) {
  var revenue = 0.0;
  var cost = 0.0;
  var orders = 0;
  for (final sale in sales) {
    if (!_matches(sale.date, from, to)) continue;
    revenue += sale.total;
    cost += sale.cost;
    orders++;
  }
  for (final item in mishkaki) {
    if (!_matches(item.date, from, to)) continue;
    revenue += item.revenue;
    cost += item.cost;
  }
  for (final payment in payments) {
    if (!_matches(payment.date, from, to)) continue;
    revenue += payment.amount;
  }
  var expenseTotal = 0.0;
  for (final expense in expenses) {
    if (!_matches(expense.date, from, to)) continue;
    expenseTotal += expense.amount;
  }
  return Totals(
    revenue: revenue,
    ingredientCost: cost,
    expenses: expenseTotal,
    orders: orders,
  );
}

class DayPoint {
  final DateTime date;
  final Totals totals;

  const DayPoint({required this.date, required this.totals});

  String get label => Fmt.shortDate(date);
}

List<DayPoint> dailyPoints({
  required DateTime start,
  required int days,
  required Iterable<Sale> sales,
  required Iterable<Expense> expenses,
  required Iterable<MishkakiSale> mishkaki,
  required Iterable<DebtPayment> payments,
}) {
  final points = <DayPoint>[];
  for (var i = 0; i < days; i++) {
    final day = DateTime(start.year, start.month, start.day + i);
    final next = DateTime(day.year, day.month, day.day + 1);
    points.add(
      DayPoint(
        date: day,
        totals: totalsFor(
          sales: sales,
          expenses: expenses,
          mishkaki: mishkaki,
          payments: payments,
          from: day,
          to: next,
        ),
      ),
    );
  }
  return points;
}

class FoodStat {
  final String name;
  final String emoji;
  final double units;
  final double revenue;
  final double profit;

  const FoodStat({
    required this.name,
    required this.emoji,
    required this.units,
    required this.revenue,
    required this.profit,
  });
}

List<FoodStat> foodStats(Iterable<Sale> sales) {
  final map = <String, FoodStat>{};
  for (final sale in sales) {
    for (final line in sale.items) {
      final existing = map[line.name];
      map[line.name] = FoodStat(
        name: line.name,
        emoji: _emojiFor(line.name),
        units: (existing?.units ?? 0) + line.qty,
        revenue: (existing?.revenue ?? 0) + line.total,
        profit: (existing?.profit ?? 0) + (line.total - line.cost),
      );
    }
  }
  final stats = map.values.toList()
    ..sort((a, b) => b.units.compareTo(a.units));
  return stats;
}

String _emojiFor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('mishkaki')) return '🍢';
  if (lower.contains('egg') || lower.contains('mayai')) return '🥚';
  if (lower.contains('chips') || lower.contains('kavu')) return '🍟';
  if (lower.contains('rice') || lower.contains('wali')) return '🍚';
  if (lower.contains('drink') || lower.contains('juice')) return '🥤';
  return '🍽️';
}

Map<String, double> expenseBreakdown(Iterable<Expense> expenses) {
  final map = <String, double>{};
  for (final expense in expenses) {
    map[expense.name] = (map[expense.name] ?? 0) + expense.amount;
  }
  final sorted = Map<String, double>.fromEntries(
    map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );
  return sorted;
}

double paidForDebt(String debtId, Iterable<DebtPayment> payments) => payments
    .where((payment) => payment.debtId == debtId)
    .fold(0, (sum, payment) => sum + payment.amount);

double outstandingDebt(
  Iterable<Debt> debts,
  Iterable<DebtPayment> payments,
) =>
    debts.fold(0, (sum, debt) {
      if (debt.paid) return sum;
      final remaining = debt.amount - paidForDebt(debt.id, payments);
      return sum + (remaining > 0 ? remaining : 0);
    });

class PersonalSummary {
  final double income;
  final double spending;
  final double balance;

  const PersonalSummary({
    required this.income,
    required this.spending,
    required this.balance,
  });
}

PersonalSummary personalSummary({
  required Iterable<PersonalIncome> income,
  required Iterable<PersonalExpense> expenses,
  DateTime? from,
  DateTime? to,
}) {
  var incomeTotal = 0.0;
  var spending = 0.0;
  for (final entry in income) {
    if (_matches(entry.date, from, to)) incomeTotal += entry.amount;
  }
  for (final entry in expenses) {
    if (_matches(entry.date, from, to)) spending += entry.amount;
  }
  return PersonalSummary(
    income: incomeTotal,
    spending: spending,
    balance: incomeTotal - spending,
  );
}

double average(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.fold<double>(0, (sum, value) => sum + value) / list.length;
}
