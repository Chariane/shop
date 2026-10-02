import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/storage/api_cache_store.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'ui/auth/app_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(HiveApiCacheStore.boxName);
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
      home: const AppGate(),
    );
  }
}
