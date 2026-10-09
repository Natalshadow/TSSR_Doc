## 1. Sauvegarde et export des GPO

La sauvegarde d'une GPO permet de la restaurer en cas de mauvaise manipulation, ou de la réimporter dans un autre environnement.

### Via la console GPMC (graphique)

1. Ouvrir **Gestion des stratégies de groupe** (`gpmc.msc`)
2. Déployer le domaine > **Objets de stratégie de groupe**
3. Clic droit sur la GPO à sauvegarder > **Sauvegarder**
4. Choisir un dossier de destination et ajouter une description
5. Cliquer **Sauvegarder**

Pour sauvegarder toutes les GPO en une fois : clic droit sur **Objets de stratégie de groupe** > **Tout sauvegarder**

### Via PowerShell

```powershell
# Sauvegarder une GPO spécifique
Backup-GPO -Name "Nom de la GPO" -Path "C:\Backup\GPO"

# Sauvegarder toutes les GPO du domaine
Backup-GPO -All -Path "C:\Backup\GPO"
```

### Restauration

```powershell
# Restaurer depuis une sauvegarde
Restore-GPO -Name "Nom de la GPO" -Path "C:\Backup\GPO"
```

---

## 2. Rapport GPRESULT

`gpresult` génère un rapport des stratégies effectivement appliquées sur une machine et/ou un utilisateur — utile pour diagnostiquer pourquoi une GPO ne s'applique pas comme attendu.

### Commandes de base

```cmd
# Résumé des GPO appliquées (utilisateur + ordinateur)
gpresult /r

# Cibler uniquement l'ordinateur
gpresult /scope computer /r

# Cibler uniquement l'utilisateur
gpresult /scope user /r
```

### Rapport HTML détaillé

```cmd
# Générer un rapport HTML complet
gpresult /h C:\rapport-gpo.html

# Ouvrir directement dans le navigateur
gpresult /h C:\rapport-gpo.html && start C:\rapport-gpo.html
```

### Rapport pour un utilisateur ou une machine distante

```cmd
# GPO appliquées pour un utilisateur spécifique
gpresult /user TSSR-MEN\nomutilisateur /r

# GPO appliquées sur une machine distante
gpresult /s NomMachineDistante /r
```

### Via PowerShell

```powershell
# Rapport HTML via PowerShell
Get-GPResultantSetOfPolicy -ReportType Html -Path "C:\rapport-gpo.html"
```

### Lire le rapport

Les sections clés à vérifier dans le rapport :

|Section|Ce qu'elle indique|
|---|---|
|**GPO appliquées**|Liste des GPO effectivement actives|
|**GPO refusées**|GPO exclues par filtrage de sécurité ou WMI|
|**Raison du refus**|Pourquoi une GPO ne s'applique pas|

---

## 3. Exécution des GPO depuis le contrôleur de domaine

En production, il n'est pas toujours possible ou souhaitable de se rendre sur chaque poste pour forcer un `gpupdate`. **Invoke-GPUpdate** permet de déclencher la mise à jour à distance depuis le contrôleur de domaine.

### Prérequis

La règle de pare-feu **Gestion des tâches planifiées à distance** doit être activée sur la machine cible. Elle peut être déployée via GPO elle-même :

```
Configuration ordinateur > Paramètres Windows > Paramètres de sécurité > 
Pare-feu Windows avec fonctions avancées > Règles de trafic entrant >
Gestion des tâches planifiées à distance (RPC)
```

### Forcer la mise à jour sur une machine distante

```powershell
# Forcer gpupdate sur un poste distant
Invoke-GPUpdate -Computer "CLI-WIN-MEN-01" -Force

# Forcer uniquement les stratégies ordinateur
Invoke-GPUpdate -Computer "CLI-WIN-MEN-01" -Target "Computer" -Force

# Forcer uniquement les stratégies utilisateur
Invoke-GPUpdate -Computer "CLI-WIN-MEN-01" -Target "User" -Force
```

### Forcer sur toutes les machines d'une OU

```powershell
Get-ADComputer -Filter * -SearchBase "OU=Workstations,DC=TSSR-MEN,DC=LAB" |
ForEach-Object { Invoke-GPUpdate -Computer $_.Name -Force }
```

### Résumé des commandes clés

|Commande|Usage|
|---|---|
|`Backup-GPO`|Sauvegarder une ou toutes les GPO|
|`Restore-GPO`|Restaurer une GPO depuis une sauvegarde|
|`gpresult /r`|Résumé des GPO appliquées localement|
|`gpresult /h fichier.html`|Rapport HTML détaillé|
|`Invoke-GPUpdate`|Forcer l'application des GPO à distance|
|`gpupdate /force`|Forcer localement sur la machine courante|