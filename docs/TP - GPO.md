# Objectif

Configurer le domaine **TSSR-MEN.LAB** avec des stratégies de groupe : des GPO communes à tout le monde, des GPO propres à chaque service, puis une validation à l'aide des commandes dédiées.

## Comment utiliser ce document

Chaque section contient un espace **Réponse / Captures** à compléter.

Les blocs `> [!tip]` et `> [!warning]` sont des pistes de guidage : à supprimer dans la version rendue.

Place les captures dans `attachments/` et insère-les avec `![[nom-capture.png]]`.

Pour chaque GPO, remplis le petit tableau « Paramètres de la GPO » : il sert aussi de pense-bête pour la validation.

## Sommaire

0. Préparation
    
1. GPO communes
    
2. GPO par service
    
3. Validation
    
4. Récapitulatif
    
5. Conclusion et difficultés rencontrées
    

## Environnement du laboratoire

|**Élément**|**Valeur**|
|---|---|
|Domaine|TSSR-MEN.LAB|
|Serveur AD / DNS / DHCP / fichiers|srv-win-men-01 (192.168.100.10)|
|Poste client|CLI-WIN-MEN-01|
|Console utilisée|Gestion de stratégie de groupe (`gpmc.msc`)|
|Partage des installateurs|`\\srv-win-men-01\Deploy$`|
|Partage de l'image de fond|`\\srv-win-men-01\Wallpapers$`|

## 0. Préparation

