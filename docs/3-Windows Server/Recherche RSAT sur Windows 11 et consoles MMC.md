
## 1. Installation des RSAT sur Windows 11

### A. Définition et rôle
Les **RSAT** (*Remote Server Administration Tools* ou Outils d'administration distante de serveur) permettent aux administrateurs réseau de gérer à distance les rôles et fonctionnalités de Windows Server depuis un poste de travail client sous Windows 11.

### B. Procédure d'installation

#### Méthode 1 : Via l'interface graphique (GUI)
1. Ouvrir les **Paramètres** (`Win + I`).
2. Naviguer dans **Système** > **Fonctionnalités facultatives** (ou **Applications** > **Fonctionnalités facultatives** selon la version de Windows 11).
3. Cliquer sur **Afficher les fonctionnalités** en face de *Ajouter une fonctionnalité facultative*.
4. Saisir `RSAT` dans la barre de recherche.
5. Sélectionner les modules souhaités (ex. : *RSAT : Outils Active Directory Domain Services et Lightweight Directory Services*) puis cliquer sur **Installer**.

#### Méthode 2 : Via PowerShell (en administrateur)
Pour afficher les outils RSAT disponibles :
```powershell
Get-WindowsCapability -Online | Where-Name -Like "Rsat*"
```

Pour installer tous les outils RSAT d'un coup :
```powershell
Get-WindowsCapability -Online | Where-Name -Like "Rsat*" | Add-WindowsCapability -Online
```

Pour installer uniquement l'outil d'administration Active Directory :
```powershell
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

---

## 2. Les consoles MMC (Microsoft Management Console)

### A. Qu'est-ce qu'une console MMC ?
La **MMC** (*Microsoft Management Console*) est un conteneur d'interface d'administration modulaire fourni par Microsoft. Elle ne fournit aucune fonction d'administration par elle-même, mais héberge des composants logiciels enfichables appelés **modules d'extension** (*snap-ins*).

### B. Fonctionnement et utilité
* **Centralisation :** permet de regrouper dans une seule fenêtre personnalisée plusieurs outils d'administration locaux ou distants.
* **Personnalisation :** possibilité de créer des consoles sur mesure (`.msc`) sauvegardables et distribuables aux équipes informatiques.
* **Mode auteur et utilisateur :** peut être configurée en mode restriction pour empêcher les utilisateurs non autorisés de modifier la structure de la console.

### C. Consoles MMC usuelles en administration système

| Nom de l'exécutable | Nom de la console | Usage principal |
| :--- | :--- | :--- |
| `mmc.exe` | Microsoft Management Console | Console vierge permettant de créer sa propre vue |
| `dsa.msc` | Utilisateurs et ordinateurs Active Directory | Gestion des objets AD (utilisateurs, groupes, UO) |
| `gpmc.msc` | Gestion des politiques de groupe | Création et application des GPO |
| `dnsmgmt.msc` | Gestionnaire DNS | Configuration des zones et enregistrements DNS |
| `compmgmt.msc` | Gestion de l'ordinateur | Regroupe la gestion des disques, services, événements locaux |
| `services.msc` | Services | Gestion du démarrage et de l'état des services Windows |
| `wf.msc` | Pare-feu Windows avec sécurité avancée | Configuration des règles d'entrée et de sortie du pare-feu |

---

## 3. Synthèse des usages

* **Interaction RSAT et MMC :** l'installation des RSAT sur un poste Windows 11 ajoute automatiquement les consoles MMC d'administration distante (telles que `dsa.msc` ou `gpmc.msc`) au système client.
* **Gain d'efficacité :** évite d'ouvrir une session RDP (*Remote Desktop*) sur le contrôleur de domaine pour effectuer des tâches d'administration quotidiennes.


# Microsoft Management Console


|Microsoft Management Console|   |
|---|---|
|[![](https://upload.wikimedia.org/wikipedia/en/f/fd/Microsoft_Management_Console_Icon.png?utm_source=en.wikipedia.org&utm_campaign=parser&utm_content=thumbnail_unscaled)](https://en.wikipedia.org/wiki/File:Microsoft_Management_Console_Icon.png)|   |
|[![](https://thumb.wikimedia.org/wikipedia/en/thumb/b/b7/Microsoft_Management_Console_-_Device_Manager.png/330px-Microsoft_Management_Console_-_Device_Manager.png?utm_source=en.wikipedia.org&utm_campaign=parser&utm_content=thumbnail)](https://en.wikipedia.org/wiki/File:Microsoft_Management_Console_-_Device_Manager.png)<br><br>Windows Management Console running in [Windows 11](https://en.wikipedia.org/wiki/Windows_11 "Windows 11"), with [Device Manager](https://en.wikipedia.org/wiki/Device_Manager "Device Manager") snap-in loaded|   |
|[Developer](https://en.wikipedia.org/wiki/Programmer "Programmer")|[Microsoft](https://en.wikipedia.org/wiki/Microsoft "Microsoft")|
|[Operating system](https://en.wikipedia.org/wiki/Operating_system "Operating system")|[Microsoft Windows](https://en.wikipedia.org/wiki/Microsoft_Windows "Microsoft Windows")|
|[Type](https://en.wikipedia.org/wiki/Software_categories#Categorization_approaches "Software categories")|System configuration application|
|[License](https://en.wikipedia.org/wiki/Software_license "Software license")|Proprietary|

**Microsoft Management Console** (**MMC**) is a component of [Microsoft Windows](https://en.wikipedia.org/wiki/Microsoft_Windows "Microsoft Windows") that provides system administrators and advanced users an interface for configuring and [monitoring](https://en.wikipedia.org/wiki/System_monitor "System monitor") the system. It was first introduced as an optional component of [Windows NT 4.0](https://en.wikipedia.org/wiki/Windows_NT_4.0 "Windows NT 4.0") via the [Option Pack](https://en.wikipedia.org/wiki/Windows_NT_4.0#Updates_and_service_packs "Windows NT 4.0") update in late 1997, which includes several features that were slated for release with [Windows 2000](https://en.wikipedia.org/wiki/Windows_2000 "Windows 2000").[[1]](https://en.wikipedia.org/wiki/Microsoft_Management_Console#cite_note-1) It later came shipped with Windows beginning with the aforementioned operating system, and has remained available in many other Windows versions since.