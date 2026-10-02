import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../providers/platform_config_provider.dart';

enum _AuthPanel {
  login,
  client,
  shop,
  verifyEmail;
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPasswordController = TextEditingController();
  final _clientConfirmPasswordController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _shopEmailController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  String? _pendingVerificationEmail;

  _AuthPanel _panel = _AuthPanel.login;
  String _selectedCategory = 'Mode';

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPasswordController.dispose();
    _clientConfirmPasswordController.dispose();
    _ownerNameController.dispose();
    _shopEmailController.dispose();
    _shopNameController.dispose();
    _shopPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loginAsClient() async {
    try {
      await ref.read(authProvider.notifier).login(
            email: _clientEmailController.text.trim(),
            password: _clientPasswordController.text,
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loginAsDemoVendor() async {
    if (ref.read(platformConfigProvider).demoMode) {
      ref.read(authProvider.notifier).enterDemoVendor();
      return;
    }
    try {
      await ref.read(authProvider.notifier).login(
            email: 'contact@tech.bj',
            password: 'password',
          );
    } catch (error) {
      _showError(error);
    }
  }

  void _enterDemoClient() {
    if (ref.read(platformConfigProvider).demoMode) {
      ref.read(authProvider.notifier).enterDemoClient();
      return;
    }
    _showError(Exception(
        'Le mode démo est disponible lorsque le serveur est hors ligne.'));
  }

  Future<void> _createClientAccount() async {
    if (_clientPasswordController.text !=
        _clientConfirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    try {
      final email = _clientEmailController.text.trim();
      await ref.read(authProvider.notifier).register(
            name: _clientNameController.text.trim(),
            email: email,
            password: _clientPasswordController.text,
            role: UserRole.client,
          );
      setState(() {
        _pendingVerificationEmail = email;
        _verificationCodeController.clear();
        _panel = _AuthPanel.verifyEmail;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createShopAccount() async {
    try {
      final email = _shopEmailController.text.trim();
      await ref.read(authProvider.notifier).register(
            name: _ownerNameController.text.trim(),
            email: email,
            password: _shopPasswordController.text,
            role: UserRole.vendor,
            shopName: _shopNameController.text.trim(),
            category: _selectedCategory,
          );
      setState(() {
        _pendingVerificationEmail = email;
        _verificationCodeController.clear();
        _panel = _AuthPanel.verifyEmail;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _verifyEmail() async {
    final email = _pendingVerificationEmail;
    if (email == null) return;
    try {
      await ref.read(authProvider.notifier).verifyEmail(
            email: email,
            code: _verificationCodeController.text.trim(),
          );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _resendVerificationCode([String? emailInput]) async {
    final email = (emailInput ?? _pendingVerificationEmail ?? '').trim();
    if (email.isEmpty) {
      _showError('Saisissez votre adresse email.');
      return;
    }
    try {
      await ref
          .read(authProvider.notifier)
          .resendVerificationCode(email: email);
      if (!mounted) return;
      setState(() {
        _pendingVerificationEmail = email;
        _panel = _AuthPanel.verifyEmail;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Si le compte attend une confirmation, un code sera envoyé si un renvoi est disponible.')),
      );
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref
        .watch(platformConfigProvider)
        .categories
        .map((category) => category.name)
        .toList();
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : (categories.isEmpty ? '' : categories.first);
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: [
            _AuthHero(),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<_AuthPanel>(
              segments: const [
                ButtonSegment(
                  value: _AuthPanel.login,
                  icon: Icon(Icons.login_rounded),
                  label: Text('Connexion'),
                ),
                ButtonSegment(
                  value: _AuthPanel.client,
                  icon: Icon(Icons.person_add_alt_1_rounded),
                  label: Text('Compte client'),
                ),
                ButtonSegment(
                  value: _AuthPanel.shop,
                  icon: Icon(Icons.storefront_rounded),
                  label: Text('Boutique'),
                ),
              ],
              selected: {
                _panel == _AuthPanel.verifyEmail ? _AuthPanel.login : _panel
              },
              onSelectionChanged: (selection) {
                setState(() => _panel = selection.first);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _panel == _AuthPanel.login
                  ? _ClientLoginForm(
                      key: const ValueKey('client-login'),
                      emailController: _clientEmailController,
                      passwordController: _clientPasswordController,
                      onLogin: _loginAsClient,
                      onDemoVendor: _loginAsDemoVendor,
                      onDemoClient: _enterDemoClient,
                      onResendVerification: () =>
                          _resendVerificationCode(_clientEmailController.text),
                      onCreateShop: () {
                        setState(() => _panel = _AuthPanel.shop);
                      },
                      onCreateClient: () {
                        setState(() => _panel = _AuthPanel.client);
                      },
                    )
                  : _panel == _AuthPanel.verifyEmail
                      ? _EmailVerificationForm(
                          key: const ValueKey('verify-email'),
                          email: _pendingVerificationEmail ?? '',
                          codeController: _verificationCodeController,
                          onVerify: _verifyEmail,
                          onResend: _resendVerificationCode,
                          onBack: () =>
                              setState(() => _panel = _AuthPanel.login),
                        )
                      : _panel == _AuthPanel.client
                          ? _ClientSignupForm(
                              key: const ValueKey('client-signup'),
                              nameController: _clientNameController,
                              emailController: _clientEmailController,
                              passwordController: _clientPasswordController,
                              confirmPasswordController:
                                  _clientConfirmPasswordController,
                              onCreateAccount: _createClientAccount,
                            )
                          : _ShopSignupForm(
                              key: const ValueKey('shop-signup'),
                              ownerNameController: _ownerNameController,
                              emailController: _shopEmailController,
                              shopNameController: _shopNameController,
                              passwordController: _shopPasswordController,
                              selectedCategory: selectedCategory,
                              categories: categories,
                              onCategoryChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedCategory = value);
                              },
                              onCreateShop: _createShopAccount,
                              onDemoVendor: _loginAsDemoVendor,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthHero extends ConsumerWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref
            .watch(platformConfigProvider)
            .featuredSlides
            .firstOrNull
            ?.imageUrl ??
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.76),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'ShopHub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Connectez-vous ou ouvrez votre boutique en quelques secondes.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailVerificationForm extends StatelessWidget {
  final String email;
  final TextEditingController codeController;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _EmailVerificationForm({
    super.key,
    required this.email,
    required this.codeController,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vérifiez votre adresse email',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
              'Saisissez le code envoyé à $email. Il reste valable 10 minutes.'),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Code à 6 chiffres',
              prefixIcon: Icon(Icons.mark_email_read_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onVerify,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Confirmer mon adresse'),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: onResend, child: const Text('Renvoyer le code')),
          ),
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }
}

class _ClientLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onDemoVendor;
  final VoidCallback onDemoClient;
  final VoidCallback onResendVerification;
  final VoidCallback onCreateShop;
  final VoidCallback onCreateClient;

  const _ClientLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onDemoVendor,
    required this.onDemoClient,
    required this.onResendVerification,
    required this.onCreateShop,
    required this.onCreateClient,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connexion client',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Accédez à vos commandes, favoris et livraisons.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded),
              label: const Text('Se connecter'),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onResendVerification,
              child: const Text('Renvoyer un code de vérification'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onDemoClient,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Explorer la démo client'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onDemoVendor,
            icon: const Icon(Icons.store_mall_directory_rounded),
            label: const Text('Explorer l’espace vendeur'),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton.icon(
            onPressed: onCreateClient,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Créer un compte client'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ShopInviteCard(onTap: onCreateShop),
        ],
      ),
    );
  }
}

class _ClientSignupForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onCreateAccount;
  final _formKey = GlobalKey<FormState>();

  _ClientSignupForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onCreateAccount,
  });

  Widget build(BuildContext context) {
    return _AuthCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Créer un compte client',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Inscrivez-vous pour commander et suivre vos achats.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Saisissez votre nom.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: Icon(Icons.mail_rounded),
              ),
              validator: (value) =>
                  value == null || !value.contains('@') || !value.contains('.')
                      ? 'Saisissez une adresse email valide.'
                      : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe (8 caractères minimum)',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
              validator: (value) => value == null || value.length < 8
                  ? 'Le mot de passe doit contenir au moins 8 caractères.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) => value != passwordController.text
                  ? 'Les mots de passe ne correspondent pas.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) onCreateAccount();
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Créer mon compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopSignupForm extends StatelessWidget {
  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController shopNameController;
  final TextEditingController passwordController;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onCreateShop;
  final VoidCallback onDemoVendor;

  const _ShopSignupForm({
    super.key,
    required this.ownerNameController,
    required this.emailController,
    required this.shopNameController,
    required this.passwordController,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onCreateShop,
    required this.onDemoVendor,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Créer un compte boutique',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Présentez votre entreprise, vendez vos produits et suivez vos commandes.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: ownerNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du responsable',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email professionnel',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: shopNameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la boutique',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe (8 caractères minimum)',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: onCategoryChanged,
            decoration: const InputDecoration(
              labelText: 'Catégorie principale',
              prefixIcon: Icon(Icons.category_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreateShop,
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Créer ma boutique'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onDemoVendor,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Voir une boutique'),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final Widget child;

  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: context.softShadow,
      ),
      child: child,
    );
  }
}

class _ShopInviteCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ShopInviteCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_business_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous avez une boutique ?',
                    style: TextStyle(
                      color: context.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Créez un compte entreprise et commencez à vendre.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
