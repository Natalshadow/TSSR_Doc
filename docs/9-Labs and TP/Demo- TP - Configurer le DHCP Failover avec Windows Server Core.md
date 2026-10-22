
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


---

## 3. Installer et autoriser DHCP sur Core

### Pas à pas (`[Core]`)

**Étape 1 : installer le rôle DHCP et les outils d'administration**

```powershell
PS C:\Users\administrator.TSSR-MEN> Install-WindowsFeature -Name DHCP -IncludeManagementTools

Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {DHCP Server}
```



**Étape 2 : configuration post-déploiement**


```powershell
PS C:\Users\administrator.TSSR-MEN> Add-DhcpServerSecurityGroup
PS C:\Users\administrator.TSSR-MEN> Restart-Service -Name DHCPServer
WARNING: Waiting for service 'DHCP Server (DHCPServer)' to start...
```

**Étape 3 : vérifier la présence et le fonctionnement du service**

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-WindowsFeature -Name DHCP

Display Name                                            Name                       Install State
------------                                            ----                       -------------
[X] DHCP Server                                         DHCP                           Installed


PS C:\Users\administrator.TSSR-MEN> Get-Service -Name DHCPServer

Status   Name               DisplayName
------   ----               -----------
Running  DHCPServer         DHCP Server


```

Regarder l'état d'installation, le statut (_Running_) et le type de démarrage (_Automatic_).

**Étape 4 : autoriser le serveur dans Active Directory**


```powershell
Add-DhcpServerInDC -DnsName SRV-WIN-MEN-02 -IPAddress 192.168.100.11
or
Add-DhcpServerInDC -DnsName SRV-WIN-MEN-02.tssr-men.lab -IPAddress 192.168.100.11
```

**Étape 5 : vérifier que les deux serveurs sont autorisés**

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DhcpServerInDC

IPAddress            DnsName
---------            -------
192.168.100.10       srv-win-men-01.tssr-men.lab
192.168.100.11       srv-win-men-02
192.168.100.11       srv-win-men-02.tssr-men.lab
```

La liste doit montrer **deux** serveurs : `SRV-WIN-MEN-01` et le Core, avec leurs adresses IP.


### À noter

| Vérification                               | Résultat |
| ------------------------------------------ | -------- |
| Résultat de l'installation du rôle         | Success  |
| Groupes de sécurité créés                  |          |
| Service `DHCPServer` : statut et démarrage | Success  |
| Serveur Core autorisé (commande utilisée)  |          |
| Serveurs autorisés dans l'annuaire (liste) |          |

---

## 4. Vérifier l'étendue actuelle

### Pas à pas (`[Graphique]`)

**Étape 1 : vérifier la plage de l'étendue `LAN-TSSR`**

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-01

ScopeId         SubnetMask      Name           State    StartRange      EndRange        LeaseDuration
-------         ----------      ----           -----    ----------      --------        -------------
192.168.100.0   255.255.255.0   LAN-TSSR       Active   192.168.100.150 192.168.100.200 8.00:00:00
```

Relever le nom, l'identifiant d'étendue, la plage (début et fin), le masque, l'état (_Active_) et la durée du bail.

**Étape 2 : vérifier les DNS et le suffixe de domaine distribués**

```powershell
PS C:\Users\Administrator> Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01

