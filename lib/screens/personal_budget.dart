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

class PersonalBudgetScreen extends StatefulWidget {
  const PersonalBudgetScreen({super.key});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  Future<void> _openBudgetEditor(double current) async {
    final store = context.read<DataStore>();
    final profile = context.read<DataProvider>().profile;
    final controller = TextEditingController(
      text: current > 0 ? current.toString() : '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(S.dailyBudget),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: S.amount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(S.save),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (saved != true) return;
    final value = double.tryParse(text) ?? 0;
    await store.saveProfile(profile.copyWith(dailyBudget: value));
    if (mounted) showSuccess(context);
  }

  Future<void> _openEditor({PersonalExpense? expense}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExpenseEditor(expense: expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final today = personalSummary(
      income: data.personalIncome,
      expenses: data.personalExpenses,
      from: Fmt.startOfDay(now),
      to: Fmt.startOfDay(tomorrow),
    );
    final week = personalSummary(
      income: data.personalIncome,
      expenses: data.personalExpenses,
      from: Fmt.startOfWeek(now),
      to: Fmt.endOfWeek(now),
    );
    final month = personalSummary(
      income: data.personalIncome,
      expenses: data.personalExpenses,
      from: Fmt.startOfMonth(now),
      to: Fmt.endOfMonth(now),
    );
    final budget = data.profile.dailyBudget;
    final progress = budget <= 0
        ? 0.0
        : (today.spending / budget).clamp(0.0, 1.0);
    final overBudget = budget > 0 && today.spending > budget;

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.personalBudget,
                    subtitle: 'Your money, separate from the business',
                    child: SoftCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.wallet, color: AppColors.accent),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Today’s spending',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openBudgetEditor(budget),
                                child: const Text('Set budget'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CountUpText(
                            value: today.spending,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            budget <= 0
                                ? 'No daily budget set yet.'
                                : 'Budget ${Fmt.money(budget)} • ${Fmt.money((budget - today.spending).abs())} ${overBudget ? 'over' : 'left'}',
                            style: TextStyle(
                              color: overBudget ? AppColors.danger : AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              color: overBudget ? AppColors.danger : AppColors.accent,
                              backgroundColor: AppColors.accentSoft,
                            ),
                          ),
                          if (overBudget)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                '⚠️ You have passed your daily budget.',
                                style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Add personal spending',
                            icon: Icons.add,
                            onPressed: () => _openEditor(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SummaryCard(
                                label: 'This week',
                                value: week.spending,
                                icon: Icons.date_range,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryCard(
                                label: S.thisMonth,
                                value: month.spending,
                                icon: Icons.calendar_month,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SoftCard(
                          color: AppColors.blueSoft,
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.primaryDark),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Personal spending never reduces your business profit.',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data.personalExpenses.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.receipt_long,
                      title: 'No personal spending yet',
                      message: S.noBudget,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                      child: SectionTitle(
                        title: 'Personal spending',
                        action: Text(
                          '${data.personalExpenses.length} records',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = data.personalExpenses[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: SoftCard(
                            padding: const EdgeInsets.all(14),
                            child: Dismissible(
                              key: ValueKey(expense.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async =>
                                  _deleteWithConfirm(expense),
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
                                    backgroundColor: AppColors.accentSoft,
                                    child: Text(
                                      Fmt.initials(expense.name),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    expense.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  subtitle: Text(Fmt.date(expense.date)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        Fmt.money(expense.amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: AppColors.primaryDark),
                                        onPressed: () =>
                                            _openEditor(expense: expense),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: data.personalExpenses.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
    );
  }

  Future<bool> _deleteWithConfirm(PersonalExpense expense) async {
    final store = context.read<DataStore>();
    final confirm = await confirmAction(
      context,
      title: S.confirmDelete,
      message: 'Delete personal expense "${expense.name}"?',
    );
    if (!confirm) return false;
    if (!mounted) return false;
    await store.deletePersonalExpense(expense.id);
    return true;
  }
}

class _ExpenseEditor extends StatefulWidget {
  final PersonalExpense? expense;

  const _ExpenseEditor({this.expense});

  @override
  State<_ExpenseEditor> createState() => _ExpenseEditorState();
}

class _ExpenseEditorState extends State<_ExpenseEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.expense?.name ?? '');
    _amount = TextEditingController(
      text: widget.expense == null ? '' : widget.expense!.amount.toString(),
    );
    _date = widget.expense?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final expense = PersonalExpense(
      id: widget.expense?.id ?? newId(),
      date: _date,
      dayKey: Fmt.dayKey(_date),
      name: _name.text.trim(),
      amount: double.parse(_amount.text.trim()),
    );
    await context.read<DataStore>().savePersonalExpense(expense);
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
                  widget.expense == null ? 'Add personal spending' : S.edit,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'What did you buy?'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name.'
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
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(label: S.save, onPressed: _save),
              ],
            ),
          ),
        ),
      );
}
