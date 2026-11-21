import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/data/auth.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService auth;
  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  AuthProvider(this.auth) {
    _subscription = auth.authState.listen(
      (user) {
        _user = user;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        _loading = false;
        _error = S.genericError;
        notifyListeners();
      },
    );
  }

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _loading;
  bool get isBusy => _busy;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _start();
    final result = await auth.signIn(email, password);
    return _finish(result);
  }

  Future<bool> signUp(
    String email,
    String password,
    String ownerName,
    String businessName,
  ) async {
    _start();
    final result = await auth.signUp(email, password, ownerName, businessName);
    return _finish(result);
  }

  Future<bool> sendPasswordReset(String email) async {
    _start();
    final result = await auth.sendPasswordReset(email);
    return _finish(result);
  }

  Future<bool> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    _start();
    final result =
        await auth.changePassword(email, currentPassword, newPassword);
    return _finish(result);
  }

  Future<void> signOut() => auth.signOut();

  void _start() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  bool _finish(AuthResult result) {
    _busy = false;
    if (!result.ok) {
      _error = result.message ?? S.genericError;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class DataProvider extends ChangeNotifier {
  final DataStore store;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> _loaded = {};
  final Map<String, String> _errors = {};

  List<MenuItem> menuItems = [];
  List<Ingredient> ingredients = [];
  List<Sale> sales = [];
  List<Expense> expenses = [];
  List<ExpenseName> expenseNames = [];
  List<MishkakiSale> mishkakiSales = [];
  List<MishkakiStock> mishkakiStock = [];
  List<Sack> sacks = [];
  List<Debt> debts = [];
  List<DebtPayment> debtPayments = [];
  List<PersonalExpense> personalExpenses = [];
  List<PersonalIncome> personalIncome = [];
  OwnerProfile profile = const OwnerProfile(
    name: '',
    businessName: 'MU Food Business',
    dailyBudget: 0,
  );

  DataProvider(this.store) {
    _subscribe();
  }

  bool get isLoading => _loaded.length < 13;

  String? get error => _errors.isEmpty ? null : _errors.values.first;

  void _watch<T>(
    String key,
    Stream<T> stream,
    void Function(T value) assign,
  ) {
    _subscriptions.add(
      stream.listen(
        (value) {
          assign(value);
          _loaded.add(key);
          _errors.remove(key);
          notifyListeners();
        },
        onError: (Object error) {
          _errors[key] = error.toString();
          _loaded.add(key);
          notifyListeners();
        },
      ),
    );
  }

  void _subscribe() {
    _watch('menu', store.menuItems(), (value) => menuItems = value);
    _watch('ingredients', store.ingredients(), (value) => ingredients = value);
    _watch('sales', store.sales(), (value) => sales = value);
    _watch('expenses', store.expenses(), (value) => expenses = value);
    _watch('expenseNames', store.expenseNames(), (value) => expenseNames = value);
    _watch('mishkaki', store.mishkakiSales(), (value) => mishkakiSales = value);
    _watch('mishkakiStock', store.mishkakiStock(), (value) => mishkakiStock = value);
    _watch('sacks', store.sacks(), (value) => sacks = value);
    _watch('debts', store.debts(), (value) => debts = value);
    _watch('debtPayments', store.debtPayments(), (value) => debtPayments = value);
    _watch('personalExpenses', store.personalExpenses(),
        (value) => personalExpenses = value);
    _watch('personalIncome', store.personalIncome(),
        (value) => personalIncome = value);
    _watch('profile', store.profile(), (value) => profile = value);
  }

  void retry() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _loaded.clear();
    _errors.clear();
    _subscribe();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
