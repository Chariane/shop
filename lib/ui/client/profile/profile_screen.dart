import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import '../../../data/models/app_user.dart';
import '../../../providers/auth_providers.dart';
import 'sections/profile_header.dart';
import 'sections/profile_menu.dart';
import 'sections/profile_quick_actions.dart';
import 'sections/profile_recent_orders.dart';
import 'sections/profile_stats.dart';
import 'sections/profile_wallet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final profileName = user?.name ?? 'Alex Martin';
    final profileEmail = user?.email ?? 'alex@example.com';
    final avatarUrl = user?.avatarUrl ?? 'https://i.pravatar.cc/150?u=alex';

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: ProfileHeader(
                  name: profileName,
                  email: profileEmail,
                  avatarUrl: avatarUrl,
                  memberSince: 'mars 2023',
                  onEdit: () => _showEditProfileSheet(
                    context,
                    ref,
                    user,
                    profileName,
                    profileEmail,
                    avatarUrl,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: ProfileStats(ordersCount: 12),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 160),
                child: ProfileWallet(
                  points: 2450,
                  tier: 'Gold',
                  progressToNext: 0.65,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _sectionTitle(context, 'Actions rapides'),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 260),
                child: ProfileQuickActions(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: _sectionTitle(context, 'Commandes récentes'),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 360),
                child: ProfileRecentOrders(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 420),
                child: _sectionTitle(context, 'Préférences'),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 460),
                child: ProfileMenu(
                  onLogout: () => _handleLogout(context, ref),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'ShopHub v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    String currentName,
    String currentEmail,
    String currentAvatarUrl,
  ) {
    if (user?.isVendor ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Le profil boutique se modifiera depuis l’espace vendeur.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _EditProfileSheet(
          initialName: currentName,
          initialEmail: currentEmail,
          initialAvatarUrl: currentAvatarUrl,
          onSave: ({
            required String name,
            required String email,
            required String avatarUrl,
          }) {
            ref.read(authProvider.notifier).updateProfile(
                  name: name,
                  email: email,
                  avatarUrl: avatarUrl,
                );
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profil mis à jour'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref.read(authProvider.notifier).logout();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Déconnecté'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  margin: const EdgeInsets.all(AppSpacing.lg),
                ),
              );
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialAvatarUrl;
  final void Function({
    required String name,
    required String email,
    required String avatarUrl,
  }) onSave;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
    required this.initialAvatarUrl,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _avatarController = TextEditingController(text: widget.initialAvatarUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final avatarUrl = _avatarController.text.trim();

    widget.onSave(
      name: name.isEmpty ? widget.initialName : name,
      email: email.isEmpty ? widget.initialEmail : email,
      avatarUrl: avatarUrl.isEmpty ? widget.initialAvatarUrl : avatarUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Modifier le profil',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _avatarController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL de la photo',
                    prefixIcon: Icon(Icons.image_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
