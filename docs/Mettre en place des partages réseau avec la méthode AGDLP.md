> [!abstract] Contexte 
> Le domaine est organisé (OU, utilisateurs, groupes globaux). Il faut maintenant donner accès aux données : créer l'arborescence de dossiers de service sur le serveur, les partager, appliquer la méthode **AGDLP** pour gérer les droits, puis limiter l'espace disque avec des **quotas** et filtrer certains types de fichiers (FSRM).

---

## Sommaire

- [[#1. Préparer les ressources]]
- [[#2. Partager les dossiers]]
- [[#3. Créer les groupes de domaine local]]
- [[#4. Droits NTFS]]
- [[#5. Matrice AGDLP]]
- [[#6. Validation]]
- [[#7. Quotas stricts]]
- [[#8. Quotas souples]]
- [[#9. Blocage d'extensions]]
- [[#10. Conclusion et difficultés rencontrées]]

---

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur (AD / DNS / DHCP / partages)|`srv-win-men-01` (`192.168.100.10`)|
|Poste client|`CLI-WIN-MEN-01`|
|Consoles utilisées|_Utilisateurs et ordinateurs AD_, _Gestion du partage_, _FSRM_|

> [!note] Snapshot initiale avant de commencer

> [!warning] État hérité du lab précédent
> 
> - `t.stark` (seul membre de `GG-ADMINISTRATIF`) a été **désactivé** et retiré de ses groupes. Il n'y a donc plus d'utilisateur actif dans ADMINISTRATIF. Décide comment tester cette ligne de la matrice (réactiver temporairement, ou créer un compte de test dans l'OU) et **écris-le** en section 6.
> - `t.odinson` doit changer son mot de passe à la prochaine connexion.
> - `n.furry` est dans `GG-INFORMATIQUE`, comme `b.banner`.
> - Le serveur est aussi le contrôleur de domaine : les groupes de domaine local se créent donc depuis ce serveur.

---

## 1. Préparer les ressources

**Arborescence à créer sur `srv-win-men-01`**

```
C:\
└── PARTAGE
    ├── ADMINISTRATIF
    ├── DIRECTION
    ├── COMPTABILITE
    ├── INFORMATIQUE
    ├── RH
    └── PRODUCTION
```

Dans chaque dossier, créer un fichier `FICHIER-NOM_SERVICE.txt` (ex. `FICHIER-RH.txt`).

> [!tip] Guidage
> 
> - Pour la création des fichiers, tu peux le faire à la main ou avec une boucle PowerShell sur la liste des services (voir l'aide-mémoire). Précise la méthode.
> - `NOM_SERVICE` : respecte le nom du dossier, sans accents (`COMPTABILITE`).
> - Pourquoi une racine commune `PARTAGE` plutôt que six dossiers à la racine de `C:\` ?

| Dossier       | Fichier créé |
| ------------- | ------------ |
| ADMINISTRATIF | Oui          |
| DIRECTION     | Oui          |
| COMPTABILITE  | Oui          |
| INFORMATIQUE  | Oui          |
| RH            | Oui          |
| PRODUCTION    | Oui          |

**Capture(s)**
![](attachments/Pasted%20image%2020261007142618.png)
![](attachments/Pasted%20image%2020261007142627.png)

**Commentaires**

---

## 2. Partager les dossiers

**Consigne :** partager chaque dossier avec **Contrôle total pour Tout le monde** ; la restriction se fait côté NTFS.

> [!tip] Guidage
> 
> - Propriétés du dossier → _Partage_ → _Partage avancé_ → _Autorisations_. Par défaut, _Tout le monde_ n'a que la lecture : note ce que tu changes.
> - Il y a **deux** couches de droits : ceux du **partage** et ceux du **NTFS**. Le droit effectif est le plus **restrictif** des deux. Pourquoi ouvrir le partage en grand et restreindre uniquement côté NTFS ?
> - Vérifie le **nom de partage** (identique au nom du dossier) et teste que `\\srv-win-men-01\RH` répond depuis le client.

|Partage|Chemin UNC|Contrôle total / Tout le monde|
|---|---|---|
|ADMINISTRATIF|`\\srv-win-men-01\ADMINISTRATIF`|☐|
|DIRECTION|`\\srv-win-men-01\DIRECTION`|☐|
|COMPTABILITE|`\\srv-win-men-01\COMPTABILITE`|☐|
|INFORMATIQUE|`\\srv-win-men-01\INFORMATIQUE`|☐|
|RH|`\\srv-win-men-01\RH`|☐|
|PRODUCTION|`\\srv-win-men-01\PRODUCTION`|☐|

**Capture(s)**
![](attachments/Pasted%20image%2020261007142754.png)
![](attachments/Pasted%20image%2020261007142758.png)
**Commentaires**

---

## 3. Créer les groupes de domaine local

**Consigne :** créer, pour chaque service, un groupe `GDL-<SERVICE>-RW` (modification) et `GDL-<SERVICE>-RO` (lecture seule), soit 12 groupes, dans l'OU `GROUPES/GDL`.

> [!warning] Faute dans l'énoncé L'énoncé écrit `GDL-ADMINISTRATIF-R0` (avec un **zéro**). C'est une coquille : utilise `-RO` (lettre O) comme les autres groupes. Note-le.

> [!tip] Guidage
> 
> - Étendue : **domaine local**. Type : **sécurité**. Crée-les dans l'OU `GDL` (clic droit sur `GDL` → _Nouveau_ → _Groupe_).
> - Que veut dire `RW` / `RO` ? Qu'est-ce que le groupe représente : une **personne**, un **service**, ou un **droit sur une ressource** ?
> - Rappel du principe **AGDLP** : _Account → Global group → Domain Local group → Permission_. Écris-le avec tes mots : pourquoi ne pas mettre directement les utilisateurs sur les dossiers ?

| Groupe                         | Créé |
| ------------------------------ | ---- |
| `GDL-ADMINISTRATIF-RW` / `-RO` | Oui  |
| `GDL-DIRECTION-RW` / `-RO`     | Oui  |
| `GDL-COMPTABILITE-RW` / `-RO`  | Oui  |
| `GDL-INFORMATIQUE-RW` / `-RO`  | Oui  |
| `GDL-RH-RW` / `-RO`            | Oui  |
| `GDL-PRODUCTION-RW` / `-RO`    | Oui  |

**Capture(s)**
![](attachments/Pasted%20image%2020261007145006.png)


> [!note] Snapshot après la partie 3

---

## 4. Droits NTFS

**Consigne :** placer les groupes de domaine local sur chaque dossier (onglet _Sécurité_) et leur attribuer les droits NTFS adéquats.

- `GDL-<SERVICE>-RW` → **Modification**
- `GDL-<SERVICE>-RO` → **Lecture et exécution**

> [!tip] Guidage
> 
> - Par défaut, un dossier **hérite** des droits de `C:\`, dont le groupe `Utilisateurs`. Si tu ne coupes pas l'héritage, tout le monde peut lire. Dans _Paramètres avancés_ → _Désactiver l'héritage_ : l'assistant propose de **convertir** ou **supprimer** les droits hérités. Lequel choisis-tu et pourquoi ?
> - Garde `SYSTEM` et `Administrateurs` : sans eux, tu risques de t'enfermer toi-même.
> - Vérifie que le droit s'applique à **ce dossier, les sous-dossiers et les fichiers**.
> - Distingue **Modification** et **Contrôle total** : que peut faire le second en plus ?
> - Cette étape peut se faire à la main (12 fois) ou via `icacls` en boucle. Précise la méthode.

| Dossier       | Héritage coupé | RW = Modification | RO = Lecture/exéc. |
| ------------- | -------------- | ----------------- | ------------------ |
| ADMINISTRATIF | Oui            | Oui               | Oui                |
| DIRECTION     | ☐              | ☐                 | ☐                  |
| COMPTABILITE  | ☐              | ☐                 | ☐                  |
| INFORMATIQUE  | ☐              | ☐                 | ☐                  |
| RH            | ☐              | ☐                 | ☐                  |
| PRODUCTION    | ☐              | ☐                 | ☐                  |

>[!note] Snapshot préalable au powershell
> Relecture plusieurs fois du code, il me semble correct, mais par précaution il vaut mieux avoir un back-up.

``` powershell
$services = "ADMINISTRATIF","DIRECTION","COMPTABILITE","INFORMATIQUE","RH","PRODUCTION"

foreach ($s in $services) {
    $p = "C:\PARTAGE\$s"
    icacls $p /inheritance:r
    icacls $p /grant "SYSTEM:(OI)(CI)F" "BUILTIN\Administrators:(OI)(CI)F"
    icacls $p /grant "TSSR-MEN\GDL-$s-RW:(OI)(CI)M"
    icacls $p /grant "TSSR-MEN\GDL-$s-RO:(OI)(CI)RX"
}
```


**Capture(s)**
![](attachments/Pasted%20image%2020261007145653.png)
**Commentaires**

---

## 5. Matrice AGDLP

**Consigne :** placer les groupes globaux dans les groupes de domaine local pour respecter la matrice :

|Service|Son partage|Autres partages|
|---|---|---|
|ADMINISTRATIF|Modification|Lecture : COMPTABILITE, RH|
|DIRECTION|Modification|Lecture : ADMINISTRATIF, COMPTABILITE, RH, PRODUCTION|
|COMPTABILITE|Modification|Aucun|
|INFORMATIQUE|Modification|Lecture : PRODUCTION|
|RH|Modification|Aucun|
|PRODUCTION|Modification|Aucun|

> [!tip] Guidage
> 
> - Raisonne **par groupe de domaine local**, pas par service. Pour chaque `GDL-X-RW` : qui peut modifier X ? Pour chaque `GDL-X-RO` : qui peut seulement lire X ? Remplis la table ci-dessous à partir de la matrice avant de toucher à AD.
> - Les groupes **globaux** vont dans les **GDL** (jamais l'inverse). Ajoute-les depuis l'onglet _Membres_ du GDL.
> - Certains groupes `-RO` n'ont aucun membre d'après la matrice : c'est normal, note-le.
> - **Lis la matrice à la lettre.** Par exemple, DIRECTION n'a pas de lecture sur INFORMATIQUE. Si tu penses que c'est un oubli, tranche et justifie dans les commentaires.

``` powershell
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-COMPTABILITE-RO" -Members "GG-ADMINISTRATIF","GG-DIRECTION"
PS C:\Users\Administrator> Get-ADGroupMember "GDL-COMPTABILITE-RO" | Select Name

Name
----
GG-DIRECTION
GG-ADMINISTRATIF


PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-RH-RO" -Members "GG-ADMINISTRATIF","GG-DIRECTION"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-ADMINISTRATIF-RO" -Members "GG-DIRECTION"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-PRODUCTION-RO" -Members "GG-DIRECTION","GG-INFORMATIQUE"
PS C:\Users\Administrator> Get-ADGroupMember "GDL-COMPTABILITE-RO" | Select Name

Name
----
GG-DIRECTION
GG-ADMINISTRATIF


PS C:\Users\Administrator> Get-ADGroupMember "GDL-PRODUCTION-RO" | Select Name

Name
----
GG-INFORMATIQUE
GG-DIRECTION


PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-ADMINISTRATIF-RW" -Members "GG-ADMINISTRATIF"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-DIRECTION-RW"     -Members "GG-DIRECTION"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-COMPTABILITE-RW"  -Members "GG-COMPTABILITE"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-INFORMATIQUE-RW"  -Members "GG-INFORMATIQUE"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-RH-RW"            -Members "GG-RH"
PS C:\Users\Administrator> Add-ADGroupMember -Identity "GDL-PRODUCTION-RW"    -Members "GG-PRODUCTION"
PS C:\Users\Administrator> Get-ADGroup -Filter 'Name -like "GDL-*"' | Sort Name | ForEach-Object {
>>     $m = (Get-ADGroupMember $_ | Select -Expand Name) -join ", "
>>     "{0,-24} {1}" -f $_.Name, $m
>> }
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
PS C:\Users\Administrator>

```

| Groupe de domaine local | Groupes globaux membres        | Fait |
| ----------------------- | ------------------------------ | ---- |
| `GDL-ADMINISTRATIF-RW`  | GG-ADMINISTRATIF               | OUI  |
| `GDL-ADMINISTRATIF-RO`  | GG-DIRECTION                   | OUI  |
| `GDL-DIRECTION-RW`      | GG-DIRECTION                   | OUI  |
| `GDL-DIRECTION-RO`      |                                |      |
| `GDL-COMPTABILITE-RW`   | GG-COMPTABILITE                | OUI  |
| `GDL-COMPTABILITE-RO`   | GG-ADMINISTRATIF, GG-DIRECTION | OUI  |
| `GDL-INFORMATIQUE-RW`   | GG-INFORMATIQUE                | OUI  |
| `GDL-INFORMATIQUE-RO`   |                                |      |
| `GDL-RH-RW`             | GG-RH                          | Oui  |
| `GDL-RH-RO`             | GG-ADMINISTRATIF, GG-DIRECTION | Oui  |
| `GDL-PRODUCTION-RW`     | GG-PRODUCTION                  | Oui  |
| `GDL-PRODUCTION-RO`     | GG-ADMINISTRATIF, GG-DIRECTION | Oui  |

**Capture(s)**

**Commentaires**

---

## 6. Validation

**Consigne :** tester les droits de chaque utilisateur en ouvrant une session avec les différents comptes.

> [!tip] Guidage
> 
> - Les groupes sont lus **à l'ouverture de session** : si tu as modifié les membres pendant qu'un utilisateur était connecté, il doit se **déconnecter / reconnecter**. Vérifie avec `whoami /groups` que le `GG-...` est bien présent.
> - Depuis le client, ouvre `\\srv-win-men-01\<PARTAGE>` pour **chaque** partage. Pour chaque test, tente trois actions : **ouvrir** le dossier, **lire** le fichier, **créer / supprimer** un fichier.
> - Note le **message exact** d'un refus. Un accès refusé sur le dossier est différent d'un accès en lecture seule : qu'observes-tu ?
> - L'onglet _Sécurité_ → _Avancé_ → _Accès effectif_ permet de simuler un utilisateur sans se connecter. Utile en complément, **pas à la place** des tests réels.
> - Remplis le tableau en écrivant `RW`, `R` ou `✖` dans chaque case.

**Attendu (déduit de la matrice) / observé**

|Utilisateur (groupe)|ADMIN|DIRECTION|COMPTA|INFO|RH|PROD|
|---|---|---|---|---|---|---|
|ADMINISTRATIF|||||||
|DIRECTION (`s.rogers`)|||||||
|COMPTABILITE (`n.romanoff`)|||||||
|INFORMATIQUE (`b.banner`)|||||||
|RH (`t.odinson`)|||||||
|PRODUCTION (`c.barton`)|||||||

**Choix pour tester ADMINISTRATIF (compte désactivé)**

**Capture(s)** (au moins un accès autorisé en écriture, un en lecture seule et un refusé)

**Commentaires**

> [!note] Snapshot après la partie 6

---

## 7. Quotas stricts

**Consigne :** installer le rôle **File Server Resource Manager** (FSRM), créer les quotas ci-dessous, puis les tester.

|Service|Quota|
|---|---|
|ADMINISTRATIF|150 Mo|
|COMPTABILITE|50 Mo|
|DIRECTION|20 Mo|
|INFORMATIQUE|100 Mo|
|PRODUCTION|200 Mo|
|RH|150 Mo|

> [!tip] Guidage
> 
> - Installation : _Gestionnaire de serveur_ → _Ajouter des rôles et fonctionnalités_ → _Services de fichiers et de stockage_ → **FSRM**. Note si un redémarrage ou une configuration (e-mail, etc.) est demandé.
> - Dans la console FSRM → _Gestion des quotas_ → _Quotas_ → _Créer un quota_. Choisis **« Définir des propriétés de quota personnalisées »** plutôt qu'un modèle, puisque chaque dossier a sa propre taille.
> - Un quota **strict** (_hard_) **bloque** l'écriture au-delà de la limite. Vérifie que c'est bien l'option cochée.
> - Test : prends **DIRECTION (20 Mo)** pour aller vite. Génère des fichiers de taille connue avec `fsutil file createnew <chemin> <taille en octets>` (voir l'aide-mémoire), ou copie des fichiers depuis le client.
> - Fais le test **progressivement** : ~50 %, ~90 %, 100 %, puis dépassement. À chaque palier, regarde l'**utilisation dans FSRM** (la console peut nécessiter une actualisation).
> - Note **ce que voit le client** : message d'erreur, et l'**espace libre** affiché dans l'Explorateur pour le lecteur réseau (indice : il ne correspond plus à celui du disque).
> - Note **ce que voit le serveur** : l'Observateur d'événements (journal Application, source `SRMSVC`) et l'état du quota dans FSRM.
> - Ne teste pas les six quotas en détail : un test complet sur un dossier suffit, vérifie les autres par la console.
> - **Supprime les fichiers de test** à la fin (étape 7 de l'énoncé).

|Quota créé|Strict|Fait|
|---|---|---|
|ADMINISTRATIF 150 Mo|☐|☐|
|COMPTABILITE 50 Mo|☐|☐|
|DIRECTION 20 Mo|☐|☐|
|INFORMATIQUE 100 Mo|☐|☐|
|PRODUCTION 200 Mo|☐|☐|
|RH 150 Mo|☐|☐|

**Journal du test (dossier : …)**

|Palier|Taille déposée|Utilisation FSRM|Observation|
|---|---|---|---|
|~50 %||||
|~90 %||||
|100 %||||
|Dépassement||||

**Capture(s)**

**Comportement du serveur / du client**

---

## 8. Quotas souples

**Consigne :** supprimer les fichiers de test, refaire la manipulation avec des quotas **souples** et observer la différence.

> [!tip] Guidage
> 
> - Tu peux **modifier** les quotas existants (propriétés du quota → option _Quota souple_) plutôt que de les recréer.
> - Refais exactement le même scénario (mêmes paliers) pour comparer à armes égales.
> - Question centrale : qu'est-ce qui change **pour l'utilisateur** et **pour l'administrateur** ? Un quota souple empêche-t-il d'écrire ? À quoi sert-il alors ? (Indice : supervision, rapports, notifications.)
> - Compare dans une table : même dépôt, résultat strict vs souple.

|Situation|Quota strict|Quota souple|
|---|---|---|
|Écriture au-delà de la limite|||
|Message côté client|||
|Trace côté serveur|||
|Cas d'usage|||

**Capture(s)**

**Commentaires**

---

## 9. Blocage d'extensions

**Consigne :** manipuler le blocage de certaines extensions de fichiers (FSRM, _Gestion du filtrage de fichiers_).

> [!tip] Guidage
> 
> - Console FSRM → _Gestion du filtrage de fichiers_. Trois notions : **groupes de fichiers** (liste d'extensions), **écrans de fichiers** (appliqués à un dossier) et **exceptions**.
> - Applique un écran sur **un** dossier de ton choix (ex. `PRODUCTION`) avec un groupe existant (_Audio and Video Files_, _Executable Files_…). Teste avec un `.mp3` et un `.txt` : lequel passe, lequel est bloqué, et quel message vois-tu ?
> - Un écran **actif** bloque ; un écran **passif** journalise seulement. Retrouve la même logique que **strict / souple** pour les quotas.
> - Bonus (optionnel) : créer ton propre groupe de fichiers avec une extension de ton choix.
> - À la fin, supprime tes fichiers de test.

|Élément|Valeur|
|---|---|
|Dossier protégé||
|Groupe de fichiers utilisé||
|Type d'écran (actif / passif)||
|Fichier bloqué (extension)||
|Fichier accepté (extension)||

**Capture(s)**

**Commentaires**

---

## 10. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

### Commandes utiles (aide-mémoire)

```powershell
# Dossiers et fichiers
$services = "ADMINISTRATIF","DIRECTION","COMPTABILITE","INFORMATIQUE","RH","PRODUCTION"
foreach ($s in $services) {
    New-Item -ItemType Directory "C:\PARTAGE\$s" -Force | Out-Null
    New-Item -ItemType File "C:\PARTAGE\$s\FICHIER-$s.txt" -Force | Out-Null
}

# Partages
New-SmbShare -Name RH -Path C:\PARTAGE\RH -FullAccess "Tout le monde"
Get-SmbShare

# Groupes de domaine local
New-ADGroup -Name "GDL-RH-RW" -GroupScope DomainLocal -GroupCategory Security `
  -Path "OU=GDL,OU=GROUPES,DC=TSSR-MEN,DC=LAB"
Add-ADGroupMember -Identity "GDL-RH-RW" -Members "GG-RH"

# NTFS
icacls C:\PARTAGE\RH /inheritance:r
icacls C:\PARTAGE\RH /grant "SYSTEM:(OI)(CI)F" "BUILTIN\Administrators:(OI)(CI)F"
icacls C:\PARTAGE\RH /grant "TSSR-MEN\GDL-RH-RW:(OI)(CI)M"
icacls C:\PARTAGE\RH /grant "TSSR-MEN\GDL-RH-RO:(OI)(CI)RX"

# FSRM
Install-WindowsFeature FS-Resource-Manager -IncludeManagementTools
New-FsrmQuota -Path C:\PARTAGE\DIRECTION -Size 20MB          # strict
Set-FsrmQuota -Path C:\PARTAGE\DIRECTION -SoftLimit:$true    # souple
Get-FsrmQuota | Select Path, Size, Usage, SoftLimit
New-FsrmFileScreen -Path C:\PARTAGE\PRODUCTION -IncludeGroup "Audio and Video Files" -Active

# Fichiers de test (taille en octets : 10 Mo = 10485760)
fsutil file createnew C:\PARTAGE\DIRECTION\test1.bin 10485760
Remove-Item C:\PARTAGE\DIRECTION\*.bin -Force

# Vérifications client
whoami /groups
```

---

> [!note] Rendu
> 
> - [ ] Aucun mot de passe visible (texte ou capture)
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Coquille `GDL-ADMINISTRATIF-R0` et lecture de la matrice tranchées et notées
> - [ ] Fichiers de test supprimés
> - [ ] Export PDF réalisé (si demandé)

> [!note] penser à supprimer les snapshots