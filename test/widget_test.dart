import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shophub/main.dart';

void main() {
  testWidgets('L\'app démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShopHubApp()));

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(Scaffold), findsWidgets);
  });
}