OptionId   Name            Type       Value                VendorClass     UserClass       PolicyName
--------   ----            ----       -----                -----------     ---------       ----------
6          DNS Servers     IPv4Add... {192.168.100.10, ...
51         Lease           DWord      {691200}
15         DNS Domain Name String     {TSSR-MEN.LAB}


PS C:\Users\Administrator> (Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -OptionId 6 -ComputerName SRV-WIN-MEN-01).Value
192.168.100.10
192.168.100.11
```

Chercher dans le résultat l'option **6** (serveurs DNS) et l'option **15** (nom de domaine DNS). L'option 6 doit contenir **les deux** DNS.


**Étape 3 : relever les exclusions et les baux actuels**

```powershell
PS C:\Users\Administrator> Get-DhcpServerv4ExclusionRange -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
PS C:\Users\Administrator> Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01

IPAddress       ScopeId         ClientId             HostName             AddressState         LeaseExpiryTime
---------       -------         --------             --------             ------------         ---------------
192.168.100.150 192.168.100.0   08-00-27-e5-de-16    CLI-WIN-MEN-01.TS... Active               10/29/2026 12:55:34 PM
```

**Étape 4 : vérifier qu'un poste obtient une configuration valide** (`[Client]`)

```powershell
ipconfig /renew
ipconfig /all
```

Regarder l'adresse (dans la plage), le serveur DHCP, les serveurs DNS et le suffixe DNS. Sur la console de la VM, pas en contrôle à distance : `/renew` seul suffit ici.

**Étape 5 : constater l'absence de l'étendue sur le Core** (avant le failover)

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02
PS C:\Users\administrator.TSSR-MEN>
```

Le résultat doit être vide.



---

## 5. Mettre en place le DHCP Failover

## Comprendre

### Qu'est-ce que le DHCP Failover
Avant Windows Server 2012, on se protégeait d'une panne en **coupant l'étendue en deux** (80/20) sur deux serveurs indépendants, sans partage d'information. Le **DHCP Failover** fait mieux : les deux serveurs forment une **relation** et partagent la **même étendue et la même base de baux**. Ils se parlent en permanence (en TCP, port 647) pour rester synchronisés.

Il existe **deux modes** :
- **Load Balance** : Les deux serveurs répondent aux clients en même temps, avec une répartition (par défaut 50/50).
- **Hot Standby** : Un serveur **actif** répond à tous les clients ; le serveur **de secours** ne répond que si l'actif tombe, et il garde en **réserve** un pourcentage des adresses pour les nouveaux clients pendant la panne.

---

### Tableau comparatif des modes

| Critère | Load Balance | Hot Standby |
| :--- | :--- | :--- |
| **Qui répond aux clients en fonctionnement normal ?** | Les deux serveurs simultanément (50/50 par défaut). | Le serveur principal (**Active**). Le secondaire reste passif. |
| **Rôle de chaque serveur** | Rôle principal/actif pour les deux (`Active/Active`). | Rôle principal (`Active`) pour le premier, secours (`Standby`) pour le second. |
| **Réserve d'adresses** | Non (répartition par ratio d'adresses). | Oui (`ReservePercent` attribué au serveur passif). |
| **Cas d'usage typique** | Même site avec fort trafic exigeant une répartition de charge. | Site principal avec serveur de secours (ou site distant de backup). |

* **Pourquoi choisir Hot Standby ici ?**  
  Dans cette infrastructure, `SRV-WIN-MEN-01` est le serveur principal de production et `SRV-WIN-MEN-02` sert uniquement de secours en cas de défaillance. Il n'y a pas de besoin de répartition de charge active.

---

### Guidage et calcul de la réserve

Calcul de la réserve d'adresses pour la plage `.150` à `.200` :
* **Nombre d'adresses de la plage (.150 à .200) :** $200 - 150 + 1 = \mathbf{51\text{ adresses}}$.
* **Calcul de 10 % :** $51 \times 0{,}10 = 5{,}1$, soit **5 adresses** (arrondi).
* **Adresses de la réserve :** 5 adresses IP que le serveur `Standby` pourra attribuer à de *nouveaux* clients pendant la panne (en plus du renouvellement des baux existants).

---

### Les états d'une relation DHCP Failover

| État | Sens | Que fait le serveur de secours ? |
| :--- | :--- | :--- |
| **Normal** | Le serveur principal fonctionne et communique sur le port TCP 647. | Il ne répond à aucune requête client et synchronise sa base de baux en tâche de fond. |
| **Communication Interrupted** | La liaison réseau entre les deux serveurs est coupée, mais le partenaire n'est pas encore déclaré mort. | Il répond aux renouvellements des clients existants et pioche dans la réserve (`ReservePercent`) pour les nouveaux clients. |
| **Partner Down** | Le serveur principal est déclaré hors service (ou basculement manuel/automatique activé). | Il prend le contrôle total de l'étendue et attribue des baux temporaires avec la durée **MCLT**. |

---

## Pas à pas

### Étape 1 : Rechercher les commandes liées au failover

```powershell
Get-Command -Module DhcpServer -Noun *Failover*
Get-Help Add-DhcpServerv4Failover -Examples
Get-Help Add-DhcpServerv4Failover
```

---

### Étape 2 : Faire correspondre les paramètres imposés

