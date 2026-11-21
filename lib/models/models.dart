import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/serialization.dart';

class Ingredient {
  final String id;
  final String name;
  final double packPrice;
  final double packQuantity;

  const Ingredient({
    required this.id,
    required this.name,
    required this.packPrice,
    required this.packQuantity,
  });

  double get costPerUnit =>
      packQuantity <= 0 ? 0 : packPrice / packQuantity;

  Map<String, dynamic> toMap() => {
        'name': name,
        'packPrice': packPrice,
        'packQuantity': packQuantity,
        'costPerUnit': costPerUnit,
      };

  factory Ingredient.fromMap(String id, Map<String, dynamic> map) => Ingredient(
        id: id,
        name: asString(map['name']),
        packPrice: asNum(map['packPrice']),
        packQuantity: asNum(map['packQuantity'], 1),
      );

  Ingredient copyWith({
    String? name,
    double? packPrice,
    double? packQuantity,
  }) =>
      Ingredient(
        id: id,
        name: name ?? this.name,
        packPrice: packPrice ?? this.packPrice,
        packQuantity: packQuantity ?? this.packQuantity,
      );
}

class IngredientLink {
  final String ingredientId;
  final double quantity;

  const IngredientLink({required this.ingredientId, required this.quantity});

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'quantity': quantity,
      };

  factory IngredientLink.fromMap(Map<String, dynamic> map) => IngredientLink(
        ingredientId: asString(map['ingredientId']),
        quantity: asNum(map['quantity']),
      );
}

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final double otherCost;
  final List<IngredientLink> ingredients;
  final bool active;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.otherCost,
    required this.ingredients,
    required this.active,
  });

  String get emoji => switch (category) {
        'Chips' => '🍟',
        'Eggs' => '🥚',
        'Rice' => '🍚',
        'Mishkaki' => '🍢',
        'Drinks' => '🥤',
        _ => '🍽️',
      };

  double unitCost(List<Ingredient> allIngredients) {
    var cost = otherCost;
    for (final link in ingredients) {
      final ingredient = allIngredients
          .where((element) => element.id == link.ingredientId)
          .firstOrNull;
      if (ingredient != null) cost += ingredient.costPerUnit * link.quantity;
    }
    return cost;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'price': price,
        'otherCost': otherCost,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'active': active,
      };

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) => MenuItem(
        id: id,
        name: asString(map['name']),
        category: asString(map['category'], 'Other'),
        price: asNum(map['price']),
        otherCost: asNum(map['otherCost']),
        ingredients: asList<IngredientLink>(
          map['ingredients'],
          (item) => item is Map
              ? IngredientLink.fromMap(Map<String, dynamic>.from(item))
              : null,
        ),
        active: asBool(map['active'], true),
      );
}

class SaleLine {
  final String menuItemId;
  final String name;
  final double qty;
  final double unitPrice;
  final double unitCostAtSale;
  final String note;

  const SaleLine({
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.unitCostAtSale,
    required this.note,
  });

  double get total => unitPrice * qty;
  double get cost => unitCostAtSale * qty;

  Map<String, dynamic> toMap() => {
        'menuItemId': menuItemId,
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
        'unitCostAtSale': unitCostAtSale,
        'note': note,
      };

  factory SaleLine.fromMap(Map<String, dynamic> map) => SaleLine(
        menuItemId: asString(map['menuItemId']),
        name: asString(map['name']),
        qty: asNum(map['qty'], 1),
        unitPrice: asNum(map['unitPrice']),
        unitCostAtSale: asNum(map['unitCostAtSale']),
        note: asString(map['note']),
      );
}

class Sale {
  final String id;
  final DateTime date;
  final String dayKey;
  final List<SaleLine> items;
  final double total;
  final double cost;
  final String note;
  final bool paid;
  final DateTime createdAt;

  const Sale({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.items,
    required this.total,
    required this.cost,
    required this.note,
    required this.paid,
    required this.createdAt,
  });

  factory Sale.create({
    required String id,
    required DateTime date,
    required List<SaleLine> items,
    required String note,
    required bool paid,
  }) =>
      Sale(
        id: id,
        date: date,
        dayKey: Fmt.dayKey(date),
        items: items,
        total: items.fold(0, (sum, item) => sum + item.total),
        cost: items.fold(0, (sum, item) => sum + item.cost),
        note: note,
        paid: paid,
        createdAt: DateTime.now(),
      );

