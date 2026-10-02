## 1. Informations de l'environnement

| **Élément** | **Rôle**            | **Nom de la machine / Réseau** | **Adresse IPv4**  | **Masque**      |
| ----------- | ------------------- | ------------------------------ | ----------------- | --------------- |
| **Serveur** | Windows Server 2025 | `SRV-WIN-MEN-01`               | `192.168.100.10`  | `255.255.255.0` |
| **Client**  | Windows 11          | `CLI-WIN-MEN-01`               | `192.168.100.100` | `255.255.255.0` |
| **Réseau**  | LAN Segment VMware  | `LAB-TSSR-MEN`                 | _N/A (Non routé)_ | _N/A_           |

## 🛠️ 2. Étape 1 : Création & Déploiement de Windows Server 2025

### 2.1 Configuration matérielle attribuée

- **vCPU :** 2
    
- **RAM :** 2 Go
    
- **Disque virtuel :** 64 Go (allocation dynamique)
    

> _[Insérer ici une capture d'écran des paramètres de la VM dans VMware Workstation]_
![](attachments/Pasted%20image%2020261002115131.png)
![](attachments/Pasted%20image%2020261002115139.png)
### 2.2 Installation & Nommage du système

- Installation de Windows Server 2025 effectuée.
    
- Modification du nom d'hôte de la machine pour `SRV-WIN-MEN-01`.
    

> _[Insérer ici une capture d'écran de la commande `hostname` ou des paramètres système validant le nom de la machine]_

## 🌐 3. Étape 2 : Création et association du LAN Segment

1. Création du LAN Segment nommé `LAB-TSSR-MEN` dans les paramètres réseau de VMware Workstation.
    
2. Bascule de la carte réseau du Serveur (**`SRV-WIN-MEN-01`**) sur ce LAN Segment.
    
3. Bascule de la carte réseau du Client (`CLI-WIN-MEN-01`) sur ce même LAN Segment.
    

> _[Insérer ici une capture d'écran de la fenêtre de configuration du LAN Segment VMware avec les cartes réseau raccordées]_

## ⚙️ 4. Étape 3 : Configuration de l'adressage IPv4 statique

Configuration manuelle des interfaces réseau (aucun service DHCP présent sur le LAN Segment) :

### 4.1 Validation de la configuration sur le Serveur

- **IPv4 :** `192.168.100.10` / `24`
    

DOS

```
ipconfig /all
```

> _[Insérer ici la capture du terminal exécutant `ipconfig` sur le Serveur]_

### 4.2 Validation de la configuration sur le Client

- **IPv4 :** `192.168.100.100` / `24`
    

DOS

```
ipconfig /all
```

> _[Insérer ici la capture du terminal exécutant `ipconfig` sur le Client]_

## 🔓 5. Étape 4 : Configuration du Pare-feu & Validation de la connectivité

### 5.1 Action réalisée sur le Pare-feu Windows

Afin d'autoriser les requêtes d'écho ICMP (Ping) bloquées par défaut :

- Activation de la règle d'entrée **« Partage de fichiers et d'imprimantes (Demande d'écho - ICMPv4-In) »** (ou via commande PowerShell `Enable-NetFirewallRule`).
    

> _[Insérer ici une capture d'écran de la règle activée dans le Pare-feu ou de la commande PowerShell exécutée]_

### 5.2 Tests de communication (PING)

#### Test 1 : Du Client (`CLI-WIN-MEN-01`) vers le Serveur (`192.168.100.10`)

DOS

```
ping 192.168.100.10
```

> _[Insérer la capture d'écran du ping réussi]_

#### Test 2 : Du Serveur (`SRV-WIN-MEN-01`) vers le Client (`192.168.100.100`)

DOS

```
ping 192.168.100.100
```

> _[Insérer la capture d'écran du ping réussi]_

## 🔍 6. Diagnostic & Conclusion

- **Bilan :** Communication bidirectionnelle établie avec succès sur le LAN Segment isolé.
    
- **Difficultés rencontrées / Remarques :** `[Note ici si tu as eu un souci, par exemple : oubli d'activer le pare-feu, erreur de frappe dans le masque de sous-réseau, etc.]`