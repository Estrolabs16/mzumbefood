import 'package:flutter/material.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class MishkakiScreen extends StatefulWidget {
  const MishkakiScreen({super.key});

  @override
  State<MishkakiScreen> createState() => _MishkakiScreenState();
}

class _MishkakiScreenState extends State<MishkakiScreen> {
  static const defaultTypes = [
    "Mishkaki ya Ng'ombe",
    'Mishkaki ya Kuku',
  ];

  String _type = defaultTypes.first;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final types = <String>{
      ...defaultTypes,
      ...data.mishkakiSales.map((item) => item.type),
      ...data.mishkakiStock.map((item) => item.type),
    }.toList();
    if (!types.contains(_type)) _type = types.first;
    final forType =
        data.mishkakiSales.where((item) => item.type == _type).toList();
    final now = DateTime.now();
    final today = _summary(forType, Fmt.startOfDay(now),
        Fmt.startOfDay(now).add(const Duration(days: 1)));
    final week = _summary(
        forType, Fmt.startOfWeek(now), Fmt.endOfWeek(now));
    final month = _summary(
        forType, Fmt.startOfMonth(now), Fmt.endOfMonth(now));
    final stockForType =
        data.mishkakiStock.where((item) => item.type == _type).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('🍢 Mishkaki corner')),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: types
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: _type == type,
                              onSelected: (_) => setState(() => _type = type),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Sticks sold',
                        icon: Icons.add,
                        color: AppColors.accent,
                        onPressed: () => _openSaleEditor(types),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openStockEditor(types),
                        child: const Text(S.stockBought),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _PeriodCard('Today', today),
                const SizedBox(height: 12),
                _PeriodCard(S.thisWeek, week),
                const SizedBox(height: 12),
                _PeriodCard(S.thisMonth, month),
                const SizedBox(height: 22),
                const SectionTitle(title: 'Sticks sold'),
                const SizedBox(height: 10),
                if (forType.isEmpty)
                  SoftCard(
                    child: EmptyState(
                      icon: Icons.kebab_dining,
                      title: 'No sticks sold yet',
                      message: 'Record your first mishkaki sale for $_type.',
                      actionLabel: 'Add sticks',
                      onAction: () => _openSaleEditor(types),
                    ),
                  )
                else
                  ...forType.take(10).map(
                        (item) => SoftCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Text('🍢', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Fmt.number(item.sticksSold)} sticks • ${Fmt.money(item.pricePerStick)} each',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      Fmt.date(item.date),
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Fmt.money(item.revenue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger),
                                onPressed: () => context
                                    .read<DataStore>()
                                    .deleteMishkaki(item.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 22),
                const SectionTitle(title: S.stockBought),
                const SizedBox(height: 10),
                if (stockForType.isEmpty)
                  SoftCard(
                    child: EmptyState(
                      icon: Icons.shopping_cart,
                      title: 'No stock recorded',
                      message: 'Track meat or stick purchases to see your costs.',
                    ),
                  )
                else
                  ...stockForType.take(10).map(
                        (item) => SoftCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2,
                                  color: AppColors.primaryDark),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Fmt.number(item.quantity)} ${item.unit}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(Fmt.date(item.date),
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(
                                Fmt.money(item.cost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger),
                                onPressed: () => context
                                    .read<DataStore>()
                                    .deleteMishkakiStock(item.id),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  ({double sticks, double revenue, double profit}) _summary(
    List<MishkakiSale> items,
    DateTime from,
    DateTime to,
  ) {
    final selected = items
        .where((item) => Fmt.inRange(item.date, from, to))
        .fold(<double>[0, 0, 0], (values, item) {
      values[0] += item.sticksSold;
      values[1] += item.revenue;
      values[2] += item.profit;
      return values;
    });
    return (
      sticks: selected[0],
      revenue: selected[1],
      profit: selected[2]
    );
  }

  Future<void> _openSaleEditor(List<String> types) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MishkakiSaleEditor(
        types: types,
        initialType: _type,
      ),
    );
  }

  Future<void> _openStockEditor(List<String> types) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MishkakiStockEditor(
        types: types,
        initialType: _type,
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String label;
  final ({double sticks, double revenue, double profit}) values;

  const _PeriodCard(this.label, this.values);

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Value('Sticks', Fmt.number(values.sticks), AppColors.primaryDark),
                _Value('Revenue', Fmt.money(values.revenue), AppColors.accent),
                _Value('Profit', Fmt.money(values.profit), AppColors.success),
              ],
            ),
          ],
        ),
      );
}

class _Value extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Value(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              )),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}

abstract class _BaseEditor extends StatefulWidget {
  final List<String> types;
  final String initialType;

  const _BaseEditor({required this.types, required this.initialType});
}

class _MishkakiSaleEditor extends _BaseEditor {
  const _MishkakiSaleEditor({
    required super.types,
    required super.initialType,
  });

  @override
  State<_MishkakiSaleEditor> createState() => _MishkakiSaleEditorState();
}

class _MishkakiSaleEditorState extends State<_MishkakiSaleEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  final _sticks = TextEditingController();
  final _price = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _sticks.dispose();
    _price.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = MishkakiSale(
      id: newId(),
      date: _date,
      dayKey: Fmt.dayKey(_date),
      type: _type,
      sticksSold: double.parse(_sticks.text.trim()),
      pricePerStick: double.parse(_price.text.trim()),
      costPerStick: double.tryParse(_cost.text.trim()) ?? 0,
      note: _note.text.trim(),
    );
    await context.read<DataStore>().saveMishkaki(item);
    if (mounted) {
      showSuccess(context);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => _sheet(
        context: context,
        title: 'Add sticks sold',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: widget.types
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sticks,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: S.sticksSold),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) return 'Enter sticks.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Price per stick'),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) return 'Enter price.';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost per stick (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: S.note),
              ),
              const SizedBox(height: 12),
              _dateTile(context),
              const SizedBox(height: 18),
              _saving
                  ? const CircularProgressIndicator()
                  : PrimaryButton(label: S.save, onPressed: _save),
            ],
          ),
        ),
      );

  Widget _dateTile(BuildContext context) => InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked != null) setState(() => _date = picked);
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Date'),
          child: Text(Fmt.date(_date)),
        ),
      );
}

class _MishkakiStockEditor extends _BaseEditor {
  const _MishkakiStockEditor({
    required super.types,
    required super.initialType,
  });

  @override
  State<_MishkakiStockEditor> createState() => _MishkakiStockEditorState();
}

class _MishkakiStockEditorState extends State<_MishkakiStockEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  String _unit = 'sticks';
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final item = MishkakiStock(
      id: newId(),
      date: _date,
      dayKey: Fmt.dayKey(_date),
      type: _type,
      quantity: double.parse(_quantity.text.trim()),
      unit: _unit,
      cost: double.parse(_cost.text.trim()),
      note: _note.text.trim(),
    );
    await context.read<DataStore>().saveMishkakiStock(item);
    if (mounted) {
      showSuccess(context);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => _sheet(
        context: context,
        title: S.stockBought,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: widget.types
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) return 'Enter amount.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: ['sticks', 'kg']
                          .map((unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _unit = value ?? 'sticks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total cost (TSh)'),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter cost.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(labelText: S.note),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text(Fmt.date(_date)),
                ),
              ),
              const SizedBox(height: 18),
              _saving
                  ? const CircularProgressIndicator()
                  : PrimaryButton(label: S.save, onPressed: _save),
            ],
          ),
        ),
      );
}

Widget _sheet({
  required BuildContext context,
  required String title,
  required Widget child,
}) =>
    Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
