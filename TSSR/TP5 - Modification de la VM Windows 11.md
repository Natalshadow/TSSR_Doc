Fiche de configuration — poste Windows

| Élément              | Ancienne valeur    | Nouvelle valeur |
| -------------------- | ------------------ | --------------- |
| Nom de la VM         | `CLI-WIN-MEN-01`   | =               |
| Rôle                 | Poste client       | =               |
| Système              | Windows 11         | =               |
| Édition              | Professionnel      | =               |
| Version              | 26H2               | =               |
| vCPU                 | 2                  | 4               |
| RAM                  | 4 Go               | 6               |
| Disque virtuel       | 64 Go              | 65 + 2          |
| Réseau logique       | `LAB-TSSR`         | =               |
| Réseau VMware        | `VMnet8`           | =               |
| Mode réseau          | NAT                | =               |
| Compte utilisé       | Compte local       | =               |
| Date d'installation  | 2026-09-30 14 h 18 | =               |
| État Windows Update  | À jour             | =               |
| État périphériques   | OK                 | =               |
| Accès Internet testé | Oui                | =               |
| Remarques            | RAS                | =               |
|                      |                    |                 |
|                      |                    |                 |
Modification des différents paramètres VMWare
![[Pasted image 20261001141635.png]]

Configuration Windows dans la VM
![[Pasted image 20261001141824.png]]
![[Pasted image 20261001142030.png]]

L'ordre actuel des partitions sur C: ne permet pas d'allouer l'espace non alloué. Il faudra d'abord mettre le recovery en pause et allouer l'espace supplémentaire via diskpart.