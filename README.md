# DeliverEat — Application de livraison de repas

Projet réalisé dans le cadre de l'examen final Flutter — Master 1 (2025-2026).

## Choix d'architecture

Le projet suit une architecture en couches strictement séparées, conforme aux contraintes techniques du sujet :

```
lib/
  core/              Configuration transverse
    api_client.dart       Client dio unique, intercepteur de refresh token
    constants.dart         URL de base de l'API (un seul point de changement)
    errors.dart             Mapping des codes d'erreur API -> messages FR
    token_storage.dart    Wrapper flutter_secure_storage

  models/            Classes typées avec fromJson (aucun Map manipulé dans les widgets)
  services/          Un service par ressource API (Auth, Restaurant, Order, Favorite, Profile...)
                     Toute la logique dio et la conversion des erreurs y sont isolées
  providers/         Un ChangeNotifier par domaine fonctionnel (état de l'app)
  screens/           Un dossier par écran/flux, avec sous-dossier widgets/ si nécessaire
  widgets/           Composants réutilisables partagés entre plusieurs écrans
```

**Flux de données** : Écran (UI) → lit un Provider → le Provider appelle un Service → le Service appelle `ApiClient.dio` → le résultat remonte typé (modèle) jusqu'à l'écran, qui se reconstruit via `notifyListeners()`.

Cette séparation permet notamment de tester indépendamment chaque couche et d'isoler tout le code réseau des widgets.

### Gestion de session (Partie 1)

Le point le plus délicat du projet : les jetons d'accès expirent après 10 minutes (volontairement, selon le sujet). Un intercepteur `dio` dans `ApiClient` détecte le code `TOKEN_EXPIRED`, appelle `/api/auth/refresh`, réenregistre la nouvelle paire de jetons, puis rejoue la requête d'origine — invisible pour l'utilisateur.

Un verrou (`_isRefreshing` + file d'attente de callbacks) évite que plusieurs requêtes concurrentes ne déclenchent chacune leur propre refresh (le refresh token étant à usage unique, une seconde tentative simultanée échouerait sinon). Si le refresh échoue définitivement, un callback `onSessionExpired` redirige l'utilisateur vers l'écran de connexion depuis n'importe quel point de l'app, via une `GlobalKey<NavigatorState>` globale.

### Suivi de commande en temps réel (Partie 4)

Le suivi de commande combine trois mécanismes pour rester robuste :
1. **WebSocket** (`wss://.../ws?token=`) pour recevoir les événements `order_update` en direct.
2. **Reconnexion automatique** avec jeton frais après une coupure (le jeton passé dans l'URL WebSocket expire comme n'importe quel access token).
3. **Repli sur polling** (`GET /api/orders/:id` toutes les 5 secondes) après 3 échecs de reconnexion, pour garantir que le suivi reste fonctionnel même si le WebSocket est indisponible.

### Mode hors ligne (Partie 5)

`connectivity_plus` seul ne suffisait pas : sur émulateur (BlueStacks), l'interface réseau reste signalée comme "connectée" même quand l'hôte n'a plus internet. La détection réelle passe donc par une résolution DNS active (`InternetAddress.lookup`) répétée toutes les 5 secondes, combinée à l'écoute des changements d'interface pour réagir plus vite dans le cas général.

## Packages utilisés

| Package | Usage |
|---|---|
| `dio` | Client HTTP, intercepteurs (auth, refresh) |
| `provider` | Gestion d'état (ChangeNotifier) |
| `flutter_secure_storage` | Stockage chiffré des jetons |
| `web_socket_channel` | Connexion WebSocket pour le suivi de commande |
| `image_picker` | Sélection de photo (galerie / appareil photo) |
| `connectivity_plus` | Détection de changement d'interface réseau |
| `shared_preferences` | Persistance des préférences (thème, langue) |
| `intl` | Formatage des dates/heures |
| `cached_network_image` | Cache des images réseau |

## Bonus implémentés

- **Mode sombre** persistant (`shared_preferences`), avec bascule rapide depuis l'AppBar (login, inscription, accueil) et depuis le profil.
- **Localisation français/anglais** via un dictionnaire centralisé (`AppStrings`), appliqué sur tous les écrans principaux, avec persistance du choix.
- **Animations Hero** entre la carte restaurant (liste) et l'en-tête de la fiche restaurant, pour une transition fluide.

## Difficultés rencontrées

- **Endpoints devinés puis corrigés** : plusieurs noms de champs JSON et chemins d'API (`imageUrl` vs `photoUrl`, `/me/favorites` vs `/favorites`, `unitPrice`/`lineTotal` vs `price`...) ont dû être ajustés après inspection directe des réponses réelles du serveur, la documentation textuelle du sujet ne donnant pas le format exact.
- **Race condition sur le refresh token** : la première version de l'intercepteur laissait une requête en attente retenter avec un token qu'on savait déjà invalide si le refresh concurrent avait échoué. Corrigé en propageant le résultat réel du refresh (succès/échec) à toutes les requêtes en attente plutôt que de supposer un succès.
- **Faux-positif de connectivité sous émulateur** : `connectivity_plus` seul rapportait une interface Wi-Fi active même après coupure réelle de la connexion internet de l'hôte (BlueStacks garde son interface réseau virtuelle). Résolu par une vérification DNS active en complément.
- **Regroupement du menu par section côté client** : l'API renvoie le menu sous forme de tableau plat avec un champ `section` par article, plutôt qu'une structure déjà groupée — le regroupement (`MenuSection.groupBySection`) est donc effectué côté application.
- **Overflows de layout** (`ListTile` avec `trailing` multi-lignes) résolus en remplaçant certains `ListTile` par des `Row`/`Column` manuels avec `mainAxisSize: MainAxisSize.min`.

## Compte de démonstration

```
E-mail    : demo@delivereat.app
Mot de passe : password123
E-mail    : bsarr597@gmail.com
Mot de passe : Sarr1017
```

## Lancement du projet

```bash
flutter pub get
flutter run
```

Le projet compile et se lance sans manipulation particulière. L'adresse de l'API est centralisée dans `lib/core/constants.dart` — un seul endroit à modifier si le serveur change d'adresse.