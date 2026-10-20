> [!abstract] Contexte  
> Le domaine Active Directory fonctionne sur un seul contrôleur de domaine Windows Server 2025. Pour améliorer la disponibilité de l’authentification et de l’annuaire, un deuxième contrôleur de domaine est ajouté, sur le serveur **Server Core** du TP précédent. Toutes les opérations se font avec **PowerShell**.

> [!note] How to read this workbook  
> The workbook has a few tasks in it: install AD DS, promote the Core server, check replication, and document everything. The main confusion came from the naming inconsistency and from running commands on the wrong machine. Each section below has a note explaining what happened and why.
> 
> - `[Core]` = `SRV-WIN-MEN-02` (the new server). `[Graphique]` = `SRV-WIN-MEN-01` (the existing DC with the GUI).
> - Commands that query Active Directory (`Get-ADUser`, `Get-ADGroupMember`, etc.) only work on a domain controller. Before promotion, the Core has no AD Web Services, so run them on `SRV-WIN-MEN-01`.

### Sommaire

- [[#1. Objectifs]]
- [[#2. Environnement]]
- [[#3. Installer le rôle Active Directory Domain Services]]
- [[#4. Promouvoir le serveur en contrôleur de domaine]]
- [[#5. Vérifier la réplication Active Directory]]
- [[#6. Validation finale]]
- [[#7. Conclusion et difficultés rencontrées]]

---

### 0. Prérequis

Suite à une migration de VMWare sur Windows 10 vers VirtualBox sur Linux CachyOS, les machines virtuelles doivent être converties et réimportées.

> [!note] Why this section exists  
> This is the setup work from before the lab proper. It’s already done and doesn’t need changes. The DC is `SRV_WIN_MEN_1` in VirtualBox, and the Core is `SRV_WIN_MEN_02`.

**Convert the disk image to VDI** :

bash

```bash
qemu-img convert -f qcow2 -O vdi \
  "/mnt/WAREHOUSE/Work/TSSR/VMs/SRV-WIN-01/SRV-WIN-MEN-01.qcow2" \
  "/mnt/WAREHOUSE/Work/TSSR/VMs/SRV-WIN-01/SRV-WIN-MEN-01.vdi"
```

**Detach the QCOW2 image** :

bash

```bash
VBoxManage storageattach "SRV_WIN_MEN_1" \
  --storagectl "SATA" --port 0 --device 0 --type hdd --medium none
```

**Attach the new VDI image** :

bash

```bash
VBoxManage storageattach "SRV_WIN_MEN_1" \
  --storagectl "SATA" --port 0 --device 0 --type hdd \
  --medium "/mnt/WAREHOUSE/Work/TSSR/VMs/SRV-WIN-01/SRV-WIN-MEN-01.vdi"
```

**Démarrage** :

bash

```bash
VBoxManage startvm "SRV_WIN_MEN_1"
```

Show Image

> [!note] The DC was powered off  
> After the migration, `SRV_WIN_MEN_1` was off, which caused the “could not be contacted” errors later. Check `VBoxManage list runningvms` before you troubleshoot anything on the network.

---

### 1. Objectifs

- [x]  Installer le rôle Active Directory Domain Services.
- [x]  Promouvoir Server Core en contrôleur de domaine supplémentaire.
- [ ]  Comprendre le fonctionnement de la réplication Active Directory.
- [ ]  Vérifier la disponibilité des deux contrôleurs de domaine.
- [ ]  Contrôler les résultats depuis le serveur graphique.

---

### 2. Environnement

|Élément|Configuration|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Contrôleur de domaine existant|`SRV-WIN-MEN-01` (`192.168.100.10/24`)|
|Nouveau contrôleur de domaine|`SRV-WIN-MEN-02` (`192.168.100.11/24`)|
|Réseau|`LAB-TSSR-MEN`|



**Nom réel du Server Core :** `SRV-WIN-MEN-02`

#### 2.1 Vérifications préalables

|Vérification|Commande|Résultat attendu|Résultat obtenu|
|---|---|---|---|
|IP et masque|`Get-NetIPConfiguration`|192.168.100.11/24|192.168.100.11|
|Serveur DNS|`Get-DnsClientServerAddress`|192.168.100.10|192.168.100.10|
|Joindre le DC existant|`Test-NetConnection 192.168.100.10 -Port 389`|Succès|Succès (TcpTestSucceeded : True)|
|Résolution des SRV du domaine|`Resolve-DnsName _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV`|`srv-win-men-01.tssr-men.lab`|Vérifié depuis le DC, à refaire sur le Core|
|Nom d’ordinateur|`hostname`|`SRV-WIN-MEN-02`|SRV-WIN-MEN-02|
|Heure cohérente avec le DC|`w32tm /query /status`|Même heure que le DC|à remplir|
|Snapshot fait|`VBoxManage snapshot "SRV_WIN_MEN_02" take "before-promotion"`|Snapshot présent|à confirmer|

> [!note] Why the network checks matter  
> Promotion fails most often because of network or DNS problems, not because of the command. These checks confirm that the Core can see the DC. Port 389 (LDAP) is the important one. In my earlier troubleshooting, `DestinationHostUnreachable` meant the DC was powered off, not that the network was broken.

> [!note] Why `Resolve-DnsName` was run on the DC  
> The output below came from `SRV-WIN-MEN-01`, which is the DC. That’s where the SRV record should be, and it confirms the DC is registered in DNS. Run the same command on the Core as well, because that’s what this check is meant to prove.

powershell

```powershell
PS C:\Users\Administrator> Resolve-DnsName _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV

Name                                     Type   TTL   Section    NameTarget                     Priority Weight Port
----                                     ----   ---   -------    ----------                     -------- ------ ----
_ldap._tcp.dc._msdcs.TSSR-MEN.LAB        SRV    600   Answer     srv-win-men-01.tssr-men.lab    0        100    389
```

---

### 3. Installer le rôle Active Directory Domain Services

**Étapes du brief**

1. Identifier le module PowerShell permettant de gérer les rôles et fonctionnalités Windows Server.
2. Rechercher les commandes permettant d’installer un rôle.
3. Installer le rôle AD DS ainsi que les outils d’administration nécessaires.
4. Vérifier que le rôle est installé.

|Question|Réponse|
|---|---|
|Module qui gère les rôles et fonctionnalités|`ServerManager` (contient `Install-WindowsFeature`)|
|Commande(s) pour installer un rôle|`Install-WindowsFeature`|
|Nom technique du rôle AD DS|`AD-Domain-Services`|
|Paramètre pour les outils d’administration|`-IncludeManagementTools`|

> [!note] How to find these yourself  
> Use `Get-Command -Noun WindowsFeature` to find the command and its module. Use `Get-WindowsFeature *AD*` to find the technical role name, which is the **Name** column, not the display name. `Get-Help Install-WindowsFeature -Examples` shows the parameter for management tools. The brief asks you to _research_ these, so note in your own words how you found each one.

**Commande d’installation utilisée** (`[Core]`) :

powershell

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

Résultat :

```
Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {Active Directory Domain Services, Group P...
```

**Vérification** (`[Core]`) :

powershell

```powershell
Get-WindowsFeature -Name AD-Domain-Services
Get-Command -Module ADDSDeployment
```

> [!note] What the verification shows  
> `Get-WindowsFeature` should show the feature as `Installed`. `Get-Command -Module ADDSDeployment` lists the promotion cmdlets (`Install-ADDSDomainController`, `Test-ADDSDomainControllerInstallation`, etc.). These cmdlets only exist once the role is installed. This is why `Test-ADDSDomainControllerInstallation` said “not recognized” before the role was installed.



---

### 4. Promouvoir le serveur en contrôleur de domaine

**Paramètres de la promotion**

|Paramètre du brief|Valeur demandée|Paramètre PowerShell trouvé|
|---|---|---|
|Domaine|`TSSR-MEN.LAB`|`-DomainName "TSSR-MEN.LAB"`|
|Type d’installation|Contrôleur de domaine supplémentaire|Commande `Install-ADDSDomainController`|
|Contrôleur en lecture seule (RODC)|Non|`-ReadOnlyReplica` absent (valeur par défaut : non)|
|Catalogue global|Activé|`-NoGlobalCatalog` absent (catalogue global activé par défaut)|
|Site Active Directory|Site existant|Non spécifié, choisi automatiquement (voir note)|
|DNS|Rôle DNS sur le nouveau DC|`-InstallDns`|
|Source de réplication initiale|Contrôleur de domaine existant|Non spécifié, choisi automatiquement (voir note)|
|Mot de passe DSRM|À saisir à l’invite|`-SafeModeAdministratorPassword` (avec `Read-Host -AsSecureString`)|
|Identifiants autorisés à promouvoir|Compte administrateur du domaine|`-Credential $cred`|

> [!note] Why `Install-ADDSDomainController` and not the others  
> There are three promotion cmdlets, and the brief’s warning is about picking the right one:
> 
> - `Install-ADDSForest` creates a **new forest**. Wrong here.
> - `Install-ADDSDomain` creates a **new child domain** in an existing forest. Wrong here.
> - `Install-ADDSDomainController` **adds a DC to an existing domain**. This is the correct one.

> [!note] Site and replication source  
> The command doesn’t set `-SiteName` or `-ReplicationSourceDC`, so AD picks them. The site comes from the IP subnet, and the only other DC is `SRV-WIN-MEN-01`, so that’s the source. To confirm the site, run `Get-ADReplicationSite` on the DC. It should show `Default-First-Site-Name` unless the lab changed it. If you want to be explicit, add `-SiteName` and `-ReplicationSourceDC` to the command.

**Étapes du brief**

1. Rechercher la commande PowerShell permettant d’ajouter un contrôleur de domaine à un domaine existant.
2. Préparer les paramètres nécessaires à la promotion.
3. Définir le mot de passe de restauration des services d’annuaire (DSRM).
4. Lancer la promotion.
5. Attendre le redémarrage du serveur.

**Préparation des identifiants** (`[Core]`, sans mot de passe dans les commandes) :

powershell

```powershell
$user = Read-Host "Compte du domaine"
$pass = Read-Host "Mot de passe" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)
$dsrm = Read-Host "Mot de passe DSRM" -AsSecureString
```

> [!note] Why `Get-Credential` didn’t work  
> `Get-Credential` opens a graphical Windows dialog, and that can’t display over SSH, so the command hung. Building the credential with `Read-Host` keeps everything in the terminal. Also, `$cred` must exist in the current session. When it was empty, the test reported “must supply a user account name”, which is misleading: the real problem was the variable, not the account.

**Commande de test des prérequis** (`[Core]`) :

powershell

```powershell
Test-ADDSDomainControllerInstallation -DomainName "TSSR-MEN.LAB" -Credential $cred -InstallDns -SafeModeAdministratorPassword $dsrm
```

Résultat : toutes les vérifications en `Success`, avec deux avertissements attendus (voir ci-dessous).

**Commande de promotion** (`[Core]`) :

powershell

```powershell
Install-ADDSDomainController -DomainName "TSSR-MEN.LAB" -Credential $cred -InstallDns -SafeModeAdministratorPassword $dsrm -Force
```

Résultat : `Operation completed successfully`, statut `Success`. Le serveur redémarre automatiquement.

> [!note] What the two warnings mean  
> Both are expected in an isolated lab, so you can ignore them, but explain them in your report:
> 
> - **Static IP:** the adapter has no static IPv6 address. In a lab with IPv4 only, DNS works fine. In production, you’d set static addresses on every adapter.
> - **DNS delegation:** there’s no parent zone above `TSSR-MEN.LAB` to delegate from. Delegation only matters if the domain must be resolved from outside the lab.

**Après le redémarrage**

|Vérification|Résultat|
|---|---|
|Durée de la promotion et du redémarrage|à mesurer et à remplir|
|Compte avec lequel tu ouvres la session|`TSSR-MEN\Administrator`|
|Le serveur est-il bien contrôleur de domaine ?|Oui (promotion en `Success`), à confirmer avec `Get-ADDomainController`|
|Avertissements rencontrés|IP statique IPv6, délégation DNS (voir note)|

**Configuration DNS et DHCP**

|Serveur|DNS préféré|DNS alternatif|
|---|---|---|
|`SRV-WIN-MEN-01`|192.168.100.10 (lui-même)|192.168.100.11|
|`SRV-WIN-MEN-02`|192.168.100.11 (lui-même)|192.168.100.10|

> [!note] Why each DC points to itself first  
> A DC should resolve DNS from its own DNS server first, then from its partner. If a DC points only at the other DC and that one is down, it can’t resolve names at all. Set this on `SRV-WIN-MEN-01` as well, as the last step of the TP.
> 
> On DHCP: the brief asks what the scope distributes. Both servers use static IPs, so DHCP doesn’t affect them. Check whether a DHCP scope exists on `SRV-WIN-MEN-01` and, if so, make sure it hands out `192.168.100.10` and `192.168.100.11` as DNS servers, or only `192.168.100.10`. Record what you find, even if you don’t change anything.

**Commentaires** : _(à rédiger avec tes propres mots)_

---

### 5. Vérifier la réplication Active Directory

#### 5.1 Lister les contrôleurs de domaine

**Étapes du brief**

1. Afficher la liste des contrôleurs de domaine.
2. Vérifier que les deux serveurs sont présents.

**Commande** (`[Graphique]` ou `[Core]` après redémarrage) :

powershell

```powershell
Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, Site, IsGlobalCatalog, OperatingSystem
```

|Contrôleur|IPv4|Site|Catalogue global|
|---|---|---|---|
|SRV-WIN-MEN-01|192.168.100.10|à vérifier|Oui (attendu)|
|SRV-WIN-MEN-02|192.168.100.11|à vérifier|Oui (attendu)|

> [!note] Check this table against real output  
> The values above are what the configuration should produce, not output I’ve seen. Replace them with what `Get-ADDomainController` actually returns. If only one server appears, the promotion didn’t finish, so check the reboot status first.

![[capture-5-1-liste-dc.png]]

#### 5.2 Contrôler l’état de la réplication

**Étapes du brief**

3. Rechercher les commandes permettant de vérifier la réplication AD.
4. Contrôler l’état de la réplication entre les deux serveurs.

|Commande|Ce qu’elle montre|Résultat observé|
|---|---|---|
|`repadmin /replsummary`|Résumé de la réplication entre tous les DC, avec les échecs|à remplir|
|`repadmin /showrepl SRV-WIN-MEN-02`|Partenaires de réplication entrants et sortants du Core, avec la date du dernier succès|à remplir|
|`dcdiag /test:replications`|Test de santé de la réplication|à remplir|
|`Get-ADReplicationPartnerMetadata -Target SRV-WIN-MEN-01`|Métadonnées de réplication (date du dernier succès, échecs)|à remplir|

> [!note] What “good” looks like  
> You want: a recent last-success time for each partner, zero failures, inbound and outbound links in both directions, and the Domain, Configuration, and Schema partitions replicating. Also check that replication works in **both** directions, not just one. If the summary says the last attempt failed with a DNS or RPC error, the cause is usually DNS or connectivity again.

![[capture-5-2-replication.png]]

**Réplication AD avec tes mots**

> [!question] À traiter

- **Multi-maître :** tous les DC peuvent accepter des modifications, et chaque changement est répliqué vers les autres. On peut donc modifier l’annuaire sur n’importe quel contrôleur, pas seulement sur un contrôleur principal.
- **Partitions :** la partition du domaine, la partition de configuration, la partition de schéma et les partitions d’application sont répliquées. SYSVOL (les scripts et stratégies de groupe) est répliqué par DFS-R, un mécanisme distinct.
- **Ce que AD réplique et vers qui :** chaque objet et attribut porte un numéro de version (USN) et une date de modification. Chaque DC garde la trace de ce qu’il a déjà reçu de chaque partenaire. La topologie (les connexions de réplication) définit qui parle à qui.
- **Intra-site vs inter-site :** la réplication intra-site est rapide et déclenchée par les changements. La réplication inter-site est planifiée et compressée, pour économiser la bande passante entre sites.

> [!note] Rewrite these in your own words  
> These are reference answers so you can check your understanding. Don’t paste them as-is: the brief wants your explanation. Read each one, close it, and write your own version.

**Commentaires** : _(à rédiger avec tes propres mots)_

#### 5.3 Test de réplication

**Étapes du brief**

1. Créer sur `SRV-WIN-MEN-01` une OU nommée `TEST-REPLICATION-CORE`.
2. Vérifier sa présence en interrogeant explicitement l’annuaire de `SRV-WIN-MEN-02`.
3. Créer un utilisateur de test dans cette OU depuis PowerShell, en ciblant le contrôleur Core.
4. Vérifier sa présence en interrogeant explicitement le serveur graphique.
5. Supprimer les objets de test après validation.

**Commandes** :

powershell

```powershell
# 1. Sur SRV-WIN-MEN-01 : créer l'OU
New-ADOrganizationalUnit -Name "TEST-REPLICATION-CORE" -Path "DC=TSSR-MEN,DC=LAB" -Server SRV-WIN-MEN-01.tssr-men.lab

# 2. Sur SRV-WIN-MEN-02 : lire l'OU
Get-ADOrganizationalUnit -Identity "OU=TEST-REPLICATION-CORE,DC=TSSR-MEN,DC=LAB" -Server SRV-WIN-MEN-02.tssr-men.lab

# 3. Créer un utilisateur de test (désactivé, sans mot de passe) ciblant le Core
New-ADUser -Name "Test Replication" -SamAccountName "test.repl" -Path "OU=TEST-REPLICATION-CORE,DC=TSSR-MEN,DC=LAB" -Enabled $false -Server SRV-WIN-MEN-02.tssr-men.lab

# 4. Lire l'utilisateur sur le serveur graphique
Get-ADUser -Identity "test.repl" -Server SRV-WIN-MEN-01.tssr-men.lab

# 5. Supprimer : d'abord l'utilisateur, puis la protection de l'OU, puis l'OU
Remove-ADUser -Identity "test.repl" -Server SRV-WIN-MEN-01.tssr-men.lab -Confirm:$false
Set-ADObject -Identity "OU=TEST-REPLICATION-CORE,DC=TSSR-MEN,DC=LAB" -ProtectedFromAccidentalDeletion $false -Server SRV-WIN-MEN-01.tssr-men.lab
Remove-ADOrganizationalUnit -Identity "OU=TEST-REPLICATION-CORE,DC=TSSR-MEN,DC=LAB" -Server SRV-WIN-MEN-01.tssr-men.lab
```

|Étape|Contrôleur ciblé|Commande|Résultat|
|---|---|---|---|
|Créer l’OU `TEST-REPLICATION-CORE`|`SRV-WIN-MEN-01`|`New-ADOrganizationalUnit ... -Server`|à remplir|
|Lire l’OU|`SRV-WIN-MEN-02`|`Get-ADOrganizationalUnit ... -Server`|à remplir|
|Créer l’utilisateur de test|`SRV-WIN-MEN-02`|`New-ADUser ... -Server`|à remplir|
|Lire l’utilisateur|`SRV-WIN-MEN-01`|`Get-ADUser ... -Server`|à remplir|
|Supprimer les objets|`SRV-WIN-MEN-01`|`Remove-ADUser`, `Remove-ADOrganizationalUnit`|à remplir|
|Contrôler la suppression|les deux|`Get-ADOrganizationalUnit` sur chaque serveur|à remplir|

> [!note] Why `-Server` matters here  
> Without `-Server`, PowerShell picks any DC, so you can’t tell which one answered. Using `-Server` for each command proves which controller has the object. If you create something on one DC and read it from the other, it shows replication worked.
> 
> If the object doesn’t show up right away, wait a few seconds and retry. If it still doesn’t show up, run `repadmin /syncall` to force replication.
> 
> The OU is protected from accidental deletion by default, which is why the delete steps need to remove the user first, then turn off that protection, then delete the OU.

![[capture-5-3-creation-ou.png]] ![[capture-5-3-lecture-core.png]] ![[capture-5-3-creation-utilisateur.png]] ![[capture-5-3-lecture-graphique.png]] ![[capture-5-3-suppression.png]]

#### 5.4 Contrôle depuis le serveur graphique

Sur `SRV-WIN-MEN-01`, ouvre les trois consoles et confirme le résultat :

- **Active Directory Users and Computers** : l’OU `Domain Controllers` doit lister les deux serveurs.
- **Active Directory Sites and Services** : `SRV-WIN-MEN-02` doit apparaître sous le site, avec ses connexions de réplication.
- **DNS** : `SRV-WIN-MEN-02` doit apparaître parmi les serveurs de noms de la zone `tssr-men.lab`.

> [!note] Screenshots  
> These are the GUI checks the brief asks for. Take one screenshot per console. Don’t include any passwords in the captures.

![[capture-5-4-aduc.png]] ![[capture-5-4-sites-services.png]] ![[capture-5-4-dns.png]]

**Commentaires** : _(à rédiger avec tes propres mots)_

---

### 6. Validation finale

|Vérification|Validé|Preuve|
|---|---|---|
|Le rôle AD DS est installé|☑|[[#3. Installer le rôle Active Directory Domain Services]]|
|Le serveur est promu en contrôleur de domaine supplémentaire|☑|[[#4. Promouvoir le serveur en contrôleur de domaine]]|
|Les deux contrôleurs de domaine sont opérationnels|☐|[[#5.1 Lister les contrôleurs de domaine]]|
|La réplication fonctionne dans les deux sens|☐|[[#5.2 Contrôler l’état de la réplication]]|
|Les objets sont accessibles depuis les deux contrôleurs|☐|[[#5.3 Test de réplication]]|

> [!check] À valider avant de rendre le TP
> 
> - [ ]  Aucune commande collée ne contient de mot de passe
> - [ ]  Chaque étape a sa commande exacte et sa capture
> - [ ]  Les objets de test ont été supprimés des deux contrôleurs
> - [ ]  Le nom du Server Core est cohérent dans tout le document

> [!note] Checklist status  
> The two ☑ items are done: the role is installed and the promotion reported success. The other three need the post-reboot checks in sections 5.1 to 5.3. Don’t tick them until you’ve seen the output.

---

### 7. Conclusion et difficultés rencontrées

#### Difficultés / erreurs rencontrées

> [!note] What to put here  
> The brief says a documented incident is worth more than a trouble-free TP. These are the ones from this session. Keep the symptom, cause, and fix for each.

|Problème|Cause|Solution|
|---|---|---|
|`Get-Credential` bloque en SSH|La commande ouvre une boîte de dialogue graphique, impossible à afficher dans une session SSH|Construire l’identifiant avec `Read-Host` et `New-Object PSCredential`|
|“The user name or password is incorrect” avec `Add-Computer`|Le premier essai utilisait `TSSR-MEN\Administrateur` (nom français) alors que le compte du DC s’appelle `Administrator`|Utiliser le nom réel, trouvé avec `Get-ADDomain` et le SID `-500`|
|`Test-ADDSDomainControllerInstallation` non reconnu|Le module `ADDSDeployment` n’existe qu’après l’installation du rôle AD DS|Installer le rôle en premier|
|“Verification of user credential permissions failed”|La variable `$cred` était vide dans la session (jamais créée)|Recréer `$cred` avant le test|
|“could not be contacted” / `DestinationHostUnreachable`|La VM du DC était éteinte après la migration VMware → VirtualBox|`VBoxManage startvm "SRV_WIN_MEN_1"`, puis vérifier avec `Test-NetConnection ... -Port 389`|
|`Get-ADUser -Filter "SID -like '*-500'"` ne renvoie rien|L’attribut SID ne se filtre pas comme une chaîne de texte|Utiliser `(Get-ADDomain).DomainSID.Value + "-500"`|
|`Get-ADUser` ne fonctionne pas sur le Core|Avant la promotion, le Core n’a pas AD Web Services|Lancer les commandes AD sur le DC|
|Commandes collées fusionnées ou préfixe `PS C:\...>` copié|Le terminal (Alacritty/Kitty) fusionne les lignes lors d’un collage multi-lignes|Coller une commande à la fois et vérifier avant d’appuyer sur Entrée|

> [!note] Why the “password incorrect” error was misleading  
> The first error came from the wrong account name, not the password. After that, `$cred` was empty in some sessions, which produced a different error. Test each variable separately (`$cred.UserName`, `$dsrm.Length`) before blaming the password.

#### Ce que j’ai retenu

_(à rédiger avec tes propres mots. Pistes : pourquoi un domaine doit avoir au moins deux DC, pourquoi le DNS pointe vers soi-même en premier, pourquoi `-Server` est utile pour tester la réplication, et pourquoi il faut vérifier la connectivité avant la promotion.)_

---

> [!note] Rendu
> 
> - [ ]  Toutes les captures insérées
> - [ ]  Tous les blocs de commandes remplis
> - [ ]  Aucun mot de passe visible (texte ou capture)
> - [ ]  Tous les blocs `[!note]` supprimés avant rendu
> - [ ]  Export PDF réalisé (si demandé)

---

**What’s still open for you:** run the post-reboot checks on `SRV-WIN-MEN-01` (`Get-ADDomainController`, `repadmin /replsummary`), fill in the replication and test-object results in 5.2 and 5.3, check whether the VirtualBox snapshot exists, and set DNS on `SRV-WIN-MEN-01`. If any command returns something different from what I expected, paste the output and I’ll update the table.