> [!info] **Pas-à-pas : Préparation du serveur et des ressources**
> 
> 1. **Dossiers partagés sur `srv-win-men-01` :**
>     
>     - Crée le dossier `C:\Deploy` et partage-le sous le nom `Deploy$`. Dans les autorisations de partage et NTFS, ajoute `Utilisateurs du domaine` (Lecture) et `Ordinateurs du domaine` (Lecture). Déposes-y `GoogleChrome.msi`, `7zip.msi` et `mRemoteNG.msi`.
>         
>     - Crée le dossier `C:\Wallpapers` et partage-le sous le nom `Wallpapers$`. Donne les accès en lecture à `Utilisateurs du domaine`. Déposes-y ton image `fond.png`.
>         
> 2. **Modèles ADMX Google Chrome :**
>     
>     - Télécharge le bundle ADMX de Chrome. Extrais-le.
>         
>     - Copie les fichiers `chrome.admx` et `google.admx` dans `C:\Windows\PolicyDefinitions` (ou dans le Magasin Central `\\TSSR-MEN.LAB\sysvol\TSSR-MEN.LAB\Policies\PolicyDefinitions` s'il existe).
>         
>     - Copie les dossiers de langue `fr-FR` associés au même endroit.
>         
> 3. **Consoles d'administration :**
>     
>     - Sur le serveur, appuie sur `Win + R`, tape `gpmc.msc` pour ouvrir la console de Gestion des stratégies de groupe.
>         
>     - Ouvre aussi `dsa.msc` (Utilisateurs et ordinateurs Active Directory) pour vérifier ton arborescence d'OU.
>         

### Convention de nommage retenue

- **GPO Ordinateur :** `GPO_C_<PERIMETRE>_<DESCRIPTION>` (Exemple: `GPO_C_COMMUN_RDP-Firewall`)
    
- **GPO Utilisateur :** `GPO_U_<PERIMETRE>_<DESCRIPTION>` (Exemple: `GPO_U_RH_MasquerLecteurC`)
    

### Comptes de test

| **Service**   | **Compte de test** | **Remarque**                              |
| ------------- | ------------------ | ----------------------------------------- |
| ADMINISTRATIF |                    | Réactivé ou créé pour remplacer `t.stark` |
| DIRECTION     |                    | Compte dans l'OU DIRECTION                |
| COMPTABILITE  |                    | Compte dans l'OU COMPTABILITE             |
| INFORMATIQUE  |                    | Compte dans l'OU INFORMATIQUE             |
| RH            |                    | Compte dans l'OU RH                       |
| PRODUCTION    |                    | Compte dans l'OU PRODUCTION               |

**Capture(s) :**

`capture-0-arborescence.png` `capture-0-snapshots.png`

## 1. GPO communes

### 1.1 Empêcher l'accès au Panneau de configuration / Paramètres

> **Consigne :** Les utilisateurs non informatiques ne doivent pas accéder au Panneau de configuration ni à l'application Paramètres.

> [!info] **Pas-à-pas : Création et configuration de la GPO**
> 
> 1. Dans `gpmc.msc`, fais un clic droit sur l'OU **UTILISATEURS** > **Créer un objet GPO dans ce domaine, et le lier ici...**.
>     
> 2. Nomme-la : `GPO_U_COMMUN_InterdirePanneauConfig`.
>     
> 3. Clic droit sur la GPO > **Modifier...**.
>     
> 4. Navigue vers : `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Panneau de configuration`.
>     
> 5. Double-clique sur **Prohiber l'accès au panneau de configuration et aux paramètres du PC** > Sélectionne **Activé** > Clique sur **OK**.
>     
> 6. **Exclusion du service INFORMATIQUE (Filtrage de sécurité) :**
>     
>     - Ferme l'éditeur. Sélectionne la GPO sous l'OU **UTILISATEURS**.
>         
>     - Dans l'onglet **Délégation**, clique sur **Avancé...**.
>         
>     - Clique sur **Ajouter...**, recherche le groupe `GG-INFORMATIQUE` (ou l'OU/utilisateur IT).
>         
>     - Dans la liste des autorisations, coche la case **Refuser** pour l'autorisation **Appliquer la stratégie de groupe**.
>         
>     - Valide les avertissements.
>         

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_COMMUN_InterdirePanneauConfig`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Prohiber l'accès au panneau de configuration et aux paramètres du PC = Activé|
|Lien et filtrage|Lié sur `OU=UTILISATEURS`, Refus "Appliquer la GPO" pour `GG-INFORMATIQUE`|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008124049.png)
![](attachments/Pasted%20image%2020261008124341.png)

### 1.2 Autoriser le Bureau à distance et créer la règle de pare-feu

> **Consigne :** Autoriser les connexions Bureau à distance sur les postes et créer la règle de pare-feu associée.

> [!info] **Pas-à-pas : Création et configuration de la GPO**
> 
> 1. Dans `gpmc.msc`, fais un clic droit sur l'OU **ORDINATEURS** > **Créer un objet GPO...**.
>     
> 2. Nomme-la : `GPO_C_COMMUN_RDP-Firewall`.
>     
> 3. Clic droit > **Modifier...**.
>     
> 4. **Activer le RDP :**
>     
>     - Navigue vers : `Configuration ordinateur` > `Stratégies` > `Modèles d'administration` > `Composants Windows` > `Services Bureau à distance` > `Hôte de session Bureau à distance` > `Connexions`.
>         
>     - Double-clique sur **Autoriser les utilisateurs à se connecter à distance à l'aide des services Bureau à distance** > **Activé**.
>         
> 5. **Ouvrir le Pare-feu :**
>     
>     - Navigue vers : `Configuration ordinateur` > `Stratégies` > `Paramètres Windows` > `Paramètres de sécurité` > `Pare-feu Windows avec sécurité avancée`.
>         
>     - Clic droit sur **Règles de trafic entrant** > **Nouvelle règle...**.
>         
>     - Choisis **Prédéfinie** > Sélectionne **Bureau à distance** dans la liste > Suivant.
>         
>     - Coche les règles proposées > Choisis **Autoriser la connexion** > Terminer.
>         

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_C_COMMUN_RDP-Firewall`|
|Configuration|Ordinateur|
|Paramètre(s) et valeur|Autoriser les connexions RDP = Activé|
|Lien et filtrage|Lié sur `OU=ORDINATEURS`|

#### Règle de pare-feu

|**Propriété**|**Valeur**|
|---|---|
|Sens|Entrant|
|Type de règle|Prédéfinie (Bureau à distance) / Port TCP 3389|
|Action|Autoriser la connexion|
|Profils|Domaine, Privé|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008124714.png)
`capture-1-2-parametre-rdp.png` `capture-1-2-regle-pare-feu.png` `capture-1-2-test-connexion.png`

### 1.3 Mettre en place un fond d'écran commun

> **Consigne :** Tous les utilisateurs doivent avoir le même fond d'écran.

> [!info] **Pas-à-pas : Configuration de la GPO Fond d'écran**
> 
> 1. Crée la GPO `GPO_U_COMMUN_FondEcran` liée à l'OU **UTILISATEURS**.
>     
> 2. Clic droit > **Modifier...**.
>     
> 3. Navigue vers : `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Bureau` > `Bureau`.
>     
> 4. Double-clique sur **Papier peint du Bureau** > Choisis **Activé**.
>     
> 5. Dans **Nom du papier peint**, indique le chemin UNC : `\\srv-win-men-01\Wallpapers$\fond.png`.
>     
> 6. Dans **Style du papier peint**, choisis **Ajuster** ou **Remplir**.
>     
> 7. Clique sur **OK**.
>     

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_COMMUN_FondEcran`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Papier peint du Bureau = Activé (`\\srv-win-men-01\Wallpapers$\fond.png`)|
|Lien et filtrage|Lié sur `OU=UTILISATEURS`|

#### Partage de l'image

|**Propriété**|**Valeur**|
|---|---|
|Chemin UNC|`\\srv-win-men-01\Wallpapers$\fond.png`|
|Permissions de partage|Utilisateurs du domaine (Lecture)|
|Permissions NTFS|Utilisateurs du domaine (Lecture & Exécution)|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008133614.png)
![](attachments/Pasted%20image%2020261008140527.png)


### 1.4 Déployer l'imprimante IMP-MEN-01

> **Consigne :** L'imprimante `IMP-MEN-01` doit être automatiquement disponible pour les utilisateurs.

> [!info] **Pas-à-pas : Déploiement via les Préférences GPO**
> 
> 1. Crée la GPO `GPO_U_COMMUN_Imprimante` liée à l'OU **UTILISATEURS**.
>     
> 2. Modifier > Navigue vers : `Configuration utilisateur` > `Préférences` > `Paramètres du Panneau de configuration` > `Imprimantes`.
>     
> 3. Clic droit dans la zone blanche > **Nouveau** > **Imprimante partagée**.
>     
> 4. Action : **Mettre à jour** (ou Créer).
>     
> 5. Chemin du partage : `\\srv-win-men-01\IMP-MEN-01`.
>     
> 6. Coche la case **Définir cette imprimante comme imprimante par défaut** si souhaité > Valide.
>     

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_COMMUN_Imprimante`|
|Méthode|Préférences de stratégie de groupe (Imprimantes partagées)|
|Configuration|Utilisateur|
|Lien et filtrage|Lié sur `OU=UTILISATEURS`|

**Capture(s) :**

![](attachments/Pasted%20image%2020261008140745.png)


### 1.5 Déployer Google Chrome et 7-Zip

> **Consigne :** Installer Google Chrome et 7-Zip automatiquement sur tous les postes.

> [!info] **Pas-à-pas : Déploiement de paquets MSI sur les Ordinateurs**
> 
> 1. Crée la GPO `GPO_C_COMMUN_DeploiementLogiciels` liée à l'OU **ORDINATEURS**.
>     
> 2. Modifier > Navigue vers : `Configuration ordinateur` > `Stratégies` > `Paramètres du logiciel` > `Installation de logiciels`.
>     
> 3. Clic droit > **Nouveau** > **Package...**.
>     
> 4. **Très Important :** Dans la boîte de dialogue d'ouverture de fichier, ne parcours pas `C:\...`. Tape directement le chemin UNC : `\\srv-win-men-01\Deploy$\GoogleChrome.msi`.
>     
> 5. Choisis la méthode d'attribution : **Attribué** > Clique sur **OK**.
>     
> 6. Répète l'opération exacte pour `7zip.msi`.
>     

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_C_COMMUN_DeploiementLogiciels`|
|Configuration|Ordinateur|
|Logiciels et mode|Google Chrome & 7-Zip (Attribué)|
|Lien et filtrage|Lié sur `OU=ORDINATEURS`|

#### Partage de distribution

|**Propriété**|**Valeur**|
|---|---|
|Chemin UNC|`\\srv-win-men-01\Deploy$`|
|Permissions de partage|Ordinateurs du domaine (Lecture), Utilisateurs du domaine (Lecture)|
|Permissions NTFS|Ordinateurs du domaine (Lecture), Utilisateurs du domaine (Lecture)|
|Méthode d'import|Copie directe des paquets `.msi` via dossier partagé|

**Capture(s) :**

![](attachments/Pasted%20image%2020261008141319.png)

### 1.6 Lecteurs réseau par service

> **Consigne :** Chaque service doit avoir le lecteur réseau correspondant au dossier auquel il a accès.

> [!info] **Pas-à-pas : Mappage centralisé avec Ciblage au niveau de l'élément**
> 
> 1. Crée la GPO `GPO_U_COMMUN_MappageLecteurs` liée à l'OU **UTILISATEURS**.
>     
> 2. Modifier > `Configuration utilisateur` > `Préférences` > `Paramètres Windows` > `Mappages de lecteurs`.
>     
> 3. Clic droit > **Nouveau** > **Lecteur mappé**.
>     
> 4. **Onglet Général :**
>     
>     - Action : **Mettre à jour**.
>         
>     - Emplacement : `\\srv-win-men-01\ADMINISTRATIF$`
>         
>     - Utiliser la lettre : `P:`
>         
> 5. **Onglet Commun :**
>     
>     - Coche **Ciblage au niveau de l'élément** > Clique sur **Ciblage...**.
>         
>     - Clique sur **Nouvel élément** > **Groupe de sécurité**.
>         
>     - Sélectionne le groupe `TSSR-MEN\GG-ADMINISTRATIF` > Valide.
>         
> 6. Répète ces étapes pour chaque service en adaptant la lettre, le chemin UNC et le groupe ciblé.
>     

#### Matrice d'accès

|**Service**|**Dossier (UNC)**|**Lettre**|**Accès**|**GG**|**GDL**|
|---|---|---|---|---|---|
|ADMINISTRATIF|`\\srv-win-men-01\ADMINISTRATIF$`|P:|RW|GG-ADMINISTRATIF|GDL-ADMINISTRATIF-RW|
|DIRECTION|`\\srv-win-men-01\DIRECTION$`|P:|RW|GG-DIRECTION|GDL-DIRECTION-RW|
|COMPTABILITE|`\\srv-win-men-01\COMPTABILITE$`|P:|RW|GG-COMPTABILITE|GDL-COMPTABILITE-RW|
|INFORMATIQUE|`\\srv-win-men-01\INFORMATIQUE$`|P:|RW|GG-INFORMATIQUE|GDL-INFORMATIQUE-RW|
|RH|`\\srv-win-men-01\RH$`|P:|RW|GG-RH|GDL-RH-RW|
|PRODUCTION|`\\srv-win-men-01\PRODUCTION$`|P:|RW|GG-PRODUCTION|GDL-PRODUCTION-RW|

#### Paramètres de la GPO

|**Élément**|**Valeur**|
|---|---|
|Nom(s) de la GPO|`GPO_U_COMMUN_MappageLecteurs`|
|Modèle|Une seule GPO avec ciblage au niveau de l'élément|
|Action utilisée|Mettre à jour|
|Lien et filtrage|Lié sur `OU=UTILISATEURS`|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008142931.png)
![](attachments/Pasted%20image%2020261008143131.png)

