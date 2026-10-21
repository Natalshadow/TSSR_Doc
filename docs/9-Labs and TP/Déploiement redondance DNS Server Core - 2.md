> [!abstract] Contexte
> L'entreprise dispose de deux contrôleurs de domaine. Le DNS est indispensable pour localiser les contrôleurs de domaine et les services d'authentification. Il faut vérifier que Windows Server Core assure aussi la résolution DNS et que le service fonctionne sur les deux contrôleurs. Les configurations se font avec PowerShell ; les outils graphiques servent à vérifier le résultat.

> [!info] Comment utiliser ce document
> 
> - Trois machines : `[Graphique]` = `SRV-WIN-MEN-01` (interface complète), `[Core]` = `SRV-WIN-MEN-02` (Server Core), `[Client]` = `CLI-WIN-MEN-01` (Windows 11, en français). Vérifie toujours sur quelle machine tu tapes.
> - Chaque partie suit le même schéma : **Comprendre** (pourquoi), **Pas à pas** (quoi faire, avec des squelettes de commandes à compléter), **À noter** (ce que tu dois observer), puis captures.
> - Dans les squelettes, `<...>` indique une valeur à remplacer par la tienne. Colle ensuite la commande **exacte** utilisée dans le bloc prévu.
> - Les `> [!tip]` et `> [!warning]` sont du guidage : à supprimer dans la version rendue.
> - Place les captures dans `attachments/` et insère-les avec `![[nom-capture.png]]`.

> [!tip] Ordre conseillé
> 
> 1. Partie 3 : vérifier le rôle DNS sur le Core (5 min).
> 2. Partie 4 : comparer les zones sur les deux serveurs (10 min).
> 3. Partie 5 : créer et retrouver les deux enregistrements (10 min).
> 4. Partie 6 : régler les DNS des deux contrôleurs (10 min).
> 5. Partie 7 : régler le DHCP puis tester depuis le client (15 min).
> 6. Fais un **snapshot** des trois VM avant la partie 6 : c'est là que tu modifies des réglages réseau.

---

## Sommaire

