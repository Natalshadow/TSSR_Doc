## 1. Informations de l'environnement

| **Élément** | **Rôle**            | **Nom de la machine / Réseau** | **Adresse IPv4**  | **Masque**      |
| ----------- | ------------------- | ------------------------------ | ----------------- | --------------- |
| **Serveur** | Windows Server 2025 | `SRV-WIN-MEN-01`               | `192.168.100.10`  | `255.255.255.0` |
| **Client**  | Windows 11          | `CLI-WIN-MEN-01`               | `192.168.100.100` | `255.255.255.0` |
| **Réseau**  | LAN Segment VMware  | `LAB-TSSR-MEN`                 | _N/A (Non routé)_ | _N/A_           |

## 2. Étape 1 : Création & Déploiement de Windows Server 2025

### 2.1 Configuration matérielle attribuée

- **vCPU :** 2
    
- **RAM :** 2 Go
    
- **Disque virtuel :** 64 Go (allocation dynamique)
    

> _[Insérer ici une capture d'écran des paramètres de la VM dans VMware Workstation]_
![](attachments/Pasted%20image%2020261002115131.png)
![](attachments/Pasted%20image%2020261002115139.png)

Correction du nom, j'ai remarqué une typo par rapport au brief.
![](attachments/Pasted%20image%2020261002124115.png)

### 2.2 Installation & Nommage du système

- Installation de Windows Server 2025 effectuée.
    ![](attachments/Pasted%20image%2020261002115910.png)
- Installation VMWare Tools (automatique)
![](attachments/Pasted%20image%2020261002115946.png)
- Modification du nom d'hôte de la machine pour `SRV-WIN-MEN-01`.
    

> _[Insérer ici une capture d'écran de la commande `hostname` ou des paramètres système validant le nom de la machine]_


![](attachments/Pasted%20image%2020261002120511.png)
## 3. Étape 2 : Création et association du LAN Segment

1. Création du LAN Segment nommé `LAB-TSSR-MEN` dans les paramètres réseau de VMware Workstation.
    
2. Bascule de la carte réseau du Serveur (**`SRV-WIN-MEN-01`**) sur ce LAN Segment.
    
3. Bascule de la carte réseau du Client (`CLI-WIN-MEN-01`) sur ce même LAN Segment.
    

> _[Insérer ici une capture d'écran de la fenêtre de configuration du LAN Segment VMware avec les cartes réseau raccordées]_

SRV:
![](attachments/Pasted%20image%2020261002120619.png)
CLI:
![](attachments/Pasted%20image%2020261002120638.png)
## 4. Étape 3 : Configuration de l'adressage IPv4 statique

Configuration manuelle des interfaces réseau (aucun service DHCP présent sur le LAN Segment) :

### 4.1 Validation de la configuration sur le Serveur
|         |                 |               |            |       |
| ------- | --------------- | ------------- | ---------- | ----- |
| Machine | IPv4            | Masque        | Passerelle | DNS   |
| Serveur | 192.168.100.10  | 255.255.255.0 | aucune     | aucun |
| Client  | 192.168.100.100 | 255.255.255.0 | aucune     | aucun |

- **IPv4 :** `192.168.100.10` / `24`
    
1) sélectionner "Use following IP" et remplir:
2) ![](attachments/Pasted%20image%2020261002121250.png)
DOS

```
ipconfig /all
```

> _[Insérer ici la capture du terminal exécutant `ipconfig` sur le Serveur]_

![](attachments/Pasted%20image%2020261002121520.png)
### 4.2 Validation de la configuration sur le Client

- **IPv4 :** `192.168.100.100` / `24`
    

DOS

```
ipconfig /all
```

> _[Insérer ici la capture du terminal exécutant `ipconfig` sur le Client]_
![](attachments/Pasted%20image%2020261002121858.png)


![](attachments/Pasted%20image%2020261002121921.png)


## 5. Étape 4 : Configuration du Pare-feu & Validation de la connectivité

### 5.1 Action réalisée sur le Pare-feu Windows

Afin d'autoriser les requêtes d'écho ICMP (Ping) bloquées par défaut :

- Activation de la règle d'entrée **« Partage de fichiers et d'imprimantes (Demande d'écho - ICMPv4-In) »** (ou via commande PowerShell `Enable-NetFirewallRule`).
    

> _[Insérer ici une capture d'écran de la règle activée dans le Pare-feu ou de la commande PowerShell exécutée]_

![](attachments/Pasted%20image%2020261002122615.png)

### 5.2 Tests de communication (PING)

#### Test 1 : Du Client (`CLI-WIN-MEN-01`) vers le Serveur (`192.168.100.10`)

DOS

```
ping 192.168.100.10
```

> _[Insérer la capture d'écran du ping réussi]_

![](attachments/Pasted%20image%2020261002122826.png)

#### Test 2 : Du Serveur (`SRV-WIN-MEN-01`) vers le Client (`192.168.100.100`)

DOS

```
ping 192.168.100.100
```

> _[Insérer la capture d'écran du ping réussi]_

![](attachments/Pasted%20image%2020261002122846.png)

## 6. Diagnostic & Conclusion

- **Bilan :** Communication bidirectionnelle établie avec succès sur le LAN Segment isolé.

Confirmé, les deux VM peuvent se ping mutuellement.

- **Difficultés rencontrées / Remarques :** 
J'oublie toujours où se trouve le panneau spécifique des règles de parefeu windows et je dois toujours rechercher à nouveau son nom exact.
