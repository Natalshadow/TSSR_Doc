

> [!abstract] Résumé 
> Mise à disposition des données d'une petite organisation sur Windows Server : un partage par service, des droits NTFS gérés par la méthode **AGDLP**, des **quotas** disque et un **filtrage de fichiers** avec FSRM. L'ensemble de la procédure est écrit en **PowerShell**, de la création des dossiers au contrôle des accès, de façon reproductible.

> [!info] Nature du projet 
> Projet réalisé en environnement de laboratoire virtualisé, pas sur une infrastructure client.

## Compétences mobilisées

- Création et administration de **partages SMB** en PowerShell
- Gestion des droits **NTFS** (héritage, permissions explicites) avec `Get-Acl` et `Set-Acl`
- Mise en œuvre de la méthode **AGDLP** avec Active Directory (groupes globaux, groupes de domaine local)
- **File Server Resource Manager** : quotas stricts et souples, écrans de fichiers
- Scripts pilotés par les données (une table décrit le modèle d'accès, la boucle l'applique)
- **Tests automatisés** des accès depuis un poste client

## Contexte et objectif

Le domaine comptait déjà ses unités d'organisation, ses utilisateurs et ses groupes par service. Il restait à leur donner accès aux données : chaque service doit disposer de son dossier, certains services doivent pouvoir **lire** les dossiers d'autres services, et personne ne doit accéder au reste. L'espace disque doit aussi être borné et certains types de fichiers refusés.

## Environnement

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur (AD, DNS, DHCP, partages)|`srv-win-men-01`, `192.168.100.10`|
|Poste client|`CLI-WIN-MEN-01`, Windows 11|
|Racine des données|`C:\PARTAGE`|
|Services|ADMINISTRATIF, DIRECTION, COMPTABILITE, INFORMATIQUE, RH, PRODUCTION|

## Modèle d'accès

Chaque service possède un dossier qu'il peut **modifier**. Certains services peuvent en plus **lire** d'autres dossiers :

|Service|Son dossier|Lecture seule sur|
|---|---|---|
|ADMINISTRATIF|Modification|COMPTABILITE, RH|
|DIRECTION|Modification|ADMINISTRATIF, COMPTABILITE, RH, PRODUCTION|
|COMPTABILITE|Modification|aucun|
|INFORMATIQUE|Modification|PRODUCTION|
|RH|Modification|aucun|
|PRODUCTION|Modification|aucun|

### Pourquoi AGDLP

La méthode **AGDLP** (_Account, Global, Domain Local, Permission_) évite d'attribuer des droits à des personnes :

- les **utilisateurs** (A) sont membres du groupe global de leur service (`GG-<SERVICE>`) ;
- les **groupes globaux** (G) sont membres de groupes de domaine local (DL) qui représentent **un droit sur une ressource** ;
- ce sont ces groupes de domaine local qui reçoivent la **permission** (P) sur le dossier.

Quand quelqu'un change de service, une seule appartenance à modifier suffit : aucun droit n'est à retoucher sur les dossiers.

|Groupe|Rôle|
|---|---|
|`GG-<SERVICE>`|Les membres d'un service (groupe global)|
|`GDL-<SERVICE>-RW`|Droit de **modification** sur le dossier du service|
|`GDL-<SERVICE>-RO`|Droit de **lecture** sur le dossier du service|

## Mise en œuvre en PowerShell

Les commandes s'exécutent sur le serveur, dans une session PowerShell ouverte en administrateur du domaine. Les services sont décrits une seule fois :

```powershell
$services = "ADMINISTRATIF","DIRECTION","COMPTABILITE","INFORMATIQUE","RH","PRODUCTION"
```

### 1. Arborescence et fichiers de test

Une racine commune (`C:\PARTAGE`) regroupe les six dossiers : un seul emplacement à sauvegarder, à superviser et à borner.

