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

class _AddSaleScreenState extends State<AddSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderNote = TextEditingController();
  final _customer = TextEditingController();
  final _phone = TextEditingController();
  final List<_LineEditor> _lines = [_LineEditor()];
  DateTime _date = DateTime.now();
  DateTime? _deadline;
  bool _unpaid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _date = Fmt.parseDayKey(widget.initialDate!);
    }
    final data = context.read<DataProvider>();
    if (widget.saleId != null) {
      final existing = data.sales
          .where((element) => element.id == widget.saleId)
          .firstOrNull;
      if (existing != null) {
        _date = existing.date;
        _orderNote.text = existing.note;
        _unpaid = !existing.paid;
        _lines
          ..clear()
          ..addAll(
            existing.items.map(
              (line) => _LineEditor(
                menuItemId: line.menuItemId,
                quantity: Fmt.number(line.qty),
                priceText: line.unitPrice.toStringAsFixed(0),
                noteText: line.note,
              ),
            ),
          );
      }
    }
  }

  @override
  void dispose() {
    _orderNote.dispose();
    _customer.dispose();
    _phone.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  MenuItem? _find(List<MenuItem> items, String id) {
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

  double _lineQty(_LineEditor line) => double.tryParse(line.qty.text.trim()) ?? 0;

  double _total(List<MenuItem> items) => _lines.fold(
        0,
        (sum, line) =>
            sum + _linePrice(_find(items, line.menuItemId), line) * _lineQty(line),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2036),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save(List<MenuItem> menu, List<Ingredient> ingredients) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final lines = <SaleLine>[];
      for (final line in _lines) {
        final item = _find(menu, line.menuItemId);
        if (item == null) continue;
        lines.add(
          SaleLine(
            menuItemId: item.id,
            name: item.name,
            qty: _lineQty(line),
            unitPrice: _linePrice(item, line),
            unitCostAtSale: item.unitCost(ingredients),
            note: line.note.text.trim(),
          ),
        );
      }
      final data = context.read<DataProvider>();
      final existing = widget.saleId == null
          ? null
          : data.sales.where((e) => e.id == widget.saleId).firstOrNull;
      final sale = Sale(
        id: existing?.id ?? newId(),
        date: _date,
        dayKey: Fmt.dayKey(_date),
        items: lines,
        total: lines.fold(0, (sum, line) => sum + line.total),
        cost: lines.fold(0, (sum, line) => sum + line.cost),
        note: _orderNote.text.trim(),
        paid: !_unpaid,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      Debt? debt;
      if (_unpaid) {
        debt = Debt(
          id: newId(),
          customer: _customer.text.trim(),
          phone: _phone.text.trim(),
          reason: sale.itemSummary,
          amount: sale.total,
          createdAt: DateTime.now(),
          dayKey: Fmt.dayKey(DateTime.now()),
          deadline: _deadline,
          paid: false,
        );
      }
      await context.read<DataStore>().saveSale(sale, debt: debt);
      if (mounted) {
        showSuccess(context);
        Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.saleId == null ? S.addSale : '${S.edit} ${S.sales}'),
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
                          child: InkWell(
                            onTap: _pickDate,
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month,
                                    color: AppColors.primaryDark),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Sale date',
                                          style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12)),
                                      Text(
                                        Fmt.date(_date),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                          fontSize: 16,
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
                        const SizedBox(height: 18),
                        const SectionTitle(title: 'Items sold'),
                        const SizedBox(height: 10),
                        ...List.generate(_lines.length, (index) {
                          return _ItemCard(
                            editor: _lines[index],
                            index: index,
                            menu: menu,
                            canRemove: _lines.length > 1,
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() => _lines.removeAt(index)),
                          );
                        }),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _lines.add(_LineEditor())),
                          icon: const Icon(Icons.add),
                          label: const Text(S.addAnotherItem),
                        ),
                        const SizedBox(height: 18),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _orderNote,
                                decoration: const InputDecoration(
                                  labelText: 'Order note (customer or reminder)',
                                  prefixIcon: Icon(Icons.notes),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Material(
                                color: Colors.transparent,
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _unpaid,
                                  onChanged: (value) =>
                                      setState(() => _unpaid = value),
                                  title: const Text(S.notPaidYet),
                                  activeThumbColor: AppColors.accent,
                                ),
                              ),
                              if (_unpaid) ...[
                                TextFormField(
                                  controller: _customer,
                                  decoration: const InputDecoration(
                                    labelText: S.customer,
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: (value) => value == null ||
                                          value.trim().isEmpty
                                      ? 'Please enter the customer name.'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: S.phone,
                                    prefixIcon: Icon(Icons.phone),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: _pickDeadline,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: S.deadline,
                                      prefixIcon: Icon(Icons.event),
                                    ),
                                    child: Text(
                                      _deadline == null
                                          ? 'Optional'
                                          : Fmt.date(_deadline!),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SoftCard(
                          color: AppColors.blueSoft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                S.orderTotal,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              CountUpText(
                                value: _total(menu),
                                style: const TextStyle(
                                  fontSize: 23,
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
                                label: '${S.save} ${S.sales}',
                                onPressed: () => _save(menu, data.ingredients),
                              ),
                      ],
                    ),
                  ),
                ),
    );
  }
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
