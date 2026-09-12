import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_user.dart';

/// ==========================================================
/// [PROVIDER #5] Utilisateur connecté
/// ==========================================================
/// StateNotifier<AppUser?> : null = déconnecté
class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  void loginAsClient() {
    state = const AppUser(
      id: 'c1',
      name: 'Alex Martin',
      email: 'alex@example.com',
      role: UserRole.client,
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
    );
  }

  void loginAsVendor(AppUser vendor) => state = vendor;

  void logout() => state = null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

/// [PROVIDER #6] Est-on connecté ?
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

/// [PROVIDER #7] Est-on vendeur ?
final isVendorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider)?.isVendor ?? false;
});