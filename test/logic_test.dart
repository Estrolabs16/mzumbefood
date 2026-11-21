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
}
