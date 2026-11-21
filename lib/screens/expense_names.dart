import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/data/repository.dart';
import 'package:mzumbefood/data/store.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class ExpenseNamesScreen extends StatefulWidget {
  const ExpenseNamesScreen({super.key});

  @override
  State<ExpenseNamesScreen> createState() => _ExpenseNamesScreenState();
}

class _ExpenseNamesScreenState extends State<ExpenseNamesScreen> {
  Future<void> _openEditor({ExpenseName? name}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NameEditor(name: name),
    );
  }

  Future<void> _delete(ExpenseName name) async {
    final confirm = await confirmAction(
      context,
      title: S.confirmDelete,
      message: 'Remove "${name.name}" from saved expenses?',
    );
    if (!confirm) return;
    if (!mounted) return;
    await context.read<DataStore>().deleteExpenseName(name.id);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text(S.expenseNames)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add),
      ),
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.expenseNames.isEmpty
              ? const EmptyState(
                  icon: Icons.label_outline,
                  title: 'No saved expense names',
                  message:
                      'Names you use for expenses will be saved here for one-tap entry.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                  itemCount: data.expenseNames.length,
                  itemBuilder: (context, index) {
                    final name = data.expenseNames[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.blueSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.label,
                                  color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${Fmt.money(name.defaultAmount)} • used ${name.useCount} times',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppColors.primaryDark),
                              onPressed: () => _openEditor(name: name),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () => _delete(name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NameEditor extends StatefulWidget {
  final ExpenseName? name;

  const _NameEditor({this.name});

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name?.name ?? '');
    _amount = TextEditingController(
      text: widget.name == null ? '' : widget.name!.defaultAmount.toString(),
    );
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
    final name = ExpenseName(
      id: widget.name?.id ?? newId(),
      name: _name.text.trim(),
      defaultAmount: double.parse(_amount.text.trim()),
      useCount: widget.name?.useCount ?? 0,
    );
    await context.read<DataStore>().saveExpenseName(name);
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
                  widget.name == null ? 'Add expense name' : S.edit,
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
                      ? 'Enter a name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Default amount (TSh)'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount <= 0) return 'Enter an amount.';
                    return null;
                  },
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
