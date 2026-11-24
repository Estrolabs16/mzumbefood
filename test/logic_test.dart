import 'package:flutter_test/flutter_test.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/models/models.dart';

void main() {
  test('money is formatted as whole Tanzanian shillings', () {
    expect(Fmt.money(12345.6), 'TSh 12,346');
  });

  test('day keys are stable and sortable', () {
    final date = DateTime(2026, 11, 21, 23, 45);
    expect(Fmt.dayKey(date), '2026-11-21');
    expect(Fmt.parseDayKey('2026-11-21'), DateTime(2026, 11, 21));
  });

  test('totals include debt payments as revenue on their received date', () {
    final day = DateTime(2026, 11, 21, 10);
    final sale = Sale.create(
      id: 's1',
      date: day,
      items: const [
        SaleLine(
          menuItemId: 'm1',
          name: 'Chips Mayai',
          qty: 1,
          unitPrice: 2000,
          unitCostAtSale: 700,
          note: '',
        ),
      ],
      note: '',
      paid: true,
    );
    final payment = DebtPayment(
      id: 'p1',
      debtId: 'd1',
      customer: 'Amina',
      amount: 1500,
      date: day,
      dayKey: Fmt.dayKey(day),
      note: '',
    );
    final totals = totalsFor(
      sales: [sale],
      expenses: const [],
      mishkaki: const [],
      payments: [payment],
    );
    expect(totals.revenue, 3500);
    expect(totals.ingredientCost, 700);
    expect(totals.expenses, 0);
    expect(totals.netProfit, 2800);
  });

  test('debts I owe count payments as expenses', () {
    final day = DateTime(2026, 11, 21, 10);
    final payment = DebtPayment(
      id: 'p2',
      debtId: 'd2',
      customer: 'Mama John',
      amount: 3000,
      date: day,
      dayKey: Fmt.dayKey(day),
      note: '',
      direction: DebtDirection.iOweThem,
    );
    final totals = totalsFor(
      sales: const [],
      expenses: const [],
      mishkaki: const [],
      payments: [payment],
    );
    expect(totals.revenue, 0);
    expect(totals.expenses, 3000);
  });

  test('sack stats group revenue, cost and profit by day', () {
    final sack = Sack(
      id: 'k1',
      product: 'Potatoes',
      boughtDate: DateTime(2026, 11, 21),
      dayKey: '2026-11-21',
      cost: 3000,
      finishedDate: DateTime(2026, 11, 23),
      note: '',
    );
    final sales = [
      Sale.create(
        id: 'a',
        date: DateTime(2026, 11, 21, 12),
        items: const [
          SaleLine(
            menuItemId: 'm1',
            name: 'Chips Mayai',
            qty: 1,
            unitPrice: 2000,
            unitCostAtSale: 500,
            note: '',
          ),
        ],
        note: '',
        paid: true,
        sackId: 'k1',
      ),
      Sale.create(
        id: 'b',
        date: DateTime(2026, 11, 23, 15),
        items: const [
          SaleLine(
            menuItemId: 'm1',
            name: 'Chips Mayai',
            qty: 1,
            unitPrice: 1000,
            unitCostAtSale: 300,
            note: '',
          ),
        ],
        note: '',
        paid: true,
        sackId: 'k1',
      ),
    ];
    final stats = buildSackStats(sacks: [sack], sales: sales).single;
    expect(stats.revenue, 3000);
    expect(stats.ingredientCost, 800);
    expect(stats.sackCost, 3000);
    expect(stats.profit, -800);
    expect(stats.days.length, 3);
    expect(stats.days.where((day) => day.revenue > 0).length, 2);
  });
}
