
> [!abstract] Consigne du formateur 
> Pour ceux qui ont fini, en attendant la correction : rechercher et manipuler les commandes PowerShell sur la gestion des dossiers, des fichiers, et du partage / des permissions NTFS.



> [!tip] Méthode de recherche 
> Pas besoin de connaître les commandes par cœur : il suffit de savoir **où chercher**. Dans PowerShell, les commandes suivent le schéma Verbe-Nom. Pour un sujet, cherche par le nom :
> 
> ```powershell
> Get-Command -Noun Item*, Content, Acl
> Get-Command -Module SmbShare
> Get-Help <commande> -Examples
> ```

---

## 1. Bac à sable

Créer un dossier jetable (sur n'importe quelle machine) :

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
PS C:\Users\administrator.TSSR-MEN> Copy-Item "$base\RH\note.txt" "$base\Compta\"
PS C:\Users\administrator.TSSR-MEN> Rename-Item "$base\Compta\note.txt" "copie.txt"
PS C:\Users\administrator.TSSR-MEN> Add-Content "$base\Compta\copie.txt" "une ligne de plus"
PS C:\Users\administrator.TSSR-MEN> Get-Content "$base\Compta\copie.txt"
premier testune ligne de plus
PS C:\Users\administrator.TSSR-MEN> Test-Path "$base\Compta\copie.txt"
True
PS C:\Users\administrator.TSSR-MEN> cd C:\Temp\TP-Sandbox
PS C:\Temp\TP-Sandbox> ls


    Directory: C:\Temp\TP-Sandbox


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        10/22/2026   7:03 AM                Compta
d-----        10/22/2026   7:03 AM                RH


PS C:\Temp\TP-Sandbox> cd RH
PS C:\Temp\TP-Sandbox\RH> ls


    Directory: C:\Temp\TP-Sandbox\RH


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/22/2026   7:03 AM             12 note.txt


PS C:\Temp\TP-Sandbox\RH> cd ..
PS C:\Temp\TP-Sandbox> cd Compta
PS C:\Temp\TP-Sandbox\Compta> ls


    Directory: C:\Temp\TP-Sandbox\Compta


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/22/2026   7:03 AM             31 copie.txt
```



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
PS C:\Temp\TP-Sandbox\Compta> Get-Acl "$base\RH" | Format-List


Path   : Microsoft.PowerShell.Core\FileSystem::C:\Temp\TP-Sandbox\RH
Owner  : BUILTIN\Administrators
Group  : TSSR-MEN\Domain Users
Access : NT AUTHORITY\SYSTEM Allow  FullControl
         BUILTIN\Administrators Allow  FullControl
         BUILTIN\Users Allow  ReadAndExecute, Synchronize
         BUILTIN\Users Allow  AppendData
         BUILTIN\Users Allow  CreateFiles
         CREATOR OWNER Allow  268435456
Audit  :
Sddl   : O:BAG:DUD:AI(A;OICIID;FA;;;SY)(A;OICIID;FA;;;BA)(A;OICIID;0x1200a9;;;BU)(A;CIID;LC;;;BU)(A;CIID;DC;;;BU)(A;OICIIOID;GA;;;CO)



PS C:\Temp\TP-Sandbox\Compta>
PS C:\Temp\TP-Sandbox\Compta> $acl  = Get-Acl "$base\RH"
PS C:\Temp\TP-Sandbox\Compta> $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("TSSR-MEN\GG-RH", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
PS C:\Temp\TP-Sandbox\Compta> $acl.SetAccessRule($rule)
PS C:\Temp\TP-Sandbox\Compta> Set-Acl "$base\RH" $acl
PS C:\Temp\TP-Sandbox\Compta>
PS C:\Temp\TP-Sandbox\Compta> Get-Acl "$base\RH" | Format-List


Path   : Microsoft.PowerShell.Core\FileSystem::C:\Temp\TP-Sandbox\RH
Owner  : BUILTIN\Administrators
Group  : TSSR-MEN\Domain Users
Access : TSSR-MEN\GG-RH Allow  Modify, Synchronize
         NT AUTHORITY\SYSTEM Allow  FullControl
         BUILTIN\Administrators Allow  FullControl
         BUILTIN\Users Allow  ReadAndExecute, Synchronize
         BUILTIN\Users Allow  AppendData
         BUILTIN\Users Allow  CreateFiles
         CREATOR OWNER Allow  268435456
Audit  :
Sddl   : O:BAG:DUD:AI(A;OICI;0x1301bf;;;S-1-5-21-3751794092-3013587998-2465217153-1117)(A;OICIID;FA;;;SY)(A;OICIID;FA;;;BA)(A;OICIID;0x1200a9;;;BU)(A;CIID;LC;;;BU)(A;CI
         ID;DC;;;BU)(A;OICIIOID;GA;;;CO)



PS C:\Temp\TP-Sandbox\Compta> icacls "$base\RH"
C:\Temp\TP-Sandbox\RH TSSR-MEN\GG-RH:(OI)(CI)(M)
                      NT AUTHORITY\SYSTEM:(I)(OI)(CI)(F)
                      BUILTIN\Administrators:(I)(OI)(CI)(F)
                      BUILTIN\Users:(I)(OI)(CI)(RX)
                      BUILTIN\Users:(I)(CI)(AD)
                      BUILTIN\Users:(I)(CI)(WD)
                      CREATOR OWNER:(I)(OI)(CI)(IO)(F)

Successfully processed 1 files; Failed processing 0 files
PS C:\Temp\TP-Sandbox\Compta>
```

Remplacer `TSSR-MEN\GG-RH` par un groupe ou un compte qui existe sur la machine (sur un poste hors domaine, un groupe local comme `Users`).

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
PS C:\Temp\TP-Sandbox\Compta> New-SmbShare -Name "Sandbox" -Path $base -ChangeAccess "TSSR-MEN\Domain Users"

Name    ScopeName Path               Description
----    --------- ----               -----------
Sandbox *         C:\Temp\TP-Sandbox


PS C:\Temp\TP-Sandbox\Compta> Get-SmbShare -Name "Sandbox"

Name    ScopeName Path               Description
----    --------- ----               -----------
Sandbox *         C:\Temp\TP-Sandbox


PS C:\Temp\TP-Sandbox\Compta> Get-SmbShareAccess -Name "Sandbox"

Name    ScopeName AccountName           AccessControlType AccessRight
----    --------- -----------           ----------------- -----------
Sandbox *         TSSR-MEN\Domain Users Allow             Change


PS C:\Temp\TP-Sandbox\Compta>
```


---

## 5. Nettoyage

```powershell
PS C:\Temp\TP-Sandbox\Compta> Remove-SmbShare -Name "Sandbox" -Force
PS C:\Temp\TP-Sandbox\Compta> Remove-Item -Path $base -Recurse -Force
Remove-Item : Cannot remove the item at 'C:\Temp\TP-Sandbox' because it is in use.
At line:1 char:1
+ Remove-Item -Path $base -Recurse -Force
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Remove-Item], PSInvalidOperationException
    + FullyQualifiedErrorId : InvalidOperation,Microsoft.PowerShell.Commands.RemoveItemCommand

PS C:\Temp\TP-Sandbox\Compta> Set-Location C:\Temp
PS C:\Temp> Remove-Item -Path $base -Recurse -Force
PS C:\Temp>
```

> [!note] L'erreur provient du fait que mon terminal était dans le working directory et qu'il ne peut pas le vider si je m'y trouve 
---

