

> [!abstract] Résumé 
> Mise en place d'un **failover DHCP en mode Hot Standby** entre deux serveurs Windows Server, dont un **Server Core** administré exclusivement en PowerShell. L'objectif : supprimer le point de défaillance unique de l'attribution d'adresses IPv4 d'un réseau de laboratoire, puis vérifier la synchronisation des étendues et des baux depuis un poste Windows 11.

> [!info] Nature du projet 
> Projet réalisé en environnement de laboratoire virtualisé, pas sur une infrastructure client.

## Compétences mobilisées

- Administration Windows Server en **PowerShell** (module `DhcpServer`, gestion à distance)
- Installation et autorisation d'un serveur DHCP dans **Active Directory**
- Configuration d'une relation **DHCP Failover** (Hot Standby, réserve d'adresses, secret partagé)
- Utilisation de **Windows Server Core** (sans interface graphique)
- **Diagnostic** d'un incident réseau lié à la liaison du failover à la mauvaise interface

## Contexte

Dans ce laboratoire, deux contrôleurs de domaine et deux serveurs DNS assuraient déjà la redondance de l'annuaire et de la résolution de noms. L'attribution des adresses IP dépendait en revanche d'un seul serveur DHCP : une panne de ce serveur empêchait les nouveaux clients d'obtenir une configuration réseau.

## Environnement

|Élément|Configuration|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur DHCP existant (actif)|`SRV-WIN-MEN-01`, `192.168.100.10`, contrôleur de domaine avec interface graphique|
|Serveur de secours|`SRV-WIN-MEN-02`, `192.168.100.11`, contrôleur de domaine **Server Core**|
|Client|`CLI-WIN-MEN-01`, Windows 11|
|Réseau|`192.168.100.0/24`, réseau virtuel isolé (VirtualBox)|
|Étendue|`LAN-TSSR`, `192.168.100.150` à `192.168.100.200`, masque `255.255.255.0`, bail de 8 jours|
|Options distribuées|Serveurs DNS `192.168.100.10` et `192.168.100.11`, domaine DNS `TSSR-MEN.LAB`|

```text
          Clients DHCP (Windows 11)
                    │
       ┌────────────┴────────────┐
SRV-WIN-MEN-01 (actif)    SRV-WIN-MEN-02 (secours, Server Core)
192.168.100.10   ◄── TCP 647 ──►   192.168.100.11
DC + DNS + DHCP                    DC + DNS + DHCP
```

## Principe : Load Balance ou Hot Standby

Le DHCP Failover (disponible depuis Windows Server 2012) fait partager aux deux serveurs **la même étendue et la même base de baux**. Ils communiquent en continu (TCP 647) et remplacent l'ancienne méthode du partage 80/20 de l'étendue, où les serveurs s'ignoraient.

|Critère|Load Balance|Hot Standby|
|---|---|---|
|Qui répond en fonctionnement normal|Les deux serveurs (50/50 par défaut)|Le serveur actif uniquement|
|Réserve d'adresses|Non|Oui, un pourcentage de la plage est réservé au serveur de secours|
|Cas d'usage typique|Fort trafic sur un même site|Site principal avec serveur de secours|

**Choix retenu : Hot Standby.** `SRV-WIN-MEN-01` reste le serveur de production et `SRV-WIN-MEN-02` n'intervient qu'en cas de défaillance : il n'y a pas de besoin de répartition de charge.

Les états d'une relation de failover :

|État|Signification|Comportement du serveur de secours|
|---|---|---|
|Normal|Les serveurs communiquent|Synchronise la base de baux, ne répond pas aux clients|
|Communication Interrupted|Le partenaire ne répond plus, sans être déclaré hors service|Renouvelle les baux existants et utilise sa réserve pour les nouveaux clients|
|Partner Down|Le partenaire est déclaré hors service|Prend en charge toute l'étendue avec des baux limités par le MCLT|

## Mise en œuvre

### 1. Installer et autoriser DHCP sur Server Core

Installation du rôle et des outils d'administration :

```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
```

```text
Success Restart Needed Exit Code      Feature Result
------- -------------- ---------      --------------
True    No             Success        {DHCP Server}
```

Création des groupes de sécurité DHCP, puis redémarrage du service pour les prendre en compte :

```powershell
Add-DhcpServerSecurityGroup
Restart-Service -Name DHCPServer
```