## 2. GPO par service

### 2.1 ADMINISTRATIF : empêcher la modification de la date et de l'heure

> [!info] **Pas-à-pas : Droits d'attribution utilisateur (Configuration Ordinateur)**
> 
> _Attention : Ce paramètre se trouve dans la configuration Ordinateur._
> 
> 1. Crée la GPO `GPO_C_ADMINISTRATIF_RestrictionHeure` et lie-la à l'OU **ORDINATEURS** (ou applique le traitement par bouclage / filtrage).
>     
> 2. Modifier > `Configuration ordinateur` > `Stratégies` > `Paramètres Windows` > `Paramètres de sécurité` > `Stratégies locales` > `Assignation des droits utilisateur`.
>     
> 3. Double-clique sur **Changer l'heure du système**.
>     
> 4. Coche **Définir ces paramètres de stratégie**.
>     
> 5. Laisse uniquement `Administrateurs` et `SERVICE LOCAL`. Retire le groupe `Utilisateurs` > Valide.
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_C_ADMINISTRATIF_RestrictionHeure`|
|Configuration|Ordinateur|
|Paramètre(s) et valeur|Changer l'heure du système = Administrateurs, SERVICE LOCAL uniquement|
|Lien et filtrage|Lié sur `OU=ORDINATEURS`|

**Capture(s) :**

![](attachments/Pasted%20image%2020261008143349.png)
`capture-2-1-gpo.png` `capture-2-1-test.png`

### 2.2 DIRECTION : page d'accueil de Chrome

> [!info] **Pas-à-pas : Configuration des Modèles ADMX Chrome**
> 
> 1. Crée la GPO `GPO_U_DIRECTION_ChromeHomepage` liée à l'OU **DIRECTION**.
>     
> 2. Modifier > `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Google` > `Google Chrome` > `Page d'accueil`.
>     
> 3. Configure **Action au démarrage** = **Ouvrir une liste d'URL**.
>     
> 4. Configure **URL à ouvrir au démarrage** = Activé, clique sur **Afficher...** et ajoute `[http://mon-entreprise.tssr-men.lab](http://mon-entreprise.tssr-men.lab)`.
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_DIRECTION_ChromeHomepage`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Page d'accueil / URLs au démarrage = `[http://mon-entreprise.tssr-men.lab](http://mon-entreprise.tssr-men.lab)`|
|Lien et filtrage|Lié sur `OU=DIRECTION` (OU Utilisateurs)|
|Emplacement des ADMX|`C:\Windows\PolicyDefinitions`|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008144236.png)
![](attachments/Pasted%20image%2020261008144259.png)
### 2.3 COMPTABILITE : interdire le Gestionnaire des tâches

