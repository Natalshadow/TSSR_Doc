
> [!abstract] Objectif 
> Installer Gentoo de bout en bout en ligne de commande, dans une VM, avec le minimum de paquets. Chaque commande est copiée telle qu'elle a été exécutée.

## Environnement

|Élément|Valeur|
|---|---|
|Hyperviseur|VirtualBox|
|Nom de la VM|`Gentoo`|
|Mode de démarrage (UEFI / BIOS)||
|Disque (chemin, ex. `/dev/vda`)||
|Version du Handbook suivie||
|Stage3 utilisée||

> [!warning] Vérifier avant chaque commande destructive Les commandes de partitionnement et de formatage effacent le disque choisi. Relis le chemin du disque avant de valider. Les commandes ci-dessous sont des repères : la référence reste le Handbook, dans la version que tu suis.

## 1. Partitionnement

```bash
# Lister les disques pour confirmer le chemin
lsblk
```

Schéma prévu (UEFI) :

| Partition | Taille | Type  | Usage       |
| --------- | ------ | ----- | ----------- |
| `/dev/…1` | 4      | EFI   | `/boot/efi` |
| `/dev/…2` | 2      | swap  | swap        |
| `/dev/…3` | 50     | Linux | `/`         |

```bash
# Formatage (adapter les chemins)
mkfs.vfat -F 32 /dev/vda1
mkswap /dev/vda2
mkfs.ext4 /dev/vda3

# Montage
mount /dev/vda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/vda1 /mnt/gentoo/boot/efi
swapon /dev/vda2
```

**Notes :**

## 2. Stage3

```bash
cd /mnt/gentoo
# Télécharger la stage3 depuis le miroir (URL choisie dans le Handbook)
wget [<URL_STAGE3>](https://distfiles.gentoo.org/releases/amd64/autobuilds/20261025T170057Z/stage3-amd64-openrc-20261025T170057Z.tar.xz)
# Vérifier la somme de contrôle avant d'extraire, nom placeholder parce que j'en ai essayé plusieurs
sha256sum stage3-*.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
```

**Somme attendue / obtenue :**

## 3. Environnement chroot

```bash
# Copier la configuration DNS et monter les systèmes de fichiers virtuels
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

**Notes :**

## 4. Portage et profil

```bash
emerge-webrsync
eselect profile list
eselect profile set <NUMERO_DU_PROFIL>
```
1 dans mon cas

`make.conf` :

```bash
nano /etc/portage/make.conf
```

**Valeurs choisies** (`MAKEOPTS`, `USE`, `COMMON_FLAGS`) :

## 5. Locale et fuseau horaire

```bash
echo "Europe/Paris" > /etc/timezone
emerge --config sys-libs/timezone-data
nano /etc/locale.gen
locale-gen
eselect locale list
eselect locale set <LOCALE>
```
FR dans mon cas
**Notes :**

## 6. Noyau

```bash
# Choisir la méthode du Handbook (binaire ou compilation manuelle)
emerge --ask sys-kernel/installkernel
emerge --ask sys-kernel/gentoo-kernel-bin
```

**Méthode choisie et raison :**

## 7. Fichier fstab, réseau et système

```bash
nano /etc/fstab          # UUID ou chemins des partitions
echo "gentoo-vm" > /etc/hostname
```

Configuration réseau (adapter au service choisi dans le Handbook) :

```bash
# Notes : service choisi, nom de l'interface, mode DHCP ou statique
```

**Notes :**

## 8. Bootloader

```bash
emerge --ask sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg
```

**Notes (UEFI ou BIOS, erreurs éventuelles) :**

## 9. Mot de passe root et utilisateur

```bash
passwd
useradd -m -G wheel <NOM_UTILISATEUR>
passwd <NOM_UTILISATEUR>
```

Le mot de passe n'est pas écrit dans ce document.

## 10. Premier démarrage

```bash
exit                     # sortir du chroot
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot
```

Retirer l'ISO de la VM avant le redémarrage, sinon le live se relance.

**Résultat du premier démarrage :**

## 11. Difficultés rencontrées

| Symptôme                            | Cause                     | Solution                           |
| ----------------------------------- | ------------------------- | ---------------------------------- |
| Manquie de place disque VM          | Config trop conservatrice | élargir                            |
| Difficulté de compilation du kernel | Pas compris               | Rajouter des flags de dependencies |



![](attachments/Pasted%20image%2020261028095753.png)
![](attachments/Pasted%20image%2020261028101344.png)


#### GRUB

Users of GRUB can use either systemd's kernel-install or the traditional Debian installkernel. The [systemd](https://packages.gentoo.org/useflags/systemd)[](https://wiki.gentoo.org/wiki/USE_flag "USE flag") USE flag switches between these implementations. To automatically run grub-mkconfig when installing the kernel, enable the [grub](https://packages.gentoo.org/useflags/grub)[](https://wiki.gentoo.org/wiki/USE_flag "USE flag") [USE flag](https://wiki.gentoo.org/wiki/USE_flag "USE flag").

**Note**  
GRUB requires kernels to be installed to /boot.

sudo nano **`/etc/portage/package.use/installkernel`**

sys-kernel/installkernel grub

`emerge --ask sys-kernel/installkernel`