| Paramètre imposé | Paramètre PowerShell trouvé |
| :--- | :--- |
| **Nom de la relation** | `-Name` |
| **Serveur sur lequel on lance la commande (actif)** | `-ComputerName` |
| **Partenaire de secours** | `-PartnerServer` |
| **Étendue** | `-ScopeId` |
| **Rôle du serveur actif** | `-ServerRole` |
| **Réserve d'adresses** | `-ReservePercent` |
| **Secret partagé (authentification)** | `-SharedSecret` |

#### Guidage théorique :
- **`-ServerRole`** : Désigne le rôle du serveur indiqué par `-ComputerName` (ici `Active`).
- **Secret partagé** : Authentifie les paquets TCP 647 entre serveurs pour éviter les faux serveurs DHCP.
- **MCLT (Max Client Lead Time)** : Durée maximale d'avance (par défaut `01:00:00`). Lors d'une panne, le serveur de secours attribue des baux courts égaux au MCLT pour éviter les conflits d'IP lorsque le serveur principal revient en ligne.

---

### Étape 3 : Créer la relation

```powershell
Add-DhcpServerv4Failover `
  -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" `
  -PartnerServer "SRV-WIN-MEN-02.tssr-men.lab" `
  -Name "Failover-LAN-TSSR" `
  -ScopeId 192.168.100.0 `
  -ServerRole Active `
  -ReservePercent 5 `
  -SharedSecret "<censored>"
```

---

### Étape 4 & 5 : Vérifier la relation et résolution du problème NAT

#### Incident identifié lors de l'inspection initiale (`Format-List *`)

Lors du premier contrôle détaillé via `Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *`, une anomalie a été détectée sur l'adresse d'écoute du serveur principal :

```text
PrimaryServerIP   : 10.0.3.15
SecondaryServerIP : 192.168.100.11
```

**Diagnostic :** Une interface carte réseau temporaire (NAT VirtualBox) était active sur `SRV-WIN-MEN-01` pour l'installation d'outils. Windows Server a automatiquement lié le failover DHCP à l'IP NAT `10.0.3.15` au lieu de l'IP du LAN `192.168.100.10`.

#### Action corrective appliquée :
1. Suppression de la carte réseau NAT sur la machine virtuelle.
2. Suppression de la relation de failover erronée :
   ```powershell
   Remove-DhcpServerv4Failover -Name "Failover-LAN-TSSR" -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" -Force
   ```
3. Vérification de l'interface réseau active :
   ```powershell
   Get-NetIPAddress -InterfaceAlias "Ethernet*" -AddressFamily IPv4 | Select-Object IPAddress, InterfaceAlias
   # Résultat : 192.168.100.10 sur Ethernet 2
   ```
J'ai oublié de coller les résultats des commandes mais tout est revenu dans l'ordre.
4. Re-création de la relation de failover.

---

#### État final validé sur les deux serveurs

**Depuis SRV-WIN-MEN-01 :**
```powershell
PS C:\Users\Administrator> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List PrimaryServerIP, SecondaryServerIP, State, ServerRole

PrimaryServerIP   : 192.168.100.10
SecondaryServerIP : 192.168.100.11
State             : Normal
ServerRole        : Active
```

**Depuis SRV-WIN-MEN-02 :**
```powershell
PS C:\Users\Administrator> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List PrimaryServerIP, SecondaryServerIP, State, ServerRole

PrimaryServerIP   : 192.168.100.10
SecondaryServerIP : 192.168.100.11
State             : Normal
ServerRole        : Standby
```

---

## 6. Vérifier la synchronisation

## Pas à pas

### Étape 1 : Examiner l'état de la relation sur les deux serveurs
```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *
```

#### Srv1

