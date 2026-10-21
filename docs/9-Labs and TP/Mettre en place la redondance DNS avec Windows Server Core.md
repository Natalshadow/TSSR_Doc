---

## title: TP - Mettre en place la redondance DNS avec Windows Server Core tags: [tssr, windows-server, active-directory, dns, dhcp, powershell, server-core, tp] date: auteur: trigramme: MEN statut: en-cours

# TP - Mettre en place la redondance DNS avec Windows Server Core

> [!abstract] Contexte L'entreprise dispose de deux contrôleurs de domaine. Le DNS est indispensable pour localiser les contrôleurs de domaine et les services d'authentification. Il faut vérifier que Windows Server Core assure aussi la résolution DNS et que le service fonctionne sur les deux contrôleurs. Les configurations se font avec PowerShell ; les outils graphiques servent à vérifier le résultat.

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

- [ ] Vérifier ou installer le rôle DNS sur Windows Server Core.
- [ ] Comprendre les zones DNS intégrées à Active Directory et leur réplication.
- [ ] Vérifier la réplication des zones et des enregistrements.
- [ ] Configurer les DNS des contrôleurs de domaine et du client.
- [ ] Tester la résolution depuis les deux serveurs et valider dans la console DNS.

---

## 2. Environnement

|Élément|Configuration|
|---|---|
|Domaine et zone DNS|`TSSR-MEN.LAB`|
|Serveur DNS existant|`SRV-WIN-MEN-01` : `192.168.100.10`|
|Nouveau serveur DNS|`SRV-WIN-MEN-02` : `192.168.100.11`|
|Type de zone|Intégrée à Active Directory|
|Poste client|`CLI-WIN-MEN-01`|

> [!tip] Guidage
> 
> - Si le nom de ton Server Core est différent de `SRV-WIN-MEN-02` (le TP précédent mentionnait aussi `SRV-CORE-...`), note ici le **nom réel** et utilise-le partout.
> - Les commandes `DnsServer` acceptent le paramètre `-ComputerName` : depuis `[Graphique]`, tu peux interroger le Core sans changer de machine. Cela repose sur la **gestion à distance** (WinRM) et sur la résolution du nom du Core. Si ça échoue, tape la commande directement sur le Core, sans `-ComputerName`.

**Nom réel du Server Core :**

---

## 3. Installer et vérifier le rôle DNS

### Comprendre

> [!question] Pourquoi le DNS est vital pour Active Directory Les contrôleurs de domaine et les clients **ne se trouvent pas par leur adresse IP mais par des enregistrements DNS** (notamment des enregistrements de type **SRV**, qui disent « tel service est fourni par tel serveur sur tel port »). Sans DNS, un poste ne retrouve plus de contrôleur de domaine : ouverture de session, GPO et recherche de l'annuaire échouent. C'est pourquoi un second serveur DNS apporte de la **redondance**.

Écris en une phrase, avec tes mots, pourquoi un client Windows a besoin du DNS pour joindre un contrôleur de domaine :

### Pas à pas (`[Core]`)

**Étape 1 : le rôle est-il déjà là ?**

Lors de la promotion du TP précédent, tu as demandé le DNS sur le nouveau contrôleur : il doit déjà être installé. Vérifie-le plutôt que de le supposer. Lis la colonne _Install State_ (ou la case `[X]` devant le nom : installé).

```text
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

```text
PS C:\Users\administrator.TSSR-MEN> Get-Service -Name DNS

Status   Name               DisplayName
------   ----               -----------
Running  DNS                DNS Server
```

Type de démarrage :

```text
PS C:\Users\administrator.TSSR-MEN> Get-Service -Name DNS | Select-Object Name, Status, StartType

Name  Status StartType
----  ------ ---------
DNS  Running Automatic
```

**Étape 4 : le module PowerShell est-il disponible ?**

S'il n'apparaît pas, la fonctionnalité des outils DNS (`RSAT-DNS-Server`) n'est pas installée : cherche-la avec `Get-WindowsFeature *DNS*`.

```text
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

**Étape 6 : découvrir les commandes d'administration DNS** (ce que demande l'étape 4 du brief)

