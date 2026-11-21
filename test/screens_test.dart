import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/screens/add_expense.dart';
import 'package:mzumbefood/screens/add_sale.dart';
import 'package:mzumbefood/screens/analytics.dart';
import 'package:mzumbefood/screens/auth/create_account.dart';
import 'package:mzumbefood/screens/auth/forgot_password.dart';
import 'package:mzumbefood/screens/auth/sign_in.dart';
import 'package:mzumbefood/screens/debts.dart';
import 'package:mzumbefood/screens/expense_names.dart';
import 'package:mzumbefood/screens/history.dart';
import 'package:mzumbefood/screens/home.dart';
import 'package:mzumbefood/screens/ingredients.dart';
import 'package:mzumbefood/screens/menu.dart';
import 'package:mzumbefood/screens/mishkaki.dart';
import 'package:mzumbefood/screens/personal_budget.dart';
import 'package:mzumbefood/screens/personal_income.dart';
import 'package:mzumbefood/screens/profile.dart';
import 'package:mzumbefood/screens/sacks.dart';
import 'package:mzumbefood/screens/shell.dart';
import 'package:mzumbefood/screens/splash.dart';
import 'package:mzumbefood/widgets/common.dart';

import 'helpers.dart';

void main() {
  testWidgets('splash shows logo and tagline', (tester) async {
    await pumpScreen(tester, const SplashScreen());
    expect(find.text(S.appName), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('sign in screen renders email and password', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    expect(find.text(S.signIn), findsWidgets);
    expect(find.text(S.email), findsOneWidget);
    expect(find.text(S.password), findsOneWidget);
  });

  testWidgets('create account screen renders', (tester) async {
    await pumpScreen(tester, const CreateAccountScreen());
    expect(find.text(S.createAccount), findsWidgets);
    expect(find.text(S.ownerName), findsOneWidget);
  });

  testWidgets('forgot password screen renders', (tester) async {
    await pumpScreen(tester, const ForgotPasswordScreen());
    expect(find.text(S.resetPassword), findsWidgets);
  });

  testWidgets('home renders empty state', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(EmptyState), findsWidgets);
  });

  testWidgets('home renders today sale', (tester) async {
    await pumpScreen(tester, const HomeScreen(), seed: seedBasics);
    expect(find.textContaining('Chips Mayai'), findsWidgets);
  });

  testWidgets('history renders calendar and records', (tester) async {
    await pumpScreen(tester, const HistoryScreen(), seed: seedBasics);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.textContaining('Chips Mayai'), findsWidgets);
  });

  testWidgets('add sale screen renders menu items', (tester) async {
    await pumpScreen(tester, const AddSaleScreen(), seed: seedBasics);
    expect(find.byType(AddSaleScreen), findsOneWidget);
    expect(find.text(S.addSale), findsWidgets);
  });

  testWidgets('add expense screen renders', (tester) async {
    await pumpScreen(tester, const AddExpenseScreen(), seed: seedBasics);
    expect(find.byType(AddExpenseScreen), findsOneWidget);
    expect(find.text(S.addExpense), findsWidgets);
  });

  testWidgets('menu screen renders foods', (tester) async {
    await pumpScreen(tester, const MenuScreen(), seed: seedBasics);
    expect(find.text('Chips Mayai'), findsWidgets);
  });

  testWidgets('ingredient screen renders costs', (tester) async {
    await pumpScreen(tester, const IngredientsScreen(), seed: seedBasics);
    expect(find.text('Egg tray (30 eggs)'), findsWidgets);
  });

  testWidgets('mishkaki screen renders sticks', (tester) async {
    await pumpScreen(tester, const MishkakiScreen(), seed: seedBasics);
    expect(find.byType(MishkakiScreen), findsOneWidget);
    expect(find.text(S.sticksSold), findsWidgets);
  });

  testWidgets('sacks screen renders sack', (tester) async {
    await pumpScreen(tester, const SacksScreen(), seed: seedBasics);
    expect(find.text('Potatoes'), findsWidgets);
  });

  testWidgets('debts screen renders unpaid customer', (tester) async {
    await pumpScreen(tester, const DebtsScreen(), seed: seedBasics);
    expect(find.text('Amina'), findsWidgets);
    expect(find.text(S.unpaid), findsOneWidget);
  });

  testWidgets('analytics renders charts', (tester) async {
    await pumpScreen(tester, const AnalyticsScreen(), seed: seedBasics);
    expect(find.byType(AnalyticsScreen), findsOneWidget);
    expect(find.text(S.revenue), findsWidgets);
  });

  testWidgets('profile renders owner and email', (tester) async {
    await pumpScreen(tester, const ProfileScreen());
    expect(find.text('owner@example.com'), findsWidgets);
    expect(find.text(S.personalIncome), findsOneWidget);
  });

  testWidgets('personal budget renders today card', (tester) async {
    await pumpScreen(tester, const PersonalBudgetScreen(), seed: seedBasics);
    expect(find.text(S.personalBudget), findsWidgets);
    expect(find.text('Lunch'), findsWidgets);
  });

  testWidgets('personal income renders income', (tester) async {
    await pumpScreen(tester, const PersonalIncomeScreen(), seed: seedBasics);
    expect(find.text(S.personalIncome), findsWidgets);
    expect(find.text('Salary'), findsWidgets);
  });

  testWidgets('expense names renders saved name', (tester) async {
    await pumpScreen(tester, const ExpenseNamesScreen(), seed: seedBasics);
    expect(find.text('Transport'), findsWidgets);
  });

  testWidgets('app shell renders five tabs and quick actions', (tester) async {
    await pumpScreen(
      tester,
      const AppShell(child: SizedBox.shrink()),
    );
    expect(find.text(S.home), findsOneWidget);
    expect(find.text(S.history), findsOneWidget);
    expect(find.text(S.debts), findsOneWidget);
    expect(find.text(S.analytics), findsOneWidget);
    expect(find.text(S.profile), findsOneWidget);

    final homeCenter = tester.getCenter(find.byKey(const Key('nav-home')));
    expect(homeCenter.dx, closeTo(540, 2));
  });
}