  String get itemSummary => items
      .map((item) => '${Fmt.number(item.qty)}x ${item.name}')
      .join(', ');

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'cost': cost,
        'note': note,
        'paid': paid,
        'createdAt': createdAt,
      };

  factory Sale.fromMap(String id, Map<String, dynamic> map) {
    final items = asList<SaleLine>(
      map['items'],
      (item) => item is Map
          ? SaleLine.fromMap(Map<String, dynamic>.from(item))
          : null,
    );
    final date = asDate(map['date']);
    return Sale(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      items: items,
      total: asNum(map['total'], items.fold(0, (s, e) => s + e.total)),
      cost: asNum(map['cost'], items.fold(0, (s, e) => s + e.cost)),
      note: asString(map['note']),
      paid: asBool(map['paid'], true),
      createdAt: asDate(map['createdAt'], date),
    );
  }
}

class Expense {
  final String id;
  final DateTime date;
  final String dayKey;
  final String name;
  final double amount;
  final String note;

  const Expense({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.name,
    required this.amount,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'name': name,
        'amount': amount,
        'note': note,
      };

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return Expense(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      name: asString(map['name']),
      amount: asNum(map['amount']),
      note: asString(map['note']),
    );
  }
}

class ExpenseName {
  final String id;
  final String name;
  final double defaultAmount;
  final int useCount;

  const ExpenseName({
    required this.id,
    required this.name,
    required this.defaultAmount,
    required this.useCount,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'defaultAmount': defaultAmount,
        'useCount': useCount,
      };

  factory ExpenseName.fromMap(String id, Map<String, dynamic> map) =>
      ExpenseName(
        id: id,
        name: asString(map['name']),
        defaultAmount: asNum(map['defaultAmount']),
        useCount: asInt(map['useCount']),
      );
}

class MishkakiSale {
  final String id;
  final DateTime date;
  final String dayKey;
  final String type;
  final double sticksSold;
  final double pricePerStick;
  final double costPerStick;
  final String note;

  const MishkakiSale({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.type,
    required this.sticksSold,
    required this.pricePerStick,
    required this.costPerStick,
    required this.note,
  });

  double get revenue => sticksSold * pricePerStick;
  double get cost => sticksSold * costPerStick;
  double get profit => revenue - cost;

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'type': type,
        'sticksSold': sticksSold,
        'pricePerStick': pricePerStick,
        'costPerStick': costPerStick,
        'note': note,
      };

  factory MishkakiSale.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return MishkakiSale(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      type: asString(map['type'], 'Mishkaki ya Ng\'ombe'),
      sticksSold: asNum(map['sticksSold']),
      pricePerStick: asNum(map['pricePerStick']),
      costPerStick: asNum(map['costPerStick']),
      note: asString(map['note']),
    );
  }
}

class MishkakiStock {
  final String id;
  final DateTime date;
  final String dayKey;
  final String type;
  final double quantity;
  final String unit;
  final double cost;
  final String note;

  const MishkakiStock({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'type': type,
        'quantity': quantity,
        'unit': unit,
        'cost': cost,
        'note': note,
      };

  factory MishkakiStock.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return MishkakiStock(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      type: asString(map['type'], 'Mishkaki ya Ng\'ombe'),
      quantity: asNum(map['quantity']),
      unit: asString(map['unit'], 'sticks'),
      cost: asNum(map['cost']),
      note: asString(map['note']),
    );
  }
}

class Sack {
  final String id;
  final String product;
  final DateTime boughtDate;
  final String dayKey;
  final double cost;
  final DateTime? finishedDate;
  final String note;

  const Sack({
    required this.id,
    required this.product,
    required this.boughtDate,
    required this.dayKey,
    required this.cost,
    required this.finishedDate,
    required this.note,
  });

  int get daysLasted {
    final end = finishedDate ?? DateTime.now();
    final days = end.difference(boughtDate).inDays + 1;
    return days < 1 ? 1 : days;
  }

  double get costPerDay => cost / daysLasted;

  Sack copyWith({DateTime? finishedDate}) => Sack(
        id: id,
        product: product,
        boughtDate: boughtDate,
        dayKey: dayKey,
        cost: cost,
        finishedDate: finishedDate ?? this.finishedDate,
        note: note,
      );