```powershell
Get-Command -Module DnsServer | Measure-Object
```

Cette commande fait la somme de quelque chose, j'ai un count de 136 mais je ne sais pas ce que c'est.

> [!note] Il s'agit du nombre de cmdlets disponibles dans le module `DnsServer`.

```powershell
Get-Command -Module DnsServer -Noun *Zone*
```

Celle-ci a l'air de lister des fonctions disponibles en lien avec le serveur DNS et les zones et la version disponible.

> [!note] Liste toutes les commandes qui agissent sur les **zones DNS** (création, suppression, modification de zone).

```powershell
Get-Command -Module DnsServer -Noun *ResourceRecord*
```

Celle-ci a l'air de lister des fonctions disponibles en lien avec le serveur DNS et les manipulations de ressources et la version disponible.

> [!note] Liste les commandes permettant de gérer les **enregistrements DNS** (A, AAAA, MX, CNAME, SRV, etc.).

```powershell
Get-Command -Module DnsServer -Verb Get
```

Similaire, mais avec un filtre sur le mot Get.

> [!note] Liste toutes les commandes de lecture/consultation du module DNS (celles qui permettent d'afficher ou récupérer des informations).

### À noter

|Vérification|Résultat|
|---|---|
|État du rôle DNS|Running|
|Installation nécessaire ?|Non|
|État et type de démarrage du service|Automatic|
|Module `DnsServer` disponible|Oui|
|Résolution locale|Oui|
|Nombre de commandes du module `DnsServer`|136|

**Commandes DNS utiles trouvées** :

|Commande|Rôle|
|---|---|
|Add-DnsServerResourceRecord||
|Get-DnsServer||
|||
|||
|||
|||
|||
|||

![[capture-3-role-dns.png]] ![[capture-3-service.png]] ![[capture-3-commandes.png]]

**Commentaires**

---

## 4. Vérifier la réplication des zones DNS

### Comprendre

> [!question] Zone intégrée à Active Directory Une zone DNS classique est stockée dans un **fichier** sur un serveur « principal » et copiée vers des serveurs « secondaires » (transfert de zone). Une zone **intégrée à AD** est stockée **dans la base Active Directory** : elle se réplique avec la réplication AD que tu as vérifiée au TP précédent.
> 
> Conséquences : tous les contrôleurs DNS ont la zone en **lecture et écriture**, sans transfert de zone, et la sécurité des mises à jour dynamiques est gérée par AD. La **portée de réplication** dit quels contrôleurs reçoivent la zone : tous les contrôleurs de la **forêt**, tous ceux du **domaine**, ou un ensemble **personnalisé**. Ces portées s'appuient sur des partitions d'annuaire dédiées (`ForestDnsZones`, `DomainDnsZones`).

> [!tip] Guidage Au TP DNS, tu as choisi « To all DNS on domain » pour ta zone inversée `100.168.192.in-addr.arpa`. Cette zone devrait donc **aussi** exister sur le Core : c'est une vérification bonus.

Écris, avec tes mots, la différence entre une zone intégrée à AD et une zone principale classique :

### Pas à pas

**Étape 1 : lister les zones des deux serveurs** (depuis `[Graphique]`, ou en local sur chaque serveur)

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

Depuis `[Graphique]` :

```text
PS C:\Users\Administrator> Get-DnsServerZone -ComputerName SRV-WIN-MEN-01

ZoneName                            ZoneType        IsAutoCreated   IsDsIntegrated  IsReverseLookupZone  IsSigned
--------                            --------        -------------   --------------  -------------------  --------
_msdcs.TSSR-MEN.LAB                 Primary         False           True            False                False
0.in-addr.arpa                      Primary         True            False           True                 False
100.168.192.in-addr.arpa            Primary         False           True            True                 False
127.in-addr.arpa                    Primary         True            False           True                 False
255.in-addr.arpa                    Primary         True            False           True                 False
TrustAnchors                        Primary         False           True            False                False
TSSR-MEN.LAB                        Primary         False           True            False                False


PS C:\Users\Administrator> Get-DnsServerZone -ComputerName SRV-WIN-MEN-02

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

ZoneName         : 0.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : 100.168.192.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure

ZoneName         : 127.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : 255.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : TrustAnchors
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Forest
DynamicUpdate    : None

ZoneName         : TSSR-MEN.LAB
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure



PS C:\Users\administrator.TSSR-MEN> Get-DnsServerZone -ComputerName SRV-WIN-MEN-02 | Select-Object ZoneName, ZoneType, IsDsIntegrated, ReplicationScope, DynamicUpdate


ZoneName         : _msdcs.TSSR-MEN.LAB
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Forest
DynamicUpdate    : Secure

ZoneName         : 0.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : 100.168.192.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure

ZoneName         : 127.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : 255.in-addr.arpa
ZoneType         : Primary
IsDsIntegrated   : False
ReplicationScope : None
DynamicUpdate    : None

ZoneName         : TrustAnchors
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Forest
DynamicUpdate    : None

ZoneName         : TSSR-MEN.LAB
ZoneType         : Primary
IsDsIntegrated   : True
ReplicationScope : Domain
DynamicUpdate    : Secure
```

Repère : la zone `TSSR-MEN.LAB` sur **les deux** serveurs, le type de zone, si elle est intégrée à AD (`IsDsIntegrated`), sa portée (`ReplicationScope`) et la mise à jour dynamique.

**Étape 3 : rechercher les zones « de service »**

Regarde la zone `_msdcs.TSSR-MEN.LAB` et note sa portée. Pourquoi serait-elle différente de la zone du domaine ?
Je ne sais pas.

> [!note] La zone `_msdcs` contient les enregistrements des services globaux (comme le catalogue global et le contrôleur principal). Sa portée de réplication est définie sur **`Forest`** pour que tous les contrôleurs de domaine de l'ensemble de la forêt Active Directory puissent localiser ces services, même si d'autres domaines sont ajoutés plus tard.

**Étape 4 : vérifier les enregistrements SRV** (ceux qui permettent de trouver les contrôleurs)

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-01

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
_gc._tcp.Default-First... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_gc._tcp.Default-First... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_gc._tcp                  SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_gc._tcp                  SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp            SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp            SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kpasswd._tcp             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][464][srv-win-men-02.tssr-men.lab.]
_kpasswd._tcp             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][464][srv-win-men-01.tssr-men.lab.]
_ldap._tcp                SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp                SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_kerberos._udp            SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._udp            SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kpasswd._udp             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][464][srv-win-men-02.tssr-men.lab.]
_kpasswd._udp             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][464][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.DomainDnsZones SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.DomainDnsZones SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.ForestDnsZones SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.ForestDnsZones SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]


PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-02

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
_gc._tcp.Default-First... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_gc._tcp.Default-First... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_gc._tcp                  SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_gc._tcp                  SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp            SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp            SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kpasswd._tcp             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][464][srv-win-men-02.tssr-men.lab.]
_kpasswd._tcp             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][464][srv-win-men-01.tssr-men.lab.]
_ldap._tcp                SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp                SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_kerberos._udp            SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._udp            SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kpasswd._udp             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][464][srv-win-men-02.tssr-men.lab.]
_kpasswd._udp             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][464][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.DomainDnsZones SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.DomainDnsZones SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.ForestDnsZones SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.ForestDnsZones SRV        33         10/5/2026 5:00:00 AM 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]

```

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName _msdcs.TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-01

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
_kerberos._tcp.Default... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.dc         SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_kerberos._tcp.dc         SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.dc             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.dc             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.b317f640-12... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.b317f640-12... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.gc             SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.gc             SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.pdc            SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]


PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName _msdcs.TSSR-MEN.LAB -RRType SRV -ComputerName SRV-WIN-MEN-02

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
_kerberos._tcp.Default... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.Default... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.dc         SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][88][srv-win-men-01.tssr-men.lab.]
_kerberos._tcp.dc         SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][88][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.dc             SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.dc             SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.b317f640-12... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.b317f640-12... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][389][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 6:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.Default-Fir... SRV        33         10/20/2026 5:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.gc             SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-01.tssr-men.lab.]
_ldap._tcp.gc             SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][3268][srv-win-men-02.tssr-men.lab.]
_ldap._tcp.pdc            SRV        33         10/21/2026 1:00:0... 00:10:00        [0][100][389][srv-win-men-01.tssr-men.lab.]
```

