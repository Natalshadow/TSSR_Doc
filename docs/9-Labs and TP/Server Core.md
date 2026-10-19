
> [!abstract] Consigne Recherches en autonomie :
> 
> - prérequis / configuration minimale pour installer Windows Server Core
> - intérêt d'installer un Server Core
> - recherches sur l'administration d'un serveur Windows via PowerShell
> - syntaxe des commandes PowerShell

> [!info] Comment utiliser ce document
> 
> - Rédige **avec tes mots** : ce document doit montrer que tu as compris, pas que tu as copié.
> - Pour chaque information importante, note la **source** (voir le tableau en bas de la section Méthode) et la **version de Windows Server** concernée : les chiffres et les fonctionnalités changent d'une version à l'autre.
> - Les blocs `> [!tip]` sont des pistes de recherche : à supprimer dans la version rendue.
> - Les commandes proposées sont en lecture seule : elles ne modifient rien.

---

## Sommaire

- [[#Méthode de recherche]]
- [[#1. Prérequis et configuration minimale de Windows Server Core]]
- [[#2. Intérêt d'installer un Server Core]]
- [[#3. Administration d'un serveur Windows via PowerShell]]
- [[#4. Syntaxe des commandes PowerShell]]
- [[#5. Synthèse]]

---

## Méthode de recherche

> [!tip] Guidage
> 
> - Commence par la **documentation officielle de Microsoft** (Microsoft Learn), puis complète avec des sources techniques reconnues. Méfie-toi des pages non datées et des vidéos qui ne citent pas de version.
> - Note la **version de Windows Server** qui sert de référence à ta recherche (celle du labo, par exemple), et signale quand une source parle d'une autre version.
> - Distingue ce qui est un **fait** (documenté) de ce qui est un **avis** (retour d'expérience).
> - Les VM du labo n'ont pas d'accès Internet : fais tes recherches sur l'ordinateur hôte, et teste les commandes dans la VM.

**Version de Windows Server de référence :**

**Sources consultées**

|N°|Titre|URL|Date de consultation|Fiabilité (officielle / tierce)|
|---|---|---|---|---|
|1|||||
|2|||||
|3|||||
|4|||||

---

## 1. Prérequis et configuration minimale de Windows Server Core

> [!question] Questions à traiter
> 
> - Qu'est-ce qu'une installation **Server Core** ? En quoi diffère-t-elle d'une installation avec **Desktop Experience** (l'interface graphique complète) ?
> - Quels sont les **prérequis matériels** minimaux : processeur (architecture, fréquence, fonctions exigées), mémoire, espace disque, réseau ?
> - Y a-t-il des exigences de **firmware** ou de sécurité (UEFI, Secure Boot, TPM) selon la version ?
> - Quelle est la différence entre la configuration **minimale** et la configuration **recommandée** ?
> - Que change le choix de l'**édition** (Standard, Datacenter) et de la **licence** (évaluation incluse) ?
> - Y a-t-il des contraintes si on installe dans une **machine virtuelle** (génération, mémoire dynamique) ?

> [!tip] Guidage Cherche la page « configuration requise » de la version choisie sur Microsoft Learn. Vérifie si les valeurs sont **différentes** entre Server Core et Desktop Experience : c'est une information utile pour la section 2.

**Tableau à compléter**

| **Composant**     | **Exigence minimale**                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------------------------- |
| **Processeur**    | 1,4 GHz, 64-bit (compatible jeux d'instructions x64, NX, DEP, CMPXCHG16b, LAHF/SAHF, PrefetchW)       |
| **Mémoire RAM**   | 512 Mo (3,2 Go minimum recommandé si virtualisé pour éviter les échecs de démarrage/installation)     |
| **Espace disque** | 32 Go (Server Core nécessite environ 4 à 6 Go d'espace disque disponible de moins que la version GUI) |
| **Réseau**        | Adaptateur Ethernet gigabit (10/100/1000 Base-T)                                                      |
| **Firmware**      | Système UEFI 2.3.1c avec Secure Boot                                                                  |



**Au choix de l'installation :** à quel moment de l'assistant choisit-on entre Core et Desktop Experience, et que se passe-t-il si on ne change rien ?

**Synthèse de la section 1 (avec tes mots)**

---

## 2. Intérêt d'installer un Server Core

> [!question] Questions à traiter
> 
> - Quels sont les **avantages** annoncés (sécurité, ressources, mises à jour, stabilité) et sur quoi reposent-ils ? Pourquoi une installation sans interface est-elle plus difficile à attaquer ?
> - Quels sont les **inconvénients** et limites (administration plus technique, dépannage, logiciels incompatibles) ?
> - Dans quels **cas d'usage** Server Core est-il adapté ? Dans lesquels est-il déconseillé ?
> - Quelles **interfaces** reste-t-il sur un Server Core (invite de commandes, PowerShell, un outil de configuration en mode texte) ?



Le choix de déployer la déclinaison **Server Core** (sans interface graphique utilisateur) repose sur quatre piliers majeurs :

- **Surface d'attaque réduite :** Moins de code, pas d'interface graphique, de navigateur ou d'outils d'administration visuels installés. Cela diminue drastiquement le nombre de vulnérabilités potentielles exploitables par un attaquant.
    
- **Maintenance et redémarrages réduits :** La majorité des correctifs Windows (Windows Updates) concernent les composants graphiques ou les dépendances associées (comme Shell, Internet Explorer/Edge libraries). Un serveur Core nécessite jusqu'à 50 à 60 % de redémarrages en moins par an.
    
- **Empreinte mémoire et disque minimale :** Libère des ressources système considérables pour les rôles serveur (Active Directory, DNS, Hyper-V). La mémoire RAM consommée au démarrage est généralement inférieure à 1 Go contre 2,5 Go à 3 Go pour une version GUI.
    
- **Standardisation et automatisation :** Force les équipes système à adopter l'administration à distance, l'automatisation via des scripts et la gestion centralisée.

---

## 3. Administration d'un serveur Windows via PowerShell

> [!question] Questions à traiter
> 
> - Comment s'administre un serveur **en local** quand il n'a pas d'interface graphique ?
> - Comment s'administre-t-il **à distance** avec PowerShell ? Que sont le **remoting**, WinRM, une **session** ?
> - Quels **outils graphiques à distance** existent (Server Manager, RSAT, Windows Admin Center) et dans quels cas les préférer à PowerShell ?
> - Quels **modules** PowerShell servent à administrer les rôles que tu as installés ?
> - Quels sont les **prérequis** pour qu'une administration à distance fonctionne (activation, pare-feu, authentification, droits) ?

> [!tip] Guidage Quelques pistes de mots-clés à chercher :
> 
> - en local : l'outil de configuration en mode texte de Server Core (`sconfig`), `Rename-Computer`, `Add-Computer`, `Install-WindowsFeature`
> - à distance : `Enter-PSSession`, `Invoke-Command`, `New-PSSession`, `Enable-PSRemoting`
> - modules : `ActiveDirectory`, `DhcpServer`, `DnsServer`, `GroupPolicy`, `SmbShare` Pour un module, la découverte se fait avec `Get-Module -ListAvailable` puis `Get-Command -Module <nom>`.

### 3.1 Administration en local

### 3.2 Administration à distance avec PowerShell

**Prérequis constatés :**

**Schéma d'une session distante** (qui se connecte à qui, avec quels droits, sur quel port) :

### 3.3 Outils graphiques à distance

|Outil|À quoi il sert|Avantages|Limites|
|---|---|---|---|
|Server Manager||||
|RSAT||||
|Windows Admin Center||||

### 3.4 Tâches courantes en PowerShell

Complète avec les cmdlets que **tu as trouvées** et ce que tu as vérifié. Pour chaque ligne, cherche d'abord la commande avec `Get-Command`, puis lis son aide avec `Get-Help <commande> -Examples`.

|Tâche|Cmdlet(s) trouvée(s)|Testée ?|Résultat observé|
|---|---|---|---|
|Voir l'adresse IP et la configuration réseau||||
|Lister les services et leur état||||
|Lister les rôles et fonctionnalités installés||||
|Lister les zones DNS||||
|Lister les baux DHCP||||
|Lister les utilisateurs d'une OU||||
|Lister les partages||||
|Produire un rapport sur les GPO||||

> [!tip] Guidage Les tâches des lignes DNS, DHCP, utilisateurs et GPO reprennent ce que tu as fait **à la souris** dans les TP : refais-les en PowerShell sur ton labo en **lecture seule** (listes et rapports). Compare : combien de clics contre combien de caractères ?

### 3.5 Sécurité et bonnes pratiques

> [!tip] Guidage Cherche : la **politique d'exécution** des scripts (`ExecutionPolicy`), les droits nécessaires pour une session distante, la **journalisation** des commandes PowerShell, et pourquoi un administrateur évite de travailler en permanence avec un compte très privilégié.

**Synthèse de la section 3 (avec tes mots)**

---

## 4. Syntaxe des commandes PowerShell

> [!question] Questions à traiter
> 
> - Quelle est la structure d'une commande **Verbe-Nom** ? Où trouve-t-on la liste des verbes approuvés ?
> - Que sont les **paramètres** (nommés, positionnels) et les **switchs** ? Comment passer plusieurs valeurs ?
> - Qu'est-ce que le **pipeline**, et en quoi diffère-t-il de celui d'un shell qui transmet du texte ?
> - Comment **filtrer**, **sélectionner**, **trier** et **mettre en forme** une sortie ?
> - Quels sont les **opérateurs de comparaison** (`-eq`, `-like`, `-match`…) et pourquoi `==` et `>` ne servent pas à comparer ?
> - Comment fonctionnent les **variables**, les **tableaux** et les **tables de hachage** ?
> - À quoi servent les **alias** et la **complétion** avec la touche Tab ?
> - Comment **tester** une commande sans l'exécuter ? (`-WhatIf`, `-Confirm`)
> - Comment **trouver de l'aide** : `Get-Help`, `Get-Command`, `Get-Member`, `Update-Help` ?

> [!tip] Guidage
> 
> - Si tu connais déjà un autre shell (par exemple Bash), fais un tableau de **correspondances et de différences** : c'est la meilleure façon de fixer les idées.
> - `Update-Help` a besoin d'Internet : à lancer sur l'ordinateur hôte, pas dans les VM du labo.
> - PowerShell travaille avec des **objets** : une commande ne renvoie pas du texte mais des objets avec des propriétés. `Get-Member` te montre lesquelles.

### Syntaxe générale des commandes


```powershell
Verb-Noun -Parametre1 Valeur1 -Parametre2 Valeur2 [-Interrupteur]
```
### 4.1 Tableau de syntaxe

|Élément|Syntaxe générale|Exemple testé|Remarque|
|---|---|---|---|
|Commande Verbe-Nom||||
|Paramètre nommé||||
|Switch||||
|Pipeline||||
|Filtrer||||
|Sélectionner des propriétés||||
|Trier||||
|Comparaison||||
|Variable||||
|Alias||||
|Simulation (`-WhatIf`)||||
|Aide||||

### 4.2 Exercices (lecture seule)

Lance ces commandes dans PowerShell, observe, puis complète la colonne « Ce que j'ai compris ».

```powershell
Get-Verb
Get-Command *service*
Get-Help Get-Service -Examples
Get-Service | Get-Member
Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 5 Name, Status
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU
Get-Alias gci
```

|Commande|Ce que j'ai compris|
|---|---|
|`Get-Verb`||
|`Get-Command *service*`||
|`Get-Help Get-Service -Examples`||
|`Get-Service \| Get-Member`||
|`Get-Service \| Where-Object ...`||
|`Get-Process \| Sort-Object ...`||
|`Get-Alias gci`||

**Capture(s)**

![[capture-4-exercices.png]]

### 4.3 Comparaison avec un autre shell (optionnel)

|Besoin|PowerShell|Autre shell|Différence|
|---|---|---|---|
|Lister les fichiers||||
|Filtrer une sortie||||
|Enchaîner des commandes||||
|Texte ou objets ?||||

**Synthèse de la section 4 (avec tes mots)**

---

## 5. Synthèse

### Ce que j'ai retenu

### Ce que je n'ai pas compris ou que je veux approfondir

### Termes à ajouter au glossaire

- [ ] Server Core / Desktop Experience
- [ ] cmdlet
- [ ] pipeline
- [ ] module
- [ ] PowerShell Remoting / WinRM
- [ ] RSAT
- [ ] ExecutionPolicy

---

> [!note] Rendu
> 
> - [ ] Version de Windows Server de référence indiquée
> - [ ] Toutes les sources notées (titre, URL, date)
> - [ ] Tableaux remplis avec mes mots
> - [ ] Exercices exécutés et captures insérées
> - [ ] Tous les blocs `[!tip]` supprimés
> - [ ] Export PDF réalisé (si demandé)