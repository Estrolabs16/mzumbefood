import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mzumbefood/core/theme.dart';
import 'package:mzumbefood/widgets/common.dart';

void main() {
  testWidgets('shared header renders title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientHeader(title: 'Home', subtitle: 'MU Food Delivery'),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('MU Food Delivery'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
  });

  testWidgets('empty state shows its action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EmptyState(
            icon: Icons.restaurant,
            title: 'Nothing here',
            message: 'Add your first record.',
            actionLabel: 'Add',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add your first record.'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
  });
}