  Map<String, dynamic> toMap() => {
        'product': product,
        'boughtDate': boughtDate,
        'dayKey': dayKey,
        'cost': cost,
        'finishedDate': finishedDate,
        'note': note,
      };

  factory Sack.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['boughtDate']);
    return Sack(
      id: id,
      product: asString(map['product'], 'Potatoes'),
      boughtDate: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      cost: asNum(map['cost']),
      finishedDate: asOptionalDate(map['finishedDate']),
      note: asString(map['note']),
    );
  }
}

class DebtPayment {
  final String id;
  final String debtId;
  final String customer;
  final double amount;
  final DateTime date;
  final String dayKey;
  final String note;

  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.customer,
    required this.amount,
    required this.date,
    required this.dayKey,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'debtId': debtId,
        'customer': customer,
        'amount': amount,
        'date': date,
        'dayKey': dayKey,
        'note': note,
      };

  factory DebtPayment.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return DebtPayment(
      id: id,
      debtId: asString(map['debtId']),
      customer: asString(map['customer']),
      amount: asNum(map['amount']),
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      note: asString(map['note']),
    );
  }
}

class Debt {
  final String id;
  final String customer;
  final String phone;
  final String reason;
  final double amount;
  final DateTime createdAt;
  final String dayKey;
  final DateTime? deadline;
  final bool paid;

  const Debt({
    required this.id,
    required this.customer,
    required this.phone,
    required this.reason,
    required this.amount,
    required this.createdAt,
    required this.dayKey,
    required this.deadline,
    required this.paid,
  });

  bool isOverdue(DateTime now, double paidAmount) =>
      !paid &&
      paidAmount < amount &&
      deadline != null &&
      deadline!.isBefore(now);

  Debt copyWith({bool? paid}) => Debt(
        id: id,
        customer: customer,
        phone: phone,
        reason: reason,
        amount: amount,
        createdAt: createdAt,
        dayKey: dayKey,
        deadline: deadline,
        paid: paid ?? this.paid,
      );

  Map<String, dynamic> toMap() => {
        'customer': customer,
        'phone': phone,
        'reason': reason,
        'amount': amount,
        'createdAt': createdAt,
        'dayKey': dayKey,
        'deadline': deadline,
        'paid': paid,
      };

  factory Debt.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['createdAt']);
    return Debt(
      id: id,
      customer: asString(map['customer']),
      phone: asString(map['phone']),
      reason: asString(map['reason']),
      amount: asNum(map['amount']),
      createdAt: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      deadline: asOptionalDate(map['deadline']),
      paid: asBool(map['paid']),
    );
  }
}

class PersonalExpense {
  final String id;
  final DateTime date;
  final String dayKey;
  final String name;
  final double amount;

  const PersonalExpense({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'name': name,
        'amount': amount,
      };

  factory PersonalExpense.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return PersonalExpense(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      name: asString(map['name']),
      amount: asNum(map['amount']),
    );
  }
}

class PersonalIncome {
  final String id;
  final DateTime date;
  final String dayKey;
  final String source;
  final double amount;
  final String note;

  const PersonalIncome({
    required this.id,
    required this.date,
    required this.dayKey,
    required this.source,
    required this.amount,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'dayKey': dayKey,
        'source': source,
        'amount': amount,
        'note': note,
      };

  factory PersonalIncome.fromMap(String id, Map<String, dynamic> map) {
    final date = asDate(map['date']);
    return PersonalIncome(
      id: id,
      date: date,
      dayKey: asString(map['dayKey'], Fmt.dayKey(date)),
      source: asString(map['source']),
      amount: asNum(map['amount']),
      note: asString(map['note']),
    );
  }
}

class OwnerProfile {
  final String name;
  final String businessName;
  final double dailyBudget;

  const OwnerProfile({
    required this.name,
    required this.businessName,
    required this.dailyBudget,
  });

  OwnerProfile copyWith({
    String? name,
    String? businessName,
    double? dailyBudget,
  }) =>
      OwnerProfile(
        name: name ?? this.name,
        businessName: businessName ?? this.businessName,
        dailyBudget: dailyBudget ?? this.dailyBudget,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'businessName': businessName,
        'dailyBudget': dailyBudget,
      };

  factory OwnerProfile.fromMap(Map<String, dynamic> map) => OwnerProfile(
        name: asString(map['name']),
        businessName: asString(map['businessName']),
        dailyBudget: asNum(map['dailyBudget']),
      );
}