Vérification du rôle et du service :

```text
Display Name                  Name      Install State
------------                  ----      -------------
[X] DHCP Server               DHCP      Installed

Status   Name               DisplayName
------   ----               -----------
Running  DHCPServer         DHCP Server
```

Un serveur DHCP membre d'un domaine **ne distribue aucune adresse tant qu'il n'est pas autorisé dans Active Directory** : c'est une protection contre les serveurs DHCP pirates. Autorisation du Core :

```powershell
Add-DhcpServerInDC -DnsName SRV-WIN-MEN-02.tssr-men.lab -IPAddress 192.168.100.11
Get-DhcpServerInDC
```

```text
IPAddress            DnsName
---------            -------
192.168.100.10       srv-win-men-01.tssr-men.lab
192.168.100.11       srv-win-men-02
192.168.100.11       srv-win-men-02.tssr-men.lab
```

Le Core apparaît sous son nom court et sous son nom complet, les deux formes de la commande ayant été testées.

### 2. Relever l'état de départ de l'étendue

Avant d'ajouter le partenaire, relevé de l'étendue existante, de ses options et d'un bail actif :

```powershell
Get-DhcpServerv4Scope -ComputerName SRV-WIN-MEN-01
```

```text
ScopeId         SubnetMask      Name           State    StartRange      EndRange        LeaseDuration
-------         ----------      ----           -----    ----------      --------        -------------
192.168.100.0   255.255.255.0   LAN-TSSR       Active   192.168.100.150 192.168.100.200 8.00:00:00
```

```powershell
(Get-DhcpServerv4OptionValue -ScopeId 192.168.100.0 -OptionId 6 -ComputerName SRV-WIN-MEN-01).Value
```

```text
192.168.100.10
192.168.100.11
```

L'option 6 distribue bien les deux serveurs DNS et l'option 15 le domaine `TSSR-MEN.LAB`. Sur le Core, `Get-DhcpServerv4Scope` ne renvoie aucun résultat : l'étendue n'existe pas encore sur ce serveur.

### 3. Créer la relation de failover

Les paramètres de la commande `Add-DhcpServerv4Failover` déterminent le mode : avec `-ServerRole` et `-ReservePercent`, la relation est de type Hot Standby.

|Besoin|Paramètre|
|---|---|
|Nom de la relation|`-Name`|
|Serveur actif (sur lequel on lance la commande)|`-ComputerName`|
|Partenaire de secours|`-PartnerServer`|
|Étendue|`-ScopeId`|
|Rôle du serveur actif|`-ServerRole`|
|Réserve d'adresses du partenaire|`-ReservePercent`|
|Authentification entre les serveurs|`-SharedSecret`|

```powershell
Add-DhcpServerv4Failover `
  -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" `
  -PartnerServer "SRV-WIN-MEN-02.tssr-men.lab" `
  -Name "Failover-LAN-TSSR" `
  -ScopeId 192.168.100.0 `
  -ServerRole Active `
  -ReservePercent 5 `
  -SharedSecret "***"
```

Le secret partagé authentifie les échanges entre les deux serveurs. La valeur utilisée dans le laboratoire n'est volontairement pas publiée ; en production, elle serait stockée dans un coffre de secrets.

### 4. Incident : la relation est liée à la mauvaise interface

Le contrôle détaillé de la relation a révélé une anomalie sur l'adresse du serveur principal :

```powershell
Get-DhcpServerv4Failover -ComputerName SRV-WIN-MEN-01 | Format-List *
```

```text
PrimaryServerIP   : 10.0.3.15
SecondaryServerIP : 192.168.100.11
```

**Diagnostic.** Une carte réseau temporaire en NAT (VirtualBox), ajoutée à `SRV-WIN-MEN-01` pour installer des outils, était restée active. Le failover s'était lié à l'adresse de cette interface (`10.0.3.15`) au lieu de l'adresse du réseau local (`192.168.100.10`), ce qui rendait la relation inutilisable pour le LAN.

**Correction.**

1. Suppression de la carte NAT de la machine virtuelle.
    
2. Suppression de la relation erronée :
    
    ```powershell
    Remove-DhcpServerv4Failover -Name "Failover-LAN-TSSR" -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" -Force
    ```
    