Puis interroge-les comme le ferait un client :

```powershell
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server 192.168.100.10

Name                                     Type   TTL   Section    NameTarget                     Priority Weight Port
----                                     ----   ---   -------    ----------                     -------- ------ ----
_ldap._tcp.dc._msdcs.TSSR-MEN.LAB        SRV    600   Answer     srv-win-men-01.tssr-men.lab    0        100    389
_ldap._tcp.dc._msdcs.TSSR-MEN.LAB        SRV    600   Answer     srv-win-men-02.tssr-men.lab    0        100    389

Name       : srv-win-men-01.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.10


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.11


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.56.101



PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server 192.168.100.11

Name                                     Type   TTL   Section    NameTarget                     Priority Weight Port
----                                     ----   ---   -------    ----------                     -------- ------ ----
_ldap._tcp.dc._msdcs.TSSR-MEN.LAB        SRV    600   Answer     srv-win-men-01.tssr-men.lab    0        100    389
_ldap._tcp.dc._msdcs.TSSR-MEN.LAB        SRV    600   Answer     srv-win-men-02.tssr-men.lab    0        100    389

Name       : srv-win-men-01.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.10


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.11


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.56.101

```

```powershell
PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _kerberos._tcp.TSSR-MEN.LAB -Type SRV -Server 192.168.100.10

Name                                     Type   TTL   Section    NameTarget                     Priority Weight Port
----                                     ----   ---   -------    ----------                     -------- ------ ----
_kerberos._tcp.TSSR-MEN.LAB              SRV    600   Answer     srv-win-men-02.tssr-men.lab    0        100    88
_kerberos._tcp.TSSR-MEN.LAB              SRV    600   Answer     srv-win-men-01.tssr-men.lab    0        100    88

Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.11


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.56.101


Name       : srv-win-men-01.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.10



PS C:\Users\administrator.TSSR-MEN> Resolve-DnsName -Name _kerberos._tcp.TSSR-MEN.LAB -Type SRV -Server 192.168.100.11

Name                                     Type   TTL   Section    NameTarget                     Priority Weight Port
----                                     ----   ---   -------    ----------                     -------- ------ ----
_kerberos._tcp.TSSR-MEN.LAB              SRV    600   Answer     srv-win-men-02.tssr-men.lab    0        100    88
_kerberos._tcp.TSSR-MEN.LAB              SRV    600   Answer     srv-win-men-01.tssr-men.lab    0        100    88

Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.11


Name       : srv-win-men-02.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.56.101


Name       : srv-win-men-01.tssr-men.lab
QueryType  : A
TTL        : 3600
Section    : Additional
IP4Address : 192.168.100.10

```


Pour chacun, tu dois trouver **deux** enregistrements (un par contrôleur). Regarde les colonnes _NameTarget_, _Port_ (389 pour LDAP, 88 pour Kerberos), _Priority_ et _Weight_.

> [!warning] Si l'enregistrement du nouveau contrôleur manque 
> Le service Netlogon du Core enregistre lui-même ses SRV. Pour forcer l'enregistrement : `nltest /dsregdns` sur `[Core]`. Relis ensuite. Si le problème persiste, vérifie les DNS configurés sur le Core (partie 6).

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

**À quoi servent les enregistrements SRV (avec tes mots) :**


**Notes**

1. **Zone Properties (`TSSR-MEN.LAB` & `_msdcs`):** In `Get-DnsServerZone` output from step 2:
    
    - Both servers show `ZoneType: Primary` and `IsDsIntegrated: True`.
        
    - For `TSSR-MEN.LAB`, `ReplicationScope` is **`Domain`** and `DynamicUpdate` is **`Secure`**.
        
    - For `_msdcs.TSSR-MEN.LAB`, `ReplicationScope` is **`Forest`**.
        
