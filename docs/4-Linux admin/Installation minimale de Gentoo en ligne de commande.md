
> [!abstract] Objectif
> Installer Gentoo Linux de bout en bout en ligne de commande, sur une VM VirtualBox en UEFI, avec un système minimal (OpenRC, sans environnement de bureau).

## Environnement

| Élément | Valeur |
|---|---|
| Hyperviseur | VirtualBox |
| Nom de la VM | `Gentoo` |
| Mode de démarrage | UEFI (vérifié avec `ls /sys/firmware/efi`) |
| Disque | `/dev/sda` |
| Système de fichiers racine | XFS |
| Stage3 | `stage3-amd64-openrc-20261025T170057Z.tar.xz` |
| Profil Portage | `default/linux/amd64/23.0` (profil 1, sans desktop ni systemd) |

> [!warning] Vérifier le disque avant chaque commande destructive
> Les commandes `mkfs` effacent la partition visée. Relire le chemin avant de valider.

## 1. Partitionnement

Vérifier les disques :

```bash
lsblk
```

Schéma utilisé :

| Partition | Usage | Système de fichiers |
|---|---|---|
| `/dev/sda1` | ESP (`/efi`) | vfat |
| `/dev/sda2` | swap | swap |
| `/dev/sda3` | racine (`/`) | xfs |

## 2. Formatage et montage

![](attachments/Pasted%20image%2020261028101344.png)

```bash
mkfs.xfs -f -L gentoo-root /dev/sda3
mkswap /dev/sda2
mkfs.vfat -F 32 /dev/sda1

mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/sda1 /mnt/gentoo/efi
swapon /dev/sda2
```

Vérifier :

```bash
findmnt -R /mnt/gentoo
```

## 3. Stage3

```bash
cd /mnt/gentoo
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20261025T170057Z/stage3-amd64-openrc-20261025T170057Z.tar.xz
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20261025T170057Z/stage3-amd64-openrc-20261025T170057Z.tar.xz.sha256
grep 'stage3-amd64-openrc-20261025T170057Z.tar.xz$' stage3-amd64-openrc-20261025T170057Z.tar.xz.sha256 | sha256sum -c -
```

La vérification doit afficher `OK`. Sinon, ne pas continuer.

```bash
tar xpvf stage3-amd64-openrc-20261025T170057Z.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
rm -f stage3-amd64-openrc-20261025T170057Z.tar.xz*
ls /mnt/gentoo/bin/bash
```

## 4. Environnement chroot

![](attachments/Pasted%20image%2020261028095753.png)

```bash
mount -t proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev
cp -L /etc/resolv.conf /mnt/gentoo/etc/
chroot /mnt/gentoo /bin/bash
source /etc/profile
```

Vérifier que la racine est bien le disque installé :

```bash
findmnt /
```

## 5. Portage et profil

```bash
emerge-webrsync
eselect profile list
eselect profile set 1
```

Vérifier la configuration :

```bash
readlink -f /etc/portage/make.profile
emerge --info | grep '^USE='
```

`USE` ne doit contenir ni `X`, ni `gnome`, ni `systemd`.

Ajouter à `/etc/portage/make.conf` :

```bash
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
```

## 6. Fstab

```bash
cat > /etc/fstab << 'EOF'
UUID=9e21f375-8957-458b-abb7-d3507caa79e8  /      xfs   noatime     0 1
UUID=CA96-5B73                             /efi   vfat  umask=0077  0 2
UUID=fa85ac24-0fe9-471d-b41e-83971c897484  none   swap  sw          0 0
EOF
```

Les UUID viennent de `blkid /dev/sda1 /dev/sda2 /dev/sda3`. Ne pas utiliser de `$(blkid ...)` dans fstab : ce n'est pas du shell, la ligne est ignorée.

## 7. Noyau et initramfs

Autoriser le firmware (licence restrictive) et les USE nécessaires :

```bash
echo "sys-kernel/linux-firmware linux-fw-redistributable no-source-code" >> /etc/portage/package.license
mkdir -p /etc/portage/package.use
echo "sys-kernel/installkernel dracut" >> /etc/portage/package.use/kernel
echo "sys-kernel/gentoo-kernel-bin initramfs" >> /etc/portage/package.use/kernel
```

Vérifier le plan, puis installer :

```bash
emerge -pv sys-boot/grub sys-fs/xfsprogs sys-kernel/dracut sys-kernel/installkernel sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware
emerge -av sys-boot/grub sys-fs/xfsprogs sys-kernel/dracut sys-kernel/installkernel sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware
```

Vérifier les fichiers de démarrage :

```bash
ls /boot
```

Résultat attendu : `vmlinuz-6.18.57-gentoo-dist-bin` et `initramfs-6.18.57-gentoo-dist-bin.img`.

Vérifier que XFS est intégré au noyau :

```bash
grep CONFIG_XFS_FS /usr/src/linux-6.18.57-gentoo-dist-bin/.config
```

Résultat attendu : `CONFIG_XFS_FS=y`.

## 8. Bootloader (GRUB, UEFI)

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=gentoo
grub-mkconfig -o /boot/grub/grub.cfg
```

Vérifier :

```bash
ls /efi/EFI/gentoo
grep -E 'linux|initrd|root=' /boot/grub/grub.cfg
efibootmgr -v
```

Résultat attendu :
- `/efi/EFI/gentoo/grubx64.efi` présent ;
- une ligne `linux` pointant vers `/boot/vmlinuz-6.18.57-gentoo-dist-bin` avec `root=UUID=9e21f375-8957-458b-abb7-d3507caa79e8` ;
- une entrée `gentoo` dans `efibootmgr`.

## 9. Mot de passe root

```bash
passwd
```

Le mot de passe n'est pas noté dans ce document.

## 10. Premier démarrage

```bash
exit                     # sortir du chroot
umount -R /mnt/gentoo
reboot
```

Retirer l'ISO de la VM avant le redémarrage, sinon le live se relance.

**Résultat :** démarrage réussi sur GRUB, connexion en root.

![](attachments/Pasted%20image%2020261028120812.png)

![](attachments/Pasted%20image%2020261028121233.png)


## 11. Difficultés rencontrées

| Symptôme                                                         | Cause                                          | Solution                                                        |
| ---------------------------------------------------------------- | ---------------------------------------------- | --------------------------------------------------------------- |
| Stage3 desktop/systemd : conflits de dépendances, USE GNOME/X/Qt | Mauvais choix de stage3                        | Passer à la stage3 OpenRC minimale                              |
| `sbverify: command not found` lors de la compilation du noyau    | `SECUREBOOT_SIGN_CERT` défini, outil absent    | Abandon du noyau sans signature ; passage à `gentoo-kernel-bin` |
| fstab ne montait pas la racine                                   | `$(blkid ...)` n'est pas interprété dans fstab | UUID littéraux                                                  |
| Espace disque insuffisant                                        | Partition trop petite                          | Repartitionnement et réinstallation                             |
| Partition `/mnt/gentoo/efi` introuvable                          | Point de montage non créé                      | `mkdir -p` avant `mount`                                        |
| Licence firmware bloquant l'installation                         | `linux-firmware` masqué par sa licence         | Ajout dans `package.license`                                    |
| Kernel sans initramfs au premier essai                           | USE `initramfs` désactivé                      | Activation de `initramfs` et `dracut`                           |
|                                                                  |                                                |                                                                 |