> [!info] **Pas-à-pas : Restriction Ctrl+Alt+Suppr**
> 
> 1. Crée la GPO `GPO_U_COMPTABILITE_BloquerTaskMgr` liée à l'OU **COMPTABILITE**.
>     
> 2. Modifier > `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Système` > `Options Ctrl+Alt+Suppr`.
>     
> 3. Double-clique sur **Supprimer le Gestionnaire des tâches** > **Activé** > **OK**.
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_COMPTABILITE_BloquerTaskMgr`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Supprimer le Gestionnaire des tâches = Activé|
|Lien et filtrage|Lié sur `OU=COMPTABILITE`|

**Capture(s) :**
![](attachments/Pasted%20image%2020261008144539.png)
`capture-2-3-gpo.png` `capture-2-3-test.png`

### 2.4 INFORMATIQUE : déployer mRemoteNG

> [!info] **Pas-à-pas : Déploiement de logiciel ciblé Utilisateur**
> 
> 1. Crée la GPO `GPO_U_INFORMATIQUE_DeploymRemoteNG` liée à l'OU **INFORMATIQUE**.
>     
> 2. Modifier > `Configuration utilisateur` > `Stratégies` > `Paramètres du logiciel` > `Installation de logiciels`.
>     
> 3. Clic droit > **Nouveau** > **Package...**.
>     
> 4. Entre le chemin UNC : `\\srv-win-men-01\Deploy$\mRemoteNG.msi`.
>     
> 5. Choisis **Attribué** (l'application s'installera à la connexion de l'utilisateur).
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_INFORMATIQUE_DeploymRemoteNG`|
|Configuration|Utilisateur|
|Mode|Attribué|
|Lien et filtrage|Lié sur `OU=INFORMATIQUE`|

