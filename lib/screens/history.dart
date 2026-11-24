import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mzumbefood/core/format.dart';
import 'package:mzumbefood/core/logic.dart';
import 'package:mzumbefood/core/strings.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/models/models.dart';
import 'package:mzumbefood/providers.dart';
import 'package:mzumbefood/widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  String _filter = S.all;
  String _period = S.all;
  String _search = '';
  bool _showPayments = true;
  bool _showMishkaki = true;
  bool _showPersonal = false;

  void _changeMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
        _selectedDay = null;
      });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final records = _buildRecords(data);
    final filtered = records.where((record) {
      if (_selectedDay != null && !Fmt.sameDay(record.date, _selectedDay!)) {
        return false;
      }
      if (_selectedDay == null && _period != S.all) {
        final now = DateTime.now();
        if (_period == S.thisWeek &&
            !Fmt.inRange(record.date, Fmt.startOfWeek(now), Fmt.endOfWeek(now))) {
          return false;
        }
        if (_period == S.thisMonth &&
            !Fmt.inRange(
                record.date, Fmt.startOfMonth(now), Fmt.endOfMonth(now))) {
          return false;
        }
      }
      if (_filter == S.sales && record.type != 'sale') return false;
      if (_filter == S.expenses && record.type != 'expense') return false;
      if (_search.isNotEmpty) {
        final query = _search.toLowerCase();
        if (!record.title.toLowerCase().contains(query) &&
            !record.subtitle.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    final grouped = <String, List<_Record>>{};
    for (final record in filtered) {
      grouped.putIfAbsent(Fmt.dayKey(record.date), () => []).add(record);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      body: data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GradientHeader(
                    title: S.history,
                    subtitle: 'Every sale and expense in one place',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () => setState(() => _selectedDay = null),
                      ),
                    ],
                    child: _Calendar(
                      month: _month,
                      selectedDay: _selectedDay,
                      sales: data.sales.map((e) => e.dayKey).toList(),
                      expenses: data.expenses.map((e) => e.dayKey).toList(),
                      payments:
                          data.debtPayments.map((e) => e.dayKey).toList(),
                      mishkaki: data.mishkakiSales.map((e) => e.dayKey).toList(),
                      onDaySelected: (day) => setState(() => _selectedDay = day),
                      onPrevious: () => _changeMonth(-1),
                      onNext: () => _changeMonth(1),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) => setState(() => _search = value),
                          decoration: const InputDecoration(
                            hintText: S.search,
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        if (_selectedDay != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => context.push(
                                '/add-sale?date=${Fmt.dayKey(_selectedDay!)}',
                              ),
                              icon: const Icon(Icons.add_shopping_cart),
                              label: const Text('Add sale for this day'),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [S.all, S.sales, S.expenses]
                                .map(
                                  (filter) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(filter),
                                      selected: _filter == filter,
                                      onSelected: (_) =>
                                          setState(() => _filter = filter),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [S.all, S.thisWeek, S.thisMonth]
                                .map(
                                  (period) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(period),
                                      selected: _period == period,
                                      onSelected: (_) =>
                                          setState(() => _period = period),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: [
                            _Toggle(
                              label: S.debtPayments,
                              value: _showPayments,
                              onChanged: (value) =>
                                  setState(() => _showPayments = value),
                            ),
                            _Toggle(
                              label: S.mishkaki,
                              value: _showMishkaki,
                              onChanged: (value) =>
                                  setState(() => _showMishkaki = value),
                            ),
                            _Toggle(
                              label: 'Personal',
                              value: _showPersonal,
                              onChanged: (value) =>
                                  setState(() => _showPersonal = value),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.history,
                      title: 'No records found',
                      message: 'Try another filter or add a sale to get started.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = keys[index];
                        final dayRecords = grouped[key]!;
                        final day = Fmt.parseDayKey(key);
                        final dayTotals = totalsFor(
                          sales: dayRecords
                              .where((r) => r.type == 'sale')
                              .map((r) => r.sale!)
                              .toList(),
                          expenses: dayRecords
                              .where((r) => r.type == 'expense')
                              .map((r) => r.expense!)
                              .toList(),
                          mishkaki: dayRecords
                              .where((r) => r.type == 'mishkaki')
                              .map((r) => r.mishkaki!)
                              .toList(),
                          payments: dayRecords
                              .where((r) => r.type == 'payment')
                              .map((r) => r.payment!)
                              .toList(),
                        );
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Fmt.date(day),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${Fmt.money(dayTotals.revenue)} in • ${Fmt.money(dayTotals.expenses)} out',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...dayRecords.map(
                                (record) => _RecordTile(record: record),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04);
                      },
                      childCount: keys.length,
                    ),
                  ),
              ],
            ),
    );
  }

  List<_Record> _buildRecords(DataProvider data) {
    final records = <_Record>[];
    for (final sale in data.sales) {
      records.add(
        _Record(
          date: sale.date,
          type: 'sale',
          title: sale.itemSummary,
          subtitle:
              '${sale.note.isEmpty ? S.sales : sale.note} • ${Fmt.dateTime(sale.createdAt)}',
          amount: sale.total,
          color: AppColors.primaryDark,
          icon: Icons.shopping_bag,
          sale: sale,
        ),
      );
    }
    for (final expense in data.expenses) {
      records.add(
        _Record(
          date: expense.date,
          type: 'expense',
          title: expense.name,
          subtitle:
              '${expense.note.isEmpty ? S.expenses : expense.note} • ${Fmt.dateTime(expense.date)}',
          amount: expense.amount,
          color: AppColors.accent,
          icon: Icons.receipt_long,
          expense: expense,
        ),
      );
    }
    if (_showPayments) {
      for (final payment in data.debtPayments) {
        records.add(
          _Record(
            date: payment.date,
            type: 'payment',
            title: S.debtPayments,
            subtitle:
                '${payment.customer}${payment.note.isEmpty ? '' : ' • ${payment.note}'} • ${Fmt.dateTime(payment.date)}',
            amount: payment.amount,
            color: AppColors.success,
            icon: Icons.payments,
            payment: payment,
          ),
        );
      }
    }
    if (_showMishkaki) {
      for (final item in data.mishkakiSales) {
        records.add(
          _Record(
            date: item.date,
            type: 'mishkaki',
            title: item.type,
            subtitle:
                '${Fmt.number(item.sticksSold)} sticks${item.note.isEmpty ? '' : ' • ${item.note}'} • ${Fmt.dateTime(item.date)}',
            amount: item.revenue,
            color: AppColors.primary,
            icon: Icons.kebab_dining,
            mishkaki: item,
          ),
        );
      }
    }
    if (_showPersonal) {
      for (final item in data.personalExpenses) {
        records.add(
          _Record(
            date: item.date,
            type: 'personal',
            title: 'Personal: ${item.name}',
            subtitle: 'Not included in business profit',
            amount: item.amount,
            color: AppColors.muted,
            icon: Icons.person,
          ),
        );
      }
      for (final item in data.personalIncome) {
        records.add(
          _Record(
            date: item.date,
            type: 'personal',
            title: 'Personal income: ${item.source}',
            subtitle: 'Not included in business revenue',
            amount: item.amount,
            color: AppColors.muted,
            icon: Icons.person,
          ),
        );
      }
    }
    return records;
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 155,
        child: Material(
          color: Colors.transparent,
          child: SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: value,
            onChanged: onChanged,
            title: Text(label, style: const TextStyle(fontSize: 12)),
            activeThumbColor: AppColors.accent,
          ),
        ),
      );
}

