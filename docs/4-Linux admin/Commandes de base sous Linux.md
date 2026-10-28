

---

## 1. Navigation et fichiers

### 1.1 Afficher le répertoire courant

**Question :** comment afficher en ligne de commande le répertoire courant ?

**Réponse :**
`pwd`


### 1.2 Se déplacer dans un répertoire

**Question :** comment se déplacer dans un répertoire (le home, par exemple) ?


**Réponse :**

`cd - Retour sur /`
`cd <path> - accéder à un chemin`
`cd ./path - accéder à un chemin à partir de pwd`

### 1.3 Créer un fichier

**Question :** comment créer un fichier ?



**Réponse :**
touch

### 1.4 Éditer un fichier avec nano

**Question :** comment éditer un fichier avec nano ?



**Réponse :**
nano "pathtofile"
ctrl O pour save
ctrl X pour quit

### 1.5 Lister le contenu d'un fichier

**Question :** comment lister le contenu d'un fichier ?

**Réponse :**
cat pour lire un fichier dans le terminal
ou nano si on doit l'éditer
ls pour lister le contenu d'un directory
### 1.6 Créer un répertoire

**Question :** comment créer un répertoire ?


**Réponse :**
mkdir
### 1.7 Supprimer un répertoire vide

**Question :** comment supprimer un répertoire vide ?


**Réponse :**

rmdir

### 1.8 Supprimer un répertoire contenant un fichier

**Question :** comment supprimer un répertoire contenant un fichier ?



**Réponse :**
rm -rf /chemin

---

## 2. Gestion des paquets



### 2.1 Mettre à jour la liste des paquets disponibles

**Question :** comment mettre à jour la liste des paquets disponibles dans les dépôts ?



**Réponse :**
sudo apt update
sudo dnf update
sudo pacman -Syu

### 2.2 Mettre à jour les paquets installés

**Question :** comment mettre à jour les paquets qui ne le sont pas ?



**Réponse :**

sudo apt upgrade
sudo dnf upgrade
sudo pacman -Syu

### 2.3 Chercher un paquet

**Question :** comment chercher un paquet sur les dépôts ?

sudo apt search
sudo dnf search
sudo pacman -Ss

**Réponse :**

### 2.4 Installer un paquet

**Question :** comment installer un paquet ?

**Réponse :**

sudo apt install
sudo dnf install
sudo pacman -S
### 2.5 Installer plusieurs paquets en même temps

**Question :** comment installer plusieurs paquets en même temps ?

**Réponse :**

simplement écrire la liste de noms à la suite
sudo pacman -S firefox chrome truc bidule machin

### 2.6 Supprimer un paquet

**Question :** comment supprimer un paquet ?


**Réponse :**

sudo apt remove
sudo pacman -Rs

---

## 3. Utilisateurs et groupes

### 3.1 Où sont stockés les utilisateurs

**Question :** dans quel fichier sont stockés les utilisateurs ?


**Réponse :**
     /etc/passwd
         User account information.

### 3.2 Lister les utilisateurs

**Question :** comment lister les utilisateurs ?

Get list of all groups:

      getent group

  See the members of a group:

      getent group group_name

  Get list of all services:

      getent services

  Find a username by UID:

      getent passwd 1000

  Perform a reverse DNS lookup:

      getent hosts host

**Réponse :**

### 3.3 Où sont stockés les groupes

**Question :** dans quel fichier sont stockés les groupes d'utilisateurs ?



**Réponse :**

❯ man 5 group
group(5)                                                                   File Formats Manual                                                                  group(5)

NAME
     group - user group file

DESCRIPTION
     The /etc/group file is a text file that defines the groups on the system.  There is one entry per line, with the following format:

         group_name:password:GID:user_list

     The fields are as follows:

     group_name
            the name of the group.

     password
            the (encrypted) group password.  If this field is empty, no password is needed.

     GID    the numeric group ID.

     user_list
            a list of the usernames that are members of this group, separated by commas.

FILES
     /etc/group

BUGS
     As the 4.2BSD initgroups(3) man page says: no one seems to keep /etc/group up-to-date.

SEE ALSO
     chgrp(1), gpasswd(1), groups(1), login(1), newgrp(1), sg(1), getgrent(3), getgrnam(3), gshadow(5), passwd(5), vigr(8)

Linux man-pages 6.19                                                           2025-05-17                                                                       group(5)
### 3.4 Créer un utilisateur

**Question :** comment créer un utilisateur ?