**Capture(s) :**


`capture-2-4-gpo.png` `capture-2-4-test-it.png` `capture-2-4-test-autre.png`

### 2.5 RH : masquer le lecteur C:

> [!info] **Pas-à-pas : Restriction d'affichage dans l'Explorateur**
> 
> 1. Crée la GPO `GPO_U_RH_MasquerLecteurC` liée à l'OU **RH**.
>     
> 2. Modifier > `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Composants Windows` > `Explorateur de fichiers`.
>     
> 3. Double-clique sur **Masquer ces lecteurs spécifiés dans Mon Ordinateur** > **Activé**.
>     
> 4. Dans la liste déroulante des options, choisis **Restreindre le lecteur C seulement** > **OK**.
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_RH_MasquerLecteurC`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Masquer ces lecteurs spécifiés dans Mon Ordinateur = Restreindre le lecteur C seulement|
|Lien et filtrage|Lié sur `OU=RH`|

**Capture(s) :**

`capture-2-5-gpo.png` `capture-2-5-explorateur.png` `capture-2-5-acces-direct.png`

### 2.6 PRODUCTION : bloquer le stockage amovible

> [!info] **Pas-à-pas : Blocage des clés USB**
> 
> 1. Crée la GPO `GPO_U_PRODUCTION_BloquerUSB` liée à l'OU **PRODUCTION**.
>     
> 2. Modifier > `Configuration utilisateur` > `Stratégies` > `Modèles d'administration` > `Système` > `Accès au stockage amovible`.
>     
> 3. Double-clique sur **Toutes les classes de stockage amovible : Refuser tous les accès** > **Activé** > **OK**.
>     

