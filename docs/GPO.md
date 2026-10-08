Recherches en autonomie :

- GPO (Stratégie Ordinateurs/Stratégie Utilisateurs)
- Ordre d'application des stratégies
- Commandes utiles pour gérer les GPO

Les politiques sont des réglages centralisés définis sur ADDS qui se propagent automatiquement aux clients et appareils qui s'y connectent.
Par exemple on peut définir le wallpaper par défaut pour l'entreprise ou une mise en verrouillage de session automatique après quelques minutes, critère de sécurité du mot de passe, etc.


## Définition

Une GPO (Group Policy Object) est un ensemble de règles et paramètres centralisés définis sur un contrôleur de domaine Active Directory. Ces paramètres se propagent automatiquement aux ordinateurs et utilisateurs qui se connectent au domaine.

**Exemples d'usage :** fond d'écran imposé, verrouillage de session automatique, politique de mot de passe, désactivation du panneau de configuration, déploiement de logiciels.

---

## Deux types de stratégies

### Stratégie Ordinateurs (Computer Configuration)

- S'applique à la **machine**, quel que soit l'utilisateur connecté
- Appliquée au **démarrage** de l'ordinateur
- Exemples : scripts de démarrage, configuration réseau, politique de sécurité système, installation de logiciels

### Stratégie Utilisateurs (User Configuration)

- S'applique à l'**utilisateur**, quelle que soit la machine utilisée
- Appliquée à l'**ouverture de session**
- Exemples : fond d'écran, redirection de dossiers, restrictions du bureau, paramètres Internet Explorer/Edge

---

## Ordre d'application des stratégies (LSDOU)

Les GPO s'appliquent dans cet ordre, du moins prioritaire au plus prioritaire :

|Ordre|Niveau|Description|
|---|---|---|
|1|**L**ocal|Politique locale de la machine (`gpedit.msc`)|
|2|**S**ite|Politiques liées au site Active Directory|
|3|**D**omaine|Politiques appliquées à tout le domaine|
|4|**O**U|Politiques appliquées à l'unité d'organisation (OU) la plus proche de l'objet|

> **Règle :** la dernière GPO appliquée l'emporte. Une GPO d'OU écrase donc une GPO de domaine en cas de conflit.

### Modificateurs d'ordre

- **Enforced (No Override) :** force la GPO à s'appliquer même si une GPO enfant la contredit
- **Block Inheritance :** une OU peut bloquer l'héritage des GPO parentes (sauf si Enforced)

---

## Commandes utiles

### gpupdate — Forcer l'application des GPO

```cmd
gpupdate /force
```

Force la mise à jour immédiate des stratégies ordinateur et utilisateur sans attendre le prochain cycle automatique (toutes les 90 minutes par défaut).

```cmd
gpupdate /target:computer
gpupdate /target:user
```

Mise à jour ciblée sur l'ordinateur ou l'utilisateur uniquement.

---

### gpresult — Vérifier les GPO appliquées

```cmd
gpresult /r
```

Affiche un résumé des GPO appliquées à l'utilisateur et à l'ordinateur courants.

```cmd
gpresult /h rapport.html
```

Génère un rapport HTML détaillé de toutes les GPO appliquées — utile pour le diagnostic.

```cmd
gpresult /scope computer /r
gpresult /scope user /r
```

Résultat ciblé ordinateur ou utilisateur.

---

### Autres commandes utiles

```powershell
Get-GPO -All
```

Liste toutes les GPO du domaine (PowerShell, nécessite le module GroupPolicy).

```powershell
Get-GPResultantSetOfPolicy -ReportType Html -Path "C:\rapport.html"
```

Équivalent PowerShell de `gpresult /h`.

```cmd
rsop.msc
```

Resultant Set of Policy — interface graphique montrant les paramètres effectivement appliqués après résolution des conflits.

---

## Cycle d'application automatique

|Contexte|Fréquence|
|---|---|
|Ordinateurs membres du domaine|Toutes les 90 minutes (± 30 min aléatoire)|
|Contrôleurs de domaine|Toutes les 5 minutes|
|Au démarrage / ouverture de session|Systématiquement|