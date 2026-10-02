# ShopHub

ShopHub est une application e-commerce multivendeur réalisée avec Flutter et Riverpod. Elle propose un catalogue, un espace vendeur, un panier, des favoris persistés localement, des notifications et des écrans de profil. Certaines parties du parcours d'achat restent à finaliser, notamment la gestion d'adresses de livraison.

## Fonctionnalités

- Catalogue de produits avec liste, recherche, filtres, tri et page détail.
- Panier avec ajout, suppression, modification des quantités et total dynamique.
- Favoris persistés localement avec `SharedPreferences`.
- Profil utilisateur avec modification des informations, import d’une photo depuis l’appareil, statistiques et actions rapides.
- Authentification API par JWT avec distinction client et vendeur.
- Création de compte boutique depuis les écrans d'authentification.
- Page publique boutique visible par les clients, avec import de sa photo de couverture.
- Dashboard vendeur avec indicateurs, gestion produits, stock, visibilité et commandes.
- Commandes clients, suivi des changements de statut et notation de la boutique après livraison (une note par commande).
- Notifications utilisateur accessibles depuis le profil.
- Animations sur l'ajout au panier et transitions d'interface.

## Stack Technique

- Flutter
- Riverpod avec `StateNotifierProvider`, `Provider`, `Provider.family`, `StateProvider`
- `AsyncValue` pour les données asynchrones
- `SharedPreferences` pour la persistance locale des favoris
- Dio avec intercepteur JWT et renouvellement du refresh token
- Hive pour le cache hors ligne; `flutter_secure_storage` pour la session
- Express, TypeScript, Prisma et PostgreSQL pour le backend ShopHub
- `google_fonts` pour la typographie

## Architecture

Le projet suit une organisation en couches afin de séparer la logique métier des widgets.

```text
lib/
  core/
    animations.dart
    theme.dart
    theme_provider.dart
  domain/
    entities/
    repositories/
    usecases/
  data/
    datasources/
      marketplace_api.dart
      mocks/
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

Contient les détails techniques qui réalisent les contrats du domaine.

- Les entités métier se trouvent dans `domain/entities/`.
- `datasources/` : appels REST avec repli sur le cache Hive.
- `repositories/` : implémentations des contrats déclarés dans `domain/repositories/`.

### `providers`

Contient l’état de présentation avec Riverpod. Les notifiers appellent les cas d’usage; les règles métier restent dans `domain/usecases/`.

### `ui`

Contient les interfaces :

- `auth/` : connexion client, création boutique, redirection selon le rôle.
- `client/` : accueil, catalogue, panier, checkout, profil, notifications, page boutique.
- `vendor/` : dashboard boutique, produits, commandes, profil public de la boutique.
- `widgets/` : composants réutilisables.

## Providers Riverpod

### Produits

- `marketplaceApiProvider` : compose les appels REST avec le cache Hive.
- `catalogRepositoryProvider` et `catalogUseCasesProvider` : chargent produits et boutiques via le domaine.
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

- Le checkout recueille les coordonnées de livraison pour chaque commande et les enregistre en instantané avec celle-ci; la gestion d’un carnet d’adresses enregistré reste à faire.
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
5. Saisie de l’adresse, choix d’un mode de livraison dynamique et lancement du paiement FedaPay sandbox.
6. Confirmation après vérification du statut FedaPay côté serveur; le panier est conservé en cas d’échec.
7. Suivi de préparation/livraison par statuts vendeur et notation de la boutique après livraison.

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

Les écrans catalogue, accueil et boutiques récupèrent produits et vendeurs depuis le backend REST, avec cache et jeux de données de démonstration en repli. Le checkout crée une commande par boutique, vérifie le stock et recalcule le mode/frais de livraison côté serveur. Les nouveaux prix et données de démonstration sont exprimés en francs CFA (XOF), et FedaPay reçoit directement un montant entier en XOF. Les anciennes lignes déjà présentes en base n’ont pas été converties automatiquement : sauvegarde et conversion explicite nécessaires avant de les réutiliser. Le vendeur avance les statuts après paiement; aucun livreur dédié ni GPS ne sont encore intégrés.

## Backend et base de données

Le backend se trouve dans `backend/`. Il utilise Node.js, Express, TypeScript, Prisma et PostgreSQL. Son architecture sépare le domaine, les cas d’usage, les adaptateurs d’infrastructure et la présentation HTTP.

```bash
cd backend
npm install
cp .env.example .env
# Remplacez les deux secrets JWT dans .env par des valeurs aléatoires longues.
npm run db:setup
npm run dev
```

L'API écoute sur `http://localhost:3000`. `npm run db:setup` applique la migration PostgreSQL versionnée puis ajoute les données de démonstration. Configure d'abord `DATABASE_URL` dans `.env`; la migration ne crée pas la base PostgreSQL elle-même. Les comptes initiaux sont `alex@example.com / password` (client) et `contact@tech.bj / password` (vendeur).

## Architecture

