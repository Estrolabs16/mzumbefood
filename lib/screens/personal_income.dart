import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class PersonalIncomeScreen extends StatefulWidget {
  const PersonalIncomeScreen({super.key});

  @override
  State<PersonalIncomeScreen> createState() => _PersonalIncomeScreenState();
}

class _PersonalIncomeScreenState extends State<PersonalIncomeScreen> {
  int _period = 0;

  Future<void> _openEditor({PersonalIncome? income}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IncomeEditor(income: income),
    );
  }

  Future<bool> _deleteWithConfirm(PersonalIncome income) async {
    final store = context.read<DataStore>();
    final confirm = await confirmAction(
      context,
      title: S.confirmDelete,
      message: 'Delete income from "${income.source}"?',
    );
    if (!confirm) return false;
    if (!mounted) return false;
    await store.deletePersonalIncome(income.id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final now = DateTime.now();
    DateTime from;
    DateTime to;
    String label;
    if (_period == 0) {
      from = Fmt.startOfDay(now);
      to = Fmt.startOfDay(now.add(const Duration(days: 1)));
      label = S.today;
    } else if (_period == 1) {
      from = Fmt.startOfWeek(now);
      to = Fmt.endOfWeek(now);
      label = S.thisWeek;
    } else {
      from = Fmt.startOfMonth(now);
      to = Fmt.endOfMonth(now);
      label = S.thisMonth;
    }
    final summary = personalSummary(
      income: data.personalIncome,
      expenses: data.personalExpenses,
      from: from,
      to: to,
    );
    final visibleIncome = data.personalIncome
        .where((item) => Fmt.inRange(item.date, from, to))
        .toList();

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.personalIncome,
                    subtitle: 'Money you receive outside the food business',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final period in [S.today, S.thisWeek, S.thisMonth])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(period),
                                    selected: _period ==
                                        [S.today, S.thisWeek, S.thisMonth]
                                            .indexOf(period),
                                    onSelected: (_) => setState(
                                      () => _period = [S.today, S.thisWeek, S.thisMonth]
                                          .indexOf(period),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SoftCard(
                          color: Colors.white,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$label income',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Personal only',
                                    style: TextStyle(
                                      color: AppColors.primaryDark.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              CountUpText(
                                value: summary.income,
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Spent',
                                      value: summary.spending,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MiniStat(
                                      label: 'Balance',
                                      value: summary.balance,
                                      color: summary.balance < 0
                                          ? AppColors.danger
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              PrimaryButton(
                                label: 'Add personal income',
                                icon: Icons.add,
                                onPressed: () => _openEditor(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: SoftCard(
                      color: AppColors.blueSoft,
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: AppColors.primaryDark),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This money is kept separate. It never appears in business revenue or profit.',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (visibleIncome.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.payments,
                      title: 'No personal income',
                      message: S.noIncome,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                      child: SectionTitle(
                        title: '$label records',
                        action: Text(
                          Fmt.money(summary.income),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final income = visibleIncome[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: SoftCard(
                            padding: const EdgeInsets.all(14),
                            child: Dismissible(
                              key: ValueKey(income.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _deleteWithConfirm(income),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.blueSoft,
                                    child: Text(
                                      Fmt.initials(income.source),
                                      style: const TextStyle(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    income.source,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  subtitle: Text(
                                    income.note.isEmpty
                                        ? Fmt.date(income.date)
                                        : '${Fmt.date(income.date)} • ${income.note}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+${Fmt.money(income.amount)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: AppColors.primaryDark),
                                        onPressed: () =>
                                            _openEditor(income: income),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: visibleIncome.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value < 0 ? '-${Fmt.money(value.abs())}' : Fmt.money(value),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 15,
                )),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

class _IncomeEditor extends StatefulWidget {
  final PersonalIncome? income;

  const _IncomeEditor({this.income});

  @override
  State<_IncomeEditor> createState() => _IncomeEditorState();
}

class _IncomeEditorState extends State<_IncomeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _source;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _source = TextEditingController(text: widget.income?.source ?? '');
    _amount = TextEditingController(
      text: widget.income == null ? '' : widget.income!.amount.toString(),
    );
    _note = TextEditingController(text: widget.income?.note ?? '');
    _date = widget.income?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final income = PersonalIncome(
      id: widget.income?.id ?? newId(),
      date: _date,
      dayKey: Fmt.dayKey(_date),
      source: _source.text.trim(),
      amount: double.parse(_amount.text.trim()),
      note: _note.text.trim(),
    );
    await context.read<DataStore>().savePersonalIncome(income);
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
                  widget.income == null ? 'Add personal income' : S.edit,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _source,
                  decoration: const InputDecoration(labelText: S.source),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a source.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: S.amount),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Enter an amount.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: S.note),
                  maxLines: 2,
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
                    decoration: const InputDecoration(labelText: 'Date received'),
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
