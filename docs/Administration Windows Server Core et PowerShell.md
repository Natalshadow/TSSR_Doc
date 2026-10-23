
> [!abstract] À propos de ce support
> Support de cours reconstruit à partir du document du formateur. Les commandes tronquées ont été complétées, les tableaux remis en forme, et des notes ont été ajoutées là où le cours est incomplet, ambigu ou demande de la prudence. Les notes `> [!note]` ne remplacent pas le cours : elles l'expliquent.

> [!info] Comment réviser avec ce support
> 1. Lis une section, puis ferme-la et refais les commandes sur ta VM.
> 2. Pour chaque commande, prédis ce qu'elle va renvoyer **avant** de l'exécuter.
> 3. Termine par l'[auto-évaluation](#auto-evaluation) : elle te dit ce qui est acquis et ce qu'il faut revoir.

---

## Sommaire

1. [Introduction à l'administration Windows Server](#1-introduction-a-ladministration-windows-server)
2. [Fondamentaux de PowerShell](#2-fondamentaux-de-powershell)
3. [Administration de Windows Server Core](#3-administration-de-windows-server-core)
4. [Administration réseau et pare-feu](#4-administration-reseau-et-pare-feu-avec-powershell)
5. [Administration distante](#5-administration-distante)
6. [Administration Active Directory](#6-administration-active-directory)
7. [Administration DNS](#7-administration-dns)
8. [Administration DHCP et DHCP Failover](#8-administration-dhcp-et-dhcp-failover)
9. [Gestion des rôles FSMO](#9-gestion-des-roles-fsmo)
10. [Diagnostic et dépannage](#10-diagnostic-et-depannage)
11. [Auto-évaluation](#auto-evaluation)

---

## 1. Introduction à l'administration Windows Server

### 1.1 Objectifs du cours

- Administrer Windows Server en ligne de commande avec PowerShell.
- Installer et exploiter Windows Server Core.
- Rechercher une cmdlet, en comprendre les paramètres et vérifier son résultat.
- Administrer les paramètres système, réseau, services et règles de sécurité.
- Installer et administrer Active Directory, DNS et DHCP.
- Contrôler la réplication AD, une relation DHCP Failover et les rôles FSMO.
- Diagnostiquer des incidents et documenter les opérations.

### 1.2 Principaux outils d'administration

| Outil | Utilisation |
|---|---|
| PowerShell | Administration en ligne de commande et automatisation |
| SConfig | Configuration initiale et mises à jour de Server Core |
| Windows Admin Center | Administration web distante |
| RSAT et MMC | Consoles spécialisées : AD DS, DNS, DHCP, etc. |
| Server Manager | Rôles, fonctionnalités et gestion de serveurs |
| CMD et utilitaires | Commandes historiques : `repadmin`, `dcdiag`, `netdom` |

> [!note] Quel outil choisir ?
> Il n'y a pas d'outil « meilleur » dans l'absolu. Sur Server Core, il n'y a pas d'interface graphique : SConfig ou PowerShell sont les seules options en local. Pour un serveur à interface, la console graphique reste souvent plus rapide pour explorer, et PowerShell devient préférable dès qu'une tâche se répète ou doit être documentée.

---

## 2. Fondamentaux de PowerShell

### 2.1 Syntaxe d'une cmdlet

PowerShell est à la fois un interpréteur de commandes et un langage de scripts. Les cmdlets suivent la convention **Verbe-Nom** avec des paramètres : `Verbe-Nom -Paramètre Valeur`.

```powershell
Get-Service -Name Spooler
```

| Élément | Exemple | Signification |
|---|---|---|
| Verbe | `Get` | Action : obtenir une information |
| Nom | `Service` | Ressource ciblée |
| Paramètre | `-Name` | Option de la commande |
| Valeur | `Spooler` | Donnée transmise au paramètre |

Verbes courants :

| Verbe | Action |
|---|---|
| Get | Consulter |
| New | Créer |
| Set | Modifier |
| Add / Remove | Ajouter / supprimer |
| Install | Installer |
| Enable / Disable | Activer / désactiver |
| Start / Stop / Restart | Démarrer / arrêter / redémarrer |
| Test | Tester |

> [!note] Le paramètre `-Name` est souvent facultatif
> `Get-Service Spooler` fonctionne aussi bien que `Get-Service -Name Spooler`. Le cours utilise la forme complète, plus lisible et plus sûre dans un script. Pour la liste des verbes reconnus par PowerShell : `Get-Verb`.

### 2.2 Rechercher les commandes et leur aide

```powershell
Get-Command                    # toutes les commandes
Get-Command -Verb Get          # toutes les commandes Get-
Get-Command -Noun Service      # toutes les commandes portant sur les services
Get-Command *Network*          # recherche par motif
Get-Help Get-Service           # aide de base
Get-Help Get-Service -Examples # exemples
Get-Help Get-Service -Full     # aide complète
Get-Help Get-Service -Online   # aide sur le site Microsoft (navigateur, Internet requis)
Get-Module -ListAvailable      # modules installés
Get-Command -Module NetTCPIP   # commandes d'un module
```

> [!note] Mettre l'aide à jour
> Sur une machine qui n'a jamais été mise à jour, `Get-Help` peut renvoyer une aide vide ou incomplète. `Update-Help` la télécharge, mais demande un accès Internet. Sur un serveur isolé, lance-la sur une machine connectée, ou dans une VM dont l'accès réseau le permet.

> [!tip] Bonne pratique
> Avant d'exécuter une commande inconnue, lis son aide et ses paramètres. Surtout si elle modifie quelque chose.

### 2.3 Objets et pipeline

Les cmdlets renvoient en général des **objets** : des valeurs structurées avec des propriétés et des méthodes. Le pipeline `|` transmet ces objets d'une commande à la suivante.

```powershell
Get-Service | Select-Object Name, Status
Get-Service | Get-Member
```

> [!note] Objets et texte : le piège des shells classiques
> Dans un shell qui manipule du texte (Bash, par exemple), on découpe la sortie avec `cut`, `awk` ou `grep`. En PowerShell, on demande directement la propriété voulue. `Get-Member` sert à découvrir les propriétés d'un objet. Ce changement de logique est la difficulté principale du cours pour les personnes venant de Linux.

### 2.4 Paramètres de prudence

| Paramètre | Utilité |
|---|---|
| `-WhatIf` | Simule une modification, si la cmdlet le prend en charge |
| `-Confirm` | Demande une confirmation avant d'agir |
| `-Verbose` | Affiche davantage de détails |
| `-ErrorAction` | Décide quoi faire en cas d'erreur (`Stop`, `Continue`, `SilentlyContinue`) |

```powershell
Remove-Item C:\Temp\test -Recurse -WhatIf
```

> [!warning] `-WhatIf` n'existe pas partout
> `-WhatIf` et `-Confirm` ne fonctionnent que si la cmdlet les implémente. Si ce n'est pas le cas, PowerShell refuse le paramètre ou ne fait rien de plus. Vérifie avec `Get-Help <commande> -Parameter *`.

> [!note] `-ErrorAction Stop` pour attraper les erreurs
> Beaucoup d'erreurs ne bloquent pas la suite du script par défaut. Avec `-ErrorAction Stop`, l'erreur devient exceptionnelle et peut être capturée par `try { } catch { }`. C'est la base de tout script fiable.

---

## 3. Administration de Windows Server Core

### 3.1 Principe et intérêt

Windows Server Core est une option d'installation de Windows Server **sans bureau graphique classique**. Elle :

- réduit le nombre de composants installés, donc la **surface d'attaque** ;
- limite les mises à jour et les redémarrages liés aux composants inutilisés ;
- facilite l'administration à distance.

Certains logiciels nécessitant une interface graphique ne sont pas compatibles. Server Core peut héberger AD DS, DNS, DHCP et les services de fichiers.

> [!note] Ce que Server Core n'enlève pas
> Server Core ne supprime pas la gestion : il déplace l'administration vers PowerShell, SConfig et les consoles distantes. Un Server Core mal administré (mots de passe faibles, mises à jour oubliées, accès distant non contrôlé) reste vulnérable.

### 3.2 SConfig et informations système

SConfig est un menu texte pour les tâches de base : nom du serveur, appartenance au domaine, réseau, mises à jour, paramètres de pare-feu et distants.

```powershell
sconfig
Get-ComputerInfo
Get-ComputerInfo | Select-Object CsName, WindowsProductName, OsVersion
Get-Process
Get-Service
Get-Disk
Get-Partition
Get-Volume
```

> [!note] SConfig ou PowerShell ?
> SConfig suffit pour la mise en route. Dès qu'une opération doit être répétée, documentée ou automatisée, PowerShell est préférable. Le cours le dit : certaines opérations restent plus adaptées à PowerShell.

### 3.3 Services Windows

```powershell
Get-Service
Get-Service -Name Spooler
Start-Service -Name Spooler
Stop-Service -Name Spooler
Restart-Service -Name Spooler
```

> [!warning] Arrêter un service peut en arrêter d'autres
> `Stop-Service` peut échouer si d'autres services en dépendent, ou les arrêter avec lui. Avant d'arrêter un service important (DNS, DHCP, Netlogon), regarde ses dépendances : `Get-Service -Name <nom> -DependentServices`.

### 3.4 Mises à jour et maintenance

Installer les mises à jour applicables, prévoir les redémarrages et vérifier les services après intervention.

```powershell
Get-HotFix
```

> [!warning] `Get-HotFix` n'est pas un inventaire complet
> `Get-HotFix` ne liste pas tous les composants ni toutes les mises à jour. Certaines mises à jour (cumulatives, de composants) n'y apparaissent pas. Pour vérifier l'état réel, utilise aussi l'outil de mise à jour (SConfig) et le journal de Windows Update.

---

## 4. Administration réseau et pare-feu avec PowerShell

### 4.1 Consulter le réseau

```powershell
Get-NetAdapter
Get-NetIPConfiguration
Get-NetIPAddress -AddressFamily IPv4
Get-DnsClientServerAddress -AddressFamily IPv4
```

### 4.2 Configurer IPv4 et DNS

```powershell
New-NetIPAddress -InterfaceAlias '<INTERFACE>' -IPAddress '<ADRESSE_IPV4>' -PrefixLength 24 -DefaultGateway '<PASSERELLE>'
Set-DnsClientServerAddress -InterfaceAlias '<INTERFACE>' -ServerAddresses ('<DNS_PRINCIPAL>', '<DNS_SECONDAIRE>')
```

Les valeurs entre chevrons sont à remplacer, y compris l'alias de l'interface.

> [!note] Le paramètre `-PrefixLength` manque dans l'énoncé
> La version du cours tronque `New-NetIPAddress`. `-PrefixLength 24` correspond à un masque `255.255.255.0`. Sans lui, la commande échoue ou applique un masque inattendu.

> [!warning] Une interface en DHCP refuse une adresse statique
> Si l'interface obtient son adresse par DHCP, `New-NetIPAddress` renvoie une erreur ou l'adresse est écrasée au renouvellement. Désactive d'abord DHCP :
> ```powershell
> Set-NetIPInterface -InterfaceAlias '<INTERFACE>' -Dhcp Disabled
> ```
> Une passerelle ne doit être définie qu'une seule fois : si la carte en a déjà une, supprime l'ancienne avant d'en ajouter une nouvelle.

### 4.3 Connectivité et résolution

```powershell
Test-Connection '<NOM_OU_IP>'
Test-NetConnection '<SERVEUR_DISTANT>' -Port 5985
Resolve-DnsName '<NOM_DNS>'
```

> [!note] Ping ne prouve pas tout
> `Test-Connection` utilise ICMP. Un pare-feu peut bloquer ICMP et laisser passer le reste : un échec de ping ne signifie donc pas que le service est indisponible. Pour un service précis, teste le **port** avec `Test-NetConnection -Port`. Le port 5985 correspond à WinRM en HTTP, 5986 à WinRM en HTTPS.

### 4.4 Pare-feu Windows

```powershell
Get-NetFirewallProfile
Get-NetFirewallRule
New-NetFirewallRule -DisplayName 'Autoriser ICMPv4' -Direction Inbound -Protocol ICMPv4 -Action Allow
```

> [!note] Commande complétée
> Dans le document du cours, la dernière commande est tronquée. Les paramètres `-Protocol ICMPv4 -Action Allow` complètent l'exemple. Sans `-Action Allow`, la règle n'est pas une autorisation.

> [!tip] Profils
> `Get-NetFirewallProfile` montre pour chaque profil (Domaine, Privé, Public) si le pare-feu est activé. Une règle appliquée au mauvais profil ne s'active pas quand la machine change de réseau : vérifie le profil réel de la carte avec `Get-NetConnectionProfile`.

---

## 5. Administration distante

### 5.1 Outils et principes

PowerShell Remoting permet d'exécuter des commandes sur une cible distante, en général via **WinRM** dans les environnements Windows. RSAT, MMC et Windows Admin Center offrent des interfaces complémentaires.

### 5.2 Commandes de base

```powershell
Enable-PSRemoting -Force
Get-Service WinRM
Test-WSMan '<SERVEUR_DISTANT>'
Invoke-Command -ComputerName '<SERVEUR_DISTANT>' -ScriptBlock { Get-Service }
```

> [!note] Ce que fait `Enable-PSRemoting`
> La commande démarre WinRM, crée un écouteur et ouvre le pare-feu pour la gestion distante. Sur les versions récentes de Windows Server, WinRM est souvent déjà actif : vérifie avant de modifier quoi que ce soit.

> [!warning] Hors domaine, la confiance doit être configurée
> Entre deux machines jointes au même domaine, l'authentification Kerberos suffit. Entre un poste hors domaine et un serveur, il faut configurer les hôtes de confiance (`TrustedHosts`) et utiliser des identifiants explicites. Pour un serveur qui ne reçoit que des requêtes de son propre domaine, ce cas n'arrive pas.

> [!note] Le « double saut »
> Si tu lances `Invoke-Command` depuis un serveur A vers un serveur B, puis que B essaie d'accéder à une ressource C, les identifiants ne suivent pas toujours. C'est la limite dite du « double saut », à connaître dès que tu administres à distance à travers plusieurs machines.

### 5.3 Windows Admin Center

Windows Admin Center permet d'examiner les ressources système, les services, les événements, les disques, le réseau, les mises à jour et le pare-feu. Il ne remplace pas toutes les consoles RSAT.

> [!note] Ce n'est pas une cmdlet
> Windows Admin Center est un outil web installé à part. Il n'apparaît pas dans `Get-Command`. Il est complémentaire de PowerShell, pas une alternative à lui.

---

## 6. Administration Active Directory

### 6.1 AD DS et contrôleurs de domaine

Active Directory Domain Services (AD DS) centralise les identités, groupes, ordinateurs et objets du domaine. Plusieurs contrôleurs de domaine accessibles en écriture possèdent des copies répliquées de l'annuaire et peuvent authentifier les utilisateurs.

> [!note] Un rôle FSMO ne fait pas d'un DC le seul authentificateur
> Un contrôleur détenant un rôle FSMO n'est pas le seul à pouvoir authentifier. Les autres DC répondent aussi. Ce n'est pas un point de défaillance unique pour l'authentification, mais certaines opérations (voir section 9) dépendent du détenteur du rôle.

### 6.2 Installer AD DS et joindre un domaine

```powershell
Get-WindowsFeature
Get-WindowsFeature AD-Domain-Services
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Add-Computer -DomainName '<DOMAINE_AD>' -Credential (Get-Credential) -Restart
```

> [!warning] Installer le rôle ne fait pas un contrôleur de domaine
> Installer AD DS met les fichiers et les outils en place. La **promotion** (section 6.3) transforme réellement le serveur en contrôleur. Ce sont deux étapes distinctes, et la seconde peut échouer même si la première a réussi.

> [!note] `Add-Computer` et joindre un domaine
> Joindre un domaine (`Add-Computer`) concerne un **poste ou un serveur membre**. Ce n'est pas la même opération que devenir contrôleur de domaine. Le cours les présente à la suite, mais ne pas les confondre est important pour l'examen.

### 6.3 Promouvoir un contrôleur supplémentaire

```powershell
Install-ADDSDomainController -DomainName '<DOMAINE_AD>' -InstallDns -Credential (Get-Credential)
```

> [!note] Commande incomplète dans le cours
> Le cours ne donne que le début de la commande. Une promotion demande en général aussi le **mot de passe DSRM**, qui sera saisi à l'invite, et peut accepter d'autres paramètres : nom de site, contrôleur en lecture seule, catalogue global. Vérifie les options complètes avec `Get-Help Install-ADDSDomainController -Full`.

> [!warning] Vérifier avant de promouvoir
> La promotion peut demander le mot de passe DSRM et d'autres paramètres. Avant l'opération, vérifie le nom, le réseau, le DNS, la connectivité et l'état du domaine. Une promotion qui échoue en cours de route laisse un serveur dans un état intermédiaire difficile à nettoyer.

### 6.4 Contrôleurs de domaine et réplication

```powershell
Import-Module ActiveDirectory
Get-ADDomainController -Filter *
Get-ADDomainController -Filter * | Select-Object HostName, IPv4Address, Site
repadmin /replsummary
repadmin /showrepl
dcdiag
```

> [!note] `repadmin` et `dcdiag` ne sont pas des cmdlets
> Ce sont des exécutables Windows qui renvoient du **texte**, pas des objets. Tu peux les lancer depuis PowerShell, mais tu ne peux pas les filtrer avec `Where-Object` comme une cmdlet. Pour une analyse structurée, préfère les cmdlets `*-AD*`.

### 6.5 Erreurs de réplication et partages essentiels

```powershell
Get-ADReplicationFailure -Target '<DOMAINE_AD>' -Scope Domain
Get-ADReplicationPartnerMetadata -Target '<DOMAINE_AD>' -Scope Domain
Get-SmbShare -Name SYSVOL, NETLOGON
```

- **SYSVOL** contient notamment des fichiers liés aux stratégies de groupe.
- **NETLOGON** est un partage utilisé par certaines fonctions du domaine (scripts d'ouverture de session notamment).

> [!tip] Vérifier après une promotion
> Après une promotion, contrôle la présence de SYSVOL et NETLOGON, puis la réplication. Une absence de SYSVOL sur un DC est un signe de problème de réplication, pas un détail d'affichage.

### 6.6 Objets AD et contrôleur ciblé

```powershell
Get-ADUser -Filter *
Get-ADGroup -Filter *
Get-ADOrganizationalUnit -Filter *
Get-ADUser -Identity '<IDENTIFIANT_UTILISATEUR>' -Server '<CONTROLEUR_DOMAINE>'
```

> [!warning] Le paramètre `-Server` est essentiel pour un test de réplication
> Consulter un objet depuis une console ne garantit pas que la réplication est terminée sur **toutes** les répliques. Pour prouver qu'un objet existe sur un DC précis, interroge ce DC avec `-Server`. Sans ce paramètre, la commande peut répondre à partir d'un autre contrôleur et le test ne prouve rien.

---

## 7. Administration DNS

### 7.1 DNS et Active Directory

DNS traduit les noms et permet de localiser des services. Les enregistrements **SRV** participent à la découverte des contrôleurs de domaine et des services LDAP et Kerberos. Un client ne retrouve pas un DC par son adresse IP, mais par ces enregistrements.

> [!note] Pourquoi le DNS est vital pour AD
> Sans DNS fonctionnel, un poste ne peut pas localiser de DC : l'ouverture de session, les stratégies de groupe et l'accès à l'annuaire échouent. C'est pour cela que le DNS d'un domaine doit être redondant comme les DC eux-mêmes.

### 7.2 Rôle et zones DNS

```powershell
Get-WindowsFeature DNS
Get-Service DNS
Get-DnsServerZone
Get-DnsServerZone -ComputerName '<SERVEUR_DNS>'
```

> [!note] Zones intégrées à AD
> Une zone intégrée à AD est stockée dans l'annuaire et se réplique avec lui. Une zone principale classique est stockée dans un fichier. La zone `_msdcs` regroupe les enregistrements de localisation des DC et se distingue de la zone du domaine.

### 7.3 Enregistrements DNS

```powershell
Get-DnsServerResourceRecord -ComputerName '<SERVEUR_DNS>' -ZoneName '<ZONE>'
Get-DnsServerResourceRecord -ComputerName '<SERVEUR_DNS>' -ZoneName '<ZONE>' -RRType SRV
Add-DnsServerResourceRecordA -ComputerName '<SERVEUR_DNS>' -ZoneName '<ZONE>' -Name '<NOM>' -IPv4Address '<ADRESSE_IP>'
```

> [!tip] Ce que tu dois savoir par cœur
> Le type d'enregistrement (`A` pour un nom vers une IPv4, `PTR` pour l'inverse, `SRV` pour un service) et la zone dans laquelle il se trouve. Le reste se retrouve avec `Get-Help`.

### 7.4 Tests de résolution et enregistrements SRV

```powershell
Resolve-DnsName -Name '<NOM_DNS>' -Server '<ADRESSE_DNS>'
Resolve-DnsName -Name '_ldap._tcp.dc._msdcs.<DOMAINE_AD>' -Type SRV -Server '<ADRESSE_DNS>'
```

> [!note] Lire un enregistrement SRV
> Un enregistrement SRV contient : la **priorité**, le **poids**, le **port** et la **cible** (le nom du serveur qui offre le service). Pour LDAP, le port est 389 ; pour Kerberos, 88. Un bon résultat renvoie **un enregistrement par contrôleur**.

---

## 8. Administration DHCP et DHCP Failover

### 8.1 Rôle DHCP et installation

DHCP distribue notamment des adresses IP, des masques, des passerelles, des serveurs DNS et des suffixes DNS.

```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
Get-WindowsFeature DHCP
Get-Service DHCPServer
Add-DhcpServerInDC -DnsName '<FQDN_SERVEUR_DHCP>' -IPAddress '<ADRESSE_IP>'
Get-DhcpServerInDC
```

Un serveur DHCP Windows membre d'un domaine AD doit y être **autorisé** pour distribuer les baux normalement.

> [!note] Étape oubliée dans le cours : les groupes de sécurité
> Après l'installation, un serveur DHCP doit généralement passer par la configuration post-déploiement, qui crée les groupes locaux (*DHCP Administrators*, *DHCP Users*). Cela se fait avec `Add-DhcpServerSecurityGroup`, puis un redémarrage du service. L'autorisation dans AD et la création des groupes sont deux choses distinctes.

### 8.2 Étendues, options et baux

```powershell
Get-DhcpServerv4Scope -ComputerName '<SERVEUR_DHCP>'
Get-DhcpServerv4OptionValue -ComputerName '<SERVEUR_DHCP>' -ScopeId '<IDENTIFIANT_ETENDUE>'
Get-DhcpServerv4Lease -ComputerName '<SERVEUR_DHCP>' -ScopeId '<IDENTIFIANT_ETENDUE>'
```

> [!note] Options au niveau serveur ou au niveau étendue
> Une option DHCP peut être définie pour tout le serveur ou seulement pour une étendue. Une option d'étendue prime sur une option serveur. Pour un failover, c'est important : seules les informations de l'étendue sont répliquées entre partenaires de manière fiable. Vérifie donc où sont tes options.

### 8.3 Modes de DHCP Failover

| Mode | Fonctionnement |
|---|---|
| Load Balance | Répartition des demandes entre deux partenaires actifs (50/50 par défaut) |
| Hot Standby | Partenaire actif et partenaire de secours |

Le failover DHCP IPv4 permet de synchroniser les baux et de partager le service entre deux serveurs.

> [!note] Ce que fait le mode Hot Standby
> En fonctionnement normal, le serveur **actif** répond à tous les clients. Le serveur de **secours** ne répond pas, mais réserve un pourcentage des adresses (la réserve) pour les nouveaux clients si l'actif tombe. Le choix du mode dépend donc de la question : faut-il répartir la charge, ou seulement tenir pendant une panne ?

### 8.4 Créer une relation Hot Standby

```powershell
Add-DhcpServerv4Failover -ComputerName '<SERVEUR_ACTIF>' -PartnerServer '<SERVEUR_SECOURS>' -Name '<NOM_RELATION>' -ScopeId '<ETENDUE>' -ServerRole Active -ReservePercent 10 -SharedSecret '<SECRET>'
```

> [!warning] Ne jamais écrire le secret partagé dans un document
> Le secret authentifie les échanges entre les deux serveurs. Il apparaît en clair dans l'historique de la session et dans tout document qui le contient. Dans un labo, c'est acceptable ; ailleurs, il doit être saisi de manière sécurisée ou stocké dans un coffre de secrets.

> [!note] Le rôle se lit dans l'aide
> Le paramètre `-ServerRole` désigne le rôle du serveur concerné. La sémantique exacte (serveur local ou partenaire) dépend du contexte : vérifie-la avec `Get-Help Add-DhcpServerv4Failover -Full` plutôt que de la mémoriser.

### 8.5 Comprendre les paramètres

| Paramètre | Sens |
|---|---|
| `-ReservePercent` | Réserve d'adresses du partenaire de secours en mode Hot Standby |
| MCLT (Maximum Client Lead Time) | Durée maximale d'avance qu'un serveur peut donner à un bail sans l'accord du partenaire. Valeur par défaut : 1 heure |
| `-SharedSecret` | Secret partagé pour authentifier les échanges entre partenaires |

> [!note] Le MCLT explique les baux courts
> Pendant une panne, le serveur de secours délivre des baux dont la durée ne dépasse pas le MCLT. Quand le serveur principal revient, les deux peuvent se réconcilier sans donner la même adresse à deux machines. C'est le mécanisme qui évite les conflits d'adresses.

### 8.6 Vérifier la relation

```powershell
Get-DhcpServerv4Failover -ComputerName '<SERVEUR_DHCP>'
Get-DhcpServerv4Failover -ComputerName '<SERVEUR_DHCP>' | Format-List *
```

L'état attendu en fonctionnement normal est **Normal**.

### 8.7 Simulation d'indisponibilité

```powershell
# Sur le serveur DHCP actif
Stop-Service DHCPServer

# Après les vérifications et le test de secours
Start-Service DHCPServer
```

> [!warning] Arrêter le service, jamais la machine
> Pour simuler une panne DHCP, arrête **uniquement** le service `DHCPServer`. Arrêter le serveur entier coupe aussi le DNS et l'annuaire, et le test ne montre plus rien de précis. Note l'heure de l'arrêt, puis observe les états de la relation à intervalles réguliers.

> [!note] Les états d'une relation
> Une relation passe en général de **Normal** à **Communication Interrupted** quand le partenaire ne répond plus, puis à **Partner Down** si le partenaire est déclaré hors service (automatiquement ou par l'administrateur). Le comportement exact dépend du basculement automatique et des délais configurés.

---

## 9. Gestion des rôles FSMO

### 9.1 Pourquoi cinq rôles ?

Active Directory est majoritairement **multi-maître** : chaque DC accepte des modifications. Certaines tâches exigent cependant un détenteur unique, pour éviter les conflits. Les rôles **FSMO** (Flexible Single Master Operations) coordonnent ces opérations.

| Rôle | Portée | Fonction |
|---|---|---|
| Schema Master | Forêt | Modifications du schéma |
| Domain Naming Master | Forêt | Ajout et suppression des domaines |
| RID Master | Domaine | Distribution des pools de RID |
| PDC Emulator | Domaine | Changements de mot de passe, temps, opérations prioritaires |
| Infrastructure Master | Domaine | Actualisation de certaines références entre domaines |

> [!note] Mnémotechnique
> Deux rôles sont uniques dans la **forêt** (schéma et nommage des domaines), trois sont uniques **dans chaque domaine** (RID, PDC Emulator, Infrastructure). Un seul DC peut détenir plusieurs rôles.

### 9.2 Identifier les détenteurs

```powershell
Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster
Get-ADDomain | Select-Object PDCEmulator, RIDMaster, InfrastructureMaster
netdom query fsmo
```

### 9.3 Consoles graphiques pour un transfert

| Console | Rôles |
|---|---|
| Utilisateurs et ordinateurs Active Directory | RID, PDC Emulator, Infrastructure Master |
| Domaines et approbations Active Directory | Domain Naming Master |
| Schéma Active Directory | Schema Master |

> [!note] La console Schéma n'est pas enregistrée par défaut
> Elle n'apparaît pas dans MMC tant qu'elle n'a pas été enregistrée. Il faut d'abord exécuter `regsvr32 schmmgmt.dll`, puis ajouter le composant dans MMC. C'est un piège classique en examen.

### 9.4 Transférer avec PowerShell

```powershell
Move-ADDirectoryServerOperationMasterRole -Identity '<CONTROLEUR_DESTINATAIRE>' -OperationMasterRole PDCEmulator
Get-ADDomainController -Identity '<CONTROLEUR_DOMAINE>' | Select-Object Name, OperationMasterRoles
```

> [!note] Transfert et saisie : deux situations différentes
> - **Transfert** : opération planifiée, l'ancien détenteur est accessible et coopère.
> - **Saisie** (seizure) : récupération forcée quand l'ancien détenteur est définitivement indisponible. C'est une opération destructive pour l'ancien DC.
>
> Le cours ne montre pas la syntaxe de la saisie. Avec `Move-ADDirectoryServerOperationMasterRole`, elle passe par le paramètre `-Force`, à n'utiliser que si l'ancien DC ne reviendra jamais.

> [!warning] Ne jamais réintroduire l'ancien DC tel quel
> Après une saisie, l'ancien contrôleur ne doit pas être remis en service sans nettoyage (métadonnées de réplication). Le réintroduire peut créer des incohérences dans l'annuaire. C'est la précaution que le cours mentionne sous le terme « précautions avant toute réintroduction ».

---

## 10. Diagnostic et dépannage

### 10.1 Démarche

Un diagnostic efficace suit un ordre :

1. **Préciser le symptôme** : qui est touché, depuis quand, quel message exact ?
2. **Vérifier la couche basse d'abord** : réseau (IP, passerelle), puis résolution DNS, puis service, puis application.
3. **Consulter les journaux** avant de modifier quoi que ce soit.
4. **Changer une seule chose à la fois**, et noter le résultat.

> [!tip] Un bon diagnostic se documente
> Note le symptôme, l'heure, la commande, le résultat et la correction. C'est ce qui sert à la fois pour l'incident suivant et pour l'entretien d'embauche.

### 10.2 Commandes de diagnostic par thème

| Domaine | Commandes |
|---|---|
| Système | `Get-ComputerInfo`, `Get-Service` |
| Réseau | `Get-NetIPConfiguration`, `Test-Connection`, `Test-NetConnection` |
| DNS | `Resolve-DnsName`, `Get-DnsServerZone` |
| Contrôleurs et réplication | `Get-ADDomainController`, `dcdiag`, `repadmin /replsummary` |
| DHCP | `Get-DhcpServerv4Scope`, `Get-DhcpServerv4Lease`, `Get-DhcpServerv4Failover` |
| FSMO | `netdom query fsmo` |
| Journaux | `Get-WinEvent` |

### 10.3 Lire les journaux Windows

```powershell
Get-WinEvent -LogName System -MaxEvents 20
Get-WinEvent -LogName 'Directory Service' -MaxEvents 20
Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = (Get-Date).AddHours(-1) }
```

> [!note] `Get-WinEvent` plutôt que `Get-EventLog`
> `Get-EventLog` est l'ancienne commande et ne lit pas tous les journaux modernes. `Get-WinEvent` est la commande à privilégier. Le filtre `-FilterHashtable` est appliqué par Windows avant l'affichage : il est donc plus rapide qu'un `Where-Object` sur des milliers d'événements.

---

## Auto-évaluation

> [!abstract] Comment t'évaluer
> Pour chaque compétence, choisis le niveau qui te correspond **sans regarder le cours** :
> - **A** : je le fais seul, sans aide, et je peux expliquer pourquoi.
> - **B** : je le fais en relisant une commande ou l'aide, mais je comprends le principe.
> - **C** : je ne le fais pas encore seul, il faut revoir la section.
>
> Un C n'est pas un échec : c'est la liste de ce qu'il faut revoir.

### Grille de compétences

| Compétence | Section | Niveau (A/B/C) |
|---|---|---|
| Lire la syntaxe Verbe-Nom et trouver une cmdlet avec `Get-Command` | 2.1, 2.2 | |
| Lire l'aide et ses exemples avant d'exécuter | 2.2 | |
| Filtrer, trier et sélectionner des propriétés avec le pipeline | 2.3 | |
| Utiliser `-WhatIf`, `-Confirm` et `-ErrorAction` | 2.4 | |
| Utiliser SConfig et expliquer ce qu'il ne fait pas | 3.2 | |
| Gérer un service et connaître ses dépendances | 3.3 | |
| Configurer une adresse IPv4 et un DNS en PowerShell | 4.2 | |
| Tester une connectivité avec le bon outil (ping ou port) | 4.3 | |
| Expliquer et ouvrir une règle de pare-feu | 4.4 | |
| Activer le remoting et exécuter une commande à distance | 5.2 | |
| Distinguer installer AD DS, promouvoir un DC et joindre un domaine | 6.2, 6.3 | |
| Vérifier la réplication AD et expliquer SYSVOL et NETLOGON | 6.4, 6.5 | |
| Vérifier qu'un objet existe sur un DC précis avec `-Server` | 6.6 | |
| Lire un enregistrement SRV et expliquer son rôle | 7.4 | |
| Autoriser un serveur DHCP dans AD | 8.1 | |
| Expliquer la différence entre Load Balance et Hot Standby | 8.3 | |
| Créer une relation de failover et vérifier son état | 8.4, 8.6 | |
| Simuler une panne DHCP sans toucher au DC | 8.7 | |
| Nommer les cinq rôles FSMO et leur portée | 9.1 | |
| Identifier les détenteurs de rôles | 9.2 | |
| Distinguer transfert et saisie d'un rôle FSMO | 9.4 | |
| Lire un journal d'événements avec `Get-WinEvent` | 10.3 | |
| Appliquer la démarche de diagnostic (couche basse d'abord) | 10.1 | |

### Questions

**1. Quelle est la différence entre une cmdlet et un exécutable comme `repadmin` ?**

??? success "Réponse"
    Une cmdlet renvoie des **objets** avec des propriétés, qu'on peut filtrer et trier avec le pipeline. Un exécutable comme `repadmin` ou `dcdiag` renvoie du **texte**. On peut les lancer depuis PowerShell, mais on ne manipule pas leurs résultats comme des objets.

**2. Tu veux savoir si un DHCP est autorisé dans AD. Quelle commande utilises-tu et pourquoi ?**

??? success "Réponse"
    `Get-DhcpServerInDC`. Un serveur DHCP membre d'un domaine ne distribue pas de baux tant qu'il n'est pas autorisé dans l'annuaire. C'est une protection contre les serveurs DHCP non autorisés.

**3. Pourquoi ping ne suffit-il pas pour dire qu'un service est disponible ?**

??? success "Réponse"
    Un pare-feu peut bloquer ICMP sans bloquer le service, ou l'inverse. Un service réel se teste sur son **port** avec `Test-NetConnection -Port`. Le ping ne valide que la réponse ICMP.

**4. Qu'est-ce qui est répliqué pendant un failover DHCP, et qu'est-ce qui ne l'est pas ?**

??? success "Réponse"
    Les baux et les paramètres d'étendue sont synchronisés entre les partenaires. Les options définies au niveau du serveur ne sont pas répliquées de manière fiable. C'est pourquoi il faut savoir où sont définies les options.

**5. Tu arrêtes le service DHCP sur le serveur actif. Quel est l'état attendu de la relation, et qu'est-ce qui ne doit surtout pas être arrêté ?**

??? success "Réponse"
    La relation passe en général à **Communication Interrupted**, puis éventuellement à **Partner Down**. Il faut arrêter uniquement le service `DHCPServer`, jamais la machine : le DNS et l'annuaire doivent continuer de fonctionner pour que le test reste lisible.

**6. Un serveur a le rôle PDC Emulator. Son DC tombe définitivement. Que faut-il faire, et quelle précaution prendre ensuite ?**

??? success "Réponse"
    Il faut **saisir** le rôle sur un autre DC (opération forcée), car le détenteur ne peut plus coopérer. Ensuite, l'ancien DC ne doit pas être réintroduit tel quel dans le domaine : ses métadonnées doivent être nettoyées avant toute remise en service.

**7. Pourquoi un enregistrement SRV est-il indispensable pour qu'un client se connecte au domaine ?**

??? success "Réponse"
    Le client ne cherche pas le DC par son adresse IP. Il interroge le DNS pour trouver un enregistrement SRV (par exemple `_ldap._tcp.dc._msdcs`) qui indique quel serveur offre le service LDAP ou Kerberos, sur quel port. Sans SRV, le poste ne trouve pas de DC.

**8. Tu crées un objet dans AD depuis le DC A. Pour prouver qu'il est répliqué, que dois-tu vérifier et comment ?**

??? success "Réponse"
    Il faut interroger explicitement le DC B avec `-Server`, par exemple `Get-ADUser -Identity <nom> -Server <DC_B>`. Une simple consultation depuis une console peut répondre à partir du DC A et ne prouve pas la réplication.

### Défis pratiques

Ces exercices se font sur ta VM. Ils valident les sections en les combinant.

- [ ] **Défi 1 (sections 2 et 3)** : sans aide, liste les services arrêtés, trie-les par nom, et exporte le résultat dans un fichier texte.
- [ ] **Défi 2 (section 4)** : configure une adresse statique sur une seconde carte, vérifie-la, puis remets l'interface en DHCP sans perdre l'accès.
- [ ] **Défi 3 (section 6)** : vérifie la réplication d'un nouvel objet entre deux DC en utilisant `-Server`, puis supprime l'objet.
- [ ] **Défi 4 (section 8)** : sur une étendue de test, crée une relation de failover, arrête le service actif, et note les états successifs de la relation.
- [ ] **Défi 5 (section 9)** : identifie les cinq détenteurs FSMO de ton domaine et écris, sans regarder, ce que fait chacun.
- [ ] **Défi 6 (section 10)** : provoque une erreur contrôlée (par exemple un service arrêté) et retrouve-la dans les journaux avec `Get-WinEvent`.

### Lecture de ton résultat

| Résultat | Ce que ça signifie | Action |
|---|---|---|
| Majorité de A | Tu maîtrises le sujet, tu peux enseigner ou aller plus loin | Passe aux défis, puis à un projet réel |
| Mélange de A et B | Tu comprends les principes, il te manque la pratique | Refais les défis sans regarder les commandes |
| Plusieurs C | Tu n'as pas encore consolidé la section | Refais la section, puis reprends les questions |

---

## Pour aller plus loin

- Transformer chaque section en **script** réutilisable, testé sur une VM propre.
- Ajouter un **aide-mémoire** d'une page avec les verbes, les paramètres de sécurité et les commandes de diagnostic.
- Constituer un **glossaire** (cmdlet, pipeline, FSMO, MCLT, SRV, AGDLP) avec une définition personnelle pour chaque terme.
- Reconstruire un laboratoire complet à partir de zéro, sans notes, et noter ce qui manque.