```powershell
foreach ($s in $services) {
    New-Item -ItemType Directory -Path "C:\PARTAGE\$s" -Force | Out-Null
    New-Item -ItemType File -Path "C:\PARTAGE\$s\FICHIER-$s.txt" -Value "Fichier du service $s" -Force | Out-Null
}
Get-ChildItem C:\PARTAGE -Recurse



    Directory: C:\PARTAGE


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        10/23/2026  10:31 AM                ADMINISTRATIF
d-----        10/23/2026  10:37 AM                COMPTABILITE
d-----        10/23/2026  10:31 AM                DIRECTION
d-----        10/23/2026  10:31 AM                INFORMATIQUE
d-----        10/23/2026  10:41 AM                PRODUCTION
d-----        10/23/2026  10:31 AM                RH


    Directory: C:\PARTAGE\ADMINISTRATIF


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             32 FICHIER-ADMINISTRATIF.txt


    Directory: C:\PARTAGE\COMPTABILITE


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             31 FICHIER-COMPTABILITE.txt
-a----        10/23/2026  10:37 AM       10485760 test1.bin
-a----        10/23/2026  10:37 AM       10485760 test2.bin
-a----        10/23/2026  10:37 AM       10485760 test3.bin
-a----        10/23/2026  10:37 AM       10485760 test4.bin
-a----        10/23/2026  10:37 AM              0 test5.bin
-a----        10/23/2026  10:37 AM              0 test6.bin


    Directory: C:\PARTAGE\DIRECTION


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             28 FICHIER-DIRECTION.txt
-a----         10/7/2026   3:39 PM              0 test.txt


    Directory: C:\PARTAGE\INFORMATIQUE


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             31 FICHIER-INFORMATIQUE.txt


    Directory: C:\PARTAGE\PRODUCTION


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             29 FICHIER-PRODUCTION.txt


    Directory: C:\PARTAGE\RH


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:27 AM             21 FICHIER-RH.txt

```

### 2. Partages SMB

Chaque dossier est partagé avec **Contrôle total pour Everyone** : la restriction se fait uniquement côté NTFS. Le droit effectif est le plus restrictif des deux couches (partage et NTFS), donc un partage ouvert n'élargit rien et il n'y a qu'un seul endroit où gérer les droits.

```powershell
foreach ($s in $services) {
    New-SmbShare -Name $s -Path "C:\PARTAGE\$s" -FullAccess "Everyone"
}


Get-SmbShare | Where-Object Path -like "C:\PARTAGE\*" | Select-Object Name, Path
Name          Path
----          ----
ADMINISTRATIF C:\PARTAGE\ADMINISTRATIF
COMPTABILITE  C:\PARTAGE\COMPTABILITE
DIRECTION     C:\PARTAGE\DIRECTION
INFORMATIQUE  C:\PARTAGE\INFORMATIQUE
PRODUCTION    C:\PARTAGE\PRODUCTION
RH            C:\PARTAGE\RH


Get-SmbShareAccess -Name "RH"
Name ScopeName AccountName AccessControlType AccessRight
---- --------- ----------- ----------------- -----------
RH   *         Everyone    Allow             Full

```

### 3. Groupes de domaine local

Douze groupes (`-RW` et `-RO` pour chaque service) sont créés dans l'unité d'organisation `GROUPES/GDL`, avec l'étendue **domaine local** et le type **sécurité**.

