
---


> [!abstract] Contexte Le domaine Active Directory fonctionne sur un seul contrôleur de domaine Windows Server 2025. Pour améliorer la disponibilité de l'authentification et de l'annuaire, un deuxième contrôleur de domaine est ajouté, sur le serveur **Server Core** du TP précédent. Toutes les opérations se font avec **PowerShell**.

> [!info] Comment utiliser ce document
> 
> - `[Core]` désigne le serveur Server Core, `[Graphique]` le serveur avec interface (`SRV-WIN-MEN-01`). Vérifie toujours sur quelle machine tu tapes.
> - Le brief te demande de **rechercher** les commandes : les `> [!tip]` donnent des pistes de découverte, pas les commandes complètes. Note ce que tu as trouvé et **comment** tu l'as trouvé.
> - Pour chaque étape, colle la **commande exacte** utilisée dans le bloc prévu et capture le résultat.
> - **N'écris jamais un mot de passe** dans ce document, dans une commande collée ou dans une capture. Le mot de passe DSRM se saisit à l'invite.
> - Supprime les blocs `> [!tip]` et `> [!warning]` dans la version rendue.

---

## Sommaire

- [[#1. Objectifs]]
- [[#2. Environnement]]
- [[#3. Installer le rôle Active Directory Domain Services]]
- [[#4. Promouvoir le serveur en contrôleur de domaine]]
- [[#5. Vérifier la réplication Active Directory]]
- [[#6. Validation finale]]
- [[#7. Conclusion et difficultés rencontrées]]

---

## 1. Objectifs

- [ ] Installer le rôle Active Directory Domain Services.
- [ ] Promouvoir Server Core en contrôleur de domaine supplémentaire.
- [ ] Comprendre le fonctionnement de la réplication Active Directory.
- [ ] Vérifier la disponibilité des deux contrôleurs de domaine.
- [ ] Contrôler les résultats depuis le serveur graphique.

---

## 2. Environnement

|Élément|Configuration|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Contrôleur de domaine existant|`SRV-WIN-MEN-01` (`192.168.100.10/24`)|
|Nouveau contrôleur de domaine|`SRV-WIN-MEN-02` (`192.168.100.11/24`)|
|Réseau|`LAB-TSSR-MEN`|

> [!warning] Incohérence de nom dans l'énoncé Le tableau d'environnement et la partie 5 parlent de `SRV-WIN-[TRI]-02`, mais la partie 4 demande de promouvoir `SRV-CORE-[TRI]-02`. Décide quel est le **vrai nom** de ton Server Core (celui du TP précédent), écris-le ci-dessous et utilise-le partout. Si le renommer est nécessaire, **fais-le avant la promotion** : renommer un contrôleur de domaine après coup est bien plus délicat.

**Nom réel du Server Core :**

### 2.1 Vérifications préalables

> [!tip] Guidage Une promotion échoue le plus souvent à cause du **réseau** ou du **DNS**, pas à cause de la commande. Vérifie, sur `[Core]`, avant de commencer :
> 
> - Adresse IP statique `192.168.100.11/24` et même réseau virtuel que `SRV-WIN-MEN-01`. (`Get-NetIPConfiguration`)
> - **Serveur DNS du Core = `192.168.100.10`** : le futur DC doit retrouver le domaine par le DNS du DC existant, pas par un autre. (`Get-DnsClientServerAddress`)
> - Le Core joint le DC existant : `Test-NetConnection 192.168.100.10`.
> - Le Core retrouve les enregistrements du domaine : `Resolve-DnsName _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV`.
> - Nom d'ordinateur correct, heure cohérente avec le DC existant.
> - Un **snapshot** de la VM avant la promotion.

|Vérification|Commande|Résultat attendu|Résultat obtenu|
|---|---|---|---|
|IP et masque||||
|Serveur DNS||||
|Joindre le DC existant||||
|Résolution des SRV du domaine||||
|Nom d'ordinateur||||
|Snapshot fait||||

![[capture-2-verifications.png]]

---

## 3. Installer le rôle Active Directory Domain Services

**Étapes du brief**

1. Identifier le module PowerShell permettant de gérer les rôles et fonctionnalités Windows Server.
2. Rechercher les commandes permettant d'installer un rôle.
3. Installer le rôle AD DS ainsi que les outils d'administration nécessaires.
4. Vérifier que le rôle est installé.

> [!tip] Guidage
> 
> - Pour **trouver le module** d'une commande : `Get-Command -Noun WindowsFeature`, puis regarde la propriété `ModuleName` de la commande retrouvée.
> - Pour **trouver le nom du rôle** : cherche dans la liste des fonctionnalités avec un filtre sur `*AD*` ou `*domain*` (`Get-WindowsFeature`). Note le nom **technique** (colonne _Name_), pas le nom affiché.
> - Lis l'aide de la commande d'installation : `Get-Help <commande> -Examples`. Cherche le paramètre qui ajoute aussi les **outils de gestion** (sur un Core, le module PowerShell Active Directory en fait partie).
> - Pour **vérifier** : la même commande de listage affiche l'état d'installation (colonne _Install State_). Vérifie aussi que le module `ActiveDirectory` est disponible (`Get-Module -ListAvailable`).

|Question|Réponse|
|---|---|
|Module qui gère les rôles et fonctionnalités||
|Commande(s) pour installer un rôle||
|Nom technique du rôle AD DS||
|Paramètre pour les outils d'administration||

**Commande d'installation utilisée** (`[Core]`)

```powershell
# colle ici la commande exacte
```

**Vérification** (`[Core]`)

```powershell
# colle ici la commande de vérification
```

![[capture-3-recherche-module.png]] ![[capture-3-installation.png]] ![[capture-3-verification.png]]

**Commentaires**

---

## 4. Promouvoir le serveur en contrôleur de domaine

**Paramètres de la promotion**

|Paramètre du brief|Valeur demandée|Paramètre PowerShell trouvé|
|---|---|---|
|Domaine|`TSSR-MEN.LAB`||
|Type d'installation|Contrôleur de domaine supplémentaire||
|Contrôleur en lecture seule (RODC)|Non||
|Catalogue global|Activé||
|Site Active Directory|Site existant||
|DNS|Rôle DNS sur le nouveau DC||
|Source de réplication initiale|Contrôleur de domaine existant||
|Mot de passe DSRM|À saisir à l'invite||
|Identifiants autorisés à promouvoir|Compte administrateur du domaine||

**Étapes du brief**

1. Rechercher la commande PowerShell permettant d'ajouter un contrôleur de domaine à un domaine existant.
2. Préparer les paramètres nécessaires à la promotion.
3. Définir le mot de passe de restauration des services d'annuaire (DSRM).
4. Lancer la promotion.
5. Attendre le redémarrage du serveur.

> [!warning] Domaine existant, pas nouvelle forêt Le brief insiste : on **ajoute** un contrôleur à un domaine existant. Les commandes de déploiement AD DS ont des variantes pour une nouvelle forêt, un nouveau domaine et un contrôleur supplémentaire : choisis la bonne et justifie-le.

> [!tip] Guidage
> 
> - Les commandes de déploiement se trouvent dans un module qui apparaît **après** l'installation du rôle : explore avec `Get-Command -Module ADDSDeployment`. Lis les verbes et les noms pour repérer la variante « contrôleur de domaine ».
> - Utilise `Get-Help <commande> -Parameter *` ou `-Examples` pour retrouver le nom de chaque paramètre du tableau ci-dessus (domaine, identifiants, catalogue global, site, DNS, source de réplication, mot de passe DSRM, redémarrage).
> - Le **site** existant : cherche-le sur `[Graphique]` avec les commandes `Get-ADReplicationSite`. Note son nom exact.
> - Les identifiants se demandent avec `Get-Credential` (compte du domaine autorisé à promouvoir).
> - Le mot de passe DSRM est de type `SecureString` : saisis-le avec `Read-Host -AsSecureString`, **jamais en clair dans la commande**. Que permet ce mot de passe, et pourquoi est-il distinct du mot de passe Administrateur du domaine ?
> - Avant de lancer, cherche s'il existe une commande de **test des prérequis** (même module, nom commençant par `Test-`) : elle détecte les problèmes sans rien modifier.
> - Les avertissements affichés à la fin (par exemple sur la délégation DNS) sont fréquents dans un labo isolé : note-les et explique-les.
> - Si la promotion échoue, un journal est écrit dans `C:\Windows\debug` (fichiers `dcpromo*.log`).

**Commande de test des prérequis**

```powershell
# colle ici la commande exacte (si utilisée)
```

**Commande de promotion** (`[Core]`)

```powershell
# colle ici la commande exacte, sans mot de passe en clair
```

**Après le redémarrage**

|Vérification|Résultat|
|---|---|
|Durée de la promotion et du redémarrage||
|Compte avec lequel tu ouvres la session||
|Le serveur est-il bien contrôleur de domaine ?||
|Avertissements rencontrés||

> [!tip] Guidage Réfléchis aussi au **DNS** après promotion : sur chaque contrôleur, quels serveurs DNS faut-il configurer, et dans quel ordre ? Pense aussi à ton **étendue DHCP** : ne distribue-t-elle que le serveur `192.168.100.10` ? Note ce que tu choisis, même si tu ne le modifies pas.

![[capture-4-commande.png]] ![[capture-4-prerequis.png]] ![[capture-4-promotion.png]] ![[capture-4-apres-redemarrage.png]]

**Commentaires**

---

## 5. Vérifier la réplication Active Directory

### 5.1 Lister les contrôleurs de domaine

**Étapes du brief**

1. Afficher la liste des contrôleurs de domaine.
2. Vérifier que les deux serveurs sont présents.

> [!tip] Guidage Cherche dans le module `ActiveDirectory` une commande dont le nom parle de _DomainController_, avec un filtre qui renvoie **tous** les contrôleurs. Sélectionne les propriétés utiles : nom, adresse IPv4, site, catalogue global, système d'exploitation.

```powershell
# colle ici la commande exacte
```

|Contrôleur|IPv4|Site|Catalogue global|
|---|---|---|---|
|||||
|||||

![[capture-5-1-liste-dc.png]]

### 5.2 Contrôler l'état de la réplication

**Étapes du brief**

3. Rechercher les commandes permettant de vérifier la réplication AD.
4. Contrôler l'état de la réplication entre les deux serveurs.

> [!tip] Guidage
> 
> - Deux familles de commandes : l'outil classique **`repadmin`** (résumé, états par partenaire) et les commandes du module `ActiveDirectory` dont le nom contient _Replication_ : `Get-Command -Module ActiveDirectory -Noun *Replication*`.
> - `dcdiag` propose aussi un test dédié à la réplication.
> - Cherche dans le résultat : la date du **dernier succès**, le nombre d'**échecs**, la **direction** (entrante / sortante) et les **partitions** répliquées.
> - Vérifie la réplication **dans les deux sens**.

|Commande|Ce qu'elle montre|Résultat observé|
|---|---|---|
||||
||||
||||

![[capture-5-2-replication.png]]

**Réplication AD avec tes mots**

> [!question] À traiter
> 
> - Qu'est-ce que la réplication **multi-maître** ? Peut-on modifier l'annuaire sur n'importe quel contrôleur ?
> - Quelles **partitions** sont répliquées ? Et le dossier **SYSVOL** ?
> - Comment AD sait-il **quoi** répliquer et **vers qui** ? (notions de USN et de topologie)
> - Quelle différence entre réplication **intra-site** et **inter-site** ?

### 5.3 Test de réplication

**Étapes du brief**

1. Créer sur `SRV-WIN-MEN-01` une OU nommée `TEST-REPLICATION-CORE`.
2. Vérifier sa présence en interrogeant explicitement l'annuaire de `SRV-WIN-MEN-02`.
3. Créer un utilisateur de test dans cette OU depuis PowerShell, en ciblant le contrôleur Core.
4. Vérifier sa présence en interrogeant explicitement le serveur graphique.
5. Supprimer les objets de test après validation.

> [!tip] Guidage
> 
> - Les commandes `New-AD...`, `Get-AD...` et `Remove-AD...` du module `ActiveDirectory` ont un paramètre pour **cibler un contrôleur précis** : trouve-le avec `Get-Help New-ADOrganizationalUnit -Parameter Server`. Sans lui, la commande choisit le contrôleur toute seule, et le test ne prouve rien.
> - Si l'objet n'apparaît pas tout de suite sur l'autre contrôleur, patiente quelques secondes et relance. Sinon, cherche comment **forcer** la réplication avec `repadmin /syncall`.
> - Pour l'utilisateur de test, un mot de passe n'est pas nécessaire pour la démonstration : un compte créé désactivé suffit. Ne mets aucun mot de passe en clair.
> - Pour la suppression, tu as déjà rencontré la **protection contre la suppression accidentelle** (OU `PROD`) : l'OU de test est protégée à sa création. Supprime d'abord l'utilisateur, puis retire la protection de l'OU avant de la supprimer.
> - Après la suppression, vérifie que les objets ont **disparu des deux contrôleurs**.

|Étape|Contrôleur ciblé|Commande|Résultat|
|---|---|---|---|
|Créer l'OU `TEST-REPLICATION-CORE`|`SRV-WIN-MEN-01`|||
|Lire l'OU|`SRV-WIN-MEN-02`|||
|Créer l'utilisateur de test|`SRV-WIN-MEN-02`|||
|Lire l'utilisateur|`SRV-WIN-MEN-01`|||
|Supprimer les objets||||
|Contrôler la suppression|les deux|||

![[capture-5-3-creation-ou.png]] ![[capture-5-3-lecture-core.png]] ![[capture-5-3-creation-utilisateur.png]] ![[capture-5-3-lecture-graphique.png]] ![[capture-5-3-suppression.png]]

### 5.4 Contrôle depuis le serveur graphique

> [!tip] Guidage Sur `[Graphique]`, confirme le résultat avec les consoles : _Active Directory Users and Computers_ (OU `Domain Controllers`, qui doit lister les deux serveurs), _Active Directory Sites and Services_ (le nouveau serveur sous le site, avec ses **connexions de réplication**) et _DNS_ (le nouveau serveur est-il listé parmi les serveurs de noms de la zone ?).

![[capture-5-4-aduc.png]] ![[capture-5-4-sites-services.png]] ![[capture-5-4-dns.png]]

**Commentaires**

---

## 6. Validation finale

|Vérification|Validé|Preuve|
|---|---|---|
|Le rôle AD DS est installé|☐|[[#3. Installer le rôle Active Directory Domain Services]]|
|Le serveur est promu en contrôleur de domaine supplémentaire|☐|[[#4. Promouvoir le serveur en contrôleur de domaine]]|
|Les deux contrôleurs de domaine sont opérationnels|☐|[[#5.1 Lister les contrôleurs de domaine]]|
|La réplication fonctionne dans les deux sens|☐|[[#5.2 Contrôler l'état de la réplication]]|
|Les objets sont accessibles depuis les deux contrôleurs|☐|[[#5.3 Test de réplication]]|

> [!check] À valider avant de rendre le TP
> 
> - [ ] Aucune commande collée ne contient de mot de passe
> - [ ] Chaque étape a sa commande exacte et sa capture
> - [ ] Les objets de test ont été supprimés des deux contrôleurs
> - [ ] Le nom du Server Core est cohérent dans tout le document

---

## 7. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

---

> [!note] Rendu
> 
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs de commandes remplis
> - [ ] Aucun mot de passe visible (texte ou capture)
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Export PDF réalisé (si demandé)