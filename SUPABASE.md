# Maison L’kam — brancher Supabase et déployer sur Vercel

Ce dossier est un site statique (aucune compilation). Le paiement reste **simulé**. Aucune clé secrète n’est nécessaire.

## 1. Créer le projet Supabase
1. supabase.com > **New project** (nom, mot de passe de base à conserver, région proche).
2. Attendez la fin de l’initialisation.

## 2. Récupérer URL et Publishable key
1. **Project Settings > API Keys** (ou *Data API*) : copiez **Project URL** et la **Publishable key** (`sb_publishable_…`).
2. Collez-les dans `supabase-client.js`. N’utilisez **jamais** la clé *secret* / *service_role*.

## 3. Exécuter les SQL (SQL Editor), dans cet ordre
1. `supabase-setup.sql` : **base neuve uniquement** (produits, rôles, RLS, 14 produits).
2. `supabase-orders.sql` : commandes + fonction `create_demo_order` (relançable).
3. `supabase-admin.sql` : plus tard (étape 6).
Si vos tables existent déjà, ne lancez pas le setup tel quel : adaptez-le d’abord (aucune table ne doit être supprimée).
Les règles de livraison (8 TND, gratuite dès 150 TND) sont dans `create_demo_order` **et** dans `CFG` de `script.js` : modifiez les deux ensemble.

## 4. Configurer Auth
1. **Authentication > URL Configuration** : *Site URL* = l’URL Vercel finale (ou `http://localhost:3000` en test).
2. *Redirect URLs* : ajoutez `http://localhost:3000/**` et `https://VOTRE-SITE.vercel.app/**`.
3. **Authentication > Sign In / Providers > Email** : gardez **Confirm email** activé.
4. Le service e-mail intégré est limité en volume : pour de vrais clients, configurez un SMTP.

## 5. Tester l’inscription
Ouvrez le site (`npx serve .` ou l’URL Vercel), créez un compte, ouvrez l’e-mail de confirmation, cliquez le lien, connectez-vous. Si aucun e-mail n’arrive : spams, limite d’envoi, *Redirect URLs*.

## 6. Devenir administrateur
1. **Authentication > Users** : copiez l’UUID de votre compte.
2. Remplacez `VOTRE-UUID` dans `supabase-admin.sql`, exécutez-le dans SQL Editor (jamais depuis le navigateur).
3. Reconnectez-vous : le lien **Admin** apparaît ; `admin.html` gère commandes et produits.

## 7. Tests à faire (sessions réelles, pas le SQL Editor qui contourne RLS)
| Acteur | Doit pouvoir | Ne doit pas pouvoir |
|---|---|---|
| Visiteur | voir les produits visibles | lire des commandes, commander |
| Client A | commander, voir **ses** commandes | voir celles de B, changer statut/prix/rôle |
| Client B | idem pour lui | voir celles de A |
| Admin | produits (CRUD), toutes les commandes, **statut** | modifier `user_roles`, autre champ de commande |
Testez aussi : panier vidé seulement après succès, coupure réseau puis réessai (pas de doublon), prix modifié par l’admin pendant un panier (message « prix changés »).

## 8. Déployer sur Vercel
1. Poussez ce dossier dans un dépôt GitHub (racine = ce dossier).
2. Vercel > **Add New > Project** > importez le dépôt.
3. **Framework Preset : Other** ; **Root Directory** : dossier contenant `index.html` ; Build Command : **vide** ; Output Directory : **vide** (ou `.`) ; Install Command : vide.
4. **Deploy**, puis copiez l’URL HTTPS.
5. Retour à Supabase : mettez à jour *Site URL* et *Redirect URLs* avec cette URL.
6. Refaites les tests (inscription, commande, admin) sur l’URL HTTPS finale.

## Erreurs fréquentes
- `supabase is not defined` : la bibliothèque n’est pas chargée avant `supabase-client.js`.
- `Invalid API key` : URL ou clé mal collée.
- Rien dans le catalogue : `supabase-setup.sql` non exécuté (le site affiche alors le catalogue local de secours).
- `permission denied` / liste vide : SQL non exécutés dans l’ordre.
- « E-mail non confirmé » : cliquez le lien reçu.
- Lien de confirmation vers localhost : corrigez *Site URL*.
- Admin refusé : UUID incorrect ou reconnexion oubliée.

## Limites
Récupération de mot de passe non implémentée. Anciennes commandes locales non importées. Paiement simulé. Pas de pages `signup.html`/`login.html` séparées : tout passe par `index.html`.
