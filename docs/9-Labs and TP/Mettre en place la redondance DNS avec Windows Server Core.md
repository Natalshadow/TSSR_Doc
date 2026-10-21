
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

> [!question] Pourquoi le DNS est vital pour Active Directory 
> Les contrôleurs de domaine et les clients **ne se trouvent pas par leur adresse IP mais par des enregistrements DNS** (notamment des enregistrements de type **SRV**, qui disent « tel service est fourni par tel serveur sur tel port »). Sans DNS, un poste ne retrouve plus de contrôleur de domaine : ouverture de session, GPO et recherche de l'annuaire échouent. C'est pourquoi un second serveur DNS apporte de la **redondance**.

Écris en une phrase, avec tes mots, pourquoi un client Windows a besoin du DNS pour joindre un contrôleur de domaine :

### Pas à pas (`[Core]`)

1. **Le rôle est-il déjà là ?** Lors de la promotion du TP précédent, tu as demandé le DNS sur le nouveau contrôleur : il doit déjà être installé. Vérifie-le plutôt que de le supposer :
    
    ```powershell
    Get-WindowsFeature -Name DNS
    ```
    
    Lis la colonne _Install State_ (installé ou non).
    
2. **S'il manque**, installe-le avec les outils de gestion (le module PowerShell `DnsServer` en fait partie) :
    
    ```powershell
    Install-WindowsFeature -Name DNS -IncludeManagementTools
    ```
    
3. **Le service fonctionne-t-il ?**
    
    ```powershell
    Get-Service -Name DNS
    ```
    
    Regarde le statut (_Running_) et le type de démarrage (_Automatic_).
    
4. **Le module PowerShell est-il disponible ?**
    
    ```powershell
    Get-Module -ListAvailable -Name DnsServer
    ```
    
    S'il n'apparaît pas, la fonctionnalité des outils DNS (`RSAT-DNS-Server`) n'est pas installée : cherche-la avec `Get-WindowsFeature *DNS*`.
    
5. **Le serveur répond-il ?** Un test direct depuis le Core :
    
    ```powershell
    Resolve-DnsName -Name TSSR-MEN.LAB -Server 127.0.0.1 -DnsOnly
    ```
    
6. **Découvrir les commandes d'administration DNS** (ce que demande l'étape 4 du brief) :
    
    ```powershell
    Get-Command -Module DnsServer | Measure-Object
    Get-Command -Module DnsServer -Noun *Zone*
    Get-Command -Module DnsServer -Noun *ResourceRecord*
    Get-Command -Module DnsServer -Verb Get
    ```
    

### À noter

|Vérification|Résultat|
|---|---|
|État du rôle DNS||
|Installation nécessaire ?||
|État et type de démarrage du service||
|Module `DnsServer` disponible||
|Résolution locale||
|Nombre de commandes du module `DnsServer`||

**Commandes DNS utiles trouvées** (choisis-en au moins 8, avec leur rôle) :

|Commande|Rôle|
|---|---|
|||
|||
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

> [!question] Zone intégrée à Active Directory Une zone DNS classique est stockée dans un **fichier** sur un serveur « principal » et copiée vers des serveurs « secondaires » (transfert de zone). Une zone **intégrée à AD** est stockée **dans la base Active Directory** : elle se réplique avec la réplication AD que tu as vérifiée au TP précédent. Conséquences : tous les contrôleurs DNS ont la zone en **lecture et écriture**, sans transfert de zone, et la sécurité des mises à jour dynamiques est gérée par AD. La **portée de réplication** dit quels contrôleurs reçoivent la zone : tous les contrôleurs de la **forêt**, tous ceux du **domaine**, ou un ensemble **personnalisé**. Ces portées s'appuient sur des partitions d'annuaire dédiées (`ForestDnsZones`, `DomainDnsZones`).

> [!tip] Guidage Au TP DNS, tu as choisi « To all DNS on domain » pour ta zone inversée `100.168.192.in-addr.arpa`. Cette zone devrait donc **aussi** exister sur le Core : c'est une vérification bonus.

Écris, avec tes mots, la différence entre une zone intégrée à AD et une zone principale classique :

### Pas à pas

1. **Lister les zones des deux serveurs** (depuis `[Graphique]`, ou en local sur chaque serveur) :
    
    ```powershell
    Get-DnsServerZone -ComputerName SRV-WIN-MEN-01
    Get-DnsServerZone -ComputerName SRV-WIN-MEN-02
    ```
    
