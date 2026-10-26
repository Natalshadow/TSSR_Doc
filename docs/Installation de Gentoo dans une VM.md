
> [!info] Compétences à ajouter au Kanban
> 
> - [ ] Lire le Handbook officiel Gentoo et s'y repérer (à faire)
> - [ ] Partitionner un disque en mode UEFI ou BIOS (à faire)
> - [ ] Télécharger et extraire une stage3 (à faire)
> - [ ] Entrer dans l'environnement avec chroot (à faire)
> - [ ] Comprendre les USE flags et `emerge` (à faire)
> - [ ] Compiler et installer un noyau (à faire)
> - [ ] Installer un bootloader (à faire)
> - [ ] Configurer le réseau et créer un utilisateur (à faire)

> [!abstract] Objectif 
> Installer Gentoo Linux dans une machine virtuelle, en notant chaque étape pour pouvoir la refaire sans aide.

## Environnement

| Élément                         | Valeur                                                                                                                                                                                                                                                                                          |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hyperviseur                     | Virtual Box                                                                                                                                                                                                                                                                                     |
| Mode de démarrage (UEFI / BIOS) | UEFI                                                                                                                                                                                                                                                                                            |
| Taille du disque virtuel        | 8 GB                                                                                                                                                                                                                                                                                            |
| RAM / vCPU                      | 4GB/2CPU                                                                                                                                                                                                                                                                                        |
| Version du Handbook suivie      | https://wiki.gentoo.org/wiki/Handbook:Main_Page<br>This page was last edited on 26 February 2026, at 16:23.                                                                                                                                                                                     |
| Support d'installation (ISO)    | [**Minimal Installation CD** openrc](https://distfiles.gentoo.org/releases/amd64/autobuilds/20261025T170057Z/install-amd64-minimal-20261025T170057Z.iso)  [](https://distfiles.gentoo.org/releases/amd64/autobuilds/20261025T170057Z/install-amd64-minimal-20261025T170057Z.iso.asc) 2026-10-25 |

## 1. Préparer la VM

- Créer la VM, choisir le mode de démarrage, attacher l'ISO.
- Notes :
- ![](attachments/Pasted%20image%2020261026113427.png)
- To gain access to the superuser account, in any terminal run:

`sudo -i`

`passwd`

New password: (Enter the new password)
Re-enter password: (Re-enter the password

To create a user account, first enter their credentials, followed by the account's password. The useradd and passwd commands are used for these tasks.

In the next example, a user called _larry_ is created and is added to the `users` and `wheel` groups:

`useradd -m -G users,wheel larry`

`passwd larry`

New password: (Enter larry's password)
Re-enter password: (Re-enter larry's password)

`sudo rc-service sshd start`

## 2. Démarrer et vérifier le réseau

- Vérifier la connectivité depuis le live (`ip a`, `ping`).
- Notes :
![](attachments/Pasted%20image%2020261026114425.png)

## 3. Partitionner et formater

- Schéma choisi :
- Commandes utilisées :
- Notes :
![](attachments/Pasted%20image%2020261026115435.png)

![](attachments/Pasted%20image%2020261026115809.png)


![](attachments/Pasted%20image%2020261026120007.png)

![](attachments/Pasted%20image%2020261026120040.png)

Link pour le stagefile

![](attachments/Pasted%20image%2020261026120349.png)
## 4. Stage3 et chroot

- Stage3 choisie (profil, init) :
- Notes :

## 5. Configuration de base

- `make.conf`, miroirs, locale, fuseau horaire :
- Notes :

## 6. Noyau

- Méthode (genkernel, configuration manuelle, dist-kernel) :
- Notes :

## 7. Bootloader

- Outil installé et configuration :
- Notes :

## 8. Réseau, utilisateur et premier démarrage

- Configuration réseau au démarrage :
- Utilisateur créé, sudo ou doas :
- Notes :

## 9. Difficultés rencontrées

|Symptôme|Cause|Solution|
|---|---|---|
||||

## 10. Ce que je retiens

---

> [!note] Avant de publier
> 
> - [ ] Aucun mot de passe ni clé dans le document
> - [ ] Commandes exactes copiées, pas résumées
> - [ ] Le Handbook et sa version sont cités