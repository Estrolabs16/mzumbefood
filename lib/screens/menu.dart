import 'package:flutter/material.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const categories = ['Chips', 'Eggs', 'Rice', 'Mishkaki', 'Drinks', 'Other'];

  Future<void> _openEditor(DataProvider data, MenuItem? item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuEditor(
        item: item,
        categories: categories,
        ingredients: data.ingredients,
        onDelete: item == null
            ? null
            : () async {
                await context.read<DataStore>().deleteMenuItem(item.id);
                if (context.mounted) Navigator.of(context).pop();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.menu),
        actions: [
          IconButton(
            tooltip: S.ingredients,
            icon: const Icon(Icons.egg_outlined),
            onPressed: () => context.push('/ingredients'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'menu-add',
        backgroundColor: AppColors.accent,
        onPressed: () => _openEditor(data, null),
        child: const Icon(Icons.add),
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.menuItems.isEmpty
              ? EmptyState(
                  icon: Icons.restaurant_menu,
                  title: S.noMenu,
                  message: S.addFoodFirst,
                  actionLabel: S.add,
                  onAction: () => _openEditor(data, null),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                  children: [
                    Text(
                      '${data.menuItems.length} foods on your menu',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    ...data.menuItems.map((item) {
                      final cost = item.unitCost(data.ingredients);
                      return SoftCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => _openEditor(data, item),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: AppColors.blueSoft,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                              ),
                              alignment: Alignment.center,
                              child: Text(item.emoji,
                                  style: const TextStyle(fontSize: 27)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '${item.category} • Cost ${Fmt.money(cost)}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Fmt.money(item.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                  ),
                                ),
                                if (!item.active)
                                  const Text(
                                    'Hidden',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _MenuEditor extends StatefulWidget {
  final MenuItem? item;
  final List<String> categories;
  final List<Ingredient> ingredients;
  final VoidCallback? onDelete;

  const _MenuEditor({
    required this.item,
    required this.categories,
    required this.ingredients,
    required this.onDelete,
  });

  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _otherCost;
  late String _category;
  late bool _active;
  final Map<String, TextEditingController> _quantities = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(
        text: item == null ? '' : item.price.toStringAsFixed(0));
    _otherCost = TextEditingController(
        text: item == null ? '0' : item.otherCost.toStringAsFixed(0));
    _category = item?.category ?? 'Chips';
    _active = item?.active ?? true;
    for (final ingredient in widget.ingredients) {
      final link = item?.ingredients
          .where((element) => element.ingredientId == ingredient.id)
          .firstOrNull;
      _quantities[ingredient.id] = TextEditingController(
        text: link == null ? '' : Fmt.number(link.quantity),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _otherCost.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final links = <IngredientLink>[];
    for (final entry in _quantities.entries) {
      final quantity = double.tryParse(entry.value.text.trim());
      if (quantity != null && quantity > 0) {
        links.add(IngredientLink(ingredientId: entry.key, quantity: quantity));
      }
    }
    final item = MenuItem(
      id: widget.item?.id ?? newId(),
      name: _name.text.trim(),
      category: _category,
      price: double.parse(_price.text.trim()),
      otherCost: double.tryParse(_otherCost.text.trim()) ?? 0,
      ingredients: links,
      active: _active,
    );
    await context.read<DataStore>().saveMenuItem(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Container(
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.item == null ? 'Add food' : 'Edit food',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: S.itemName),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a name.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: S.category),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Other'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: S.sellingPrice),
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a price.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _otherCost,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Other cost per item',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.ingredients.isNotEmpty) ...[
                  const SectionTitle(title: 'Ingredients used'),
                  ...widget.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${ingredient.name}\n${Fmt.moneyPrecise(ingredient.costPerUnit)} / unit',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _quantities[ingredient.id],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                    title: const Text('Active (show when adding sales)'),
                    activeThumbColor: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                _saving
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(label: S.save, onPressed: _save),
                if (widget.onDelete != null)
                  TextButton(
                    onPressed: widget.onDelete,
                    child: const Text(
                      S.delete,
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