|**Élément**|**Valeur**|
|---|---|
|Nom de la GPO|`GPO_U_PRODUCTION_BloquerUSB`|
|Configuration|Utilisateur|
|Paramètre(s) et valeur|Toutes les classes de stockage amovible : Refuser tous les accès = Activé|
|Lien et filtrage|Lié sur `OU=PRODUCTION`|

**Capture(s) :**

`capture-2-6-gpo.png` `capture-2-6-test.png`

## 3. Validation

### 3.1 Commandes à manipuler

> [!info] **Pas-à-pas : Exécution des tests sur le poste client `CLI-WIN-MEN-01`**
> 
> 1. Ouvre une invite de commandes (`cmd`) en tant qu'utilisateur simple pour exécuter `gpupdate` et `gpresult /r /scope user`.
>     
> 2. Ouvre une invite de commandes (`cmd`) **en tant qu'administrateur** pour exécuter `gpresult /r /scope computer` et générer le rapport HTML.
>     

|**Commande**|**Rôle**|**Ce qui a été observé**|
|---|---|---|
|`gpupdate /force`|Force le rafraîchissement immédiat de toutes les GPO.|Message indiquant que les stratégies utilisateur et ordinateur ont été mises à jour avec succès.|
|`gpupdate /target:user`|Force uniquement la mise à jour des GPO de la section Utilisateur.|Traitement plus rapide ne ciblant que le contexte utilisateur connecté.|
|`gpupdate /target:computer`|Force uniquement la mise à jour des GPO de la section Ordinateur.|Déclenche parfois un message demandant un redémarrage si un logiciel MSI doit s'installer.|
|`gpresult /r`|Affiche le résumé RSoP en ligne de commande pour la session et la machine.|Liste les GPO appliquées et filtrées pour l'utilisateur et l'ordinateur.|
|`gpresult /r /scope user`|Restreint l'affichage de `gpresult` à la section Utilisateur.|Permet de vérifier les GPO d'OU service, le fond d'écran et les lecteurs mappés.|
|`gpresult /r /scope computer`|Restreint l'affichage à la section Ordinateur (nécessite d'être Admin local).|Permet de vérifier le pare-feu, le RDP et l'installation de Chrome/7-Zip.|
|`gpresult /h C:\gpo-rapport.html`|Génère un rapport HTML complet et lisible dans un navigateur.|Fichier détaillé contenant la valeur exacte de chaque paramètre appliqué.|
|`rsop.msc`|Outil graphique (hérité) affichant le jeu de stratégies résultant.|Affiche une console type `gpmc` avec uniquement les paramètres réels appliqués au poste.|

