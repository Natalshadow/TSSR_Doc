---

## title: TP - Organiser les utilisateurs, groupes et ordinateurs Active Directory tags: [tssr, windows-server, active-directory, ou, gpo, imprimante, tp] date: auteur: trigramme: MEN statut: en-cours

# TP - Organiser les utilisateurs, groupes et ordinateurs Active Directory

> [!abstract] Contexte Le domaine Active Directory est opérationnel. Il faut maintenant l'organiser : arborescence d'OU, utilisateurs, groupes, classement de l'ordinateur du domaine, puis gérer le cycle de vie des comptes (mot de passe oublié, départ, arrivée) et publier une imprimante partagée.

> [!info] Comment utiliser ce document
> 
> - Chaque section contient un espace **Réponse / Captures** à compléter.
> - Les blocs `> [!tip]` sont des pistes de guidage : à supprimer dans la version rendue (les `> [!warning]` aussi).
> - Place les captures dans `attachments/` et insère-les avec `![[nom-capture.png]]`.
> - **Ne mets jamais de mot de passe en clair** dans ce document ni dans une capture visible. Écris seulement « mot de passe défini » ou « mot de passe temporaire conforme à la consigne ».

---

## Sommaire

- [[#1. Construire l'arborescence d'OU]]
- [[#2. Créer les utilisateurs]]
- [[#3. Créer les groupes globaux de sécurité]]
- [[#4. Classer l'ordinateur du domaine]]
- [[#5. Valider avec une ouverture de session]]
- [[#6. Cycle de vie et sécurité des comptes]]
- [[#7. Partage d'imprimante]]
- [[#8. Récapitulatif]]
- [[#9. Conclusion et difficultés rencontrées]]

---

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur AD / DNS / DHCP|`srv-win-men-01` (`192.168.100.10`)|
|Poste client|`CLI-WIN-MEN-01`|
|Console utilisée|_Utilisateurs et ordinateurs Active Directory_ (ADUC)|

---
> [!note] Création d'une snapshot initiale
## 1. Construire l'arborescence d'OU

**Structure à créer**

```
TSSR-MEN.LAB
├── GROUPES
│   ├── GG
│   └── GDL
├── ORDINATEURS
│   ├── SERVEURS
│   └── POSTES CLIENTS
└── UTILISATEURS
    ├── ADMINISTRATIF
    ├── DIRECTION
    ├── COMPTABILITE
    ├── INFORMATIQUE
    ├── RH
    └── PRODUCTION
```

> [!tip] Guidage
> 
> - Crée d'abord les OU de premier niveau (`GROUPES`, `ORDINATEURS`, `UTILISATEURS`), puis leurs sous-OU. Une OU se crée **dans** l'élément sélectionné : vérifie le parent avant de valider.
> - Respecte exactement les noms et la casse de l'énoncé (y compris l'espace dans `POSTES CLIENTS`).
> - Pose-toi la question : pourquoi une OU plutôt qu'un simple conteneur (`Users`, `Computers`) ? Qu'est-ce qu'une OU permet que le conteneur par défaut ne permet pas ?

**Capture(s)**

![](attachments/Pasted%20image%2020261007093652.png)

### OU temporaire `PROD`

**Consigne :** créer une OU temporaire nommée `PROD`, puis la supprimer. Si la protection contre la suppression accidentelle empêche l'opération, l'identifier et la retirer **uniquement pour cette OU**.

> [!tip] Guidage
> 
> - Note le **message d'erreur exact** lors de la première tentative de suppression.
> - Les propriétés d'une OU n'affichent pas tous leurs onglets par défaut : regarde dans les options d'affichage de la console.
> - Vérifie que les **autres** OU restent protégées (propriété `ProtectedFromAccidentalDeletion`).
> - Pourquoi cette protection est-elle activée par défaut à la création d'une OU ?

**Capture(s)**

![](attachments/Pasted%20image%2020261007093735.png) ![](attachments/Pasted%20image%2020261007093729.png) ![](attachments/Pasted%20image%2020261007093745.png) ![[capture-1-prod-supprimee.png]]

**Réponse (message d'erreur, option identifiée, raison d'être de la protection)**
>[!note] 
>Je vais dans propriétés de PROD pour voir s'il y a un bouton d'escalation admin, mais il n'y a pas.
>Petite recherche internet et visiblement il faut activer les features avancées dans les menus de la console.
>

![](attachments/Pasted%20image%2020261007094259.png)
![](attachments/Pasted%20image%2020261007094247.png)

A partir de là ça fonctionne.

---

## 2. Créer les utilisateurs

> [!note] Le mot de passe des utilisateurs dans cet exercice sera `Tssr2026`

| Nom              | Login        | OU            | Créé |
| ---------------- | ------------ | ------------- | ---- |
| Tony STARK       | `t.stark`    | ADMINISTRATIF | Oui  |
| Steve ROGERS     | `s.rogers`   | DIRECTION     | Oui  |
| Natasha ROMANOFF | `n.romanoff` | COMPTABILITE  | Oui  |
| Bruce BANNER     | `b.banner`   | INFORMATIQUE  | Oui  |
| Thor ODINSON     | `t.odinson`  | RH            | Oui  |
| Clint BARTON     | `c.barton`   | PRODUCTION    | Oui  |




> [!tip] Guidage
> 
> - Dans l'assistant, distingue le **nom complet**, le **nom d'ouverture de session** (login) et le suffixe de domaine affiché à côté. Quel est le suffixe UPN proposé ?
> - Le mot de passe doit respecter la **stratégie de mots de passe** du domaine. Si l'assistant refuse, note le message : il te dit ce que la stratégie exige.
> - Regarde les cases proposées sous le mot de passe (changement obligatoire à la prochaine ouverture de session, expiration…). Note celles que tu coches et pourquoi.
> - Clique-droit dans une OU → _Nouveau_ → _Utilisateur_ te place directement dans la bonne OU. Vérifie à la fin que chaque compte est dans l'OU attendue.

**Options de mot de passe choisies**

| Option                                            | Choix     |
| ------------------------------------------------- | --------- |
| Changement obligatoire à la prochaine session     | Non (Lab) |
| L'utilisateur ne peut pas changer le mot de passe | Non (Lab) |
| Le mot de passe n'expire jamais                   | Oui (Lab) |
| Compte désactivé                                  | Non       |

**Capture(s)**

![](attachments/Pasted%20image%2020261007094610.png)
![](attachments/Pasted%20image%2020261007094627.png)
![](attachments/Pasted%20image%2020261007095217.png)

**Commentaires**

---

## 3. Créer les groupes globaux de sécurité

| Groupe             | Membre attendu   | Créé | Membre ajouté |
| ------------------ | ---------------- | ---- | ------------- |
| `GG-ADMINISTRATIF` | Tony STARK       | Oui  | Oui           |
| `GG-DIRECTION`     | Steve ROGERS     | Oui  | Oui           |
| `GG-COMPTABILITE`  | Natasha ROMANOFF | Oui  | Oui           |
| `GG-INFORMATIQUE`  | Bruce BANNER     | Oui  | Oui           |
| `GG-RH`            | Thor ODINSON     | Oui  | Oui           |
| `GG-PRODUCTION`    | Clint BARTON     | Oui  | Oui           |

**Consigne :** stocker les groupes dans l'OU `GROUPES/GG`.

> [!tip] Guidage
> 
> - Dans l'assistant, vérifie les deux listes : **étendue** (domaine local, globale, universelle) et **type** (sécurité, distribution). Ici : globale + sécurité.
> - Crée chaque groupe **dans l'OU `GG`** (clic droit sur `GG` → _Nouveau_ → _Groupe_), sinon tu devras les déplacer.
> - Les membres s'ajoutent soit depuis le groupe (onglet _Membres_), soit depuis l'utilisateur (onglet _Membre de_). Précise la méthode utilisée.
> - Réfléchis au sens du nom : que signifie **GG** ici, et à quoi servira plus tard la sous-OU `GDL` ? (Indice : le principe de gestion « A G DL P ».)

**Capture(s)**

![](attachments/Pasted%20image%2020261007101028.png) ![](attachments/Pasted%20image%2020261007100731.png)

**Commentaires (étendue et type choisis, rôle de GG et GDL)**

>[!note] snapshot part 3 done

---

## 4. Classer l'ordinateur du domaine

**Consigne :** déplacer `CLI-WIN-MEN-01` dans l'OU `ORDINATEURS`.

> [!tip] Guidage
> 
> - Repère d'abord **où se trouve** l'ordinateur actuellement (conteneur par défaut). Capture l'état _avant_.
> - Deux méthodes possibles : clic droit → _Déplacer…_, ou glisser-déposer. Précise celle utilisée.
> - L'arborescence contient aussi une sous-OU `POSTES CLIENTS`. L'énoncé demande `ORDINATEURS` : respecte-le, et note si une sous-OU serait plus logique pour un poste client, et pourquoi.
> - Pourquoi classer un ordinateur dans une OU ? (Indice : application ciblée de stratégies de groupe.)

**Avant**

![](attachments/Pasted%20image%2020261007101304.png)

**Après**

![](attachments/Pasted%20image%2020261007101316.png)

**Commentaires**

Je l'ai placé dans POSTES CLIENT parce que c'est ce qui serait logique.

---

## 5. Valider avec une ouverture de session

**Étapes**

1. Choisir un utilisateur créé.
2. Ouvrir une session sur le client.
3. Vérifier que le domaine authentifie correctement l'utilisateur.
4. Vérifier l'appartenance au bon groupe.

| Élément                    | Valeur           |
| -------------------------- | ---------------- |
| Utilisateur testé          | t.stark          |
| Identifiant saisi (format) | TSSR-MEN\t.stark |
| Session ouverte ?          | Oui              |
| Groupe attendu             | Oui              |

> [!tip] Guidage
> 
> - Sur l'écran de connexion, précise **comment** tu désignes le compte : `NETBIOS\login` ou `login@domaine` ? Les deux sont-ils acceptés ?
> - Si le changement de mot de passe était coché à la création, la première connexion t'y oblige : note-le, c'est une observation utile.
> - Pour prouver l'authentification par le domaine : `whoami` (affiche `DOMAINE\utilisateur`) et `echo %USERDOMAIN%` / `echo %LOGONSERVER%`.
> - Pour prouver l'appartenance au groupe : `whoami /groups`. Cherche la ligne du `GG-...` attendu.
> - Les groupes sont lus **à l'ouverture de session** : un groupe ajouté pendant que l'utilisateur est connecté n'apparaît qu'à la reconnexion.

```powershell
whoami
echo %LOGONSERVER%
whoami /groups
```

**Capture(s)**
``` powershell
PS C:\WINDOWS\system32> whoami
tssr-men\t.stark
PS C:\WINDOWS\system32> echo %LOGONSERVER%
%LOGONSERVER%
PS C:\WINDOWS\system32> whoami /groups

Informations de groupe
----------------------

Nom du groupe                                         Type              SID                                            Attributs
===================================================== ================= ============================================== ====================================================
Tout le monde                                         Groupe bien connu S-1-1-0                                        Groupe obligatoire, Activé par défaut, Groupe activé
BUILTIN\Utilisateurs                                  Alias             S-1-5-32-545                                   Groupe obligatoire, Activé par défaut, Groupe activé
AUTORITE NT\INTERACTIF                                Groupe bien connu S-1-5-4                                        Groupe obligatoire, Activé par défaut, Groupe activé
OUVERTURE DE SESSION DE CONSOLE                       Groupe bien connu S-1-2-1                                        Groupe obligatoire, Activé par défaut, Groupe activé
AUTORITE NT\Utilisateurs authentifiés                 Groupe bien connu S-1-5-11                                       Groupe obligatoire, Activé par défaut, Groupe activé
AUTORITE NT\Cette organisation                        Groupe bien connu S-1-5-15                                       Groupe obligatoire, Activé par défaut, Groupe activé
LOCAL                                                 Groupe bien connu S-1-2-0                                        Groupe obligatoire, Activé par défaut, Groupe activé
TSSR-MEN\GG-ADMINISTRATIF                             Groupe            S-1-5-21-3751794092-3013587998-2465217153-1113 Groupe obligatoire, Activé par défaut, Groupe activé
Identité déclarée par une autorité d’authentification Groupe bien connu S-1-18-1                                       Groupe obligatoire, Activé par défaut, Groupe activé
Étiquette obligatoire\Niveau obligatoire moyen        Nom               S-1-16-8192                                     
PS C:\WINDOWS\system32>
```
![](attachments/Pasted%20image%2020261007101642.png)  

**Commentaires**

---

## 6. Cycle de vie et sécurité des comptes

### 6.1 Mot de passe oublié (Thor ODINSON)

**Contexte :** l'utilisateur Thor ODINSON ne peut plus ouvrir sa session.

**Étapes**

1. Utiliser la fonction de recherche AD pour retrouver son compte.
2. Réinitialiser son mot de passe avec une valeur temporaire conforme à la consigne du formateur.
3. Forcer le changement du mot de passe à la prochaine ouverture de session.
4. Tester la connexion.

> [!tip] Guidage
> 
> - Pour la recherche : clic droit sur le domaine → _Rechercher…_ (ou l'icône de loupe). Précise sur quel critère tu cherches (nom, login) et comment tu as ouvert le compte depuis les résultats.
> - La réinitialisation se fait par clic droit sur le compte. Observe les deux cases proposées : laquelle correspond à l'étape 3 ?
> - Note la différence entre **réinitialiser** et **déverrouiller** un compte : quel est le symptôme de chacun ?
> - Au test, décris ce que voit l'utilisateur : quel écran apparaît, que lui demande-t-on ?

**Capture(s)**

![](attachments/Pasted%20image%2020261007102149.png) ![](attachments/Pasted%20image%2020261007102209.png)  

**Commentaires**

---

### 6.2 Départ collaborateur (Tony STARK)

**Contexte :** Tony STARK quitte définitivement l'entreprise. Son départ doit être traité **sans supprimer** son compte immédiatement.

> [!warning] Incohérence apparente de l'énoncé L'énoncé le présente comme « membre du service RH », alors que dans la partie 2 il est créé dans l'OU `ADMINISTRATIF` et sera membre de `GG-ADMINISTRATIF` (le groupe `GG-RH` contient Thor ODINSON). Décide comment tu traites cette différence (suivre les groupes réellement attribués, ou demander au formateur) et **écris-le** ici.

**Décision / hypothèse retenue :** Il reste dans le service admin

**Étapes**

1. Rechercher le compte dans Active Directory.
2. Désactiver son compte utilisateur.
3. Retirer le compte des groupes liés à son activité professionnelle.
4. Créer une OU `Utilisateurs Désactivés` sous `UTILISATEURS`.
5. Déplacer le compte utilisateur dans cette OU.
6. Ajouter dans la description du compte : `Compte désactivé - Départ de l'entreprise - [DATE]`.
7. Vérifier qu'il n'est plus possible d'ouvrir une session avec ce compte.

> [!tip] Guidage
> 
> - Avant de modifier quoi que ce soit, capture l'**état initial** : OU, groupes (onglet _Membre de_), description.
> - Désactiver un compte et le supprimer n'ont pas le même effet. Pourquoi garde-t-on le compte quelques semaines ? (Pense aux fichiers, aux droits, à l'audit, à un éventuel retour.)
> - Un compte garde toujours au moins un groupe : observe lequel ne peut pas être retiré de la même manière, et pourquoi.
> - Fais attention au **ordre des étapes** : après le déplacement, l'OU d'origine ne contient plus le compte. Pense à vérifier le résultat à la fin.
> - Remplace `[DATE]` par la date réelle. Quel format as-tu choisi ?
> - Pour l'étape 7, capture le **message exact** affiché sur l'écran de connexion du client. Décris la différence avec un mot de passe incorrect.

| Étape                              | Fait | Preuve |
| ---------------------------------- | ---- | ------ |
| Recherche du compte                | Oui  |        |
| Compte désactivé                   | Oui  |        |
| Groupes retirés                    | Oui  |        |
| OU `Utilisateurs Désactivés` créée | Oui  |        |
| Compte déplacé                     | Oui  |        |
| Description renseignée             | Oui  |        |
| Connexion refusée                  | ☐    |        |
>[!note] Le groupe "everyone" est toujours actif

**Capture(s)**

![](attachments/Pasted%20image%2020261007102444.png)    ![](attachments/Pasted%20image%2020261007102847.png) ![](attachments/Pasted%20image%2020261007102835.png)

**Commentaires**

---

### 6.3 Arrivée collaborateur Informatique (Nick FURRY)

**Contexte :** Nick FURRY rejoint l'équipe informatique. Il doit posséder un compte classique pour ses activités quotidiennes **et** un compte distinct pour l'administration.

**Étapes**

1. Créer son compte utilisateur `n.furry`, le placer dans l'OU `INFORMATIQUE` et dans le groupe `GG-INFORMATIQUE`.
2. Créer son compte administrateur `adm.n.furry`, le placer dans l'OU `COMPTES-ADMIN` (à créer) et dans le groupe `GG-ADMIN-IT` (à créer).
3. Se documenter sur le **Tiering AD**.

> [!warning] Nom de l'OU Selon la source, le nom s'écrit `COMPTES-ADMIN` ou `COMPTESADMIN` (césure en fin de ligne dans l'énoncé). Vérifie l'énoncé d'origine ou demande au formateur, puis reste cohérent.

> [!tip] Guidage
> 
> - **Où** créer `COMPTES-ADMIN` et `GG-ADMIN-IT` ? L'énoncé ne le précise pas : décide (sous `UTILISATEURS` ? à la racine ? `GG-ADMIN-IT` dans `GROUPES/GG` comme les autres ?) et **justifie ton choix** par rapport à l'arborescence existante.
> - Les deux comptes de Nick sont **deux objets distincts** : noms, logins et mots de passe différents. Pourquoi ne pas lui donner un seul compte avec tous les droits ?
> - Pour l'instant `adm.n.furry` n'a de droits que ceux de son groupe : note que **créer le groupe ne donne encore aucun privilège** (c'est une autre étape).
> - Vérifie les deux comptes à la fin : OU, groupes, et que les deux n'ont pas le même mot de passe.

| Compte        | OU              | Groupe            | Créé |
| ------------- | --------------- | ----------------- | ---- |
| `n.furry`     | `INFORMATIQUE`  | `GG-INFORMATIQUE` | Oui  |
| `adm.n.furry` | `COMPTES-ADMIN` | `GG-ADMIN-IT`     | ☐    |

**Capture(s)**

![](attachments/Pasted%20image%2020261007103052.png) ![](attachments/Pasted%20image%2020261007103509.png) ![](attachments/Pasted%20image%2020261007103518.png) 

**Choix d'emplacement et justification**

#### Tiering AD — notes personnelles

> [!tip] Guidage L'énoncé renvoie à un article « Sécuriser Active Directory : comprendre le Tiering Model ». Rédige ta synthèse **avec tes mots**, sans copier le texte. Quelques questions pour structurer :
> 
> - Qu'est-ce qu'un **Tier 0**, un **Tier 1**, un **Tier 2** ? Que contient chacun (exemples concrets dans ton lab) ?
> - Quelle règle empêche un compte d'un niveau élevé de se connecter à un niveau inférieur, et quel risque cela évite-t-il (vol d'identifiants, mouvement latéral) ?
> - Où se situent, dans ton lab, le contrôleur de domaine, le poste client `CLI-WIN-MEN-01` et le compte `adm.n.furry` ?
> - Pourquoi Nick a-t-il besoin de **deux** comptes ? Quel lien avec le tiering ?

**Synthèse**

**Source(s) consultée(s)**

---

## 7. Partage d'imprimante

**Paramètres de l'imprimante**

|Paramètre|Valeur|
|---|---|
|Nom|`IMP-MEN-01`|
|Type|Imprimante locale|
|Pilote|Generic / Text Only|
|Port|Paramètres par défaut|

**Étapes**

1. Créer l'imprimante manuellement avec les paramètres ci-dessus. **Ne pas encore la partager.**
2. Ouvrir les propriétés de l'imprimante.
3. Activer le partage.
4. Publier l'imprimante dans l'annuaire.
5. Créer une OU `IMPRIMANTES` et y déplacer l'imprimante.
6. Configurer l'imprimante sur le client.

> [!tip] Guidage
> 
> - Précise **sur quelle machine** tu crées l'imprimante (serveur ou client) et par quel chemin (_Périphériques et imprimantes_, _Paramètres_, console de gestion de l'impression).
> - Pour un pilote _Generic / Text Only_, regarde d'abord le **constructeur** dans la liste avant le modèle.
> - Le partage et la publication se règlent dans les propriétés de l'imprimante : repère l'onglet qui regroupe les deux. Note le **nom de partage** proposé et s'il change quelque chose pour le client.
> - Pour l'étape 5, l'objet imprimante publié n'apparaît pas toujours dans la console : essaie l'affichage avancé, et cherche-le plutôt sous l'objet **ordinateur** qui héberge l'imprimante. Note où tu l'as trouvé.
> - Pour l'étape 6, deux approches existent : par le **chemin réseau** (`\\serveur\partage`) ou par **recherche dans l'annuaire**. Teste-les si possible et indique celle qui a fonctionné, avec la raison de l'autre si elle échoue.
> - Distingue bien **partager** (rendre l'imprimante accessible en réseau) et **publier** (la rendre découvrable dans l'annuaire).

**Capture(s)**

![[capture-7-creation.png]] ![[capture-7-proprietes-avant-partage.png]] ![[capture-7-partage-publication.png]] ![[capture-7-ou-imprimantes.png]] ![[capture-7-client.png]]

**Commentaires (machine utilisée, emplacement de l'objet dans l'annuaire, méthode côté client)**

---

## 8. Récapitulatif

> [!check] À valider avant de rendre le TP Coche chaque point uniquement si tu peux le **prouver** par une capture ou une commande.

|Vérification|Validé|Preuve|
|---|---|---|
|Arborescence d'OU conforme|☐|[[#1. Construire l'arborescence d'OU]]|
|OU `PROD` créée puis supprimée, protection retirée uniquement sur cette OU|☐|[[#1. Construire l'arborescence d'OU]]|
|Six utilisateurs créés dans les bonnes OU|☐|[[#2. Créer les utilisateurs]]|
|Six groupes `GG-` créés dans `GROUPES/GG` avec leurs membres|☐|[[#3. Créer les groupes globaux de sécurité]]|
|`CLI-WIN-MEN-01` déplacé dans `ORDINATEURS`|☐|[[#4. Classer l'ordinateur du domaine]]|
|Session ouverte avec un compte du domaine, groupe vérifié|☐|[[#5. Valider avec une ouverture de session]]|
|Mot de passe de Thor ODINSON réinitialisé, changement forcé|☐|[[#6.1 Mot de passe oublié (Thor ODINSON)]]|
|Départ de Tony STARK traité (désactivé, groupes, OU, description)|☐|[[#6.2 Départ collaborateur (Tony STARK)]]|
|Deux comptes Nick FURRY créés (OU et groupes)|☐|[[#6.3 Arrivée collaborateur Informatique (Nick FURRY)]]|
|Synthèse sur le Tiering AD rédigée|☐|[[#6.3 Arrivée collaborateur Informatique (Nick FURRY)]]|
|Imprimante créée, partagée, publiée, déplacée dans `IMPRIMANTES` et utilisable sur le client|☐|[[#7. Partage d'imprimante]]|

### Arborescence finale

Capture de l'arborescence complète en fin de TP (OU supplémentaires incluses : `Utilisateurs Désactivés`, `COMPTES-ADMIN`, `IMPRIMANTES`).

![[capture-8-arborescence-finale.png]]

---

## 9. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

### Commandes utiles (aide-mémoire)

```powershell
# Vérifications côté client
whoami
whoami /groups
echo %LOGONSERVER%

# Équivalents PowerShell côté serveur (module ActiveDirectory)
Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName
Get-ADUser -Identity t.odinson -Properties Description, Enabled, MemberOf
Get-ADGroupMember -Identity GG-RH
Set-ADAccountPassword -Identity t.odinson -Reset
Set-ADUser -Identity t.odinson -ChangePasswordAtLogon $true
Disable-ADAccount -Identity t.stark
Move-ADObject -Identity "<DN du compte>" -TargetPath "<DN de l'OU cible>"
```

---

> [!note] Rendu
> 
> - [ ] Aucun mot de passe visible (texte ou capture)
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Incohérences de l'énoncé (Tony STARK, nom `COMPTES-ADMIN`) tranchées et notées
> - [ ] Export PDF réalisé (si demandé)

> [!note] penser à supprimer les snapshots


