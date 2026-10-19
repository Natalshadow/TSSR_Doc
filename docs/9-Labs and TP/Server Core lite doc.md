##  Recherches - Windows Server Core et PowerShell (version courte) tags: [tssr, windows-server, server-core, powershell, recherche] date: auteur: trigramme: MEN

> [!info] Version courte (10 min) Une réponse courte et personnelle par rubrique. Cite la source en bas. Supprime ce bloc et les `[!tip]` au rendu. Répartition conseillée : 2 min par rubrique, 2 min pour les sources et la relecture.

**Version de Windows Server de référence :**

---

## 1. Prérequis / configuration minimale (Server Core)

> [!tip] Où chercher Microsoft Learn, page « configuration requise » de ta version de Windows Server.


| **Composant**            | **Exigence minimale**                                                                                 |
| ------------------------ | ----------------------------------------------------------------------------------------------------- |
| **Processeur**           | 1,4 GHz, 64-bit (compatible jeux d'instructions x64, NX, DEP, CMPXCHG16b, LAHF/SAHF, PrefetchW)       |
| **Mémoire RAM**          | 512 Mo (3,2 Go minimum recommandé si virtualisé pour éviter les échecs de démarrage/installation)     |
| **Espace disque**        | 32 Go (Server Core nécessite environ 4 à 6 Go d'espace disque disponible de moins que la version GUI) |
| **Réseau**               | Adaptateur Ethernet gigabit (10/100/1000 Base-T)                                                      |
| **Firmware**             | Système UEFI 2.3.1c avec Secure Boot                                                                  |

---

## 2. Intérêt d'un Server Core

> [!tip] Pistes Sécurité, ressources, mises à jour, administration.

Le choix de déployer la déclinaison **Server Core** (sans interface graphique utilisateur) repose sur quatre piliers majeurs :

- **Surface d'attaque réduite :** Moins de code, pas d'interface graphique, de navigateur ou d'outils d'administration visuels installés. Cela diminue drastiquement le nombre de vulnérabilités potentielles exploitables par un attaquant.
    
- **Maintenance et redémarrages réduits :** La majorité des correctifs Windows (Windows Updates) concernent les composants graphiques ou les dépendances associées (comme Shell, Internet Explorer/Edge libraries). Un serveur Core nécessite jusqu'à 50 à 60 % de redémarrages en moins par an.
    
- **Empreinte mémoire et disque minimale :** Libère des ressources système considérables pour les rôles serveur (Active Directory, DNS, Hyper-V). La mémoire RAM consommée au démarrage est généralement inférieure à 1 Go contre 2,5 Go à 3 Go pour une version GUI.
    
- **Standardisation et automatisation :** Force les équipes système à adopter l'administration à distance, l'automatisation via des scripts et la gestion centralisée.

---

## 3. Administration via PowerShell

> [!tip] Pistes En local : `sconfig`. À distance : `Enter-PSSession`, `Invoke-Command`. Outils graphiques à distance : Server Manager, RSAT, Windows Admin Center.

- **En local :**
- **À distance :**
- **Prérequis :**

---

## 4. Syntaxe des commandes PowerShell

> [!tip] Pistes Structure Verbe-Nom, paramètres, pipeline `|`, aide avec `Get-Help` et `Get-Command`.

|Élément|Syntaxe|Exemple|
|---|---|---|
|Commande|||
|Paramètre|||
|Pipeline|||
|Filtrer|||
|Aide|||
```powershell
Verb-Noun -Parametre1 Valeur1 -Parametre2 Valeur2 [-Interrupteur]
```


---

## Sources