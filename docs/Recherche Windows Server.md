Versions de Windows Server (Core / Expérience de bureau) 
Editions (Datacenter/Standard) 
Différents rôles/fonctionnalités que l'on peut installer


| Core                                        | Desktop                                                                                                                                                                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CLI only                                    | With desktop environment + GUI                                                                                                                                           |
|                                             | - Windows Server Standard<br>- Windows Server Standard avec expérience de bureau<br>- Windows Server Datacenter<br>- Windows Server Datacenter avec expérience de bureau |
| Less disk space required                    | More disk space required                                                                                                                                                 |
| CLI                                         | CLI or GUI                                                                                                                                                               |
| Some roles and features are missing         | All roles and features available                                                                                                                                         |
| Remote management possible via GUI or shell | Same as Core                                                                                                                                                             |
| Attack surface minimized                    | Full attack surface                                                                                                                                                      |
| Microsoft Management Console missing        | MMC installed                                                                                                                                                            |

## Comparatif des Éditions : Standard vs Datacenter

| Fonctionnalité / Critère              | Windows Server Standard                            | Windows Server Datacenter                                  |
| :------------------------------------ | :------------------------------------------------- | :--------------------------------------------------------- |
| **Cible principal**                   | Environnements physiques ou faiblement virtualisés | Datacenters et environnements hautement virtualisés        |
| **Droits de virtualisation**          | **2 machines virtuelles** (ou OSE) par licence     | **Machines virtuelles illimitées**                         |
| **Storage Spaces Direct (S2D)**       | Non supporté                                       | **Oui** (Cluster de stockage logiciel haute disponibilité) |
| **Storage Replica**                   | Limité (1 partenariat, 1 volume jusqu'à 2 To)      | **Illimité**                                               |
| **Shielded Virtual Machines**         | Non                                                | **Oui** (Protection et chiffrement des VMs contre l'hôte)  |
| **Réseau basé sur le logiciel (SDN)** | Non                                                | **Oui** (Software-Defined Networking / Contrôleur réseau)  |
| **Containers Windows**                | Illimités                                          | Illimités                                                  |
| **Containers Hyper-V**                | Limités à 2                                        | Illimités                                                  |
| **Mode d'installation**               | Core ou Expérience de bureau                       | Core ou Expérience de bureau                               |
| **Modèle de licence**                 | Basé sur les cœurs processeurs (Core-based)        | Basé sur les cœurs processeurs (Core-based)                |


## Tableau des rôles et fonctionnalités

| Rôle / Fonctionnalité | Supporté sur Server Core ? | Supporté sur Expérience de bureau ? | Remarques / Limitations sur Core |
| --- | --- | --- | --- |
| **Active Directory Domain Services (AD DS)** | Oui | Oui | Promotion du domaine exécutée via PowerShell (`Install-AdnsDomainController`). |
| **DHCP Server & DNS Server** | Oui | Oui | Administration distante effectuée via RSAT ou PowerShell. |
| **Hyper-V** | Oui | Oui | Mode recommandé sur Core pour réserver les ressources matérielles aux VMs. |
| **File and Storage Services** | Oui | Oui | SMB, NFS, Quotas et Déduplication entièrement gérés en ligne de commande. |
| **Web Server (IIS)** | Oui | Oui | Administration distante via PowerShell ou la console IIS Manager. |
| **Failover Clustering** | Oui | Oui | Idéal sur Core pour maintenir des clusters hautement disponibles. |
| **Windows Admin Center (WAC)** | Oui | Oui | Agent et service administrables à distance depuis une interface web. |
| **Remote Desktop Services (RDS / Session Host)** | Non (Sauf Licensing) | Oui | Incompatible : Le rôle d'hôte de session exige l'environnement graphique. |
| **Active Directory Federation Services (AD FS)** | Non | Oui | Exige des composants graphiques et d'authentification utilisateur. |
| **Fax Server / Print Server (Avancé)** | Limité | Oui | Les outils de gestion d'impression locaux nécessitent la console MMC. |
| **Outils de diagnostic graphique (DirectX / MMC)** | Non | Oui | Absent sur Core (`mmc.exe` et exécutables Win32 GUI indisponibles). |