2. **Les comparer** avec les propriétés utiles :
    
    ```powershell
    Get-DnsServerZone -ComputerName <serveur> | Select-Object ZoneName, ZoneType, IsDsIntegrated, ReplicationScope, DynamicUpdate
    ```
    
    Repère : la zone `TSSR-MEN.LAB` sur **les deux** serveurs, le type de zone, si elle est intégrée à AD (`IsDsIntegrated`), sa portée (`ReplicationScope`) et la mise à jour dynamique.
    
3. **Rechercher les zones « de service »** : regarde la zone `_msdcs.TSSR-MEN.LAB` et note sa portée. Pourquoi serait-elle différente de la zone du domaine ?
    
4. **Vérifier les enregistrements SRV** (ceux qui permettent de trouver les contrôleurs) :
    
    ```powershell
    Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -RRType SRV -ComputerName <serveur>
    Get-DnsServerResourceRecord -ZoneName _msdcs.TSSR-MEN.LAB -RRType SRV -ComputerName <serveur>
    ```
    
    Puis interroge-les comme le ferait un client :
    
    ```powershell
    Resolve-DnsName -Name _ldap._tcp.dc._msdcs.TSSR-MEN.LAB -Type SRV -Server <IP du serveur DNS>
    Resolve-DnsName -Name _kerberos._tcp.TSSR-MEN.LAB -Type SRV -Server <IP du serveur DNS>
    ```
    
    Pour chacun, tu dois trouver **deux** enregistrements (un par contrôleur). Regarde les colonnes _NameTarget_, _Port_ (389 pour LDAP, 88 pour Kerberos), _Priority_ et _Weight_.
    

> [!warning] Si l'enregistrement du nouveau contrôleur manque Le service Netlogon du Core enregistre lui-même ses SRV. Pour forcer l'enregistrement : `nltest /dsregdns` sur `[Core]`. Relis ensuite. Si le problème persiste, vérifie les DNS configurés sur le Core (partie 6).

### À noter

|Élément|`SRV-WIN-MEN-01`|`SRV-WIN-MEN-02`|
|---|---|---|
|Zone `TSSR-MEN.LAB` présente|||
|Type de zone|||
|Intégrée à AD|||
|Portée de réplication|||
|Mise à jour dynamique|||
|Zone `_msdcs.TSSR-MEN.LAB` : portée|||
|Zone inversée `100.168.192.in-addr.arpa` présente (bonus)|||
|Enregistrements SRV `_ldap._tcp.dc._msdcs` (nombre)|||
|Enregistrements SRV `_kerberos._tcp` (nombre)|||

![[capture-4-zones-01.png]] ![[capture-4-zones-02.png]] ![[capture-4-srv.png]]

**À quoi servent les enregistrements SRV (avec tes mots) :**

**Commentaires**

---

## 5. Tester la réplication des enregistrements

### Comprendre

> [!question] Ce que ce test prouve Tu crées une modification sur **un** serveur et tu la retrouves sur **l'autre**. Comme la zone est dans AD, c'est la **réplication Active Directory** qui transporte l'enregistrement. Il faut donc **interroger explicitement** chaque serveur (`-ComputerName`, `-Server`) : sans ça, la commande peut répondre à partir d'un seul serveur et le test ne prouve rien.

### Pas à pas

**A. Enregistrement créé sur `[Graphique]`**

|Paramètre|Valeur|
|---|---|
|Nom|`test-core`|
|Type|A|
|IPv4|`192.168.100.253`|
|Zone|`TSSR-MEN.LAB`|

1. `[Graphique]` Console _DNS_ → _Forward Lookup Zones_ → `TSSR-MEN.LAB` → clic droit → **New Host (A or AAAA)...** → nom `test-core`, IP `192.168.100.253` → **Add Host**.
    
2. `[Core]` Vérifie sa présence en local :
    
    ```powershell
    Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name test-core
    ```
    
3. `[Core]` Interroge **explicitement** le DNS du Core :
    
    ```powershell
    Resolve-DnsName -Name test-core.TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly
    ```
    

**B. Deuxième enregistrement créé depuis PowerShell, en ciblant le Core**

> [!tip] Guidage Le brief ne donne ni nom ni adresse pour le second enregistrement : choisis-les. Une adresse **libre**, hors de la plage DHCP (`.150` à `.200`) et différente de `.10`, `.11`, `.99` et `.253`. Choisis un nom qui rappelle son origine (par exemple le suffixe `-ps`).

1. Crée l'enregistrement (la commande part de `[Graphique]` ou du Core, mais **cible le Core**) :
    
    ```powershell
    Add-DnsServerResourceRecordA -Name <nom> -ZoneName TSSR-MEN.LAB -IPv4Address <adresse> -ComputerName SRV-WIN-MEN-02
    ```
    