void seedBasics(InMemoryRepository repository) {
  final now = DateTime.now();
  final dayKey = Fmt.dayKey(now);

  repository.seed(Collections.ingredients, 'egg-tray', Ingredient(
    id: 'egg-tray',
    name: 'Egg tray (30 eggs)',
    packPrice: 9500,
    packQuantity: 30,
  ).toMap());

  repository.seed(Collections.menuItems, 'chips-mayai', MenuItem(
    id: 'chips-mayai',
    name: 'Chips Mayai',
    category: 'Chips',
    price: 2000,
    otherCost: 400,
    ingredients: const [IngredientLink(ingredientId: 'egg-tray', quantity: 2)],
    active: true,
  ).toMap());

  final sale = Sale.create(
    id: 'sale-1',
    date: now,
    items: const [
      SaleLine(
        menuItemId: 'chips-mayai',
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
  repository.seed(Collections.sales, sale.id, sale.toMap());

  repository.seed(Collections.expenses, 'expense-1', Expense(
    id: 'expense-1',
    date: now,
    dayKey: dayKey,
    name: 'Charcoal',
    amount: 800,
    note: '',
  ).toMap());

  repository.seed(Collections.mishkaki, 'mishkaki-1', MishkakiSale(
    id: 'mishkaki-1',
    date: now,
    dayKey: dayKey,
    type: "Mishkaki ya Ng'ombe",
    sticksSold: 10,
    pricePerStick: 1000,
    costPerStick: 500,
    note: '',
  ).toMap());

  repository.seed(Collections.sacks, 'sack-1', Sack(
    id: 'sack-1',
    product: 'Potatoes',
    boughtDate: now.subtract(const Duration(days: 3)),
    dayKey: Fmt.dayKey(now.subtract(const Duration(days: 3))),
    cost: 25000,
    finishedDate: null,
    note: '',
  ).toMap());

  repository.seed(Collections.debts, 'debt-1', Debt(
    id: 'debt-1',
    customer: 'Amina',
    phone: '',
    reason: 'Chips Mayai',
    amount: 2000,
    createdAt: now,
    dayKey: dayKey,
    deadline: null,
    paid: false,
  ).toMap());

  repository.seed(Collections.expenseNames, 'name-1', ExpenseName(
    id: 'name-1',
    name: 'Transport',
    defaultAmount: 500,
    useCount: 2,
  ).toMap());

  repository.seed(Collections.personalExpenses, 'personal-1', PersonalExpense(
    id: 'personal-1',
    date: now,
    dayKey: dayKey,
    name: 'Lunch',
    amount: 1500,
  ).toMap());

  repository.seed(Collections.personalIncome, 'income-1', PersonalIncome(
    id: 'income-1',
    date: now,
    dayKey: dayKey,
    source: 'Salary',
    amount: 50000,
    note: '',
  ).toMap());
}
