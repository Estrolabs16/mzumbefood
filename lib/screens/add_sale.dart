import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class AddSaleScreen extends StatefulWidget {
  final String? saleId;
  final String? initialDate;

  const AddSaleScreen({super.key, this.saleId, this.initialDate});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _LineEditor {
  String menuItemId;
  final TextEditingController qty;
  final TextEditingController price;
  final TextEditingController note;

  _LineEditor({
    this.menuItemId = '',
    String quantity = '1',
    String priceText = '',
    String noteText = '',
  })  : qty = TextEditingController(text: quantity),
        price = TextEditingController(text: priceText),
        note = TextEditingController(text: noteText);

  void dispose() {
    qty.dispose();
    price.dispose();
    note.dispose();
  }
}

MenuItem? _findItem(List<MenuItem> items, String id) {
  for (final item in items) {
    if (item.id == id) return item;
  }
  return null;
}

double _linePrice(MenuItem? item, _LineEditor line) {
  final override = double.tryParse(line.price.text.trim());
  if (override != null && override > 0) return override;
  return item?.price ?? 0;
}

double _lineQty(_LineEditor line) =>
    double.tryParse(line.qty.text.trim()) ?? 0;

class _OrderDraft {
  final String? existingId;
  final DateTime? createdAt;
  final TextEditingController note;
  final TextEditingController customer;
  final TextEditingController phone;
  final List<_LineEditor> lines;
  DateTime date;
  DateTime? deadline;
  bool unpaid;
  String? sackId;

  _OrderDraft({
    this.existingId,
    this.createdAt,
    required this.date,
    List<_LineEditor>? lines,
    String noteText = '',
    String customerText = '',
    String phoneText = '',
    this.unpaid = false,
    this.sackId,
  })  : note = TextEditingController(text: noteText),
        customer = TextEditingController(text: customerText),
        phone = TextEditingController(text: phoneText),
        lines = lines ?? [_LineEditor()];

  double total(List<MenuItem> menu) => lines.fold(
        0,
        (sum, line) =>
            sum + _linePrice(_findItem(menu, line.menuItemId), line) * _lineQty(line),
      );

  void dispose() {
    note.dispose();
    customer.dispose();
    phone.dispose();
    for (final line in lines) {
      line.dispose();
    }
  }
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<_OrderDraft> _orders;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    var initial = DateTime.now();
    if (widget.initialDate != null) {
      initial = Fmt.parseDayKey(widget.initialDate!);
    }
    final data = context.read<DataProvider>();
    _orders = [_OrderDraft(date: initial)];
    if (widget.saleId != null) {
      final existing = data.sales
          .where((element) => element.id == widget.saleId)
          .firstOrNull;
      if (existing != null) {
        _orders = [
          _OrderDraft(
            existingId: existing.id,
            createdAt: existing.createdAt,
            date: existing.date,
            noteText: existing.note,
            unpaid: !existing.paid,
            sackId: existing.sackId,
            lines: existing.items
                .map(
                  (line) => _LineEditor(
                    menuItemId: line.menuItemId,
                    quantity: Fmt.number(line.qty),
                    priceText: line.unitPrice.toStringAsFixed(0),
                    noteText: line.note,
                  ),
                )
                .toList(),
          ),
        ];
      }
    }
  }

  @override
  void dispose() {
    for (final order in _orders) {
      order.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orders[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _orders[index].date = picked);
  }

  Future<void> _pickDeadline(int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orders[index].deadline ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2036),
    );
    if (picked != null) setState(() => _orders[index].deadline = picked);
  }

  Future<void> _save(List<MenuItem> menu, List<Ingredient> ingredients) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final store = context.read<DataStore>();
      var savedCount = 0;
      var reuseExistingId = true;
      for (final order in _orders) {
        final sackId = order.sackId == null || order.sackId!.isEmpty
            ? null
            : order.sackId;
        for (final line in order.lines) {
          final item = _findItem(menu, line.menuItemId);
          if (item == null) continue;
          final saleLine = SaleLine(
            menuItemId: item.id,
            name: item.name,
            qty: _lineQty(line),
            unitPrice: _linePrice(item, line),
            unitCostAtSale: item.unitCost(ingredients),
            note: line.note.text.trim(),
          );
          final isEdited = order.existingId != null && reuseExistingId;
          if (isEdited) reuseExistingId = false;
          final sale = Sale(
            id: isEdited ? order.existingId! : newId(),
            date: order.date,
            dayKey: Fmt.dayKey(order.date),
            items: [saleLine],
            total: saleLine.total,
            cost: saleLine.cost,
            note: order.note.text.trim(),
            paid: !order.unpaid,
            createdAt: isEdited
                ? order.createdAt ?? DateTime.now()
                : DateTime.now(),
            updatedAt: isEdited ? DateTime.now() : null,
            sackId: sackId,
          );
          Debt? debt;
          if (order.unpaid) {
            debt = Debt(
              id: newId(),
              customer: order.customer.text.trim(),
              phone: order.phone.text.trim(),
              reason: sale.itemSummary,
              amount: sale.total,
              createdAt: DateTime.now(),
              dayKey: Fmt.dayKey(DateTime.now()),
              deadline: order.deadline,
              paid: false,
            );
          }
          await store.saveSale(sale, debt: debt);
          savedCount++;
        }
      }
      if (mounted) {
        showSuccess(
          context,
          savedCount == 1 ? S.saved : 'Saved $savedCount orders',
        );
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final menu = data.menuItems.where((item) => item.active).toList();
    final grandTotal = _orders.fold(
      0.0,
      (sum, order) => sum + order.total(menu),
    );
    final orderCount = _orders.fold(
      0,
      (sum, order) => sum + order.lines.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.saleId == null ? S.batchSale : '${S.edit} ${S.sales}',
        ),
      ),
      body: data.isLoading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: ShimmerList(count: 3),
            )
          : menu.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.restaurant_menu,
                      title: S.noMenu,
                      message: S.addFoodFirst,
                      actionLabel: S.addFoodFirst,
                      onAction: () => context.push('/menu'),
                    ),
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
                      children: [
                        SoftCard(
                          color: AppColors.blueSoft,
                          child: const Text(
                            'Every food item is saved as its own order with its own date, note, customer and total. Add as many foods as you need.',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...List.generate(_orders.length, (index) {
                          final order = _orders[index];
                          return _OrderCard(
                            order: order,
                            index: index,
                            menu: menu,
                            sacks: data.sacks,
                            canRemove: _orders.length > 1,
                            onChanged: () => setState(() {}),
                            onRemove: () {
                              final removed = _orders.removeAt(index);
                              removed.dispose();
                              setState(() {});
                            },
                            onPickDate: () => _pickDate(index),
                            onPickDeadline: () => _pickDeadline(index),
                          );
                        }),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => setState(
                            () => _orders.add(
                              _OrderDraft(date: _orders.last.date),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(S.addAnotherOrder),
                        ),
                        const SizedBox(height: 20),
                        SoftCard(
                          color: AppColors.accentSoft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'All orders',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '$orderCount order${orderCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              CountUpText(
                                value: grandTotal,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _saving
                            ? const Center(child: CircularProgressIndicator())
                            : PrimaryButton(
                                label: orderCount == 1
                                    ? '${S.save} ${S.sales}'
                                    : 'Save $orderCount orders',
                                onPressed: () => _save(menu, data.ingredients),
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final _OrderDraft order;
  final int index;
  final List<MenuItem> menu;
  final List<Sack> sacks;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickDate;
  final VoidCallback onPickDeadline;

  const _OrderCard({
    required this.order,
    required this.index,
    required this.menu,
    required this.sacks,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onPickDate,
    required this.onPickDeadline,
  });

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${S.orderNumber} ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  Fmt.money(order.total(menu)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    fontSize: 16,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: S.removeOrder,
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onPickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: AppColors.primaryDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sale date',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            Fmt.date(order.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: order.sackId,
              decoration: const InputDecoration(
                labelText: 'Link to sack (optional)',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No sack'),
                ),
                ...sacks.map(
                  (sack) => DropdownMenuItem<String?>(
                    value: sack.id,
                    child: Text(
                      '${sack.product} • ${Fmt.date(sack.boughtDate)} • ${Fmt.money(sack.cost)}',
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                order.sackId = value;
                onChanged();
              },
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Items sold'),
            const SizedBox(height: 10),
            ...List.generate(order.lines.length, (itemIndex) {
              return _ItemCard(
                editor: order.lines[itemIndex],
                index: itemIndex,
                menu: menu,
                canRemove: order.lines.length > 1,
                onChanged: onChanged,
                onRemove: () {
                  final removed = order.lines.removeAt(itemIndex);
                  removed.dispose();
                  onChanged();
                },
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                order.lines.add(_LineEditor());
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text(S.addAnotherItem),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: order.note,
              decoration: const InputDecoration(
                labelText: 'Order note (customer or reminder)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: order.unpaid,
                onChanged: (value) {
                  order.unpaid = value;
                  onChanged();
                },
                title: const Text(S.notPaidYet),
                activeThumbColor: AppColors.accent,
              ),
            ),
            if (order.unpaid) ...[
              TextFormField(
                controller: order.customer,
                decoration: const InputDecoration(
                  labelText: S.customer,
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the customer name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: order.phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: S.phone,
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: onPickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: S.deadline,
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    order.deadline == null
                        ? 'Optional'
                        : Fmt.date(order.deadline!),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class _ItemCard extends StatelessWidget {
  final _LineEditor editor;
  final int index;
  final List<MenuItem> menu;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ItemCard({
    required this.editor,
    required this.index,
    required this.menu,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Item ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    )),
                const Spacer(),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove item',
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: onRemove,
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: editor.menuItemId.isEmpty ? null : editor.menuItemId,
              decoration: const InputDecoration(labelText: 'Food item'),
              items: menu
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(
                        '${item.emoji} ${item.name} • ${Fmt.money(item.price)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                editor.menuItemId = value ?? '';
                onChanged();
              },
              validator: (value) =>
                  value == null || value.isEmpty ? 'Choose a food item.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: editor.qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: S.quantity),
                    onChanged: (_) => onChanged(),
                    validator: (value) {
                      final qty = double.tryParse(value ?? '');
                      if (qty == null || qty <= 0) return 'Enter a quantity.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: editor.price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price override',
                      hintText: 'Optional',
                    ),
                    onChanged: (_) => onChanged(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Enter a valid price.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: editor.note,
              decoration: const InputDecoration(labelText: 'Item note (optional)'),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      );
}