**Réponse :**

  Create a new user:

      sudo useradd username

  Create a new user with the specified user ID:

      sudo useradd --uid user_id username

  Create a new user with the specified shell:

      sudo useradd --shell path/to/shell username

  Create a new user belonging to additional groups (mind the lack of whitespace):

      sudo useradd --groups group1,group2,... username

  Create a new user with the default home directory:

      sudo useradd --create-home username

  Create a new user with the home directory filled by template directory files:

      sudo useradd --skel path/to/template_directory --create-home username

  Create a new system user without the home directory:

      sudo useradd --system username
### 3.5 Assigner un mot de passe

**Question :** comment lui assigner un mot de passe ?

**Réponse :**
passwd
### 3.6 Supprimer un utilisateur

**Question :** comment supprimer un utilisateur ?



**Réponse :**

  Create a new user:

      sudo useradd username

  Create a new user with the specified user ID:

      sudo useradd --uid user_id username

  Create a new user with the specified shell:

      sudo useradd --shell path/to/shell username

  Create a new user belonging to additional groups (mind the lack of whitespace):

      sudo useradd --groups group1,group2,... username

  Create a new user with the default home directory:

      sudo useradd --create-home username

  Create a new user with the home directory filled by template directory files:

      sudo useradd --skel path/to/template_directory --create-home username

  Create a new system user without the home directory:

      sudo useradd --system username
### 3.7 Modifier les options d'un utilisateur

**Question :** comment modifier les options d'un utilisateur ?

**Réponse :**

bash

```bash
usermod -s /bin/bash alice     # change le shell
usermod -l nouveau alice       # renomme le compte
usermod -L alice               # verrouille le compte
usermod -U alice               # déverrouille le compte
usermod -aG audio alice        # ajoute au groupe audio (voir 3.11)
```

### 3.8 Voir les groupes d'un utilisateur

**Question :** comment voir à quel groupe appartient un utilisateur ?

**Réponse :**

bash

```bash
groups alice    # noms des groupes
id alice        # UID, GID principal et tous les groupes, avec leurs numéros
```

`groups` donne seulement les noms. `id` donne aussi les numéros, utiles pour vérifier.

### 3.9 Créer un groupe

**Question :** comment créer un groupe ?

**Réponse :**

bash

```bash
groupadd projet
```

### 3.10 Mettre un utilisateur dans un groupe

**Question :** comment mettre un utilisateur dans un groupe ?

**Réponse :**

bash

```bash
gpasswd -a alice projet
```

`gpasswd -a` ajoute l'utilisateur au groupe. Le résultat est le même avec `usermod -aG projet alice`.

### 3.11 Ajouter sans perdre les groupes existants

**Question :** comment ajouter un utilisateur à un groupe, tout en le gardant dans les groupes qu'il a déjà ?

**Réponse :**

bash

```bash
id alice                       # avant : noter les groupes actuels
usermod -aG projet alice       # -a ajoute, sans -a les groupes sont remplacés
id alice                       # après : les anciens groupes sont toujours là
```

L'option `-a` (append) est indispensable avec `-G`. Sans elle, `usermod -G projet alice` retire l'utilisateur de tous les autres groupes secondaires et ne garde que `projet`.

---

## 4. Répertoires à la racine du système

**Question :** décris l'utilité des répertoires à la racine du système.

**Réponse :** 

|Répertoire|Utilité|
|---|---|
|`/bin`|Commandes essentielles accessibles à tous les utilisateurs, même avant le montage des autres partitions (`ls`, `cp`, `cat`)|
|`/boot`|Noyau Linux, initramfs et fichiers du bootloader|
|`/dev`|Fichiers spéciaux qui représentent les périphériques (`/dev/sda`, `/dev/null`)|
|`/etc`|Fichiers de configuration du système et des services|
|`/home`|Répertoires personnels des utilisateurs|
|`/lib`|Bibliothèques partagées nécessaires à `/bin` et `/sbin`|
|`/media`|Points de montage automatiques des supports amovibles (clé USB, CD)|
|`/mnt`|Point de montage temporaire, choisi manuellement par l'administrateur|
|`/opt`|Logiciels tiers installés hors gestionnaire de paquets|
|`/proc`|Système de fichiers virtuel donnant accès aux informations des processus et du noyau|
|`/root`|Répertoire personnel de l'utilisateur `root` (séparé de `/home` pour rester accessible en cas de problème)|
|`/sbin`|Commandes d'administration système (`fdisk`, `ip`)|
|`/srv`|Données servies par le système (sites web, FTP)|
|`/sys`|Système de fichiers virtuel donnant accès aux périphériques et pilotes du noyau (sysfs)|
|`/tmp`|Fichiers temporaires, souvent vidés au démarrage|
|`/usr`|Programmes, bibliothèques et documentation pour les utilisateurs (`/usr/bin`, `/usr/lib`, `/usr/local`)|
|`/var`|Données qui changent pendant l'exécution : journaux, files d'attente, caches, bases de données|
