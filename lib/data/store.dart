import 'package:mzumbefood/core/serialization.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/models/models.dart';

abstract final class Collections {
  static const profile = 'profile';
  static const menuItems = 'menuItems';
  static const ingredients = 'ingredients';
  static const sales = 'sales';
  static const expenses = 'expenses';
  static const expenseNames = 'expenseNames';
  static const mishkaki = 'mishkaki';
  static const mishkakiStock = 'mishkakiStock';
  static const sacks = 'sacks';
  static const debts = 'debts';
  static const debtPayments = 'debtPayments';
  static const personalExpenses = 'personalExpenses';
  static const personalIncome = 'personalIncome';
}

class DataStore {
  final DataRepository repository;

  DataStore(this.repository);

  Stream<List<MenuItem>> menuItems() => repository
      .watch(Collections.menuItems)
      .map((rows) => rows
          .map((row) => MenuItem.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  Stream<List<Ingredient>> ingredients() => repository
      .watch(Collections.ingredients)
      .map((rows) => rows
          .map((row) => Ingredient.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  Stream<List<Sale>> sales() => repository.watch(Collections.sales).map(
        (rows) => rows
            .map((row) => Sale.fromMap(asString(row['id']), row))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Stream<List<Expense>> expenses() => repository.watch(Collections.expenses).map(
        (rows) => rows
            .map((row) => Expense.fromMap(asString(row['id']), row))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );

  Stream<List<ExpenseName>> expenseNames() => repository
      .watch(Collections.expenseNames)
      .map((rows) => rows
          .map((row) => ExpenseName.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.useCount.compareTo(a.useCount)));

  Stream<List<MishkakiSale>> mishkakiSales() => repository
      .watch(Collections.mishkaki)
      .map((rows) => rows
          .map((row) => MishkakiSale.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Stream<List<MishkakiStock>> mishkakiStock() => repository
      .watch(Collections.mishkakiStock)
      .map((rows) => rows
          .map((row) => MishkakiStock.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Stream<List<Sack>> sacks() => repository.watch(Collections.sacks).map(
        (rows) => rows
            .map((row) => Sack.fromMap(asString(row['id']), row))
            .toList()
          ..sort((a, b) => b.boughtDate.compareTo(a.boughtDate)),
      );

  Stream<List<Debt>> debts() => repository.watch(Collections.debts).map(
        (rows) => rows
            .map((row) => Debt.fromMap(asString(row['id']), row))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  Stream<List<DebtPayment>> debtPayments() => repository
      .watch(Collections.debtPayments)
      .map((rows) => rows
          .map((row) => DebtPayment.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Stream<List<PersonalExpense>> personalExpenses() => repository
      .watch(Collections.personalExpenses)
      .map((rows) => rows
          .map((row) => PersonalExpense.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Stream<List<PersonalIncome>> personalIncome() => repository
      .watch(Collections.personalIncome)
      .map((rows) => rows
          .map((row) => PersonalIncome.fromMap(asString(row['id']), row))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)));

  Stream<OwnerProfile> profile() => repository.watch(Collections.profile).map(
        (rows) => rows.isEmpty
            ? const OwnerProfile(
                name: '',
                businessName: 'MU Food Business',
                dailyBudget: 0,
              )
            : OwnerProfile.fromMap(rows.first),
      );

  Future<void> saveProfile(OwnerProfile profile) =>
      repository.write(Collections.profile, 'profile', profile.toMap());

  Future<void> saveMenuItem(MenuItem item) =>
      repository.write(Collections.menuItems, item.id, item.toMap());

  Future<void> deleteMenuItem(String id) =>
      repository.delete(Collections.menuItems, id);

  Future<void> saveIngredient(Ingredient ingredient) => repository.write(
        Collections.ingredients,
        ingredient.id,
        ingredient.toMap(),
      );

  Future<void> deleteIngredient(String id) =>
      repository.delete(Collections.ingredients, id);

  Future<void> saveSale(Sale sale, {Debt? debt}) async {
    await repository.write(Collections.sales, sale.id, sale.toMap());
    if (debt != null) {
      await repository.write(Collections.debts, debt.id, debt.toMap());
    }
  }

  Future<void> deleteSale(String id) => repository.delete(Collections.sales, id);

  Future<void> saveExpense(Expense expense) async {
    await repository.write(Collections.expenses, expense.id, expense.toMap());
    final existing = await _firstWhere(
      Collections.expenseNames,
      (row) => asString(row['name']).toLowerCase() == expense.name.toLowerCase(),
    );
    final name = existing == null
        ? ExpenseName(
            id: newId(),
            name: expense.name,
            defaultAmount: expense.amount,
            useCount: 1,
          )
        : ExpenseName(
            id: asString(existing['id']),
            name: expense.name,
            defaultAmount: expense.amount,
            useCount: asInt(existing['useCount']) + 1,
          );
    await repository.write(Collections.expenseNames, name.id, name.toMap());
  }

  Future<void> deleteExpense(String id) =>
      repository.delete(Collections.expenses, id);

  Future<void> saveExpenseName(ExpenseName name) =>
      repository.write(Collections.expenseNames, name.id, name.toMap());

  Future<void> deleteExpenseName(String id) =>
      repository.delete(Collections.expenseNames, id);

  Future<void> saveMishkaki(MishkakiSale item) =>
      repository.write(Collections.mishkaki, item.id, item.toMap());

  Future<void> deleteMishkaki(String id) =>
      repository.delete(Collections.mishkaki, id);

  Future<void> saveMishkakiStock(MishkakiStock item) =>
      repository.write(Collections.mishkakiStock, item.id, item.toMap());

  Future<void> deleteMishkakiStock(String id) =>
      repository.delete(Collections.mishkakiStock, id);

  Future<void> saveSack(Sack sack) =>
      repository.write(Collections.sacks, sack.id, sack.toMap());

  Future<void> deleteSack(String id) => repository.delete(Collections.sacks, id);

  Future<void> saveDebt(Debt debt) =>
      repository.write(Collections.debts, debt.id, debt.toMap());

  Future<void> recordDebtPayment(Debt debt, DebtPayment payment) async {
    await repository.write(Collections.debtPayments, payment.id, payment.toMap());
    final payments = await repository.watch(Collections.debtPayments).first;
    final total = payments
        .where((row) => asString(row['debtId']) == debt.id)
        .fold<double>(0, (sum, row) => sum + asNum(row['amount']));
    final paid = total >= debt.amount - 0.01;
    await repository.write(
      Collections.debts,
      debt.id,
      debt.copyWith(paid: paid).toMap(),
    );
  }

  Future<void> deleteDebt(String id) => repository.delete(Collections.debts, id);

  Future<void> savePersonalExpense(PersonalExpense expense) => repository.write(
        Collections.personalExpenses,
        expense.id,
        expense.toMap(),
      );

  Future<void> deletePersonalExpense(String id) =>
      repository.delete(Collections.personalExpenses, id);

  Future<void> savePersonalIncome(PersonalIncome income) => repository.write(
        Collections.personalIncome,
        income.id,
        income.toMap(),
      );

  Future<void> deletePersonalIncome(String id) =>
      repository.delete(Collections.personalIncome, id);

  Future<void> seedSampleMenu() async {
    final ingredients = <Ingredient>[
      Ingredient(
        id: 'egg-tray',
        name: 'Egg tray (30 eggs)',
        packPrice: 9500,
        packQuantity: 30,
      ),
    ];
    final items = <MenuItem>[
      MenuItem(
        id: 'chips-mayai',
        name: 'Chips Mayai',
        category: 'Chips',
        price: 2000,
        otherCost: 400,
        ingredients: const [IngredientLink(ingredientId: 'egg-tray', quantity: 2)],
        active: true,
      ),
      MenuItem(
        id: 'egg-single',
        name: 'Egg (single)',
        category: 'Eggs',
        price: 500,
        otherCost: 0,
        ingredients: const [IngredientLink(ingredientId: 'egg-tray', quantity: 1)],
        active: true,
      ),
      MenuItem(
        id: 'chips-kavu',
        name: 'Chips Kavu',
        category: 'Chips',
        price: 1500,
        otherCost: 500,
        ingredients: const [],
        active: true,
      ),
      MenuItem(
        id: 'rice-plate',
        name: 'Rice Plate',
        category: 'Rice',
        price: 2500,
        otherCost: 900,
        ingredients: const [],
        active: true,
      ),
      MenuItem(
        id: 'mishkaki-beef',
        name: 'Mishkaki ya Ng\'ombe',
        category: 'Mishkaki',
        price: 1000,
        otherCost: 500,
        ingredients: const [],
        active: true,
      ),
      MenuItem(
        id: 'mishkaki-chicken',
        name: 'Mishkaki ya Kuku',
        category: 'Mishkaki',
        price: 1200,
        otherCost: 650,
        ingredients: const [],
        active: true,
      ),
    ];
    for (final ingredient in ingredients) {
      await saveIngredient(ingredient);
    }
    for (final item in items) {
      await saveMenuItem(item);
    }
  }

  Future<Map<String, dynamic>?> _firstWhere(
    String collection,
    bool Function(Map<String, dynamic> row) predicate,
  ) async {
    final rows = await repository.watch(collection).first;
    for (final row in rows) {
      if (predicate(row)) return row;
    }
    return null;
  }

  String buildCsv({
    required List<Sale> sales,
    required List<Expense> expenses,
    required List<Debt> debts,
  }) {
    final buffer = StringBuffer()
      ..writeln('type,date,dayKey,name,amount,note');
    for (final sale in sales) {
      buffer.writeln(
        'sale,${sale.date.toIso8601String()},${sale.dayKey},${_escape(sale.itemSummary)},${sale.total},${_escape(sale.note)}',
      );
    }
    for (final expense in expenses) {
      buffer.writeln(
        'expense,${expense.date.toIso8601String()},${expense.dayKey},${_escape(expense.name)},${expense.amount},${_escape(expense.note)}',
      );
    }
    for (final debt in debts) {
      buffer.writeln(
        'debt,${debt.createdAt.toIso8601String()},${debt.dayKey},${_escape(debt.customer)},${debt.amount},${_escape(debt.reason)}',
      );
    }
    return buffer.toString();
  }

  String _escape(String value) => '"${value.replaceAll('"', '""')}"';
}