class _Calendar extends StatelessWidget {
  final DateTime month;
  final DateTime? selectedDay;
  final List<String> sales;
  final List<String> expenses;
  final List<String> payments;
  final List<String> mishkaki;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _Calendar({
    required this.month,
    required this.selectedDay,
    required this.sales,
    required this.expenses,
    required this.payments,
    required this.mishkaki,
    required this.onDaySelected,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
   final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = <Widget>[
      ...List.generate(
        leading,
        (_) => const SizedBox(height: 42),
      ),
      ...List.generate(daysInMonth, (index) {
        final day = DateTime(month.year, month.month, index + 1);
        final key = Fmt.dayKey(day);
        final selected = selectedDay != null && Fmt.sameDay(day, selectedDay!);
        final hasSale = sales.contains(key) ||
            payments.contains(key) ||
            mishkaki.contains(key);
        final hasExpense = expenses.contains(key);
        return GestureDetector(
          onTap: () => onDaySelected(day),
          child: Container(
            height: 42,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? null : Colors.transparent,
              gradient: selected ? AppColors.brandGradient : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x334A9FC8),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSale)
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: selected ? Colors.white : AppColors.primaryDark,
                      ),
                    if (hasExpense)
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_monthName(month.month)} ${month.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const Row(
          children: [
            _WeekDay('M'),
            _WeekDay('T'),
            _WeekDay('W'),
            _WeekDay('T'),
            _WeekDay('F'),
            _WeekDay('S'),
            _WeekDay('S'),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }

  String _monthName(int month) => [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];
}

class _WeekDay extends StatelessWidget {
  final String label;

  const _WeekDay(this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
}

class _Record {
  final DateTime date;
  final String type;
  final String title;
  final String subtitle;
  final double amount;
  final Color color;
  final IconData icon;
  final Sale? sale;
  final Expense? expense;
  final DebtPayment? payment;
  final MishkakiSale? mishkaki;

  _Record({
    required this.date,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.icon,
    this.sale,
    this.expense,
    this.payment,
    this.mishkaki,
  });
}

class _RecordTile extends StatelessWidget {
  final _Record record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () {
          if (record.sale != null) {
            context.push('/add-sale?id=${record.sale!.id}');
          } else if (record.expense != null) {
            context.push('/add-expense?id=${record.expense!.id}');
          } else if (record.mishkaki != null) {
            context.push('/mishkaki');
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: record.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(record.icon, color: record.color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    record.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.money(record.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: record.color,
                    fontSize: 13,
                  ),
                ),
                if (record.sale != null ||
                    record.expense != null ||
                    record.mishkaki != null)
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ],
        ),
      );
}
