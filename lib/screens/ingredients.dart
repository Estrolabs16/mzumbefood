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

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  Future<void> _openEditor(Ingredient? ingredient) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IngredientEditor(
        ingredient: ingredient,
        onDelete: ingredient == null
            ? null
            : () async {
                await context.read<DataStore>().deleteIngredient(ingredient.id);
                if (context.mounted) Navigator.of(context).pop();
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.ingredients)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'ingredient-add',
        backgroundColor: AppColors.accent,
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.add),
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
              children: [
                SoftCard(
                  color: AppColors.blueSoft,
                  child: const Row(
                    children: [
                      Text('🥚', style: TextStyle(fontSize: 34)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Edit your egg tray price here. Every menu item using eggs updates automatically, while old sales keep their original cost.',
                          style: TextStyle(color: AppColors.ink, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (data.ingredients.isEmpty)
                  EmptyState(
                    icon: Icons.egg,
                    title: 'No ingredient costs yet',
                    message: 'Add a pack, for example an egg tray of 30 eggs.',
                    actionLabel: S.add,
                    onAction: () => _openEditor(null),
                  )
                else
                  ...data.ingredients.map(
                    (ingredient) => SoftCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => _openEditor(ingredient),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(14)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.inventory_2,
                                color: AppColors.accent),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ingredient.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '${Fmt.money(ingredient.packPrice)} / ${Fmt.number(ingredient.packQuantity)} units',
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
                                Fmt.moneyPrecise(ingredient.costPerUnit),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const Text('per unit',
                                  style: TextStyle(
                                      color: AppColors.muted, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _IngredientEditor extends StatefulWidget {
  final Ingredient? ingredient;
  final VoidCallback? onDelete;

  const _IngredientEditor({required this.ingredient, required this.onDelete});

  @override
  State<_IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<_IngredientEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _packPrice;
  late final TextEditingController _packQuantity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.ingredient;
    _name = TextEditingController(text: ingredient?.name ?? '');
    _packPrice = TextEditingController(
        text: ingredient == null ? '' : ingredient.packPrice.toStringAsFixed(0));
    _packQuantity = TextEditingController(
        text: ingredient == null ? '30' : Fmt.number(ingredient.packQuantity));
  }

  @override
  void dispose() {
    _name.dispose();
    _packPrice.dispose();
    _packQuantity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ingredient = Ingredient(
      id: widget.ingredient?.id ?? newId(),
      name: _name.text.trim(),
      packPrice: double.parse(_packPrice.text.trim()),
      packQuantity: double.parse(_packQuantity.text.trim()),
    );
    await context.read<DataStore>().saveIngredient(ingredient);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(_packQuantity.text) ?? 0;
    final price = double.tryParse(_packPrice.text) ?? 0;
    final perUnit = quantity <= 0 ? 0.0 : price / quantity;
    return Container(
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
                widget.ingredient == null ? 'Add ingredient cost' : 'Edit cost',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Pack name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a name.'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _packPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pack price'),
                      onChanged: (_) => setState(() {}),
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
                      controller: _packQuantity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Units in pack'),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter a quantity.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SoftCard(
                color: AppColors.blueSoft,
                child: Text(
                  'Cost per unit: ${Fmt.moneyPrecise(perUnit)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
}
