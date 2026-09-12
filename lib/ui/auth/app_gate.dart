import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_providers.dart';
import '../client/client_shell.dart';
import '../vendor/vendor_shell.dart';
import 'auth_screen.dart';

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const AuthScreen();
    }

    if (user.isVendor) {
      return const VendorShell();
    }

    return const ClientShell();
  }
}
