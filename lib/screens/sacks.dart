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
  Future<void> _openEditor({Sack? sack}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SackEditor(sack: sack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final stats = buildSackStats(sacks: data.sacks, sales: data.sales);
    final statsById = {for (final item in stats) item.sack.id: item};
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
                    'Record the price of each sack. Link sales to a sack to see revenue, ingredient cost and profit for every day the sack was used.',
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
                    (sack) => _SackCard(
                      sack: sack,
                      stats: statsById[sack.id],
                      onEdit: () => _openEditor(sack: sack),
                      onFinish: () async {
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
                                finished.map((sack) => sack.daysLasted.toDouble()),
                              )),
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
                                finished.map((sack) => sack.cost),
                              )),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.accent,
                              ),
                            ),
                            const Text('Average sack price',
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
                      message: 'Finished sacks will appear here with their full profit.',
                    ),
                  )
                else
                  ...history.map(
                    (sack) => _SackCard(
                      sack: sack,
                      stats: statsById[sack.id],
                      onEdit: () => _openEditor(sack: sack),
                      onDelete: () async {
                        final confirm = await confirmAction(
                          context,
                          title: S.confirmDelete,
                          message: 'Delete this sack record?',
                        );
                        if (confirm && context.mounted) {
                          await context.read<DataStore>().deleteSack(sack.id);
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SackCard extends StatelessWidget {
  final Sack sack;
  final SackStats? stats;
  final VoidCallback onEdit;
  final VoidCallback? onFinish;
  final VoidCallback? onDelete;

  const _SackCard({
    required this.sack,
    required this.stats,
    required this.onEdit,
    this.onFinish,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final usedDays = stats?.days.where((day) => day.revenue > 0).toList() ?? [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🥔', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sack.product,
                        style: const TextStyle(
                          fontSize: 17,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(S.sackPrice,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        )),
                    Text(
                      Fmt.money(sack.cost),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (sack.daysLasted % 14) / 14,
                minHeight: 9,
                backgroundColor: AppColors.blueSoft,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _SackValue('${sack.daysLasted}', 'days'),
                ),
                Expanded(
                  child: _SackValue(Fmt.money(sack.costPerDay), 'cost / day'),
                ),
                Expanded(
                  child: _SackValue(
                    Fmt.money(stats?.revenue ?? 0),
                    'revenue',
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            if (stats != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SackValue(
                      Fmt.money(stats!.ingredientCost),
                      'ingredient cost',
                    ),
                    _SackValue(
                      Fmt.money(stats!.sackCost),
                      'sack cost',
                      color: AppColors.accent,
                    ),
                    _SackValue(
                      Fmt.money(stats!.profit),
                      'profit',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
            if (usedDays.isNotEmpty) ...[
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: AppColors.primaryDark,
                collapsedIconColor: AppColors.primaryDark,
                title: const Text(
                  'Sales by day',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                subtitle: Text(
                  '${usedDays.length} day${usedDays.length == 1 ? '' : 's'} with sales',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                children: usedDays
                    .map(
                      (day) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 66,
                              child: Text(
                                Fmt.shortDate(day.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'In ${Fmt.money(day.revenue)}',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Cost ${Fmt.money(day.ingredientCost + day.sackCost)}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              Fmt.money(day.profit),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.success,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(S.edit),
                ),
                const Spacer(),
                if (onFinish != null)
                  TextButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(S.finishSack),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: S.delete,
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SackValue extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SackValue(this.value, this.label, {this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      );
}

class _SackEditor extends StatefulWidget {
  final Sack? sack;

  const _SackEditor({this.sack});

  @override
  State<_SackEditor> createState() => _SackEditorState();
}

class _SackEditorState extends State<_SackEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _product;
  late final TextEditingController _cost;
  late final TextEditingController _note;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final sack = widget.sack;
    _product = TextEditingController(text: sack?.product ?? 'Potatoes');
    _cost = TextEditingController(
      text: sack == null ? '' : sack.cost.toStringAsFixed(0),
    );
    _note = TextEditingController(text: sack?.note ?? '');
    _date = sack?.boughtDate ?? DateTime.now();
  }

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
    final existing = widget.sack;
    final sack = Sack(
      id: existing?.id ?? newId(),
      product: _product.text.trim(),
      boughtDate: _date,
      dayKey: Fmt.dayKey(_date),
      cost: double.parse(_cost.text.trim()),
      finishedDate: existing?.finishedDate,
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
                Text(
                  widget.sack == null ? 'Add a sack' : 'Edit sack',
                  style: const TextStyle(
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
                  decoration: const InputDecoration(labelText: S.sackPrice),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Enter a price.';
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
