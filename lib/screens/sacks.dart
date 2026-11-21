import 'package:flutter/material.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class SacksScreen extends StatefulWidget {
  const SacksScreen({super.key});

  @override
  State<SacksScreen> createState() => _SacksScreenState();
}

class _SacksScreenState extends State<SacksScreen> {
  Future<void> _openEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SackEditor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final active = data.sacks
        .where((sack) => sack.finishedDate == null)
        .toList()
      ..sort((a, b) => b.boughtDate.compareTo(a.boughtDate));
    final history = data.sacks
        .where((sack) => sack.finishedDate != null)
        .toList()
      ..sort((a, b) => b.boughtDate.compareTo(a.boughtDate));
    final finished = data.sacks.where((sack) => sack.finishedDate != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('🥔 Sacks')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'sack-add',
        backgroundColor: AppColors.accent,
        onPressed: _openEditor,
        child: const Icon(Icons.add),
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
              children: [
                SoftCard(
                  color: AppColors.blueSoft,
                  child: const Text(
                    'Track each sack from the day you buy it. The app shows how many days it lasted and the cost per day.',
                    style: TextStyle(color: AppColors.ink, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: S.activeSack),
                const SizedBox(height: 10),
                if (active.isEmpty)
                  SoftCard(
                    child: EmptyState(
                      icon: Icons.inventory_2,
                      title: 'No active sack',
                      message: S.noSacks,
                      actionLabel: 'Add sack',
                      onAction: _openEditor,
                    ),
                  )
                else
                  ...active.map(
                    (sack) => SoftCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🥔', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sack.product,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      'Bought ${Fmt.date(sack.boughtDate)}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Fmt.money(sack.cost),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: (sack.daysLasted % 14) / 14,
                              minHeight: 10,
                              backgroundColor: AppColors.blueSoft,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SackValue(
                                  '${sack.daysLasted}', 'days so far'),
                              _SackValue(
                                  Fmt.money(sack.costPerDay), 'cost per day'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: S.finishSack,
                            color: AppColors.primaryDark,
                            onPressed: () async {
                              final confirm = await confirmAction(
                                context,
                                title: S.finishSack,
                                message: 'Mark this sack as finished today?',
                              );
                              if (confirm && context.mounted) {
                                await context.read<DataStore>().saveSack(
                                      sack.copyWith(finishedDate: DateTime.now()),
                                    );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              Fmt.number(average(
                                finished.map((sack) => sack.daysLasted.toDouble())),),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const Text('Average days / sack',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              Fmt.money(average(
                                finished.map((sack) => sack.cost),)),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                            const Text('Average cost / sack',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionTitle(title: 'Sack history'),
                const SizedBox(height: 10),
                if (history.isEmpty)
                  SoftCard(
                    child: EmptyState(
                      icon: Icons.history,
                      title: 'No finished sacks yet',
                      message: 'Finished sacks will appear here with their cost per day.',
                    ),
                  )
                else
                  ...history.map(
                    (sack) => SoftCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Text('🥔', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sack.product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  '${sack.daysLasted} days • ${Fmt.money(sack.costPerDay)}/day',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () async {
                              final confirm = await confirmAction(
                                context,
                                title: S.confirmDelete,
                                message: 'Delete this sack record?',
                              );
                              if (confirm && context.mounted) {
                                await context
                                    .read<DataStore>()
                                    .deleteSack(sack.id);
                              }
                            },
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

class _SackValue extends StatelessWidget {
  final String value;
  final String label;

  const _SackValue(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}

class _SackEditor extends StatefulWidget {
  const _SackEditor();

  @override
  State<_SackEditor> createState() => _SackEditorState();
}

class _SackEditorState extends State<_SackEditor> {
  final _formKey = GlobalKey<FormState>();
  final _product = TextEditingController(text: 'Potatoes');
  final _cost = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _product.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final sack = Sack(
      id: newId(),
      product: _product.text.trim(),
      boughtDate: _date,
      dayKey: Fmt.dayKey(_date),
      cost: double.parse(_cost.text.trim()),
      finishedDate: null,
      note: _note.text.trim(),
    );
    await context.read<DataStore>().saveSack(sack);
    if (mounted) {
      showSuccess(context);
      Navigator.of(context).pop();
    }
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
                const Text(
                  'Add a sack',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _product,
                  decoration: const InputDecoration(labelText: 'Product'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a product.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost (TSh)'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Enter a cost.';
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
                    decoration: const InputDecoration(labelText: 'Date bought'),
                    child: Text(Fmt.date(_date)),
                  ),
                ),
                const SizedBox(height: 18),
                _saving
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(label: S.save, onPressed: _save),
              ],
            ),
          ),
        ),
      );
}