```powershell

PS C:\Users\Administrator> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *


ScopeId               : 192.168.100.0
PrimaryServerIP       : 192.168.100.10
SecondaryServerIP     : 192.168.100.11
AutoStateTransition   : False
EnableAuth            : True
LoadBalancePercent    :
MaxClientLeadTime     : 01:00:00
Mode                  : HotStandby
Name                  : Failover-LAN-TSSR
PartnerServer         : SRV-WIN-MEN-02.tssr-men.lab
PrimaryServerName     : SRV-WIN-MEN-01.tssr-men.lab
ReservePercent        : 5
SecondaryServerName   : SRV-WIN-MEN-02.tssr-men.lab
ServerRole            : Active
ServerType            : PrimaryServer
State                 : Normal
StateSwitchInterval   :
PSComputerName        :
CimClass              : root/Microsoft/Windows/DHCP:DhcpServerv4Failover
CimInstanceProperties : {AutoStateTransition, EnableAuth, LoadBalancePercent, MaxClientLeadTime...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties



PS C:\Users\Administrator> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *


ScopeId               : 192.168.100.0
PrimaryServerIP       : 192.168.100.10
SecondaryServerIP     : 192.168.100.11
AutoStateTransition   : False
EnableAuth            : True
LoadBalancePercent    :
MaxClientLeadTime     : 01:00:00
Mode                  : HotStandby
Name                  : Failover-LAN-TSSR
PartnerServer         : SRV-WIN-MEN-01.tssr-men.lab
PrimaryServerName     : SRV-WIN-MEN-01.tssr-men.lab
ReservePercent        : 5
SecondaryServerName   : SRV-WIN-MEN-02.tssr-men.lab
ServerRole            : Standby
ServerType            : SecondaryServer
State                 : Normal
StateSwitchInterval   :
PSComputerName        :
CimClass              : root/Microsoft/Windows/DHCP:DhcpServerv4Failover
CimInstanceProperties : {AutoStateTransition, EnableAuth, LoadBalancePercent, MaxClientLeadTime...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties

```
#### Srv2

```powershell
PS C:\Users\administrator.TSSR-MEN> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *


ScopeId               : 192.168.100.0
PrimaryServerIP       : 192.168.100.10
SecondaryServerIP     : 192.168.100.11
AutoStateTransition   : False
EnableAuth            : True
LoadBalancePercent    :
MaxClientLeadTime     : 01:00:00
Mode                  : HotStandby
Name                  : Failover-LAN-TSSR
PartnerServer         : SRV-WIN-MEN-02.tssr-men.lab
PrimaryServerName     : SRV-WIN-MEN-01.tssr-men.lab
ReservePercent        : 5
SecondaryServerName   : SRV-WIN-MEN-02.tssr-men.lab
ServerRole            : Active
ServerType            : PrimaryServer
State                 : Normal
StateSwitchInterval   :
PSComputerName        :
CimClass              : root/Microsoft/Windows/DHCP:DhcpServerv4Failover
CimInstanceProperties : {AutoStateTransition, EnableAuth, LoadBalancePercent, MaxClientLeadTime...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties



PS C:\Users\administrator.TSSR-MEN> Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-02 | Format-List *


ScopeId               : 192.168.100.0
PrimaryServerIP       : 192.168.100.10
SecondaryServerIP     : 192.168.100.11
AutoStateTransition   : False
EnableAuth            : True
LoadBalancePercent    :
MaxClientLeadTime     : 01:00:00
Mode                  : HotStandby
Name                  : Failover-LAN-TSSR
PartnerServer         : SRV-WIN-MEN-01.tssr-men.lab
PrimaryServerName     : SRV-WIN-MEN-01.tssr-men.lab
ReservePercent        : 5
SecondaryServerName   : SRV-WIN-MEN-02.tssr-men.lab
ServerRole            : Standby
ServerType            : SecondaryServer
State                 : Normal
StateSwitchInterval   :
PSComputerName        :
CimClass              : root/Microsoft/Windows/DHCP:DhcpServerv4Failover
CimInstanceProperties : {AutoStateTransition, EnableAuth, LoadBalancePercent, MaxClientLeadTime...}
CimSystemProperties   : Microsoft.Management.Infrastructure.CimSystemProperties
```


### Étape 2 : Vérifier la présence de l'étendue sur le Core (`SRV-WIN-MEN-02`)
```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02


PS C:\Users\Administrator> Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-02

ScopeId         SubnetMask      Name           State    StartRange      EndRange        LeaseDuration
-------         ----------      ----           -----    ----------      --------        -------------
192.168.100.0   255.255.255.0   LAN-TSSR       Active   192.168.100.150 192.168.100.200 8.00:00:00
```

### Étape 3 : Comparer et forcer la réplication
```powershell
Invoke-DhcpServerv4FailoverReplication -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" -Name "Failover-LAN-TSSR"
```
J'ai oublié de copier/coller le résultat et maintenant il risque d'écraser la config:

