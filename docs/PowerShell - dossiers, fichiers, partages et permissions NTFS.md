
> [!abstract] Consigne du formateur 
> Pour ceux qui ont fini, en attendant la correction : rechercher et manipuler les commandes PowerShell sur la gestion des dossiers, des fichiers, et du partage / des permissions NTFS.

> [!info] Version rapide 
> Le tableau donne les cmdlets de départ. Ton travail : **les lancer dans le bac à sable ci-dessous** et noter ce que tu observes. Tout se passe dans un dossier jetable, rien d'autre n'est touché.

> [!tip] Méthode de recherche 
> Tu n'as pas besoin de connaître les commandes par cœur : il suffit de savoir **où chercher**. Dans PowerShell, les commandes suivent le schéma Verbe-Nom. Pour un sujet, cherche par le nom :
> 
> ```powershell
> Get-Command -Noun Item*, Content, Acl
> Get-Command -Module SmbShare
> Get-Help <commande> -Examples
> ```

---

## 1. Bac à sable

Crée un dossier jetable (sur n'importe quelle machine) :

```powershell
$base = "C:\Temp\TP-Sandbox"
New-Item -ItemType Directory -Path "$base\RH", "$base\Compta" -Force
```

---

## 2. Dossiers et fichiers

|Tâche|Commande de départ|Testée|Observation|
|---|---|---|---|
|Créer un dossier / un fichier|`New-Item`|||
|Lister le contenu (récursif)|`Get-ChildItem -Recurse`|||
|Copier|`Copy-Item`|||
|Déplacer|`Move-Item`|||
|Renommer|`Rename-Item`|||
|Lire un fichier|`Get-Content`|||
|Écrire / ajouter dans un fichier|`Set-Content`, `Add-Content`|||
|Vérifier qu'un chemin existe|`Test-Path`|||
|Supprimer|`Remove-Item`|||

**À essayer :**

```powershell
New-Item -ItemType File -Path "$base\RH\note.txt" -Value "premier test"
Get-ChildItem $base -Recurse
Copy-Item "$base\RH\note.txt" "$base\Compta\"
Rename-Item "$base\Compta\note.txt" "copie.txt"
Add-Content "$base\Compta\copie.txt" "une ligne de plus"
Get-Content "$base\Compta\copie.txt"
Test-Path "$base\Compta\copie.txt"
```

**Commentaires :**

---

## 3. Permissions NTFS

> [!question] Rappel 
> Les permissions **NTFS** s'appliquent au dossier lui-même, sur le disque. Les permissions de **partage** s'appliquent seulement quand on y accède par le réseau. Un utilisateur obtient au final **le plus restrictif des deux**.

|Tâche|Commande de départ|Testée|Observation|
|---|---|---|---|
|Lire les permissions d'un dossier|`Get-Acl`|||
|Créer une règle d'accès|`FileSystemAccessRule` (objet .NET)|||
|Appliquer les permissions|`Set-Acl`|||
|Alternative en ligne de commande|`icacls`|||

**À essayer :**

```powershell
Get-Acl "$base\RH" | Format-List

$acl  = Get-Acl "$base\RH"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("TSSR-MEN\GG-RH", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl "$base\RH" $acl

Get-Acl "$base\RH" | Format-List
icacls "$base\RH"
```

Remplace `TSSR-MEN\GG-RH` par un groupe ou un compte qui existe sur ta machine (sur un poste hors domaine, un groupe local comme `Users`).

**À répondre :** que signifient `Modify`, `ContainerInherit` et `ObjectInherit` ? Que se passe-t-il si on retire l'héritage ?

---

## 4. Partages (SMB)

|Tâche|Commande de départ|Testée|Observation|
|---|---|---|---|
|Lister les partages|`Get-SmbShare`|||
|Créer un partage|`New-SmbShare`|||
|Voir les droits du partage|`Get-SmbShareAccess`|||
|Donner / retirer un droit|`Grant-SmbShareAccess`, `Revoke-SmbShareAccess`|||
|Supprimer un partage|`Remove-SmbShare`|||

**À essayer** (en administrateur) :

```powershell
New-SmbShare -Name "Sandbox" -Path $base -ChangeAccess "TSSR-MEN\Domain Users"
Get-SmbShare -Name "Sandbox"
Get-SmbShareAccess -Name "Sandbox"
```

**Commentaires :**

---

## 5. Nettoyage

```powershell
Remove-SmbShare -Name "Sandbox" -Force
Remove-Item -Path $base -Recurse -Force
```

---