2. **Reverse Lookup Zone (`100.168.192.in-addr.arpa`):**
    
    - Listed in both server outputs as `Primary`, `IsDsIntegrated: True`, and `ReplicationScope: Domain`.
        
3. **SRV Record Counts:** In `Get-DnsServerResourceRecord` outputs from step 4:
    
    - `_ldap._tcp.dc._msdcs` returns **2 records** (one pointing to `srv-win-men-01.tssr-men.lab` and one pointing to `srv-win-men-02.tssr-men.lab`).
        
    - `_kerberos._tcp` also returns **2 records** (one for each domain controller).
---

## 5. Tester la réplication des enregistrements

### Comprendre

> [!question] Ce que ce test prouve 
> Tu crées une modification sur **un** serveur et tu la retrouves sur **l'autre**. Comme la zone est dans AD, c'est la **réplication Active Directory** qui transporte l'enregistrement. Il faut donc **interroger explicitement** chaque serveur (`-ComputerName`, `-Server`) : sans ça, la commande peut répondre à partir d'un seul serveur et le test ne prouve rien.

### Pas à pas

**A. Enregistrement créé sur `[Graphique]`**

|Paramètre|Valeur|
|---|---|
|Nom|`test-core`|
|Type|A|
|IPv4|`192.168.100.253`|
|Zone|`TSSR-MEN.LAB`|

**A.1 : créer l'enregistrement** (`[Graphique]`)

Console _DNS_ → _Forward Lookup Zones_ → `TSSR-MEN.LAB` → clic droit → **New Host (A or AAAA)...** → nom `test-core`, IP `192.168.100.253` → **Add Host**.
![](attachments/Pasted%20image%2020261021110800.png)

**A.2 : vérifier sa présence en local** (`[Core]`)

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core
Get-DnsServerResourceRecord : Failed to get test-core record in TSSR-MEN.LAB zone on SRV-WIN-MEN-02 server.
At line:1 char:1
+ Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (test-core:root/Microsoft/...rResourceRecord) [Get-DnsServerResourceRecord], CimException
    + FullyQualifiedErrorId : WIN32 9714,Get-DnsServerResourceRecord

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

> [!tip] Guidage 
> Le brief ne donne ni nom ni adresse pour le second enregistrement : choisis-les. Une adresse **libre**, hors de la plage DHCP (`.150` à `.200`) et différente de `.10`, `.11`, `.99` et `.253`. Choisis un nom qui rappelle son origine (par exemple le suffixe `-ps`).

**B.1 : créer l'enregistrement** (la commande part de `[Graphique]` ou du Core, mais **cible le Core**)

```powershell
Add-DnsServerResourceRecordA -Name secondRecord -ZoneName TSSR-MEN.LAB -IPv4Address 192.168.100.140 -ComputerName SRV-WIN-MEN-02
```

**B.2 : le retrouver sur le serveur graphique**

```powershell
PS C:\Users\administrator.TSSR-MEN> repadmin /syncall /AdeP
Syncing all NC's held on SRV-WIN-MEN-02.
Syncing partition: DC=ForestDnsZones,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication is in progress:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication completed successfully:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=DomainDnsZones,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication is in progress:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication completed successfully:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Schema,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication is in progress:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication completed successfully:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication is in progress:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication completed successfully:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

Syncing partition: DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication is in progress:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: The following replication completed successfully:
    From: CN=NTDS Settings,CN=SRV-WIN-MEN-02,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
    To  : CN=NTDS Settings,CN=SRV-WIN-MEN-01,CN=Servers,CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=TSSR-MEN,DC=LAB
CALLBACK MESSAGE: SyncAll Finished.
SyncAll terminated with no errors.

PS C:\Users\administrator.TSSR-MEN> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord -ComputerName SRV-WIN-MEN-01
Get-DnsServerResourceRecord : Failed to get secondRecord record in TSSR-MEN.LAB zone on SRV-WIN-MEN-01 server.
At line:1 char:1
+ Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (secondRecord:root/Microsoft/...rResourceRecord) [Get-DnsServerResourceRecord], CimException
    + FullyQualifiedErrorId : WIN32 9714,Get-DnsServerResourceRecord

PS C:\Users\administrator.TSSR-MEN>
```
La commande ne semble pas se propager et le record n'apparaît pas.