```powershell
foreach ($s in $services) {
     foreach ($droit in "RW", "RO") {
         $nom = "GDL-$s-$droit"

         if (-not (Get-ADGroup -Filter "Name -eq '$nom'" `
                 -ErrorAction SilentlyContinue)) {
             New-ADGroup -Name $nom `
                 -GroupScope DomainLocal `
                 -GroupCategory Security `
                 -Path "OU=GDL,OU=GROUPES,DC=TSSR-MEN,DC=LAB"

             Write-Host "Créé : $nom" -ForegroundColor Green
         }
         else {
             Write-Host "Déjà existant : $nom" -ForegroundColor Yellow
         }
     }
 }
Déjà existant : GDL-ADMINISTRATIF-RW
Déjà existant : GDL-ADMINISTRATIF-RO
Déjà existant : GDL-DIRECTION-RW
Déjà existant : GDL-DIRECTION-RO
Déjà existant : GDL-COMPTABILITE-RW
Déjà existant : GDL-COMPTABILITE-RO
Déjà existant : GDL-INFORMATIQUE-RW
Déjà existant : GDL-INFORMATIQUE-RO
Déjà existant : GDL-RH-RW
Déjà existant : GDL-RH-RO
Déjà existant : GDL-PRODUCTION-RW
Déjà existant : GDL-PRODUCTION-RO
```

### 4. Droits NTFS

Par défaut, un dossier hérite des droits de `C:\`, dont ceux du groupe `Users` : sans action, tout le monde pourrait lire les dossiers. L'héritage est donc **coupé sans conserver les droits hérités**, puis les droits explicites sont posés. `SYSTEM` et `Administrators` sont conservés pour ne pas se verrouiller soi-même.

```powershell
foreach ($s in $services) {
    $chemin = "C:\PARTAGE\$s"
    $acl = Get-Acl $chemin
    $acl.SetAccessRuleProtection($true, $false)    # coupe l'héritage et supprime les droits hérités

    $regles = @(
        @("NT AUTHORITY\SYSTEM",       "FullControl"),
        @("BUILTIN\Administrators",    "FullControl"),
        @("TSSR-MEN\GDL-$s-RW",        "Modify"),
        @("TSSR-MEN\GDL-$s-RO",        "ReadAndExecute")
    )
    foreach ($r in $regles) {
        $ace = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $r[0], $r[1], "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($ace)
    }
    Set-Acl -Path $chemin -AclObject $acl
}
```

Les droits sont appliqués au dossier, à ses sous-dossiers et à ses fichiers. **Modification** permet de lire, écrire et supprimer, mais pas de changer les permissions ; **Lecture et exécution** n'autorise que la consultation.

Contrôle des permissions en place :

```powershell
foreach ($s in $services) {
    "--- $s"
    (Get-Acl "C:\PARTAGE\$s").Access |
        Select-Object IdentityReference, FileSystemRights, IsInherited |
        Format-Table -AutoSize
}

--- ADMINISTRATIF

IdentityReference                        FileSystemRights IsInherited
-----------------                        ---------------- -----------
CREATOR OWNER                                 FullControl       False
NT AUTHORITY\SYSTEM                           FullControl       False
BUILTIN\Administrators                        FullControl       False
TSSR-MEN\GDL-ADMINISTRATIF-RW                 FullControl       False
TSSR-MEN\GDL-ADMINISTRATIF-RO ReadAndExecute, Synchronize       False


--- DIRECTION

IdentityReference                    FileSystemRights IsInherited
-----------------                    ---------------- -----------
NT AUTHORITY\SYSTEM                       FullControl       False
BUILTIN\Administrators                    FullControl       False
TSSR-MEN\GDL-DIRECTION-RW         Modify, Synchronize       False
TSSR-MEN\GDL-DIRECTION-RO ReadAndExecute, Synchronize       False


--- COMPTABILITE

IdentityReference                       FileSystemRights IsInherited
-----------------                       ---------------- -----------
NT AUTHORITY\SYSTEM                          FullControl       False
BUILTIN\Administrators                       FullControl       False
TSSR-MEN\GDL-COMPTABILITE-RW         Modify, Synchronize       False
TSSR-MEN\GDL-COMPTABILITE-RO ReadAndExecute, Synchronize       False


--- INFORMATIQUE

IdentityReference                       FileSystemRights IsInherited
-----------------                       ---------------- -----------
NT AUTHORITY\SYSTEM                          FullControl       False
BUILTIN\Administrators                       FullControl       False
TSSR-MEN\GDL-INFORMATIQUE-RW         Modify, Synchronize       False
TSSR-MEN\GDL-INFORMATIQUE-RO ReadAndExecute, Synchronize       False


--- RH

IdentityReference                 FileSystemRights IsInherited
-----------------                 ---------------- -----------
NT AUTHORITY\SYSTEM                    FullControl       False
BUILTIN\Administrators                 FullControl       False
TSSR-MEN\GDL-RH-RW             Modify, Synchronize       False
TSSR-MEN\GDL-RH-RO     ReadAndExecute, Synchronize       False


--- PRODUCTION

IdentityReference                     FileSystemRights IsInherited
-----------------                     ---------------- -----------
NT AUTHORITY\SYSTEM                        FullControl       False
BUILTIN\Administrators                     FullControl       False
TSSR-MEN\GDL-PRODUCTION-RW         Modify, Synchronize       False
TSSR-MEN\GDL-PRODUCTION-RO ReadAndExecute, Synchronize       False

```

Chaque dossier ne doit plus afficher que quatre entrées, aucune héritée.

<!-- TODO : coller ici la sortie réelle du contrôle des permissions pour un dossier (par exemple RH) après exécution. -->

### 5. Application de la matrice AGDLP

La matrice est décrite sous forme de **table de données** : la boucle applique ensuite les mêmes règles à tous les services. Ajouter un service ou modifier un droit revient à changer une ligne.

```powershell
$lecture = @{
    ADMINISTRATIF = "COMPTABILITE","RH"
    DIRECTION     = "ADMINISTRATIF","COMPTABILITE","RH","PRODUCTION"
    COMPTABILITE  = @()
    INFORMATIQUE  = "PRODUCTION"
    RH            = @()
    PRODUCTION    = @()
}

foreach ($s in $services) {
    Add-ADGroupMember -Identity "GDL-$s-RW" -Members "GG-$s"        # le service modifie son dossier
    foreach ($cible in $lecture[$s]) {
        Add-ADGroupMember -Identity "GDL-$cible-RO" -Members "GG-$s" # le service lit le dossier d'un autre
    }
}
```

Vérification de l'appartenance de chaque groupe de domaine local :

```powershell
Get-ADGroup -Filter 'Name -like "GDL-*"' | Sort Name | ForEach-Object {
    $m = (Get-ADGroupMember $_ | Select -Expand Name) -join ", "
    "{0,-24} {1}" -f $_.Name, $m
}

GDL-ADMINISTRATIF-RO     GG-DIRECTION
GDL-ADMINISTRATIF-RW     GG-ADMINISTRATIF
GDL-COMPTABILITE-RO      GG-DIRECTION, GG-ADMINISTRATIF
GDL-COMPTABILITE-RW      GG-COMPTABILITE
GDL-DIRECTION-RO
GDL-DIRECTION-RW         GG-DIRECTION
GDL-INFORMATIQUE-RO
GDL-INFORMATIQUE-RW      GG-INFORMATIQUE
GDL-PRODUCTION-RO        GG-INFORMATIQUE, GG-DIRECTION
GDL-PRODUCTION-RW        GG-PRODUCTION
GDL-RH-RO                GG-DIRECTION, GG-ADMINISTRATIF
GDL-RH-RW                GG-RH

```

VS. le résultat attendu :
```text
GDL-ADMINISTRATIF-RO     GG-DIRECTION
GDL-ADMINISTRATIF-RW     GG-ADMINISTRATIF
GDL-COMPTABILITE-RO      GG-DIRECTION, GG-ADMINISTRATIF
GDL-COMPTABILITE-RW      GG-COMPTABILITE
GDL-DIRECTION-RO
GDL-DIRECTION-RW         GG-DIRECTION
GDL-INFORMATIQUE-RO
GDL-INFORMATIQUE-RW      GG-INFORMATIQUE
GDL-PRODUCTION-RO        GG-INFORMATIQUE, GG-DIRECTION
GDL-PRODUCTION-RW        GG-PRODUCTION
GDL-RH-RO                GG-DIRECTION, GG-ADMINISTRATIF
GDL-RH-RW                GG-RH
```

Les groupes `GDL-DIRECTION-RO` et `GDL-INFORMATIQUE-RO` sont vides : d'après la matrice, aucun autre service ne lit ces deux dossiers.

### 6. Validation des accès depuis le client

Les accès attendus se déduisent directement de la matrice :

|Utilisateur (service)|ADMINISTRATIF|DIRECTION|COMPTABILITE|INFORMATIQUE|RH|PRODUCTION|
|---|---|---|---|---|---|---|
|ADMINISTRATIF|RW|✖|R|✖|R|✖|
|DIRECTION|R|RW|R|✖|R|R|
|COMPTABILITE|✖|✖|RW|✖|✖|✖|
|INFORMATIQUE|✖|✖|✖|RW|✖|R|
|RH|✖|✖|✖|✖|RW|✖|
|PRODUCTION|✖|✖|✖|✖|✖|RW|

Pour comparer ces attendus à la réalité, un script teste chaque partage avec les droits du compte connecté : il tente de **lister** le dossier, puis de **créer et supprimer** un fichier temporaire. Il s'exécute dans une session ouverte avec le compte à tester (les groupes sont lus à l'ouverture de session) :

```powershell
whoami /groups | Select-String "GG-"

$services = "ADMINISTRATIF","DIRECTION","COMPTABILITE","INFORMATIQUE","RH","PRODUCTION"
foreach ($s in $services) {
    $unc = "\\srv-win-men-01\$s"
    $lecture = $false
    $ecriture = $false
    try { $null = Get-ChildItem $unc -ErrorAction Stop; $lecture = $true } catch {}
    if ($lecture) {
        $tmp = Join-Path $unc "test-ecriture-$env:USERNAME.tmp"
        try {
            New-Item -ItemType File -Path $tmp -ErrorAction Stop | Out-Null
            Remove-Item $tmp -ErrorAction Stop
            $ecriture = $true
        } catch {}
    }
    [pscustomobject]@{
        Partage = $s
        Acces   = if ($ecriture) { "RW" } elseif ($lecture) { "R" } else { "Refusé" }
    }
}

Partage       Acces
-------       -----
ADMINISTRATIF RW
DIRECTION     RW
COMPTABILITE  RW
INFORMATIQUE  RW
RH            RW
PRODUCTION    RW

```

<!-- TODO : exécuter le script avec un compte par service (les six lignes du tableau) et ajouter ici le tableau des résultats observés. -->

### 7. Quotas stricts

Le rôle **File Server Resource Manager** (FSRM) apporte quotas et filtrage de fichiers. Un quota **strict** refuse toute écriture au-delà de la limite.

```powershell
Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools

$quotas = @{
    ADMINISTRATIF = 150MB
    COMPTABILITE  = 50MB
    DIRECTION     = 20MB
    INFORMATIQUE  = 100MB
    PRODUCTION    = 200MB
    RH            = 150MB
}
foreach ($s in $quotas.Keys) {
    New-FsrmQuota -Path "C:\PARTAGE\$s" -Size $quotas[$s]
}

Get-FsrmQuota | Select-Object Path, Size, Usage, SoftLimit

Path                          Size Usage SoftLimit
----                          ---- ----- ---------
C:\PARTAGE\ADMINISTRATIF 157286400  2048     False
C:\PARTAGE\COMPTABILITE   52428800  2048      True
C:\PARTAGE\DIRECTION      20971520  3072     False
C:\PARTAGE\INFORMATIQUE  104857600  2048     False
C:\PARTAGE\PRODUCTION    209715200  2048     False
C:\PARTAGE\RH            157286400  2048     False

```

Test sur le dossier `COMPTABILITE` (50 Mo) : des fichiers de 10 Mo sont écrits un à un jusqu'au dépassement, avec relevé de l'utilisation à chaque étape.

```powershell
$dossier = "C:\PARTAGE\COMPTABILITE"
1..6 | ForEach-Object {
    $nom = "test$_.bin"
    try {
        [System.IO.File]::WriteAllBytes((Join-Path $dossier $nom), [byte[]]::new(10MB))
        $etat = "écrit"
    } catch {
        $etat = "refusé : " + $_.Exception.Message
    }
    $q = Get-FsrmQuota -Path $dossier
    "{0} : {1} (utilisation {2:N1} Mo sur {3:N0} Mo)" -f $nom, $etat, ($q.Usage / 1MB), ($q.Size / 1MB)
}

test1.bin : écrit (utilisation 10.0 Mo sur 50 Mo)
test2.bin : écrit (utilisation 20.0 Mo sur 50 Mo)
test3.bin : écrit (utilisation 30.0 Mo sur 50 Mo)
test4.bin : écrit (utilisation 40.0 Mo sur 50 Mo)
test5.bin : écrit (utilisation 50.0 Mo sur 50 Mo)
test6.bin : écrit (utilisation 60.0 Mo sur 50 Mo)


```

L'événement correspondant est consultable dans le journal :

```powershell
Get-WinEvent -FilterHashtable @{ LogName = "Application"; ProviderName = "SRMSVC" } -MaxEvents 10 |
    Select-Object TimeCreated, Id, Message
    
    
TimeCreated               Id Message
-----------               -- -------
10/23/2026 10:22:54 AM 12317 File Server Resource Manager failed to enumerate share paths or DFS paths.  Mappings from local file paths to share and DFS paths may be incomplete or ...
10/23/2026 10:22:26 AM 12295 File Server Resource Manager has completed a configuration request from the file screen filter driver for volume 'C:'.
10/23/2026 10:22:26 AM 12294 File Server Resource Manager has received a configuration request from the file screen filter driver for volume 'C:'.
10/23/2026 10:22:25 AM  8202 Communication port '\DataScreenCommPort' to the 'DataScrn' filter driver was established.
10/23/2026 10:22:25 AM  8202 Communication port '\QuotaCommPort' to the 'Quota' filter driver was established.
10/22/2026 11:08:22 AM 12317 File Server Resource Manager failed to enumerate share paths or DFS paths.  Mappings from local file paths to share and DFS paths may be incomplete or ...
10/22/2026 11:08:15 AM 12295 File Server Resource Manager has completed a configuration request from the file screen filter driver for volume 'C:'.
10/22/2026 11:08:15 AM 12294 File Server Resource Manager has received a configuration request from the file screen filter driver for volume 'C:'.
10/22/2026 11:08:15 AM  8202 Communication port '\QuotaCommPort' to the 'Quota' filter driver was established.
10/22/2026 11:08:15 AM  8202 Communication port '\DataScreenCommPort' to the 'DataScrn' filter driver was established.
```



### 8. Quotas souples

Un quota **souple** ne bloque rien : il sert à surveiller et à notifier. La bascule se fait sur le même dossier, après suppression des fichiers de test :

```powershell
Remove-Item "C:\PARTAGE\COMPTABILITE\test*.bin" -Force
Set-FsrmQuota -Path "C:\PARTAGE\COMPTABILITE" -SoftLimit:$false
Get-FsrmQuota -Path "C:\PARTAGE\COMPTABILITE" | Select-Object Path, Size, Usage, SoftLimit
Path                        Size    Usage SoftLimit
----                        ----    ----- ---------
C:\PARTAGE\COMPTABILITE 52428800 41951232     False


$dossier = "C:\PARTAGE\COMPTABILITE"
1..6 | ForEach-Object {
>>     $nom = "test$_.bin"
>>     try {
>>         [System.IO.File]::WriteAllBytes((Join-Path $dossier $nom), [byte[]]::new(10MB))
>>         $etat = "écrit"
>>     } catch {
>>         $etat = "refusé : " + $_.Exception.Message
>>     }
>>     $q = Get-FsrmQuota -Path $dossier
>>     "{0} : {1} (utilisation {2:N1} Mo sur {3:N0} Mo)" -f $nom, $etat, ($q.Usage / 1MB), ($q.Size / 1MB)
>> }
test1.bin : écrit (utilisation 10.0 Mo sur 50 Mo)
test2.bin : écrit (utilisation 20.0 Mo sur 50 Mo)
test3.bin : écrit (utilisation 30.0 Mo sur 50 Mo)
test4.bin : écrit (utilisation 40.0 Mo sur 50 Mo)
test5.bin : refusé : Exception calling "WriteAllBytes" with "2" argument(s): "There is not enough space on the disk.
" (utilisation 40.0 Mo sur 50 Mo)
test6.bin : refusé : Exception calling "WriteAllBytes" with "2" argument(s): "There is not enough space on the disk.
" (utilisation 40.0 Mo sur 50 Mo)


```

Le même test que précédemment est ensuite relancé pour comparer les deux comportements.

|Type de quota|Au dépassement de la limite|
|---|---|
|Strict|L'écriture est refusée|
|Souple|L'écriture est autorisée, le dépassement est consigné|


### 9. Blocage d'extensions

Un **écran de fichiers** s'applique à un dossier à partir d'un **groupe de fichiers** (une liste d'extensions). Un écran **actif** bloque, un écran **passif** journalise seulement : même logique que strict et souple pour les quotas.

```powershell
Get-FsrmFileGroup | Select-Object Name

Name
----
Audio and Video Files
Image Files
Office Files
E-mail Files
Executable Files
System Files
Compressed Files
Web Page Files
Text Files
Backup Files
Temporary Files

New-FsrmFileScreen -Path "C:\PARTAGE\PRODUCTION" -IncludeGroup "Audio and Video Files" -Active
New-FsrmFileScreen : 0x80045303, The specified object already exists.
At line:1 char:1
+ New-FsrmFileScreen -Path "C:\PARTAGE\PRODUCTION" -IncludeGroup "Audio ...
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : ResourceExists: (MSFT_FSRMFileScreen:Root/Microsoft/..._FSRMFileScreen) [New-FsrmFileScreen], CimException
    + FullyQualifiedErrorId : MI RESULT 11,New-FsrmFileScreen


New-Item -ItemType File -Path "C:\PARTAGE\PRODUCTION\test.txt"


    Directory: C:\PARTAGE\PRODUCTION


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        10/23/2026  10:39 AM              0 test.txt


New-Item -ItemType File -Path "C:\PARTAGE\PRODUCTION\test.mp3"
New-Item : Access to the path 'C:\PARTAGE\PRODUCTION\test.mp3' is denied.
At line:1 char:1
+ New-Item -ItemType File -Path "C:\PARTAGE\PRODUCTION\test.mp3"
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : PermissionDenied: (C:\PARTAGE\PRODUCTION\test.mp3:String) [New-Item], UnauthorizedAccessException
    + FullyQualifiedErrorId : NewItemUnauthorizedAccessError,Microsoft.PowerShell.Commands.NewItemCommand


Get-FsrmFileScreen -Path "C:\PARTAGE\PRODUCTION"


Active          : True
Description     :
IncludeGroup    : {Audio and Video Files}
MatchesTemplate : False
Notification    :
Path            : C:\PARTAGE\PRODUCTION
Template        :
PSComputerName  :


```

Résultat attendu : le fichier `.txt` est créé, le `.mp3` est refusé.


Nettoyage en fin de test :

```powershell
Remove-Item "C:\PARTAGE\PRODUCTION\test.*" -Force -ErrorAction SilentlyContinue
```

## Ce que ce laboratoire démontre

- Appliquer la méthode **AGDLP** de bout en bout, des groupes à la permission, avec une matrice décrite en une seule table.
- Remplacer une procédure en interface graphique, répétitive (douze groupes, six dossiers, douze jeux de permissions), par un script **relisible et rejouable**.
- Gérer les droits au bon endroit : **partage ouvert, restriction côté NTFS**, héritage coupé, comptes système conservés.
- **Contrôler** le résultat par un audit des ACL, un listing des groupes et un test d'accès exécuté avec les droits de chaque utilisateur.
- Encadrer l'usage du stockage avec **FSRM** : quotas stricts ou souples, filtrage d'extensions.

## Limites de ce laboratoire

- Environnement virtuel, six utilisateurs, un seul serveur de fichiers : pas de charge ni de volumétrie réelles.
- Les quotas et l'écran de fichiers sont testés sur un dossier représentatif, les autres sont contrôlés par leur configuration.