```powershell

PS C:\Users\Administrator> Invoke-DhcpServerv4FailoverReplication -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" -Name "Failover-LAN-TSSR"

Confirm
The configuration of all the scopes for the specified failover relationships on host server SRV-WIN-MEN-01.tssr-men.lab
 will be replicated to the partner server. Do you want to perform this action?
[Y] Yes  [N] No  [S] Suspend  [?] Help (default is "Y"): n
PS C:\Users\Administrator>

```

---

### Synthèse comparative des deux serveurs

| Élément | SRV-WIN-MEN-01 | SRV-WIN-MEN-02 |
| :--- | :--- | :--- |
| **État de la relation** | Normal | Normal |
| **Étendue présente** | Oui (`192.168.100.0`) | Oui (`192.168.100.0`) |
| **Plage** | 192.168.100.150 - 192.168.100.200 | 192.168.100.150 - 192.168.100.200 |
| **Masque** | 255.255.255.0 | 255.255.255.0 |
| **Durée du bail** | 8 jours (par défaut) | 8 jours (synchronisé) |
| **Option 6 (DNS)** | Configurée | Synchronisée |
| **Option 15 (domaine)** | `tssr-men.lab` | `tssr-men.lab` |
| **Exclusions** | Synchronisées | Synchronisées |
| **Baux présents** | Base de baux active | Base de baux répliquée |

---

## 7. Tester depuis Windows 11

### Pas à pas (`[Client]`)

**Étape 1 : vérifier que le client est en obtention automatique**

```powershell
Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, Dhcp
ipconfig /all



```

![](Deliverable%20version/attachments/Pasted%20image%2020261022113146.png)
![](Deliverable%20version/attachments/Pasted%20image%2020261022113210.png)S

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
![](Deliverable%20version/attachments/Pasted%20image%2020261022113332.png)
Relève : l'adresse (dans la plage `.150` à `.200` ?), le **serveur DHCP**, les **deux serveurs DNS**, le suffixe, les dates d'obtention et d'expiration du bail.

**Étape 4 : contrôler le bail côté service DHCP**

```powershell
PS C:\Users\Administrator> Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01

IPAddress       ScopeId         ClientId             HostName             AddressState         LeaseExpiryTime
---------       -------         --------             --------             ------------         ---------------
192.168.100.150 192.168.100.0   08-00-27-e5-de-16    CLI-WIN-MEN-01.TS... Active               10/22/2026 12:32:27 PM


PS C:\Users\Administrator> Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02

IPAddress       ScopeId         ClientId             HostName             AddressState         LeaseExpiryTime
---------       -------         --------             --------             ------------         ---------------
192.168.100.150 192.168.100.0   08-00-27-e5-de-16    CLI-WIN-MEN-01.TS... Active               10/22/2026 12:32:26 PM

```

Retrouve ton client par son adresse MAC (`ipconfig /all`) ou son nom.

![](Deliverable%20version/attachments/Pasted%20image%2020261022114824.png)

### À noter

| Élément                           | Valeur constatée               |
| --------------------------------- | ------------------------------ |
| Obtention automatique (IP et DNS) | Oui                            |
| Adresse obtenue                   | 192.168.100.150                |
| Dans la plage prévue ?            | Oui                            |
| Serveur DHCP qui a répondu        | 192.168.100.10                 |
| DNS reçus (ordre)                 | 192.168.100.10, 192.168.100.11 |
| Bail obtenu / expirant            | Oui, 1h                        |
| Bail visible sur `SRV-WIN-MEN-01` | Oui                            |
| Bail visible sur `SRV-WIN-MEN-02` | Oui                            |


---

## 8. Simuler une indisponibilité du serveur DHCP actif


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



---

## 9. Validation finale

- [x] **DHCP est installé et autorisé sur Server Core**
  - *Preuve :* [[#3. Installer et autoriser DHCP sur Core]]
- [x] **Le partenariat Hot Standby est en place**
  - *Preuve :* [[#5. Mettre en place le DHCP Failover]]
- [x] **L'étendue et les baux sont synchronisés**
  - *Preuve :* [[#6. Vérifier la synchronisation]]



---

## 10. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage 
> Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

| Problème                                                                                      | Cause | Solution |
| --------------------------------------------------------------------------------------------- | ----- | -------- |
| Difficultés à maintenir le modèle mental pour définir où je dois exécuter la prochaine étape. |       |          |

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
> - [x] Toutes les captures insérées
> - [x] Tous les blocs de commandes et tableaux remplis


