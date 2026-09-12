import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shophub/main.dart';

void main() {
  testWidgets('L\'app démarre correctement', (WidgetTester tester) async {
    // On lance l'app dans un ProviderScope
    await tester.pumpWidget(const ProviderScope(child: ShopHubApp()));

    // Le premier frame s'affiche (avant le chargement des données)
    expect(find.byType(MaterialApp), findsOneWidget);

    // On attend la fin des futures (fake API) + les animations
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // L'app doit être montée sans crash
    expect(find.byType(Scaffold), findsWidgets);
  });
}