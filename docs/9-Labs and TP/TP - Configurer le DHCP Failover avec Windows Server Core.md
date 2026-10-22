> [!abstract] Contexte Le laboratoire dispose de deux contrôleurs de domaine et de deux serveurs DNS, mais l'attribution des adresses IPv4 dépend encore d'un seul serveur DHCP. Il faut installer DHCP sur Windows Server Core, établir une relation de basculement (failover) avec le serveur existant et vérifier son fonctionnement. Les configurations se font avec PowerShell et se valident avec les outils graphiques.

> [!info] Comment utiliser ce document
> 
> - Trois machines : `[Graphique]` = `SRV-WIN-MEN-01` (interface complète, serveur DHCP existant), `[Core]` = `SRV-WIN-MEN-02` (Server Core), `[Client]` = `CLI-WIN-MEN-01` (Windows 11, en français).
> - Chaque partie suit le schéma : **Comprendre** (pourquoi), **Pas à pas** (quoi faire, avec des squelettes de commandes), **À noter** (ce qu'il faut observer), puis captures.
> - Dans les squelettes, `<...>` indique une valeur à remplacer. Colle ensuite la commande **exacte** utilisée dans le bloc prévu.
> - Les `> [!tip]` et `> [!warning]` sont du guidage : à supprimer dans la version rendue.
> - **La version pour le formateur** est en bas du document, après la grande coupure.
> - **N'écris pas le secret partagé** du failover dans le document, ni dans une capture.

> [!tip] Ordre conseillé
> 
> 1. Partie 3 : installer et autoriser DHCP sur le Core (10 min).
> 2. Partie 4 : relever l'état de départ de l'étendue (5 min).
> 3. Partie 5 : créer la relation de failover (10 min). **Snapshot des deux serveurs avant.**
> 4. Partie 6 : vérifier la synchronisation (10 min).
> 5. Partie 7 : tester depuis le client (10 min).
> 6. Partie 8 : simuler la panne (15 min). **Snapshot avant.**

---

## Sommaire

- [[#1. Objectifs]]
- [[#2. Environnement]]
- [[#3. Installer et autoriser DHCP sur Core]]
- [[#4. Vérifier l'étendue actuelle]]
- [[#5. Mettre en place le DHCP Failover]]
- [[#6. Vérifier la synchronisation]]
- [[#7. Tester depuis Windows 11]]
- [[#8. Simuler une indisponibilité du serveur DHCP actif]]
- [[#9. Validation finale]]
- [[#10. Conclusion et difficultés rencontrées]]

---

## 1. Objectifs

- [ ] Installer et autoriser le service DHCP sur Windows Server Core.
- [ ] Comprendre la différence entre les modes Load Balance et Standby.
- [ ] Configurer une relation DHCP Failover actif/passif.
- [ ] Vérifier la synchronisation des étendues et des baux.
- [ ] Tester le comportement du service en cas d'indisponibilité du serveur actif.

---

## 2. Environnement

|Élément|Configuration|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur DHCP existant|`SRV-WIN-MEN-01` : `192.168.100.10`|
|Serveur Core|`SRV-WIN-MEN-02` : `192.168.100.11`|
|Client|`CLI-WIN-MEN-01`|
|Réseau|`192.168.100.0/24`|

**Étendue existante**

|Paramètre|Valeur|
|---|---|
|Nom|`LAN-TSSR`|
|Plage|`192.168.100.150` à `192.168.100.200`|
|Masque|`255.255.255.0`|
|Domaine DNS|`TSSR-MEN.LAB`|
|DNS distribués|`192.168.100.10` et `192.168.100.11`|

**Paramètres du failover imposés**

|Paramètre|Valeur|
|---|---|
|Nom de relation|`CLUSTER-DHCP-TSSR-MEN`|
|Mode|Hot Standby|
|Serveur actif|`SRV-WIN-MEN-01`|
|Partenaire de secours|`SRV-WIN-MEN-02`|
|Étendue|`192.168.100.0/24`|
|Réserve d'adresses du partenaire|10 %|

> [!tip] Guidage
> 
> - Si le nom de ton Server Core diffère de `SRV-WIN-MEN-02`, note le **nom réel** ci-dessous et utilise-le partout.
> - Ouvre PowerShell avec un compte administrateur du domaine (`TSSR-MEN\Administrator`) : l'autorisation dans Active Directory et le failover l'exigent.
> - Les commandes `DhcpServer` acceptent `-ComputerName` : depuis `[Graphique]`, tu peux interroger le Core. Cela repose sur la gestion à distance (comme au TP DNS). Si ça échoue, tape la commande en local sur le Core.

**Nom réel du Server Core :**

---

## 3. Installer et autoriser DHCP sur Core

### Comprendre

> [!question] Installer, configurer, autoriser : trois choses différentes
> 
> - **Installer** le rôle met le service DHCP sur la machine.
> - La **configuration post-déploiement** crée les groupes de sécurité locaux (_DHCP Administrators_, _DHCP Users_) pour déléguer l'administration.
> - **Autoriser** le serveur dans Active Directory le déclare comme serveur DHCP légitime du domaine. Sans cela, un serveur DHCP membre d'un domaine **ne distribue pas** d'adresses : c'est une protection contre les serveurs DHCP pirates.
> 
> Sur le serveur graphique, tu avais fait ces trois choses avec l'assistant. Ici, tu les fais une par une en PowerShell.

Écris en une phrase, avec tes mots, pourquoi un serveur DHCP doit être autorisé dans Active Directory :

### Pas à pas (`[Core]`)

**Étape 1 : installer le rôle DHCP et les outils d'administration**

```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
```

Si tu veux retrouver le nom du rôle, cherche avec `Get-WindowsFeature *DHCP*`. Note le résultat de l'installation (_Success_, besoin d'un redémarrage ou non).

**Étape 2 : configuration post-déploiement**

Cherche dans le module `DhcpServer` la commande qui crée les groupes de sécurité (`Get-Command -Module DhcpServer -Noun *SecurityGroup*`), puis redémarre le service pour prendre en compte les nouveaux groupes :

```powershell
Add-DhcpServerSecurityGroup
Restart-Service -Name DHCPServer
```

**Étape 3 : vérifier la présence et le fonctionnement du service**

```powershell
Get-WindowsFeature -Name DHCP
Get-Service -Name DHCPServer
```

Regarde l'état d'installation, le statut (_Running_) et le type de démarrage (_Automatic_).

**Étape 4 : autoriser le serveur dans Active Directory**

Cherche la commande avec `Get-Command -Module DhcpServer -Noun *InDC*`. Elle demande le **nom DNS complet** et l'**adresse IP** du serveur :

```powershell
Add-DhcpServerInDC -DnsName <nom DNS complet du Core> -IPAddress <adresse IPv4 du Core>
```

**Étape 5 : vérifier que les deux serveurs sont autorisés**

```powershell
Get-DhcpServerInDC
```

La liste doit montrer **deux** serveurs : `SRV-WIN-MEN-01` et le Core, avec leurs adresses IP.

> [!warning] Si l'autorisation échoue Vérifie que tu es connecté avec un compte qui a le droit d'autoriser un serveur DHCP dans l'annuaire (un administrateur du domaine racine) et que le nom DNS complet du Core se résout (`Resolve-DnsName <nom>`). N'invente pas l'adresse IP : relève-la sur le Core (`Get-NetIPAddress`).

### À noter

|Vérification|Résultat|
|---|---|
|Résultat de l'installation du rôle||
|Groupes de sécurité créés||
|Service `DHCPServer` : statut et démarrage||
|Serveur Core autorisé (commande utilisée)||
|Serveurs autorisés dans l'annuaire (liste)||

![[capture-3-installation.png]] ![[capture-3-service.png]] ![[capture-3-autorisation.png]] ![[capture-3-serveurs-autorises.png]]

**Commentaires**

---

## 4. Vérifier l'étendue actuelle

### Comprendre

> [!question] Pourquoi relever l'état de départ Avant de créer le failover, tu dois savoir **ce que contient l'étendue** : plage, options (DNS, domaine), exclusions et baux. Après la mise en place, c'est ce contenu que le serveur de secours doit retrouver, à l'identique.

### Pas à pas (`[Graphique]`)

**Étape 1 : vérifier la plage de l'étendue `LAN-TSSR`**

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-01
```

Relève le nom, l'identifiant d'étendue, la plage (début et fin), le masque, l'état (_Active_) et la durée du bail.

**Étape 2 : vérifier les DNS et le suffixe de domaine distribués**

```powershell
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
```

Cherche dans le résultat l'option **6** (serveurs DNS) et l'option **15** (nom de domaine DNS). L'option 6 doit contenir **les deux** DNS.

> [!tip] Guidage
> 
> - Une option peut être définie au niveau de l'**étendue** ou au niveau du **serveur**. Pour la redondance, repère **où** sont tes options : la réplication du failover ne copie que ce qui est dans l'étendue (vérifie ce point dans la documentation Microsoft).
> - Pour un affichage plus lisible : `... | Select-Object OptionId, Name, @{n='Value';e={$_.Value -join ', '}}`.

**Étape 3 : relever les exclusions et les baux actuels**

```powershell
Get-DhcpServerv4ExclusionRange -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
```

**Étape 4 : vérifier qu'un poste obtient une configuration valide** (`[Client]`)

```powershell
ipconfig /renew
ipconfig /all
```

Regarde : l'adresse (dans la plage), le serveur DHCP, les serveurs DNS et le suffixe DNS. Tu es sur la console de la VM, pas en contrôle à distance : `/renew` seul suffit ici.

**Étape 5 : constater l'absence de l'étendue sur le Core** (avant le failover)

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02
```

Le résultat doit être vide : c'est ton « avant ».

### À noter

|Élément|Valeur constatée|
|---|---|
|Nom de l'étendue||
|Plage||
|Masque||
|État||
|Durée du bail||
|Option 6 (DNS)||
|Option 15 (domaine)||
|Où sont définies les options (étendue / serveur)||
|Exclusions||
|Baux actuels||
|Adresse obtenue par le client||
|Étendue présente sur le Core ?||

![[capture-4-etendue.png]] ![[capture-4-options.png]] ![[capture-4-baux.png]] ![[capture-4-client.png]] ![[capture-4-core-avant.png]]

**Commentaires**

---

## 5. Mettre en place le DHCP Failover

### Comprendre

> [!question] Qu'est-ce que le DHCP Failover Avant Windows Server 2012, on se protégeait d'une panne en **coupant l'étendue en deux** (80/20) sur deux serveurs indépendants, sans partage d'information. Le **DHCP Failover** fait mieux : les deux serveurs forment une **relation** et partagent la **même étendue et la même base de baux**. Ils se parlent en permanence (en TCP, port 647) pour rester synchronisés.
> 
> Il existe **deux modes** :
> 
> - **Load Balance** : les deux serveurs répondent aux clients en même temps, avec une répartition (par défaut 50/50).
> - **Hot Standby** : un serveur **actif** répond à tous les clients ; le serveur **de secours** ne répond que si l'actif tombe, et il garde en **réserve** un pourcentage des adresses pour les nouveaux clients pendant la panne.

Complète ce tableau avec tes mots, après avoir lu l'aide ou la documentation :

|Critère|Load Balance|Hot Standby|
|---|---|---|
|Qui répond aux clients en fonctionnement normal ?|||
|Rôle de chaque serveur|||
|Réserve d'adresses|||
|Cas d'usage typique|||
|Pourquoi choisir Hot Standby ici ?|||

> [!tip] Guidage Fais le calcul de ta réserve : l'étendue contient `.150` à `.200`, soit combien d'adresses ? Quel est **10 %** de ce nombre ? Cette réserve est ce que le Core pourra donner à de nouveaux clients pendant la panne.

Nombre d'adresses de la plage, et adresses de la réserve (arrondi) :

**Les états d'une relation** (à compléter en cherchant dans la documentation) :

|État|Sens|Que fait le serveur de secours ?|
|---|---|---|
|Normal|||
|Communication Interrupted|||
|Partner Down|||

### Pas à pas

**Étape 1 : rechercher les commandes liées au failover**

```powershell
Get-Command -Module DhcpServer -Noun *Failover*
Get-Help Add-DhcpServerv4Failover -Examples
Get-Help Add-DhcpServerv4Failover
```

Repère dans l'aide que la commande a **deux jeux de paramètres** : un pour _Load Balance_, un pour _Hot Standby_. Le mode n'est pas un paramètre : c'est l'**ensemble des paramètres** que tu fournis qui le détermine.

**Étape 2 : faire correspondre les paramètres imposés**

|Paramètre imposé|Paramètre PowerShell trouvé|
|---|---|
|Nom de la relation||
|Serveur sur lequel on lance la commande (actif)||
|Partenaire de secours||
|Étendue||
|Rôle du serveur actif||
|Réserve d'adresses||
|Secret partagé (authentification entre serveurs)||

> [!tip] Guidage
> 
> - Le paramètre de rôle (`-ServerRole`) désigne le rôle du serveur indiqué par `-ComputerName`.
> - Le **secret partagé** authentifie les messages entre les deux serveurs. Choisis-en un, **ne l'écris pas** dans ce document. Il apparaît en clair dans l'historique de la console : acceptable dans un labo, à éviter en production.
> - Pose-toi la question de la **durée maximale d'avance du client (MCLT)** : cherche ce que c'est, et pourquoi les baux donnés par le serveur de secours pendant une panne sont plus courts.

**Étape 3 : créer la relation** (depuis le serveur qui héberge l'étendue, donc `[Graphique]`)

```powershell
Add-DhcpServerv4Failover -ComputerName <serveur actif> -Name "<nom de la relation>" -PartnerServer <partenaire> -ScopeId <étendue> -ServerRole <rôle> -ReservePercent <pourcentage> -SharedSecret "<secret, ne pas le noter ici>"
```

**Étape 4 : vérifier que chaque serveur identifie son partenaire**

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02
```

Pour tout voir : ajoute `| Format-List *`. Relève le nom de la relation, le mode, le rôle de chaque serveur, le partenaire, le pourcentage de réserve, la durée MCLT, le basculement automatique (_AutoStateTransition_) et l'**état**.

**Étape 5 : vérifier que la relation est opérationnelle**

L'état doit être **Normal** sur les deux serveurs. S'il ne l'est pas, regarde la section suivante.

> [!warning] Si la relation ne s'établit pas
> 
> - Le Core est-il **autorisé** et le service DHCP **démarré** (partie 3) ?
> - Les deux serveurs se joignent-ils en **TCP 647** ? Cherche les règles de pare-feu liées à DHCP : `Get-NetFirewallRule -DisplayName *DHCP*`.
> - Le nom du partenaire se résout-il en DNS ? Essaie avec l'adresse IP.
> - Si la création échoue à mi-chemin, `Get-DhcpServerv4Failover` te dit ce qui existe déjà avant de recommencer.

### À noter

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|Nom de la relation|||
|Mode|||
|Rôle|||
|Partenaire identifié|||
|Réserve (%)|||
|MCLT|||
|Basculement automatique|||
|État|||

**Commande de création utilisée** (sans le secret) :

```powershell
# colle ici la commande exacte, secret remplacé par ***
```

![[capture-5-aide.png]] ![[capture-5-creation.png]] ![[capture-5-relation-01.png]] ![[capture-5-relation-02.png]]

**Commentaires**

---

## 6. Vérifier la synchronisation

### Comprendre

> [!question] Ce que le failover réplique Quand la relation est créée, le serveur actif **copie l'étendue** vers le partenaire (plage, options, exclusions, durée de bail) puis les deux serveurs échangent les **baux** en continu. Tu peux aussi **forcer** la réplication de la configuration. Les paramètres définis au **niveau du serveur** (et non de l'étendue) ne sont, en principe, pas répliqués : c'est pour cela qu'on a relevé où se trouvaient les options en partie 4.

### Pas à pas

**Étape 1 : examiner l'état de la relation sur les deux serveurs**

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *
```

**Étape 2 : vérifier la présence de l'étendue sur le Core**

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02
```

**Étape 3 : comparer les paramètres des étendues**

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-01 | Format-List *
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02 | Format-List *
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -ComputerName <serveur> | Select-Object OptionId, Name, @{n='Value';e={$_.Value -join ', '}}
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName <serveur>
```

Compare : plage, masque, état, durée du bail, options 6 et 15, exclusions et baux. Si quelque chose manque, force la réplication puis relis :

```powershell
Invoke-DhcpServerv4FailoverReplication -ComputerName SRV-WIN-MEN-01 -Name "<nom de la relation>"
```

**Étape 4 : contrôler la relation depuis la console DHCP du serveur graphique** (`[Graphique]`)

1. Console _DHCP_. Si le Core n'apparaît pas : clic droit sur **DHCP** → **Add Server...** → ajoute le Core.
2. Développe **IPv4** → clic droit sur l'étendue `LAN-TSSR` → **Properties**, puis cherche l'onglet **Failover** : relation, mode, état et partenaire doivent y apparaître. Selon la version, l'état de la relation est aussi visible dans les propriétés de **IPv4**.
3. Dans l'étendue du Core, regarde **Address Leases** : le bail de ton client doit y figurer.

### À noter

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|État de la relation|||
|Étendue présente|||
|Plage|||
|Masque|||
|Durée du bail|||
|Option 6 (DNS)|||
|Option 15 (domaine)|||
|Exclusions|||
|Baux présents|||

![[capture-6-etat.png]] ![[capture-6-etendue-core.png]] ![[capture-6-comparaison.png]] ![[capture-6-console-failover.png]] ![[capture-6-baux-core.png]]

**Commentaires (différences constatées, réplication forcée ou non)**

---

## 7. Tester depuis Windows 11

### Comprendre

> [!question] Ce que tu t'attends à voir En fonctionnement normal, en mode Hot Standby, **seul le serveur actif répond** aux clients : le serveur DHCP indiqué dans `ipconfig /all` doit être `192.168.100.10`. Le Core a pourtant le bail dans sa base (réplication), mais il ne répond pas tant que l'actif est disponible.

### Pas à pas (`[Client]`)

**Étape 1 : vérifier que le client est en obtention automatique**

```powershell
Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, Dhcp
ipconfig /all
```

Cherche _DHCP activé : Oui_. Les DNS ne doivent pas être saisis à la main.

**Étape 2 : libérer puis renouveler le bail**

Tu es sur la console de la VM, donc tu peux enchaîner. Sous Windows PowerShell 5.1, le séparateur est le point-virgule :

```powershell
ipconfig /release; ipconfig /renew
```

**Étape 3 : vérifier l'adresse et le serveur qui a répondu**

```powershell
ipconfig /all
```

Relève : l'adresse (dans la plage `.150` à `.200` ?), le **serveur DHCP**, les **deux serveurs DNS**, le suffixe, les dates d'obtention et d'expiration du bail.

**Étape 4 : contrôler le bail côté service DHCP**

```powershell
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02
```

Retrouve ton client par son adresse MAC (`ipconfig /all`) ou son nom.

### À noter

|Élément|Valeur constatée|
|---|---|
|Obtention automatique (IP et DNS)||
|Adresse obtenue||
|Dans la plage prévue ?||
|Serveur DHCP qui a répondu||
|DNS reçus (ordre)||
|Bail obtenu / expirant||
|Bail visible sur `SRV-WIN-MEN-01`||
|Bail visible sur `SRV-WIN-MEN-02`||

![[capture-7-client-auto.png]] ![[capture-7-release-renew.png]] ![[capture-7-ipconfig.png]] ![[capture-7-baux-serveurs.png]]

**Commentaires**

---

## 8. Simuler une indisponibilité du serveur DHCP actif

### Comprendre

> [!question] Ce qui doit se passer, et ses limites Quand le serveur actif ne répond plus, la relation passe de **Normal** à **Communication Interrupted** : le Core sait qu'il ne joint plus son partenaire, mais ne sait pas **pourquoi** (panne, ou simple coupure réseau ?). Il adopte donc une attitude prudente. L'état **Partner Down** (où le serveur de secours prend l'ensemble de l'étendue en charge) ne survient pas forcément tout seul : il dépend d'un **basculement automatique** (_AutoStateTransition_) et d'un délai (_StateSwitchInterval_), ou d'une décision de l'administrateur. Vérifie la valeur par défaut avec `Get-DhcpServerv4Failover | Format-List *`. Les **limites** à observer : quelles adresses le Core peut-il donner, pour quelle durée, et à quels clients (ceux qui ont déjà un bail, ou de nouveaux).

> [!warning] Précautions
> 
> - **Snapshot** des deux serveurs avant de commencer.
> - Tu arrêtes **uniquement le service DHCP** de `SRV-WIN-MEN-01`, jamais le contrôleur de domaine ni la machine : le DNS, Active Directory et la réplication doivent continuer de fonctionner.
> - Pendant la panne, interroge le **Core** : `SRV-WIN-MEN-01` ne répondra plus aux commandes DHCP.
> - N'oublie pas de **redémarrer** le service à la fin (étape 6).

### Pas à pas

**Étape 1 : relever l'état initial** (partenariat et baux)

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02
```

**Étape 2 : arrêter le service DHCP sur `SRV-WIN-MEN-01`** (`[Graphique]`)

```powershell
Stop-Service -Name DHCPServer
Get-Service -Name DHCPServer
```

Note l'heure exacte : elle te sert à mesurer le délai des changements d'état.

**Étape 3 : observer l'évolution de l'état du partenariat** (`[Core]`)

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *
```

Relance la commande à intervalles réguliers (une ou deux minutes) et note chaque changement d'état avec l'heure.

**Étape 4 : tester le comportement depuis le client** (`[Client]`)

Teste d'abord un client **qui a déjà un bail** (renouvellement), puis un cas de **nouveau bail** :

```powershell
ipconfig /renew
ipconfig /all
```

```powershell
ipconfig /release; ipconfig /renew
ipconfig /all
```

**Étape 5 : identifier le serveur qui a répondu et relever les limites** (`[Client]`, `[Core]`)

Dans `ipconfig /all`, relève le **serveur DHCP**, l'adresse, la **durée du bail** et les dates. Côté Core :

```powershell
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02
```

Compare la durée du bail reçu avec celle de l'étendue.

**Étape 6 : redémarrer le service DHCP du serveur principal** (`[Graphique]`)

```powershell
Start-Service -Name DHCPServer
Get-Service -Name DHCPServer
```

**Étape 7 : vérifier le retour à la normale**

Relève, à intervalles, l'état sur les deux serveurs jusqu'à **Normal** (il peut passer par des états de récupération intermédiaires), puis compare les baux :

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02
```

### À noter

**Évolution de l'état**

|Heure|Événement|État vu sur `SRV-WIN-MEN-01`|État vu sur `SRV-WIN-MEN-02`|
|---|---|---|---|
||Avant la panne|||
||Service arrêté sur `-01`|||
|||||
|||||
||Service redémarré sur `-01`|||
||Retour à la normale|||

**Comportement du client pendant la panne**

|Test|Serveur qui a répondu|Adresse|Durée du bail|Résultat|
|---|---|---|---|---|
|Renouvellement (bail existant)|||||
|Nouveau bail (`/release` puis `/renew`)|||||

**Limites observées** (réponds avec tes observations) :

- Le Core a-t-il pu renouveler le bail existant ?
- A-t-il pu donner un **nouveau** bail ? Dans quelle partie de la plage (la réserve de 10 %) ?
- Quelle **durée de bail** a-t-il accordée, comparée à celle de l'étendue ?
- L'état est-il resté à _Communication Interrupted_, ou est-il passé à _Partner Down_ ? Pourquoi ?
- Que se passerait-il si la réserve était épuisée ?

![[capture-8-etat-initial.png]] ![[capture-8-service-arrete.png]] ![[capture-8-etat-interrompu.png]] ![[capture-8-client-renouvellement.png]] ![[capture-8-client-nouveau-bail.png]] ![[capture-8-baux-core.png]] ![[capture-8-service-redemarre.png]] ![[capture-8-retour-normal.png]]

**Commentaires**

---

## 9. Validation finale

|Vérification|Validé|Preuve|
|---|---|---|
|DHCP est installé et autorisé sur Server Core|☐|[[#3. Installer et autoriser DHCP sur Core]]|
|Le partenariat Hot Standby est en place|☐|[[#5. Mettre en place le DHCP Failover]]|
|L'étendue et les baux sont synchronisés|☐|[[#6. Vérifier la synchronisation]]|
|Le client Windows 11 reçoit une configuration correcte|☐|[[#7. Tester depuis Windows 11]]|
|Le serveur de secours a été testé et son fonctionnement expliqué|☐|[[#8. Simuler une indisponibilité du serveur DHCP actif]]|
|Le service principal est rétabli et la relation est à l'état normal|☐|[[#8. Simuler une indisponibilité du serveur DHCP actif]]|

> [!check] À valider avant de rendre le TP
> 
> - [ ] Chaque étape a sa commande exacte et sa capture
> - [ ] Aucun secret partagé visible (texte ou capture)
> - [ ] Les limites observées pendant la panne sont écrites avec tes mots
> - [ ] Le service DHCP de `SRV-WIN-MEN-01` est bien redémarré et la relation est à **Normal**

---

## 10. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

### Commandes utiles (aide-mémoire)

```powershell
# Installation et autorisation
Install-WindowsFeature -Name DHCP -IncludeManagementTools
Add-DhcpServerSecurityGroup
Add-DhcpServerInDC -DnsName <nom DNS complet> -IPAddress <ip>
Get-DhcpServerInDC

# Étendue
Get-DhcpServerv4Scope -ComputerName <serveur>
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -ComputerName <serveur>
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName <serveur>

# Failover
Get-Command -Module DhcpServer -Noun *Failover*
Add-DhcpServerv4Failover -ComputerName <actif> -Name "<relation>" -PartnerServer <secours> -ScopeId <étendue> -ServerRole <rôle> -ReservePercent <n> -SharedSecret "<secret>"
Get-DhcpServerv4Failover -ComputerName <serveur> | Format-List *
Invoke-DhcpServerv4FailoverReplication -ComputerName <serveur> -Name "<relation>"

# Service
Get-Service -Name DHCPServer
Stop-Service -Name DHCPServer
Start-Service -Name DHCPServer

# Client
ipconfig /release; ipconfig /renew
ipconfig /all
```

---

> [!note] Rendu
> 
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs de commandes et tableaux remplis
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Export PDF réalisé (si demandé)

<br> <br> <br> <br> <br>

---

---

---

<br> <br> <br> <br> <br>

# ✂ VERSION POUR LE FORMATEUR (à découper ici)

> Tout ce qui suit est la **version à rendre** : pas de guidage, pas d'explications d'étudiant. Remplis les champs, colle tes commandes, insère les captures. Si tu publies le guide sur ton site, **ne publie pas cette partie** (elle va dans le dossier `Deliverable version`).

---

# TP - Configurer le DHCP Failover avec Windows Server Core

**Domaine :** `TSSR-MEN.LAB` · **Serveur existant :** `SRV-WIN-MEN-01` (`192.168.100.10`) · **Serveur Core :** `SRV-WIN-MEN-02` (`192.168.100.11`) · **Client :** `CLI-WIN-MEN-01`

|Paramètre du failover|Valeur|
|---|---|
|Nom de relation|`CLUSTER-DHCP-TSSR-MEN`|
|Mode|Hot Standby|
|Serveur actif|`SRV-WIN-MEN-01`|
|Partenaire de secours|`SRV-WIN-MEN-02`|
|Étendue|`192.168.100.0/24`|
|Réserve d'adresses du partenaire|10 %|

## 3. Installation et autorisation de DHCP sur Core (rendu)

```powershell
# installation du rôle et des outils
```

```powershell
# configuration post-déploiement et vérification du service
```

```powershell
# autorisation dans Active Directory et vérification des deux serveurs autorisés
```

|Vérification|Résultat|
|---|---|
|Rôle DHCP installé||
|Service `DHCPServer` (statut, démarrage)||
|Serveur Core autorisé||
|Serveurs autorisés dans l'annuaire||

![[capture-3-installation.png]] ![[capture-3-service.png]] ![[capture-3-autorisation.png]] ![[capture-3-serveurs-autorises.png]]

**Commentaires :**

## 4. Étendue actuelle (rendu)

|Élément|Valeur constatée|
|---|---|
|Nom||
|Plage||
|Masque||
|Option 6 (DNS)||
|Option 15 (domaine)||
|Adresse obtenue par le client||

```powershell
# commandes utilisées pour relever l'étendue, les options et les baux
```

![[capture-4-etendue.png]] ![[capture-4-options.png]] ![[capture-4-client.png]]

**Commentaires :**

## 5. Mise en place du DHCP Failover (rendu)

**Différence entre Load Balance et Hot Standby :**

**Commande de création** (secret remplacé par `***`) :

```powershell
# commande exacte
```

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|Nom de la relation|||
|Mode|||
|Rôle|||
|Partenaire|||
|Réserve (%)|||
|État|||

![[capture-5-creation.png]] ![[capture-5-relation-01.png]] ![[capture-5-relation-02.png]]

**Commentaires :**

## 6. Synchronisation (rendu)

```powershell
# commandes de comparaison des étendues, options et baux sur les deux serveurs
```

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|Étendue présente|||
|Plage / masque|||
|Options 6 et 15|||
|Baux présents|||

![[capture-6-etat.png]] ![[capture-6-etendue-core.png]] ![[capture-6-console-failover.png]]

**Commentaires :**

## 7. Test depuis Windows 11 (rendu)

```powershell
# commandes exécutées sur le client
```

|Élément|Valeur constatée|
|---|---|
|Adresse obtenue (dans la plage ?)||
|Serveur DHCP qui a répondu||
|DNS reçus||
|Bail visible sur `SRV-WIN-MEN-01` / `-02`||

![[capture-7-client-auto.png]] ![[capture-7-ipconfig.png]] ![[capture-7-baux-serveurs.png]]

**Commentaires :**

## 8. Indisponibilité du serveur DHCP actif (rendu)

```powershell
# commandes : état initial, arrêt du service, observation, tests client, redémarrage, retour à la normale
```

|Heure|Événement|État sur `SRV-WIN-MEN-01`|État sur `SRV-WIN-MEN-02`|
|---|---|---|---|
||Avant la panne|||
||Service arrêté sur `-01`|||
|||||
||Service redémarré sur `-01`|||
||Retour à la normale|||

|Test client|Serveur qui a répondu|Adresse|Durée du bail|Résultat|
|---|---|---|---|---|
|Renouvellement|||||
|Nouveau bail|||||

**Limites observées :**

![[capture-8-etat-interrompu.png]] ![[capture-8-client-renouvellement.png]] ![[capture-8-client-nouveau-bail.png]] ![[capture-8-retour-normal.png]]

## 9. Validation finale (rendu)

|Vérification|Validé|
|---|---|
|DHCP installé et autorisé sur Server Core|☐|
|Partenariat Hot Standby en place|☐|
|Étendue et baux synchronisés|☐|
|Client Windows 11 : configuration correcte|☐|
|Serveur de secours testé et expliqué|☐|
|Service principal rétabli, relation à l'état normal|☐|

**Conclusion et difficultés rencontrées :**

|Problème|Cause|Solution|
|---|---|---|
||||