**Capture(s) :**

`capture-3-gpupdate.png` `capture-3-gpresult-user.png` `capture-3-gpresult-computer.png` `capture-3-rapport-html.png`

### 3.2 Validation GPO par GPO

|**GPO**|**Compte / poste testé**|**Preuve (commande ou action)**|**Résultat attendu**|**Résultat obtenu**|**Capture**|
|---|---|---|---|---|---|
|Panneau de config|`a.dupont` / `i.admin`|Ouverture de `control.exe`|Refus pour Dupont, Accès pour Admin|Conforme|`capture-1-1-test-non-it.png`|
|RDP + Pare-feu|`CLI-WIN-MEN-01`|`Test-NetConnection -Port 3389`|Port 3389 Ouvert (TcpTestSucceeded: True)|Conforme|`capture-1-2-test-connexion.png`|
|Fond d'écran|`a.dupont`|Fermeture/Ouverture de session|Fond d'écran entreprise affiché|Conforme|`capture-1-3-resultat.png`|
|Imprimante|`a.dupont`|Console Imprimantes / `net use`|`IMP-MEN-01` présente par défaut|Conforme|`capture-1-4-client-apres.png`|
|Chrome & 7-Zip|`CLI-WIN-MEN-01`|Redémarrage de la VM|Icônes présentes sur le bureau / Program Files|Conforme|`capture-1-5-installe.png`|
|Lecteurs réseau|`a.dupont`|`net use` dans la console|Lecteur P: pointant sur `\\...Wait\ADMINISTRATIF$`|Conforme|`capture-1-6-net-use.png`|
|Date / Heure|`CLI-WIN-MEN-01`|Clic sur l'horloge système|Option "Modifier la date et l'heure" grisée/refusée|Conforme|`capture-2-1-test.png`|
|Chrome Homepage|`d.boss`|Ouverture de Google Chrome|Onglet ouvert sur `mon-entreprise.tssr-men.lab`|Conforme|`capture-2-2-chrome-policy.png`|
|Gestionnaire tâches|`c.compta`|`Ctrl + Maj + Echap`|Message "Le gestionnaire a été désactivé par l'admin"|Conforme|`capture-2-3-test.png`|
|mRemoteNG|`i.admin`|Menu Démarrer|Application présente pour `i.admin`, absente pour les autres|Conforme|`capture-2-4-test-it.png`|
|Lecteur C:|`r.humain`|Ouverture de l'Explorateur|Disque C: invisible (mais accessible via `C:\` dans la barre)|Conforme|`capture-2-5-explorateur.png`|
|Stockage amovible|`p.usine`|Insertion clé USB virt.|Message "Accès refusé" lors de l'ouverture de la clé|Conforme|`capture-2-6-test.png`|

### 3.3 Ordre d'application et héritage

> [!info] **Pas-à-pas : Analyse de l'ordre d'application (LSDOU)**
> 
> - **Ordre d'application :** **L**ocal > **S**ite > **D**omaine > **O**U (**LSDOU**). En cas de conflit de paramètre, c'est la dernière GPO appliquée qui l'emporte (la GPO la plus proche de l'objet dans l'arborescence d'OU).
>     
> - **Utilisateur dans `UTILISATEURS/RH` :** Il reçoit les GPO liées au Domaine, les GPO liées à l'OU parente `UTILISATEURS` (Fond d'écran, Lecteurs réseau, Imprimantes, Interdiction du Panneau de configuration), puis les GPO spécifiques liées à l'OU fille `RH` (Masquer le lecteur C:).
>     
> - **Options avancées :**
>     
>     - _Bloquer l'héritage :_ Empêche les GPO des OU parentes de s'appliquer sur l'OU ciblée.
>         
>     - _Appliquée (Enforced) :_ Force l'application d'une GPO parent même si une OU fille a activé le blocage d'héritage.
>         

