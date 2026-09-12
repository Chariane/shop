import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/datasources/mocks/vendors_mock.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';

enum _AuthPanel {
  login,
  shop;
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _clientEmailController =
      TextEditingController(text: 'alex@example.com');
  final _clientPasswordController = TextEditingController(text: 'password');
  final _ownerNameController = TextEditingController(text: 'Nadège Zannou');
  final _shopEmailController =
      TextEditingController(text: 'contact@boutique.bj');
  final _shopNameController = TextEditingController(text: 'Ma Boutique BJ');

  _AuthPanel _panel = _AuthPanel.login;
  String _selectedCategory = 'Mode';

  static const _categories = [
    'Mode',
    'Tech',
    'Maison',
    'Beauté',
    'Alimentation',
    'Artisanat',
  ];

  @override
  void dispose() {
    _clientEmailController.dispose();
    _clientPasswordController.dispose();
    _ownerNameController.dispose();
    _shopEmailController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _loginAsClient() {
    final email = _clientEmailController.text.trim();
    ref.read(authProvider.notifier).loginAsClient(
          email: email.isEmpty ? 'alex@example.com' : email,
        );
  }

  void _loginAsDemoVendor() {
    ref.read(authProvider.notifier).loginAsVendor(VendorsMock.vendor1);
  }

  void _createShopAccount() {
    final ownerName = _ownerNameController.text.trim();
    final email = _shopEmailController.text.trim();
    final shopName = _shopNameController.text.trim();

    final auth = ref.read(authProvider.notifier);
    auth.registerVendorAccount(
      ownerName: ownerName.isEmpty ? 'Propriétaire boutique' : ownerName,
      email: email.isEmpty ? 'contact@boutique.bj' : email,
      shopName: shopName.isEmpty ? 'Nouvelle boutique' : shopName,
      category: _selectedCategory,
    );
    final vendor = ref.read(authProvider);
    if (vendor != null) {
      ref.read(vendorsProvider.notifier).upsertVendor(vendor);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const _AuthHero(),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<_AuthPanel>(
              segments: const [
                ButtonSegment(
                  value: _AuthPanel.login,
                  icon: Icon(Icons.login_rounded),
                  label: Text('Connexion'),
                ),
                ButtonSegment(
                  value: _AuthPanel.shop,
                  icon: Icon(Icons.storefront_rounded),
                  label: Text('Boutique'),
                ),
              ],
              selected: {_panel},
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
                      onCreateShop: () {
                        setState(() => _panel = _AuthPanel.shop);
                      },
                    )
                  : _ShopSignupForm(
                      key: const ValueKey('shop-signup'),
                      ownerNameController: _ownerNameController,
                      emailController: _shopEmailController,
                      shopNameController: _shopNameController,
                      selectedCategory: _selectedCategory,
                      categories: _categories,
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

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  static const _image =
      'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _image,
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

class _ClientLoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onDemoVendor;
  final VoidCallback onCreateShop;

  const _ClientLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onDemoVendor,
    required this.onCreateShop,
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
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onDemoVendor,
            icon: const Icon(Icons.store_mall_directory_rounded),
            label: const Text('Explorer l’espace vendeur'),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ShopInviteCard(onTap: onCreateShop),
        ],
      ),
    );
  }
}

class _ShopSignupForm extends StatelessWidget {
  final TextEditingController ownerNameController;
  final TextEditingController emailController;
  final TextEditingController shopNameController;
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