- [[#1. Objectifs]]
- [[#2. Environnement]]
- [[#3. Installer et vérifier le rôle DNS]]
- [[#4. Vérifier la réplication des zones DNS]]
- [[#5. Tester la réplication des enregistrements]]
- [[#6. Configurer les serveurs DNS]]
- [[#7. Tester depuis le client Windows 11]]
- [[#8. Validation]]
- [[#9. Conclusion et difficultés rencontrées]]

---

## 1. Objectifs

- [x] Vérifier ou installer le rôle DNS sur Windows Server Core.
- [x] Comprendre les zones DNS intégrées à Active Directory et leur réplication.
- [x] Vérifier la réplication des zones et des enregistrements.
- [x] Configurer les DNS des contrôleurs de domaine et du client.
- [x] Tester la résolution depuis les deux serveurs et valider dans la console DNS.

---

## 2. Environnement

|Élément|Configuration|
|---|---|
|Domaine et zone DNS|`TSSR-MEN.LAB`|
|Serveur DNS existant|`SRV-WIN-MEN-01` : `192.168.100.10`|
|Nouveau serveur DNS|`SRV-WIN-MEN-02` : `192.168.100.11`|
|Type de zone|Intégrée à Active Directory|
|Poste client|`CLI-WIN-MEN-01`|

**Nom réel du Server Core :** `SRV-WIN-MEN-02`

---

## 3. Installer et vérifier le rôle DNS

### Comprendre

> [!question] Pourquoi le DNS est vital pour Active Directory 
> Les contrôleurs de domaine et les clients **ne se trouvent pas par leur adresse IP mais par des enregistrements DNS** (notamment des enregistrements de type **SRV**, qui disent « tel service est fourni par tel serveur sur tel port »). Sans DNS, un poste ne retrouve plus de contrôleur de domaine : ouverture de session, GPO et recherche de l'annuaire échouent. C'est pourquoi un second serveur DNS apporte de la **redondance**.

Un client Windows membre du domaine a besoin du DNS pour localiser les enregistrements SRV indiquant l'emplacement exact des services Active Directory (LDAP, Kerberos, Catalogue Global) afin de s'authentifier et d'appliquer les stratégies de groupe.

### Pas à pas (`[Core]`)

**Étape 1 : le rôle est-il déjà là ?**

Lors de la promotion du TP précédent, tu as demandé le DNS sur le nouveau contrôleur : il doit déjà être installé. Vérifie-le plutôt que de le supposer. Lis la colonne _Install State_ (ou la case `[X]` devant le nom : installé).

```powershell
PS C:\Users\administrator.TSSR-MEN>  Get-WindowsFeature -Name DNS
Display Name                                            Name
------------                                            ----
[X] DNS Server                                          DNS
```

**Étape 2 : s'il manque**, installe-le avec les outils de gestion (le module PowerShell `DnsServer` en fait partie) :

```powershell
Install-WindowsFeature -Name DNS -IncludeManagementTools
```

**Étape 3 : le service fonctionne-t-il ?**

Regarde le statut (_Running_) et le type de démarrage (_Automatic_).

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-Service -Name DNS

Status   Name               DisplayName
------   ----               -----------
Running  DNS                DNS Server
```

Type de démarrage :

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-Service -Name DNS | Select-Object Name, Status, StartType

Name  Status StartType
----  ------ ---------
DNS  Running Automatic
```

**Étape 4 : le module PowerShell est-il disponible ?**

S'il n'apparaît pas, la fonctionnalité des outils DNS (`RSAT-DNS-Server`) n'est pas installée : cherche-la avec `Get-WindowsFeature *DNS*`.

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-Module -ListAvailable -Name DnsServer


    Directory: C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules


ModuleType Version    Name                                ExportedCommand
                                                          s
---------- -------    ----                                ---------------
Manifest   2.0.0.0    DnsServer                           {Add-DnsServ...
```

**Étape 5 : le serveur répond-il ?**

Un test direct depuis le Core :

```text
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name TSSR-MEN.LAB -Server 127.0.0.1 -DnsOnly

Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
TSSR-MEN.LAB                                   A      600   Answer     192.168.100.11
TSSR-MEN.LAB                                   A      600   Answer     192.168.100.10
```

**Étape 6 : découvrir les commandes d'administration DNS**

```powershell
Get-Command -Module DnsServer | Measure-Object
```

> [!note] Il s'agit du nombre total de cmdlets disponibles dans le module `DnsServer` (136 fonctions au total).

```powershell
Get-Command -Module DnsServer -Noun *Zone*
```

> [!note] Liste toutes les commandes qui agissent sur les **zones DNS** (création, suppression, modification de zone).

```powershell
Get-Command -Module DnsServer -Noun *ResourceRecord*
```

> [!note] Liste les commandes permettant de gérer les **enregistrements DNS** (A, AAAA, MX, CNAME, SRV, etc.).

```powershell
Get-Command -Module DnsServer -Verb Get
```

> [!note] Liste toutes les commandes de lecture/consultation du module DNS (celles qui permettent d'afficher ou récupérer des informations).

### À noter

|Vérification|Résultat|
|---|---|
|État du rôle DNS|Running / Installed|
|Installation nécessaire ?|Non (déjà présent suite à la promotion)|
|État et type de démarrage du service|Running / Automatic|
|Module `DnsServer` disponible|Oui|
|Résolution locale|Oui|
|Nombre de commandes du module `DnsServer`|136|

**Commandes DNS utiles trouvées** :

|Commande|Rôle|
|---|---|
|`Add-DnsServerResourceRecord`|Ajoute un nouvel enregistrement DNS|
|`Get-DnsServer`|Affiche la configuration globale du serveur DNS|
|`Get-DnsServerZone`|Liste les zones DNS hébergées sur le serveur|
|`Get-DnsServerResourceRecord`|Récupère les enregistrements d'une zone DNS donnée|
|`Remove-DnsServerResourceRecord`|Supprime un enregistrement DNS spécifique|
|`Set-DnsClientServerAddress`|Configure les serveurs DNS de l'interface réseau|


---

## 4. Vérifier la réplication des zones DNS

### Comprendre

> [!question] Zone intégrée à Active Directory 
> Une zone DNS classique est stockée dans un **fichier** sur un serveur « principal » et copiée vers des serveurs « secondaires » (transfert de zone). Une zone **intégrée à AD** est stockée **dans la base Active Directory** : elle se réplique avec la réplication AD que tu as vérifiée au TP précédent.

Une zone intégrée Active Directory stocke ses données directement au sein de la base de données NTDS (`ntds.dit`) et s'appuie sur le mécanisme de réplication AD multi-maître, offrant une écriture sur n'importe quel contrôleur, une sécurité renforcée et l'absence de transferts de zone au format fichier.

### Pas à pas

**Étape 1 : lister les zones des deux serveurs**

Depuis `[Core]` :

```text
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerZone -ComputerName SRV-WIN-MEN-01

ZoneName                            ZoneType        IsAutoCreated   IsDsIntegrated  IsReverseLookupZone  IsSigned
--------                            --------        -------------   --------------  -------------------  --------
_msdcs.TSSR-MEN.LAB                 Primary         False           True            False                False
0.in-addr.arpa                      Primary         True            False           True                 False
100.168.192.in-addr.arpa            Primary         False           True            True                 False
127.in-addr.arpa                    Primary         True            False           True                 False
255.in-addr.arpa                    Primary         True            False           True                 False
TrustAnchors                        Primary         False           True            False                False
TSSR-MEN.LAB                        Primary         False           True            False                False


PS C:\Users\administrator.TSSR-MEN> Get-DnsServerZone -ComputerName SRV-WIN-MEN-02

ZoneName                            ZoneType        IsAutoCreated   IsDsIntegrated  IsReverseLookupZone  IsSigned
--------                            --------        -------------   --------------  -------------------  --------
_msdcs.TSSR-MEN.LAB                 Primary         False           True            False                False
0.in-addr.arpa                      Primary         True            False           True                 False
100.168.192.in-addr.arpa            Primary         False           True            True                 False
127.in-addr.arpa                    Primary         True            False           True                 False
255.in-addr.arpa                    Primary         True            False           True                 False
TrustAnchors                        Primary         False           True            False                False
TSSR-MEN.LAB                        Primary         False           True            False                False
```

**Étape 2 : les comparer** avec les propriétés utiles

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerZone -ComputerName SRV-WIN-MEN-01 | Select-Object ZoneName, ZoneType, IsDsIntegrated, ReplicationScope, DynamicUpdate

ZoneName         : _msdcs.TSSR-MEN.LAB
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Forest
DynamicUpdate    : Secure

ZoneName         : 100.168.192.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure

ZoneName         : TSSR-MEN.LAB
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure
```

**Étape 3 : rechercher les zones « de service »**

La zone `_msdcs` contient les enregistrements des services globaux (comme le catalogue global et le contrôleur principal). Sa portée de réplication est définie sur **`Forest`** pour que tous les contrôleurs de domaine de l'ensemble de la forêt Active Directory puissent localiser ces services, même si d'autres domaines sont ajoutés plus tard.

**Étape 4 : vérifier les enregistrements SRV**

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-01
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-02
```

Vérification de résolution cliente :

```powershell
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server 192.168.100.10
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server 192.168.100.11
```

### À noter

| Élément                                                   | `SRV-WIN-MEN-01` | `SRV-WIN-MEN-02` |
| --------------------------------------------------------- | ---------------- | ---------------- |
| Zone `TSSR-MEN.LAB` présente                              | Oui              | Oui              |
| Type de zone                                              | Primary          | Primary          |
| Intégrée à AD                                             | True             | True             |
| Portée de réplication                                     | Domain           | Domain           |
| Mise à jour dynamique                                     | Secure           | Secure           |
| Zone `_msdcs.TSSR-MEN.LAB` : portée                       | Forest           | Forest           |
| Zone inversée `100.168.192.in-addr.arpa` présente (bonus) | Oui              | Oui              |
| Enregistrements SRV `_ldap._tcp.dc._msdcs` (nombre)       | 2                | 2                |
| Enregistrements SRV `_kerberos._tcp` (nombre)             | 2                | 2                |

**À quoi servent les enregistrements SRV :**
Ils permettent aux machines clientes et serveurs du réseau de localiser dynamiquement l'adresse IP et les ports réseau des services spécifiques hébergés par Active Directory (authentification Kerberos, requêtes d'annuaire LDAP, Catalogue Global).

---

## 5. Tester la réplication des enregistrements

### Comprendre

> [!question] Ce que ce test prouve 
> Tu crées une modification sur **un** serveur et tu la retrouves sur **l'autre**. Comme la zone est dans AD, c'est la **réplication Active Directory** qui transporte l'enregistrement. Il faut donc **interroger explicitement** chaque serveur (`-ComputerName`, `-Server`) : sans ça, la commande peut répondre à partir d'un seul serveur et le test ne prouve rien.

### Pas à pas

**A. Enregistrement créé sur `[Graphique]`**

**A.1 : créer l'enregistrement** (`[Graphique]`)
Console _DNS_ → _Forward Lookup Zones_ → `TSSR-MEN.LAB` → **New Host (A or AAAA)...** → `test-core` (`192.168.100.253`).

**A.2 : vérifier sa présence en local** (`[Core]`)

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
test-core                 A          1          0                    01:00:00        192.168.100.253
```

**A.3 : interroger explicitement le DNS du Core** (`[Core]`)

```powershell
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name test-core.TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly

Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
test-core.TSSR-MEN.LAB                         A      3600  Answer     192.168.100.253
```

**B. Deuxième enregistrement créé depuis PowerShell, en ciblant le Core**

**B.1 : créer l'enregistrement**

```powershell
Add-DnsServerResourceRecordA -Name secondRecord -ZoneName TSSR-MEN.LAB -IPv4Address 192.168.100.140 -ComputerName SRV-WIN-MEN-02
```

**B.2 : le retrouver sur le serveur graphique**

```powershell
PS C:\Users\Administrator> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord -ComputerName SRV-WIN-MEN-01

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
secondRecord              A          1          0                    01:00:00        192.168.100.140
```

**B.3 : le résoudre depuis Windows 11** (`[Client]`)

```powershell
Resolve-DnsName -Name secondRecord.TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
```

### À noter

| Étape                        | Serveur interrogé | Commande                                                                                                                         | Résultat               | Délai            |
| ---------------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------- | ---------------------- | ---------------- |
| `test-core` visible en local | `SRV-WIN-MEN-02`  | `Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core`                                                            | OK (`192.168.100.253`) | Instantané       |
| `test-core` résolu           | `192.168.100.11`  | `Resolve-DnsName -Name test-core.TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly`                                                  | OK                     | Instantané       |
| Second enregistrement créé   | `SRV-WIN-MEN-02`  | `Add-DnsServerResourceRecordA -Name secondRecord -ZoneName TSSR-MEN.LAB -IPv4Address 192.168.100.140 -ComputerName SRV-WIN-MEN-02` | OK                     | Instantané       |
| Second enregistrement lu     | `SRV-WIN-MEN-01`  | `Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord -ComputerName SRV-WIN-MEN-01`                            | OK (`192.168.100.140`) | Quelques minutes |
| Second enregistrement résolu | depuis le client  | `Resolve-DnsName -Name secondRecord.TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly`                                                | OK                     | Quelques minutes |

**Nettoyage :**
Les enregistrements de test ont été supprimés afin de maintenir une zone propre et d'éviter d'augmenter inutilement la surface d'attaque.

```powershell
Remove-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core -RRType A -ComputerName SRV-WIN-MEN-01 -Force
Remove-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord -RRType A -ComputerName SRV-WIN-MEN-02 -Force
```

---

## 6. Configurer les serveurs DNS

### Comprendre

> [!question] Pourquoi les DNS d'un contrôleur de domaine comptent 
> Un contrôleur de domaine est **aussi un client DNS** : il consulte une liste ordonnée (**préféré**, puis **alternatif**). 

**Stratégie retenue et justification :**
Pour chaque contrôleur de domaine, nous configurons le partenaire en DNS préféré (`192.168.100.10` sur le Core et vice-versa) et l'adresse IP locale / adresse de bouclage (`127.0.0.1` ou son propre IP) en DNS alternatif. Cela garantit qu'au démarrage, un contrôleur s'appuie sur un annuaire DNS déjà démarré et fonctionnel pour initialiser ses services, tout en maintenant sa propre résolution si le partenaire est hors ligne.

### Pas à pas

**Étape 1 : examiner la configuration actuelle**

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsClientServerAddress -AddressFamily IPv4
```

**Étape 2 : définir la liste**

Sur `SRV-WIN-MEN-01` :
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses ("192.168.100.11","127.0.0.1")
```

Sur `SRV-WIN-MEN-02` :
```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("192.168.100.10","127.0.0.1")
```

**Étape 3 : revérifier et vider le cache**

```powershell
Clear-DnsClientCache
```

**Étape 4 : vérifier la résolution du domaine**

```powershell
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name TSSR-MEN.LAB
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name SRV-WIN-MEN-01.TSSR-MEN.LAB
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name SRV-WIN-MEN-02.TSSR-MEN.LAB
```

**Étape 5 : contrôle global**

```powershell
dcdiag /test:dns | Select-String -Pattern 'passed|failed'
```

### À noter

| Élément                                | `SRV-WIN-MEN-01`                          | `SRV-WIN-MEN-02`                          |
| -------------------------------------- | ----------------------------------------- | ----------------------------------------- |
| Alias de la carte réseau               | Ethernet 2                                | Ethernet                                  |
| DNS **avant**                          | `127.0.0.1`                               | `192.168.100.10`, `127.0.0.1`             |
| DNS préféré **après**                  | `192.168.100.11`                          | `192.168.100.10`                          |
| DNS alternatif **après**               | `127.0.0.1`                               | `127.0.0.1`                               |
| Résolution du domaine                  | Oui — `192.168.100.10` et `192.168.100.11` | Oui — `192.168.100.10` et `192.168.100.11` |
| Résolution des deux noms de contrôleur | Oui (`.10` et `.11`)                      | Oui (`.10` et `.11`)                      |

---

## 7. Tester depuis le client Windows 11

### Comprendre

> [!question] Le client reçoit ses DNS par DHCP 
> Ton client est en DHCP depuis le TP DHCP. En ajoutant `192.168.100.11` dans l'option 006, le client reçoit **deux** serveurs et bascule automatiquement sur le second si le premier ne répond pas.

### Pas à pas

**Étape 1 : identifier les DNS actuels** (`[Client]`)

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

**Étape 2 : modifier l'option DHCP 006** (`[Graphique]`)

```powershell
Set-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -OptionId 6 -Value "192.168.100.10","192.168.100.11"
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -OptionId 6
```

**Étape 3 : renouveler la bail et contrôler** (`[Client]`)

```powershell
ipconfig /renew
ipconfig /all
```

**Étape 4 : interroger explicitement chacun des deux serveurs** (`[Client]`)

```powershell
Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly
```

**Étape 5 : résoudre les noms de contrôleurs** (`[Client]`)

```powershell
Resolve-DnsName -Name SRV-WIN-MEN-01.TSSR-MEN.LAB -Server 192.168.100.10
Resolve-DnsName -Name SRV-WIN-MEN-02.TSSR-MEN.LAB -Server 192.168.100.11
```

### À noter

|Élément|Résultat|
|---|---|
|DNS du client **avant**|`192.168.100.10`|
|Option DHCP 006 **après**|`192.168.100.10`, `192.168.100.11`|
|DNS du client **après** (ordre)|1. `192.168.100.10`, 2. `192.168.100.11`|
|Domaine résolu par `192.168.100.10`|Oui (`192.168.100.10`, `192.168.100.11`)|
|Domaine résolu par `192.168.100.11`|Oui (`192.168.100.10`, `192.168.100.11`)|

|Nom résolu|Via `192.168.100.10`|Via `192.168.100.11`|
|---|---|---|
|`SRV-WIN-MEN-01.TSSR-MEN.LAB`|`192.168.100.10`|`192.168.100.10`|
|`SRV-WIN-MEN-02.TSSR-MEN.LAB`|`192.168.100.11`|`192.168.100.11`|

---

## 8. Validation

|Vérification|Validé|Preuve|
|---|---|---|
|Le rôle DNS fonctionne sur les deux contrôleurs|☑|[[#3. Installer et vérifier le rôle DNS]]|
|La zone intégrée à AD est présente sur les deux serveurs|☑|[[#4. Vérifier la réplication des zones DNS]]|
|Les enregistrements AD et de test sont disponibles|☑|[[#4. Vérifier la réplication des zones DNS]] et [[#5. Tester la réplication des enregistrements]]|
|La réplication des modifications DNS fonctionne dans les deux sens|☑|[[#5. Tester la réplication des enregistrements]]|
|Le client interroge les deux DNS et obtient des réponses correctes|☑|[[#7. Tester depuis le client Windows 11]]|

---

## 9. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

| Problème | Cause | Solution |
| --- | --- | --- |
| L'enregistrement `secondRecord` n'apparaissait pas immédiatement sur `SRV-WIN-MEN-01`. | Délai naturel de propagation de la réplication Active Directory entre les deux contrôleurs. | Exécution de `repadmin /syncall /AdeP` pour forcer la synchronisation inter-annuaire puis attente de la mise à jour du cache local DNS. |
| Erreur `1311 ERROR_NO_LOGON_SERVERS` lors de `nltest /dsregdns`. | Le service Netlogon écoutait sur une seconde interface réseau secondaire (`Ethernet 2` / `.56.101`). | Suppression de l'enregistrement A parasite, redémarrage du service Netlogon (`Restart-Service Netlogon`) et ré-exécution de `nltest /dsregdns`. |
| Plantage VM / Ressources hôte insuffisantes. | Saturation de la mémoire RAM du poste hôte exécutant 3 VM simultanées. | Démarrage séquentiel des VM et optimisation de la mémoire allouée. |

### Ce que j'ai retenu

1. Les zones DNS intégrées Active Directory simplifient la gestion de la haute disponibilité : toute modification apportée sur un serveur DNS s'appuie sur la topologie de réplication AD multi-maître sans nécessiter de configuration manuelle de transfert de zone.
2. Les enregistrements SRV sont essentiels au fonctionnement des réseaux Active Directory ; leur enregistrement automatique est assuré par le service `Netlogon`.
3. Une configuration robuste des cartes réseau sur les contrôleurs de domaine impose un pointage DNS croisé pour éviter l'isolement au démarrage.