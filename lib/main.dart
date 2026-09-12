import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'ui/client/client_shell.dart';

void main() {
  runApp(const ProviderScope(child: ShopHubApp()));
}

class ShopHubApp extends ConsumerWidget {
  const ShopHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ShopHub',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const ClientShell(),
    );
  }
}