3. Vérification de l'interface active :
    
    ```powershell
    Get-NetIPAddress -InterfaceAlias "Ethernet*" -AddressFamily IPv4 | Select-Object IPAddress, InterfaceAlias
    ```
    
    Résultat : `192.168.100.10`.
    
4. Recréation de la relation avec la même commande.
    

**Enseignement :** sur un serveur à plusieurs interfaces, vérifier l'adresse retenue par un service avant de valider sa configuration, et retirer les interfaces temporaires une fois leur usage terminé.

### 5. Résultat : relation opérationnelle sur les deux serveurs

Depuis `SRV-WIN-MEN-01` :

```text
PrimaryServerIP   : 192.168.100.10
SecondaryServerIP : 192.168.100.11
State             : Normal
ServerRole        : Active
```

Depuis `SRV-WIN-MEN-02` :

```text
PrimaryServerIP   : 192.168.100.10
SecondaryServerIP : 192.168.100.11
State             : Normal
ServerRole        : Standby
```

Les deux serveurs identifient leur partenaire et la relation est à l'état **Normal**. La réplication de la configuration peut aussi être forcée :

```powershell
Invoke-DhcpServerv4FailoverReplication -ComputerName "SRV-WIN-MEN-01.tssr-men.lab" -Name "Failover-LAN-TSSR"
```

### 6. Vérification depuis le client Windows 11

Le client est configuré en obtention automatique de l'adresse IP et des DNS. Après libération et renouvellement du bail (`ipconfig /release; ipconfig /renew`) :

|Vérification|Résultat|
|---|---|
|Adresse obtenue|`192.168.100.150`, dans la plage `.150` à `.200`|
|Serveur DHCP qui a répondu|`192.168.100.10` (serveur actif)|
|DNS reçus|`192.168.100.10` puis `192.168.100.11`|

Client Windows 11 en obtention automatique Configuration IP du client Sortie de ipconfig /all après renouvellement du bail

Le bail du client est présent **sur les deux serveurs**, ce qui confirme la synchronisation de la base de baux :

```powershell
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-01
Get-DhcpServerv4Lease -ScopeId 192.168.100.0 -ComputerName SRV-WIN-MEN-02
```

```text
IPAddress       ScopeId         ClientId             HostName             AddressState         LeaseExpiryTime
---------       -------         --------             --------             ------------         ---------------
192.168.100.150 192.168.100.0   08-00-27-e5-de-16    CLI-WIN-MEN-01.TS... Active               10/22/2026 12:32:27 PM

IPAddress       ScopeId         ClientId             HostName             AddressState         LeaseExpiryTime
---------       -------         --------             --------             ------------         ---------------
192.168.100.150 192.168.100.0   08-00-27-e5-de-16    CLI-WIN-MEN-01.TS... Active               10/22/2026 12:32:26 PM
```

Baux DHCP visibles côté serveurs

Le premier bail accordé après la mise en place de la relation expire environ une heure plus tard, alors que l'étendue est configurée pour 8 jours. C'est cohérent avec le **MCLT** (Maximum Client Lead Time, 1 h par défaut) : tant que le partenaire n'a pas confirmé un bail, le serveur n'accorde qu'une durée limitée, ce qui évite les conflits d'adresses en cas de reprise par le serveur de secours.

<!-- TODO : ajouter ici la section « Test de bascule » (arrêt du service DHCP sur SRV-WIN-MEN-01, états de la relation, bail obtenu auprès du Core, retour à la normale) une fois le test réalisé et ses résultats relevés. -->

## Ce que ce laboratoire démontre

- Installer, autoriser et superviser un serveur DHCP sur **Windows Server Core**, entièrement en ligne de commande.
- Mettre en place un **failover Hot Standby** avec réserve d'adresses et authentification entre partenaires.
- **Diagnostiquer** une relation mal liée (mauvaise interface) à partir de la sortie détaillée d'une commande, la corriger et la revalider.
- Vérifier une configuration par plusieurs angles : état de la relation sur chaque serveur, présence de l'étendue et des baux côté secours, comportement réel côté client.

## Limites de ce laboratoire

- Environnement virtuel isolé, une seule étendue, un seul client : pas de charge réelle.
- Le secret partagé du laboratoire n'est pas géré comme il le serait en production.
- Le comportement en cas de panne du serveur actif n'est pas couvert par cette page.