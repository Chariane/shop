import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';
import '../../../providers/auth_providers.dart';
import 'sections/profile_header.dart';
import 'sections/profile_menu.dart';
import 'sections/profile_quick_actions.dart';
import 'sections/profile_recent_orders.dart';
import 'sections/profile_stats.dart';
import '../../../providers/orders_providers.dart';
import '../../../providers/notification_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final ordersAsync = ref.watch(myOrdersProvider);
    final profileName = user?.name ?? '';
    final profileEmail = user?.email ?? '';
    final avatarUrl = user?.avatarUrl ?? '';

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
                  memberSince: _memberSince(user?.createdAt),
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
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: ProfileStats(
                    ordersCount: ordersAsync.valueOrNull?.length ?? 0,
                    loyaltyPoints:
                        ref.watch(loyaltyPointsProvider).valueOrNull ?? 0),
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
              FadeSlideIn(
                delay: const Duration(milliseconds: 360),
                child: ProfileRecentOrders(
                    orders: ordersAsync.valueOrNull ?? const [],
                    isLoading: ordersAsync.isLoading,
                    hasError: ordersAsync.hasError),
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

  String _memberSince(DateTime? createdAt) {
    if (createdAt == null) return 'Date indisponible';
    final date = createdAt.toLocal();
    return '${date.month.toString().padLeft(2, '0')}/${date.year}';
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
          onUploadAvatar: (file) =>
              ref.read(marketplaceApiProvider).uploadProfileImage(file),
          onSave: ({
            required String name,
            required String email,
            required String avatarUrl,
          }) async {
            try {
              await ref.read(authProvider.notifier).updateProfile(
                    name: name,
                    email: email,
                    avatarUrl: avatarUrl,
                  );
              if (!sheetContext.mounted) return;
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
            } catch (error) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(
                    content: Text(error.toString()),
                    backgroundColor: AppColors.danger),
              );
            }
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
  final Future<String> Function(XFile file) onUploadAvatar;
  final Future<void> Function({
    required String name,
    required String email,
    required String avatarUrl,
  }) onSave;

  const _EditProfileSheet({
    required this.initialName,
    required this.initialEmail,
    required this.initialAvatarUrl,
    required this.onUploadAvatar,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La photo doit faire 5 Mo maximum.')),
      );
      return;
    }
    setState(() {
      _selectedAvatar = file;
      _avatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    try {
      final avatarUrl = _selectedAvatar == null
          ? widget.initialAvatarUrl
          : await widget.onUploadAvatar(_selectedAvatar!);
      await widget.onSave(
        name: name.isEmpty ? widget.initialName : name,
        email: email.isEmpty ? widget.initialEmail : email,
        avatarUrl: avatarUrl,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString()), backgroundColor: AppColors.danger),
      );
    }
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!) as ImageProvider<Object>
                          : widget.initialAvatarUrl.isNotEmpty
                              ? NetworkImage(widget.initialAvatarUrl)
                                  as ImageProvider<Object>
                              : null,
                      child: _avatarBytes == null &&
                              widget.initialAvatarUrl.isEmpty
                          ? const Icon(Icons.person_rounded, size: 30)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_selectedAvatar == null
                            ? 'Choisir une photo'
                            : 'Changer la photo'),
                      ),
                    ),
                  ],
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