2. Retrouve-le **sur le serveur graphique** :
    
    ```powershell
    Get-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name <nom> -ComputerName SRV-WIN-MEN-01
    ```
    
    Vérifie aussi dans la console DNS de `[Graphique]` (touche F5 pour actualiser).
    
3. `[Client]` Résous-le depuis Windows 11 :
    
    ```powershell
    Resolve-DnsName -Name <nom>.TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
    ```
    

> [!warning] Délai de réplication Si l'enregistrement n'apparaît pas tout de suite sur l'autre serveur, patiente quelques dizaines de secondes (jusqu'à quelques minutes), puis relance. Sinon, force la réplication AD avec `repadmin /syncall /AdeP` et relis. Note le délai constaté.

### À noter

|Étape|Serveur interrogé|Commande|Résultat|Délai|
|---|---|---|---|---|
|`test-core` visible en local|`SRV-WIN-MEN-02`||||
|`test-core` résolu|`192.168.100.11`||||
|Second enregistrement créé|`SRV-WIN-MEN-02`||||
|Second enregistrement lu|`SRV-WIN-MEN-01`||||
|Second enregistrement résolu|depuis le client||||

![[capture-5-creation-test-core.png]] ![[capture-5-lecture-core.png]] ![[capture-5-resolution-core.png]] ![[capture-5-creation-powershell.png]] ![[capture-5-lecture-graphique.png]] ![[capture-5-resolution-client.png]]

**Nettoyage :** supprimes-tu ou gardes-tu les enregistrements de test ? Note ton choix. Pour supprimer : `Remove-DnsServerResourceRecord -ZoneName TSSR-MEN.LAB -Name <nom> -RRType A -ComputerName <serveur> -Force`.

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

1. **Examiner la configuration actuelle** sur chacun des deux serveurs :
    
    ```powershell
    Get-DnsClientServerAddress -AddressFamily IPv4
    ```
    
    Note l'alias de la carte (par exemple `Ethernet0`) et les adresses actuelles. Le TP précédent a peut-être laissé le Core pointer uniquement vers `192.168.100.10`, et `SRV-WIN-MEN-01` uniquement vers lui-même.
    
2. **Définir la liste** (une commande par serveur, adaptée à ta stratégie) :
    
    ```powershell
    Set-DnsClientServerAddress -InterfaceAlias "<alias de la carte>" -ServerAddresses ("<DNS préféré>","<DNS alternatif>")
    ```
    
3. **Revérifier**, puis vide le cache DNS du client DNS de la machine :
    
    ```powershell
    Get-DnsClientServerAddress -AddressFamily IPv4
    Clear-DnsClientCache
    ```
    
4. **Vérifier que chaque contrôleur résout le domaine** (sur chaque serveur) :
    
    ```powershell
    Resolve-DnsName -Name TSSR-MEN.LAB
    Resolve-DnsName -Name SRV-WIN-MEN-01.TSSR-MEN.LAB
    Resolve-DnsName -Name SRV-WIN-MEN-02.TSSR-MEN.LAB
    ```
    
5. **Contrôle global (optionnel)** : `dcdiag /test:dns` lance un test DNS complet du contrôleur. La sortie est longue : lis surtout les lignes _passed_ et _failed_.
    

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

1. `[Client]` **Identifier les DNS actuels** :
    
    ```powershell
    ipconfig /all
    Get-DnsClientServerAddress -AddressFamily IPv4
    ```
    
2. `[Graphique]` **Modifier l'option DHCP** de l'étendue `LAN-TSSR`, soit à la console (_DHCP_ → `IPv4` → étendue → **Scope Options** → clic droit sur **006 DNS Servers** → **Properties** → ajoute `192.168.100.11` sans retirer `192.168.100.10`), soit en PowerShell :
    
    ```powershell
    Set-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -DnsServer <DNS1>,<DNS2>
    Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0
    ```
    
3. `[Client]` **Récupérer la nouvelle configuration** et contrôler :
    
    ```powershell
    ipconfig /renew
    ipconfig /all
    ```
    
    Les deux DNS doivent apparaître. Note l'**ordre** : c'est celui de la liste que tu as saisie dans le DHCP. Si tu es en contrôle à distance, rappelle-toi l'avertissement du formateur sur `ipconfig /release` ; ici `/renew` seul suffit.
    
4. `[Client]` **Interroger explicitement chacun des deux serveurs** :
    
    ```powershell
    Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.10 -DnsOnly
    Resolve-DnsName -Name TSSR-MEN.LAB -Server 192.168.100.11 -DnsOnly
    ```
    
    Équivalent avec l'outil classique : `nslookup TSSR-MEN.LAB 192.168.100.11`.
    
5. `[Client]` **Résoudre les deux contrôleurs et les enregistrements de test** sur chaque serveur DNS :
    
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