```text
backend/src/
  domain/          règles métier et ports (interfaces)
  application/     cas d’usage indépendants des frameworks
  infrastructure/  Prisma, PostgreSQL, bcrypt, JWT et configuration
  presentation/    Express, routes HTTP, validation et presenters
  server.ts        composition root et démarrage
backend/prisma/
  schema.prisma    schéma relationnel PostgreSQL
  migrations/      SQL versionné généré depuis Prisma
  seed.ts          données de démonstration
lib/
  domain/          contrats et modèles métier Flutter
  data/            API REST, cache et repositories
  core/            Dio, token storage et Hive
  providers/       état Riverpod
  ui/              écrans Flutter
```

Les routes principales comprennent l'authentification (`/api/auth/*`), `GET /api/app-config`, les routes catalogue et boutiques (`/api/products`, `/api/vendors`), `POST /api/uploads/images`, `POST /api/uploads/profile-image`, les commandes et avis (`/api/orders`, `/api/orders/:id/review`, `GET /api/vendors/:id/reviews`), les notifications (`/api/notifications/me`) et les points fidélité (`/api/loyalty/me`). Les mots de passe sont hachés avec bcrypt. Les refresh tokens sont stockés sous forme hachée et tournés lors du renouvellement. Les images de profil nécessitent une session; les images produit et couverture boutique nécessitent une session vendeur. Une note (1 à 5 étoiles, commentaire facultatif) est autorisée uniquement au client propriétaire d’une commande livrée et une seule fois par commande.

## Configuration Flutter

À la racine du projet :

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

`10.0.2.2` désigne la machine hôte depuis l'émulateur Android. Pour Flutter Web, Linux, macOS ou Windows sur la même machine, utilisez `http://localhost:3000/api`. Depuis un téléphone physique, remplacez `localhost` par l'adresse IP locale de l'ordinateur. En production, utilisez une URL HTTPS et des secrets JWT distincts.

Les produits et boutiques consultés sont mis en cache dans Hive et restent disponibles hors ligne. Les jetons sont enregistrés avec `flutter_secure_storage`; Dio ajoute l'access token et renouvelle la session sur une réponse 401. Les erreurs réseau sont présentées sous forme de messages lisibles.

Les tests repository se lancent avec `flutter test test/data/repositories/product_repository_test.dart`. Le backend se compile avec `cd backend && npm run build`.

## Configuration dynamique et mode démo

La configuration publique (catégories, bannières du carrousel et options/tarifs de livraison) est servie par `GET /api/app-config` depuis la ligne `PlatformConfig`. Au premier accès avec une base disponible, l'API crée cette ligne avec les valeurs initiales; ses champs JSON peuvent ensuite être modifiés dans PostgreSQL. Il n'y a pas encore d'écran d'administration pour éditer ces réglages.

Si PostgreSQL est inaccessible ou si la table de configuration manque, l'API renvoie la configuration de secours avec `demoMode: true`. L'application utilise alors son cache catalogue puis ses jeux de données `ProductsMock`/`VendorsMock` et propose une connexion locale de démonstration. Les données de démonstration ne sont pas persistées; les opérations d'écriture nécessitant l'API/la base peuvent échouer. Le checkout est désactivé dans ce mode. Le serveur a toujours besoin des secrets JWT; `DATABASE_URL` est nécessaire pour les opérations persistantes, mais le backend peut démarrer sans base.

Le modèle `SavedAddress` existe dans le schéma mais le carnet d’adresses enregistré n’est pas encore relié à l’application; les informations saisies au checkout sont toutefois stockées sur la commande. Certains libellés et actions de l'interface ne sont pas administrables depuis la configuration de plateforme. Les photos de profil, de boutique et de produits sont téléversées depuis l’appareil puis enregistrées dans `backend/uploads`; en production, ce stockage local doit être remplacé ou complété par un stockage de fichiers durable.

## Vérification email

À l'inscription client ou vendeur, ShopHub envoie un code à 6 chiffres valable 10 minutes. Aucune session n'est créée avant confirmation; les codes sont hachés en base, limités à cinq essais et le renvoi est soumis à un délai d'une minute. Les paramètres SMTP sont lus depuis les variables `MAIL_SERVER`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`, `MAIL_SSL_TLS` et `MAIL_STARTTLS` de `backend/.env`. Les utilisateurs préexistants sont conservés comme vérifiés. Les avis des boutiques sont stockés et agrégés en base; appliquez les migrations avec `cd backend && npx prisma migrate deploy`.

## Checkout FedaPay sandbox

Configure `FEDAPAY_ENVIRONMENT=sandbox` et `FEDAPAY_SECRET_KEY` avec une clé de test dans `backend/.env`. Pour la production, définis explicitement `FEDAPAY_ENVIRONMENT=live` et utilise une clé Live. Les tarifs et prix sont en XOF, sans conversion au moment du paiement. L’application ouvre la page de paiement FedaPay; ShopHub interroge ensuite l’API FedaPay depuis le serveur pour confirmer l’état. Le backend ne traite pas encore les webhooks signés; le polling ne garantit la confirmation que lorsque l’application peut interroger l’API. Une commande impayée reste invisible au vendeur, n’est pas préparée, et le stock réservé est restitué quand FedaPay indique un échec ou une annulation. Les callbacks visibles côté client ne sont jamais considérés comme une preuve de paiement.
