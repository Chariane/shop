# ShopHub

ShopHub est une application e-commerce multivendeur réalisée avec Flutter et Riverpod. Elle propose un parcours client complet, un espace vendeur, un catalogue de produits, un panier, des favoris persistés localement, un checkout avec livraison, des notifications et des écrans de profil.

## Fonctionnalités

- Catalogue de produits avec liste, recherche, filtres, tri et page détail.
- Panier avec ajout, suppression, modification des quantités et total dynamique.
- Favoris persistés localement avec `SharedPreferences`.
- Profil utilisateur avec modification des informations, statistiques et actions rapides.
- Authentification locale avec distinction client et vendeur.
- Création de compte boutique depuis les écrans d'authentification.
- Page publique boutique visible par les clients.
- Dashboard vendeur avec indicateurs, gestion produits, stock, visibilité et commandes.
- Checkout avec adresse, modes de livraison et récapitulatif.
- Notifications utilisateur accessibles depuis le profil.
- Animations sur l'ajout au panier et transitions d'interface.

## Stack Technique

- Flutter
- Riverpod avec `StateNotifierProvider`, `Provider`, `Provider.family`, `StateProvider`
- `AsyncValue` pour les données asynchrones
- `SharedPreferences` pour la persistance locale des favoris
- `google_fonts` pour la typographie

## Architecture

Le projet suit une organisation en couches afin de séparer la logique métier des widgets.

```text
lib/
  core/
    animations.dart
    theme.dart
    theme_provider.dart
  data/
    datasources/
      marketplace_api.dart
      mocks/
    models/
    repositories/
  providers/
  ui/
    auth/
    client/
    vendor/
    widgets/
```

### `core`

Contient les éléments transverses de l'application : thème clair/sombre, couleurs, espacements, animations et transitions.

### `data`

Contient les modèles, les sources de données locales et les repositories.

- `models/` : `Product`, `CartItem`, `AppUser`, `Order`, `DeliveryOption`, `AppNotification`, `VendorOrder`.
- `datasources/` : source locale qui fournit les produits et boutiques.
- `repositories/` : abstraction d'accès aux données, notamment pour les produits, commandes et favoris.

### `providers`

Contient toute la logique d'état de l'application avec Riverpod. Les widgets consomment ces providers au lieu de porter directement la logique métier.

### `ui`

Contient les interfaces :

- `auth/` : connexion client, création boutique, redirection selon le rôle.
- `client/` : accueil, catalogue, panier, checkout, profil, notifications, page boutique.
- `vendor/` : dashboard boutique, produits, commandes, profil public de la boutique.
- `widgets/` : composants réutilisables.

## Providers Riverpod

### Produits

- `marketplaceApiProvider` : fournit la source de données locale.
- `productRepositoryProvider` : fournit le repository des produits.
- `productsProvider` : charge et maintient le catalogue avec `AsyncValue<List<Product>>`.
- `productDetailProvider` : récupère un produit par identifiant.
- `categoriesProvider` : construit la liste des catégories.
- `vendorProductsProvider` : récupère les produits publics d'une boutique.

### Filtres et tri

- `filterProvider` : conserve la recherche, la catégorie et le tri sélectionnés.
- `filteredProductsProvider` : applique recherche, catégorie, tri et visibilité des produits.

### Panier

- `cartProvider` : gère les articles du panier.
- `cartCountProvider` : calcule le nombre total d'articles.
- `cartTotalProvider` : calcule le total du panier.
- `cartByVendorProvider` : groupe les articles par boutique.

### Favoris

- `favoritesRepositoryProvider` : fournit le repository de persistance locale.
- `favoritesProvider` : charge et sauvegarde les favoris avec `AsyncValue<Set<String>>`.
- `isFavoriteProvider` : indique si un produit est favori.
- `favoritesCountProvider` : calcule le nombre de favoris.

### Authentification et utilisateurs

- `authProvider` : gère l'utilisateur connecté et son rôle.
- `isAuthenticatedProvider` : indique si un utilisateur est connecté.
- `isVendorProvider` : indique si l'utilisateur connecté est vendeur.
- `vendorsProvider` : charge et maintient la liste des boutiques.
- `vendorByIdProvider` : récupère une boutique par identifiant.

### Checkout et livraison

- `deliveryAddressProvider` : fournit l'adresse de livraison.
- `deliveryOptionsProvider` : fournit les modes de livraison.
- `selectedDeliveryOptionIdProvider` : conserve le mode de livraison sélectionné.
- `selectedDeliveryOptionProvider` : récupère l'option sélectionnée.
- `checkoutTotalProvider` : calcule le total panier + livraison.

### Notifications

- `notificationsProvider` : gère les notifications utilisateur.
- `unreadNotificationsCountProvider` : calcule les notifications non lues.

### Vendeur

- `vendorOrdersProvider` : gère les commandes d'une boutique.
- `vendorOrdersByVendorProvider` : filtre les commandes par boutique.

### Thème

- `themeModeProvider` : gère le thème clair/sombre.
- `isDarkProvider` : indique si le thème sombre est actif.

## Parcours Utilisateur

### Client

1. Connexion depuis l'écran d'authentification.
2. Navigation dans l'accueil ou le catalogue.
3. Consultation d'une fiche produit.
4. Ajout au panier ou aux favoris.
5. Passage de commande avec choix du mode de livraison.
6. Consultation du profil, des notifications, favoris et informations de livraison.

### Vendeur

1. Connexion à une boutique existante ou création d'un compte boutique.
2. Accès automatique à l'espace vendeur.
3. Consultation des indicateurs de la boutique.
4. Ajout et modification de produits.
5. Gestion du stock et de la visibilité des produits côté client.
6. Suivi et avancement des commandes.
7. Modification des informations publiques de la boutique.

## Gestion des États

Les états asynchrones sont représentés avec `AsyncValue`, ce qui permet d'afficher clairement :

- un état de chargement ;
- un état d'erreur ;
- les données disponibles.

Les écrans qui chargent des produits, boutiques ou favoris s'appuient sur `when`, `maybeWhen` ou `valueOrNull` selon le besoin.

## Tests

Le projet contient des tests sur la logique principale :

- calcul du panier ;
- persistance des favoris ;
- filtrage des produits masqués ;
- avancement des commandes vendeur ;
- démarrage de l'application.

Lancer l'analyse statique :

```bash
flutter analyze
```

Lancer les tests :

```bash
flutter test
```

## Installation

Cloner le projet, installer les dépendances puis lancer l'application.

```bash
flutter pub get
flutter run
```

## Notes

Les données produits, boutiques, livraisons, commandes et notifications sont fournies localement afin de concentrer le projet sur le state management avec Riverpod et sur l'organisation de l'application.