## 4. Récapitulatif

|**GPO**|**Configuration**|**Lien (OU)**|**Filtrage**|**Validée**|
|---|---|---|---|---|
|Panneau de configuration|Utilisateur|`UTILISATEURS`|Refus "Appliquer" sur `GG-INFORMATIQUE`|[X]|
|Bureau à distance + pare-feu|Ordinateur|`ORDINATEURS`|Utilisateurs authentifiés|[X]|
|Fond d'écran|Utilisateur|`UTILISATEURS`|Utilisateurs authentifiés|[X]|
|Imprimante IMP-MEN-01|Utilisateur|`UTILISATEURS`|Utilisateurs authentifiés|[X]|
|Chrome et 7-Zip|Ordinateur|`ORDINATEURS`|Ordinateurs du domaine|[X]|
|Lecteurs réseau|Utilisateur|`UTILISATEURS`|Ciblage par groupe de sécurité (`GG-...`)|[X]|
|ADMINISTRATIF (Heure)|Ordinateur|`ORDINATEURS`|Ordinateurs du domaine|[X]|
|DIRECTION (Chrome)|Utilisateur|`DIRECTION`|Utilisateurs authentifiés|[X]|
|COMPTABILITE (TaskMgr)|Utilisateur|`COMPTABILITE`|Utilisateurs authentifiés|[X]|
|INFORMATIQUE (mRemoteNG)|Utilisateur|`INFORMATIQUE`|Utilisateurs authentifiés|[X]|
|RH (Masquer C:)|Utilisateur|`RH`|Utilisateurs authentifiés|[X]|
|PRODUCTION (USB)|Utilisateur|`PRODUCTION`|Utilisateurs authentifiés|[X]|

**Capture de GPMC avec toutes les GPO et leurs liens :**

`capture-4-gpmc-vue-globale.png`

## 5. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

|**Problème**|**Cause**|**Solution**|
|---|---|---|
|Les paquets Chrome et 7-Zip ne s'installaient pas au démarrage de la VM client.|Le chemin vers le fichier MSI avait été indiqué avec une lettre locale (`C:\Deploy\...`) au lieu d'un chemin UNC réseau.|Modification de la source dans la GPO pour pointer vers `\\srv-win-men-01\Deploy$\...`.|
|L'imprimante déployée par GPO ne s'affichait pas chez l'utilisateur de test.|L'ancienne imprimante ajoutée manuellement lors d'un TP précédent entrait en conflit.|Suppression de l'imprimante manuelle sur le client, puis exécution d'un `gpupdate /force`.|
|La restriction de l'heure ne s'appliquait pas en la liant sur l'OU `ADMINISTRATIF`.|Le paramètre "Changer l'heure" est un paramètre de configuration **Ordinateur**, alors que l'OU `ADMINISTRATIF` ne contient que des objets **Utilisateurs**.|Déplacement de la liaison de la GPO sur l'OU `ORDINATEURS`.|

### Ce que j'ai retenu

- Une GPO côté **Utilisateur** doit être liée à une OU contenant des **Utilisateurs**, et inversement pour les GPO **Ordinateurs**.
    
- Pour le déploiement de logiciels par GPO, le dossier source doit obligatoirement être un **partage réseau UNC** accessible en lecture aux comptes `Ordinateurs du domaine`.
    
- Le ciblage au niveau de l'élément dans les **Préférences GPO** permet de simplifier considérablement l'architecture en évitant de multiplier le nombre de GPO distinctes.