### Troubleshoot du record perdu:

```powershell
PS C:\Users\Administrator> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -ComputerName SRV-WIN-MEN-01 | Where-Object { $_.HostName -like "*secondRecord*" }
PS C:\Users\Administrator> Update-DnsServerDsZone -Name TSSR-MEN.LAB -ComputerName SRV-WIN-MEN-01
Update-DnsServerDsZone : The term 'Update-DnsServerDsZone' is not recognized as the name of a cmdlet, function, script
file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct
and try again.
At line:1 char:1
+ Update-DnsServerDsZone -Name TSSR-MEN.LAB -ComputerName SRV-WIN-MEN-0 ...
+ ~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (Update-DnsServerDsZone:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException

PS C:\Users\Administrator> Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name secondRecord -ComputerName SRV-WIN-MEN-01

HostName                  RecordType Type       Timestamp            TimeToLive      RecordData
--------                  ---------- ----       ---------            ----------      ----------
secondRecord              A          1          0                    01:00:00        192.168.100.140


PS C:\Users\Administrator>
```
Je pense que c'était juste long.

Vérifie aussi dans la console DNS de `[Graphique]` (touche F5 pour actualiser).

**B.3 : le résoudre depuis Windows 11** (`[Client]`)

```powershell
Resolve-DnsName -Name <nom>.TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
```

> [!warning] Délai de réplication 
> Si l'enregistrement n'apparaît pas tout de suite sur l'autre serveur, patiente quelques dizaines de secondes (jusqu'à quelques minutes), puis relance. Sinon, force la réplication AD avec `repadmin /syncall /AdeP` et relis. Note le délai constaté.

### À noter

|Étape|Serveur interrogé|Commande|Résultat|Délai|
|---|---|---|---|---|
|`test-core` visible en local|`SRV-WIN-MEN-02`||||
|`test-core` résolu|`192.168.100.11`||||
|Second enregistrement créé|`SRV-WIN-MEN-02`||||
|Second enregistrement lu|`SRV-WIN-MEN-01`||||
|Second enregistrement résolu|depuis le client||||


**Nettoyage :** supprimes-tu ou gardes-tu les enregistrements de test ? Note ton choix. Pour supprimer :

```powershell
Remove-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name <nom> -RRType A -ComputerName <serveur> -Force
```

**Commentaires**

---

## 6. Configurer les serveurs DNS

### Comprendre

> [!question] Pourquoi les DNS d'un contrôleur de domaine comptent Un contrôleur de domaine est **aussi un client DNS** : il consulte une liste ordonnée (**préféré**, puis **alternatif**). Cette liste a des conséquences :
> 
> - Si un contrôleur ne se désigne que lui-même, il peut se retrouver « isolé » au démarrage : son DNS n'a pas encore chargé la zone ou n'a pas encore répliqué les changements.
> - Si un contrôleur ne désigne que son partenaire, il dépend de ce partenaire pour sa propre résolution.
> - Les stratégies courantes : le **partenaire en préféré** et **soi-même en alternatif**, ou l'inverse, avec une adresse de bouclage (`127.0.0.1`) ou l'adresse IP propre.
> 
> Le brief demande de configurer « selon la stratégie du laboratoire » sans la définir : **choisis-en une, justifie-la**, et si besoin demande confirmation au formateur.

**Stratégie retenue et justification :**

### Pas à pas

**Étape 1 : examiner la configuration actuelle** sur chacun des deux serveurs

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

Note l'alias de la carte (par exemple `Ethernet0`) et les adresses actuelles. Le TP précédent a peut-être laissé le Core pointer uniquement vers `192.168.100.10`, et `SRV-WIN-MEN-01` uniquement vers lui-même.

**Étape 2 : définir la liste** (une commande par serveur, adaptée à ta stratégie)

```powershell
Set-DnsClientServerAddress -InterfaceAlias "<alias de la carte>" -ServerAddresses ("<DNS préféré>","<DNS alternatif>")
```

