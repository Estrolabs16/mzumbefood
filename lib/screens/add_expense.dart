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

class AddExpenseScreen extends StatefulWidget {
  final String? expenseId;

  const AddExpenseScreen({super.key, this.expenseId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<DataProvider>();
    final existing = data.expenses
        .where((element) => element.id == widget.expenseId)
        .firstOrNull;
    if (existing != null) {
      _name.text = existing.name;
      _amount.text = existing.amount.toStringAsFixed(0);
      _note.text = existing.note;
      _date = existing.date;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = context.read<DataProvider>();
      final existing = data.expenses
          .where((element) => element.id == widget.expenseId)
          .firstOrNull;
      final expense = Expense(
        id: existing?.id ?? newId(),
        date: _date,
        dayKey: Fmt.dayKey(_date),
        name: _name.text.trim(),
        amount: double.parse(_amount.text.trim()),
        note: _note.text.trim(),
      );
      await context.read<DataStore>().saveExpense(expense);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId == null ? S.addExpense : '${S.edit} ${S.expenses}'),
      ),
      body: data.isLoading
          ? const Padding(
              padding: EdgeInsets.all(18),
              child: ShimmerList(count: 3),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                  children: [
                    if (data.expenseNames.isNotEmpty) ...[
                      const SectionTitle(title: 'Quick pick'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.expenseNames.take(12).map((name) {
                          return InputChip(
                            label: Text(name.name),
                            avatar: const Icon(Icons.local_offer, size: 16),
                            onPressed: () {
                              setState(() {
                                _name.text = name.name;
                                if (name.defaultAmount > 0) {
                                  _amount.text =
                                      name.defaultAmount.toStringAsFixed(0);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Expense name',
                        hintText: 'mafuta, electricity, wages...',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Please enter an expense name.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: S.amount,
                        prefixIcon: Icon(Icons.money),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value ?? '');
                        if (amount == null || amount <= 0) {
                          return 'Enter an amount greater than zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                const Text('Date',
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                                Text(
                                  Fmt.date(_date),
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _note,
                      decoration: const InputDecoration(
                        labelText: S.note,
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _saving
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                            label: '${S.save} ${S.expenses}',
                            onPressed: _save,
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
