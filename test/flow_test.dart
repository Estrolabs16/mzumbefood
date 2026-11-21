import 'package:flutter_test/flutter_test.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';

void main() {
  test('unpaid sale creates debt and payment marks it paid on received date', () async {
    final store = DataStore(InMemoryRepository());
    final day = DateTime(2026, 11, 21, 10);
    final sale = Sale.create(
      id: 'sale-1',
      date: day,
      items: const [
        SaleLine(
          menuItemId: 'chips',
          name: 'Chips Mayai',
          qty: 1,
          unitPrice: 2000,
          unitCostAtSale: 700,
          note: '',
        ),
      ],
      note: '',
      paid: false,
    );
    final debt = Debt(
      id: 'debt-1',
      customer: 'Amina',
      phone: '',
      reason: 'Chips Mayai',
      amount: 2000,
      createdAt: day,
      dayKey: Fmt.dayKey(day),
      deadline: null,
      paid: false,
    );

    await store.saveSale(sale, debt: debt);

    final debts = await store.debts().first;
    expect(debts, hasLength(1));
    expect(debts.first.paid, isFalse);
    expect(outstandingDebt(debts, const []), 2000);

    final received = day.add(const Duration(days: 2));
    await store.recordDebtPayment(
      debt,
      DebtPayment(
        id: 'payment-1',
        debtId: debt.id,
        customer: debt.customer,
        amount: 2000,
        date: received,
        dayKey: Fmt.dayKey(received),
        note: '',
      ),
    );

    final updatedDebts = await store.debts().first;
    final payments = await store.debtPayments().first;
    expect(updatedDebts.first.paid, isTrue);
    expect(payments, hasLength(1));

    final totalsOnReceivedDay = totalsFor(
      sales: await store.sales().first,
      expenses: await store.expenses().first,
      mishkaki: await store.mishkakiSales().first,
      payments: payments,
      from: Fmt.startOfDay(received),
      to: Fmt.startOfDay(received.add(const Duration(days: 1))),
    );
    expect(totalsOnReceivedDay.revenue, 2000);
    expect(totalsOnReceivedDay.orders, 0);
  });

  test('sample menu seeds ingredients and computes unit cost', () async {
    final store = DataStore(InMemoryRepository());
    await store.seedSampleMenu();

    final ingredients = await store.ingredients().first;
    final items = await store.menuItems().first;
    expect(ingredients, hasLength(1));
    expect(items, hasLength(6));

    final eggs = ingredients.first;
    final chipsMayai = items.firstWhere((item) => item.name == 'Chips Mayai');
    expect(eggs.costPerUnit, closeTo(316.67, 0.01));
    expect(
      chipsMayai.unitCost(ingredients),
      closeTo(400 + (2 * 9500 / 30), 0.01),
    );
  });

  test('personal money never mixes with business totals', () async {
    final store = DataStore(InMemoryRepository());
    final day = DateTime(2026, 11, 21, 10);
    await store.savePersonalIncome(PersonalIncome(
      id: 'income-1',
      date: day,
      dayKey: Fmt.dayKey(day),
      source: 'Salary',
      amount: 50000,
      note: '',
    ));
    await store.savePersonalExpense(PersonalExpense(
      id: 'expense-1',
      date: day,
      dayKey: Fmt.dayKey(day),
      name: 'Lunch',
      amount: 1500,
    ));

    final personal = personalSummary(
      income: await store.personalIncome().first,
      expenses: await store.personalExpenses().first,
    );
    final business = totalsFor(
      sales: await store.sales().first,
      expenses: await store.expenses().first,
      mishkaki: await store.mishkakiSales().first,
      payments: await store.debtPayments().first,
    );

    expect(personal.income, 50000);
    expect(personal.spending, 1500);
    expect(personal.balance, 48500);
    expect(business.revenue, 0);
    expect(business.expenses, 0);
  });

  test('expense name is saved with an increasing use count', () async {
    final store = DataStore(InMemoryRepository());
    final day = DateTime(2026, 11, 21, 10);
    await store.saveExpense(Expense(
      id: 'expense-1',
      date: day,
      dayKey: Fmt.dayKey(day),
      name: 'Transport',
      amount: 500,
      note: '',
    ));
    await store.saveExpense(Expense(
      id: 'expense-2',
      date: day,
      dayKey: Fmt.dayKey(day),
      name: 'Transport',
      amount: 700,
      note: '',
    ));

    final names = await store.expenseNames().first;
    expect(names, hasLength(1));
    expect(names.first.name, 'Transport');
    expect(names.first.useCount, 2);
    expect(names.first.defaultAmount, 700);
  });
}
