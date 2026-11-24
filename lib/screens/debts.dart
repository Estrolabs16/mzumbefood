import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  int _tab = 0;
  DebtDirection _direction = DebtDirection.theyOweMe;

  Future<void> _openAdd() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DebtEditor(initialDirection: _direction),
    );
  }

  Future<void> _openPayment(Debt debt, double remaining) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentEditor(debt: debt, remaining: remaining),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final theyOwe = outstandingDebtFor(
      data.debts,
      data.debtPayments,
      DebtDirection.theyOweMe,
    );
    final iOwe = outstandingDebtFor(
      data.debts,
      data.debtPayments,
      DebtDirection.iOweThem,
    );
    final now = DateTime.now();
    final matching = data.debts
        .where((debt) => debt.direction == _direction)
        .toList();
    final unpaid = matching.where((debt) => !debt.paid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paid = matching.where((debt) => debt.paid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final list = _tab == 0 ? unpaid : paid;

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.debts,
                    subtitle: _direction == DebtDirection.theyOweMe
                        ? 'Track who still owes you'
                        : 'Track what you still owe',
                    child: SoftCard(
                      color: AppColors.accentSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.theyOweYou,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    CountUpText(
                                      value: theyOwe,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 42,
                                color: AppColors.line,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      S.youOwe,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    CountUpText(
                                      value: iOwe,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            label: 'Add debt',
                            icon: Icons.person_add,
                            onPressed: _openAdd,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.04, duration: 320.ms),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(S.theyOweMe),
                            selected: _direction == DebtDirection.theyOweMe,
                            onSelected: (_) => setState(
                              () => _direction = DebtDirection.theyOweMe,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(S.iOweThem),
                            selected: _direction == DebtDirection.iOweThem,
                            onSelected: (_) => setState(
                              () => _direction = DebtDirection.iOweThem,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text(S.unpaid),
                            selected: _tab == 0,
                            onSelected: (_) => setState(() => _tab = 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text(S.paid),
                            selected: _tab == 1,
                            onSelected: (_) => setState(() => _tab = 1),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04),
                  ),
                ),
                if (list.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: _tab == 0 ? Icons.volunteer_activism : Icons.check_circle,
                      title: _tab == 0
                          ? (_direction == DebtDirection.theyOweMe
                              ? 'No one owes you'
                              : 'You owe nothing')
                          : 'No paid debts yet',
                      message: _tab == 0
                          ? (_direction == DebtDirection.theyOweMe
                              ? S.noDebts
                              : 'You have no outstanding payments to make.')
                          : 'Paid debts will appear here.',
                      actionLabel: _tab == 0 ? 'Add debt' : null,
                      onAction: _tab == 0 ? _openAdd : null,
                    ).animate().fadeIn(duration: 300.ms),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = list[index];
                        final paidAmount = paidForDebt(debt.id, data.debtPayments);
                        final remaining = debt.amount - paidAmount;
                        final overdue = debt.isOverdue(now, paidAmount);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              key: ValueKey(debt.id),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: overdue
                                          ? AppColors.accentSoft
                                          : AppColors.blueSoft,
                                      child: Text(
                                        Fmt.initials(debt.customer),
                                        style: TextStyle(
                                          color: overdue
                                              ? AppColors.accent
                                              : AppColors.primaryDark,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            debt.customer,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.ink,
                                              fontSize: 17,
                                            ),
                                          ),
                                          Text(
                                            debt.reason.isEmpty
                                                ? Fmt.date(debt.createdAt)
                                                : debt.reason,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            debt.direction ==
                                                    DebtDirection.theyOweMe
                                                ? S.theyOweMe
                                                : S.iOweThem,
                                            style: TextStyle(
                                              color: debt.direction ==
                                                      DebtDirection.theyOweMe
                                                  ? AppColors.primaryDark
                                                  : AppColors.danger,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      Fmt.money(remaining > 0 ? remaining : 0),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: overdue
                                            ? AppColors.danger
                                            : AppColors.accent,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (overdue)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentSoft,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Overdue • due ${Fmt.date(debt.deadline!)}',
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (paidAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: LinearProgressIndicator(
                                      value: (paidAmount / debt.amount).clamp(0, 1),
                                      minHeight: 8,
                                      backgroundColor: AppColors.blueSoft,
                                      color: AppColors.success,
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                if (!debt.paid) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: remaining <= 0
                                              ? null
                                              : () =>
                                                  _openPayment(debt, remaining),
                                          child: const Text(S.partialPayment),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: PrimaryButton(
                                          label: S.markPaid,
                                          color: AppColors.success,
                                          onPressed: () async {
                                            final store = context.read<DataStore>();
                                            final confirm = await confirmAction(
                                              context,
                                              title: S.markPaid,
                                              message: debt.direction ==
                                                      DebtDirection.theyOweMe
                                                  ? 'Mark ${debt.customer}\'s debt as paid?'
                                                  : 'Mark your debt to ${debt.customer} as paid?',
                                            );
                                            if (!confirm || remaining <= 0) return;
                                            await store.recordDebtPayment(
                                                  debt,
                                                  DebtPayment(
                                                    id: newId(),
                                                    debtId: debt.id,
                                                    customer: debt.customer,
                                                    amount: remaining,
                                                    date: DateTime.now(),
                                                    dayKey: Fmt.dayKey(DateTime.now()),
                                                    note: 'Marked as paid',
                                                    direction: debt.direction,
                                                  ),
                                                );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (debt.phone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      '📞 ${debt.phone}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                               ],
                             ),
                           )
                               .animate()
                               .fadeIn(
                                 delay: (index % 6 * 30).ms,
                                 duration: 280.ms,
                               )
                               .slideY(begin: 0.03, duration: 280.ms),
                         );
                       },
                      childCount: list.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
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

class _DebtEditor extends StatefulWidget {
  final DebtDirection initialDirection;

  const _DebtEditor({required this.initialDirection});

  @override
  State<_DebtEditor> createState() => _DebtEditorState();
}

class _DebtEditorState extends State<_DebtEditor> {
  final _formKey = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _phone = TextEditingController();
  late DebtDirection _direction = widget.initialDirection;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _customer.dispose();
    _amount.dispose();
    _reason.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final debt = Debt(
      id: newId(),
      customer: _customer.text.trim(),
      phone: _phone.text.trim(),
      reason: _reason.text.trim(),
      amount: double.parse(_amount.text.trim()),
      createdAt: now,
      dayKey: Fmt.dayKey(now),
      deadline: _deadline,
      paid: false,
      direction: _direction,
    );
    await context.read<DataStore>().saveDebt(debt);
    if (mounted) {
      showSuccess(context);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => _sheet(
        context: context,
        title: 'Add debt',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(S.theyOweMe),
                      selected: _direction == DebtDirection.theyOweMe,
                      onSelected: (_) =>
                          setState(() => _direction = DebtDirection.theyOweMe),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(S.iOweThem),
                      selected: _direction == DebtDirection.iOweThem,
                      onSelected: (_) =>
                          setState(() => _direction = DebtDirection.iOweThem),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customer,
                decoration: InputDecoration(
                  labelText: _direction == DebtDirection.theyOweMe
                      ? S.customer
                      : S.personName,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a customer name.'
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
                controller: _reason,
                decoration: const InputDecoration(labelText: 'Reason or items'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: S.phone),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2036),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: S.deadline),
                  child: Text(_deadline == null ? 'Optional' : Fmt.date(_deadline!)),
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

class _PaymentEditor extends StatefulWidget {
  final Debt debt;
  final double remaining;

  const _PaymentEditor({required this.debt, required this.remaining});

  @override
  State<_PaymentEditor> createState() => _PaymentEditorState();
}

class _PaymentEditorState extends State<_PaymentEditor> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<DataStore>().recordDebtPayment(
          widget.debt,
          DebtPayment(
            id: newId(),
            debtId: widget.debt.id,
            customer: widget.debt.customer,
            amount: double.parse(_amount.text.trim()),
            date: _date,
            dayKey: Fmt.dayKey(_date),
            note: _note.text.trim(),
            direction: widget.debt.direction,
          ),
        );
    if (mounted) {
      showSuccess(context);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => _sheet(
        context: context,
        title: '${S.partialPayment} • ${widget.debt.customer}',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Remaining: ${Fmt.money(widget.remaining)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: S.amount),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter an amount.';
                  if (amount > widget.remaining) {
                    return 'More than the remaining balance.';
                  }
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
                  decoration: const InputDecoration(labelText: 'Date received'),
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