**Étape 3 : revérifier**, puis vider le cache du client DNS de la machine

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
Clear-DnsClientCache
```

**Étape 4 : vérifier que chaque contrôleur résout le domaine** (sur chaque serveur)

```powershell
Resolve-DnsName -Name TSSR-MEN.LAB
Resolve-DnsName -Name SRV-WIN-MEN-01.TSSR-MEN.LAB
Resolve-DnsName -Name SRV-WIN-MEN-02.TSSR-MEN.LAB
```

**Étape 5 : contrôle global (optionnel)**

`dcdiag /test:dns` lance un test DNS complet du contrôleur. La sortie est longue : lis surtout les lignes _passed_ et _failed_.

### À noter

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|Alias de la carte réseau|||
|DNS **avant**|||
|DNS préféré **après**|||
|DNS alternatif **après**|||
|Résolution du domaine|||
|Résolution des deux noms de contrôleur|||

![[capture-6-dns-avant.png]] ![[capture-6-set-dns.png]] ![[capture-6-dns-apres.png]] ![[capture-6-resolution.png]]

**Commentaires**

---

## 7. Tester depuis le client Windows 11

### Comprendre

> [!question] Le client reçoit ses DNS par DHCP Ton client est en DHCP depuis le TP DHCP : ses serveurs DNS ne se règlent donc pas sur le client, mais dans l'**option DHCP 006 (DNS Servers)** de l'étendue. Tant que cette option ne contient que `192.168.100.10`, le client n'a pas de DNS de secours. En ajoutant `192.168.100.11`, le client reçoit **deux** serveurs et bascule sur le second si le premier ne répond pas.

### Pas à pas

**Étape 1 : identifier les DNS actuels** (`[Client]`)

```powershell
ipconfig /all
Get-DnsClientServerAddress -AddressFamily IPv4
```

**Étape 2 : modifier l'option DHCP** de l'étendue `LAN-TSSR` (`[Graphique]`)

Soit à la console : _DHCP_ → `IPv4` → étendue → **Scope Options** → clic droit sur **006 DNS Servers** → **Properties** → ajoute `192.168.100.11` sans retirer `192.168.100.10`. Soit en PowerShell :

```powershell
Set-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -DnsServer <DNS1>,<DNS2>
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0
```

**Étape 3 : récupérer la nouvelle configuration et contrôler** (`[Client]`)

```powershell
ipconfig /renew
ipconfig /all
```

Les deux DNS doivent apparaître. Note l'**ordre** : c'est celui de la liste que tu as saisie dans le DHCP. Si tu es en contrôle à distance, rappelle-toi l'avertissement du formateur sur `ipconfig /release` ; ici `/renew` seul suffit.

**Étape 4 : interroger explicitement chacun des deux serveurs** (`[Client]`)

```powershell
Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly
```

Équivalent avec l'outil classique : `nslookup TSSR-MEN.LAB 192.168.100.11`.

**Étape 5 : résoudre les deux contrôleurs et les enregistrements de test** sur chaque serveur DNS (`[Client]`)

```powershell
Resolve-DnsName -Name SRV-WIN-MEN-01.TSSR-MEN.LAB -Server <IP>
Resolve-DnsName -Name SRV-WIN-MEN-02.TSSR-MEN.LAB -Server <IP>
Resolve-DnsName -Name test-core.TSSR-MEN.LAB -Server <IP>
Resolve-DnsName -Name <nom du second enregistrement>.TSSR-MEN.LAB -Server <IP>
```

> [!tip] Guidage
> 
> - Pour un tableau propre, répète les quatre commandes avec `192.168.100.10` puis avec `192.168.100.11`. Les réponses doivent être **identiques** : c'est la preuve que les deux serveurs servent la même zone.
> - `nslookup` affiche encore `Server: UnKnown` ? C'est le **PTR** du serveur DNS interrogé qui manque dans la zone inversée (voir le TP DNS). Ce n'est pas un échec de résolution. Tu peux créer le PTR pour `.10` et `.11` (`Add-DnsServerResourceRecordPtr`) si tu veux, en le notant.
> - Quelle différence entre `-Server <IP>` (tu choisis le DNS interrogé) et une requête sans `-Server` (Windows choisit selon sa liste) ?

### À noter

|Élément|Résultat|
|---|---|
|DNS du client **avant**||
|Option DHCP 006 **après**||
|DNS du client **après** (ordre)||
|Domaine résolu par `192.168.100.10`||
|Domaine résolu par `192.168.100.11`||

|Nom résolu|Via `192.168.100.10`|Via `192.168.100.11`|
|---|---|---|
|`SRV-WIN-MEN-01.TSSR-MEN.LAB`|||
|`SRV-WIN-MEN-02.TSSR-MEN.LAB`|||
|`test-core.TSSR-MEN.LAB`|||
|second enregistrement de test|||

![[capture-7-client-avant.png]] ![[capture-7-option-dhcp.png]] ![[capture-7-client-apres.png]] ![[capture-7-resolution-10.png]] ![[capture-7-resolution-11.png]]

### Pour aller plus loin : test de panne (optionnel)

> [!tip] Guidage C'est la vraie preuve de la **redondance**. Fais un snapshot avant, et n'oublie pas de redémarrer le service ensuite.
> 
> 1. `[Core]` `Stop-Service -Name DNS`
> 2. `[Client]` `Clear-DnsClientCache`, puis résous `SRV-WIN-MEN-01.TSSR-MEN.LAB` **sans** `-Server`. Le client bascule-t-il sur l'autre serveur ? Combien de temps la réponse met-elle à arriver ?
> 3. `[Core]` `Start-Service -Name DNS`
> 4. Refais le test dans l'autre sens (arrête le DNS de `[Graphique]`).

**Résultats du test de panne :**

**Commentaires**

---

## 8. Validation

|Vérification|Validé|Preuve|
|---|---|---|
|Le rôle DNS fonctionne sur les deux contrôleurs|☐|[[#3. Installer et vérifier le rôle DNS]]|
|La zone intégrée à AD est présente sur les deux serveurs|☐|[[#4. Vérifier la réplication des zones DNS]]|
|Les enregistrements AD et de test sont disponibles|☐|[[#4. Vérifier la réplication des zones DNS]] et [[#5. Tester la réplication des enregistrements]]|
|La réplication des modifications DNS fonctionne dans les deux sens|☐|[[#5. Tester la réplication des enregistrements]]|
|Le client interroge les deux DNS et obtient des réponses correctes|☐|[[#7. Tester depuis le client Windows 11]]|

> [!check] À valider avant de rendre le TP
> 
> - [ ] Chaque étape a sa commande exacte et sa capture
> - [ ] Le sens des deux créations est clair : une depuis le Graphique, une depuis PowerShell en ciblant le Core
> - [ ] La stratégie DNS des contrôleurs est écrite et justifiée
> - [ ] Les enregistrements de test sont gardés ou supprimés, et c'est noté

![[capture-8-console-dns-01.png]] ![[capture-8-console-dns-02.png]]

---

## 9. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

### Commandes utiles (aide-mémoire)

```powershell
# Rôle et service
Get-WindowsFeature -Name DNS
Get-Service -Name DNS

# Zones et enregistrements
Get-DnsServerZone -ComputerName <serveur>
Get-DnsServerResourceRecord -ZoneName <zone> -ComputerName <serveur>
Add-DnsServerResourceRecordA -Name <nom> -ZoneName <zone> -IPv4Address <ip> -ComputerName <serveur>

# Résolution
Resolve-DnsName -Name <nom> -Server <ip> -DnsOnly
Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server <ip>

# Configuration cliente
Get-DnsClientServerAddress -AddressFamily IPv4
Set-DnsClientServerAddress -InterfaceAlias "<alias>" -ServerAddresses ("<dns1>","<dns2>")
Clear-DnsClientCache

# DHCP
Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0
Set-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -DnsServer <dns1>,<dns2>
```

---

> [!note] Rendu
> 
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs de commandes et tableaux remplis
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Export PDF réalisé (si demandé)