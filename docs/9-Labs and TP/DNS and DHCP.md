---

## title: TP - Exploiter DHCP et DNS tags: [tssr, windows-server, active-directory, dns, dhcp, tp] date: auteur: trigramme: statut: en-cours

# TP - Exploiter DHCP et DNS

> [!abstract] Contexte Le domaine Active Directory est opérationnel. Vous devez maintenant exploiter DNS, puis mettre en place DHCP pour automatiser la configuration réseau du poste client.

> [!info] Comment utiliser ce document
> 
> - Remplace `MEN` par ton trigramme partout (zone : `TSSR-MEN.LAB`).
> - Chaque section contient un espace **Réponse / Captures** à compléter.
> - Les blocs `> [!tip]` sont des pistes de guidage : supprime-les dans la version rendue.
> - Place les captures dans un dossier `attachments/` et insère-les avec `![[nom-capture.png]]`.
> - Pour chaque capture, vérifie que le **nom de la machine** et l'**heure** sont visibles si possible.

---

## Sommaire

- [[#1. Objectifs]]
- [[#2. Partie A — DNS]]
- [[#3. Partie B — DHCP]]
- [[#4. Vérifications finales]]
- [[#5. Conclusion et difficultés rencontrées]]

---

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur AD / DNS / DHCP|`192.168.100.10`|
|Nom du serveur||
|Nom du poste client||
|Réseau|`192.168.100.0/24`|

---

## 1. Objectifs

- [ ] Créer et tester des enregistrements DNS directs et inverses.
- [ ] Installer et autoriser le serveur DHCP.
- [ ] Créer une étendue adaptée au laboratoire.
- [ ] Distribuer au client son adresse IPv4 et le DNS du domaine.
- [ ] Observer le cycle d'un bail DHCP.

---

## 2. Partie A — DNS

### 2.1 Observer la zone existante

**Étapes**

1. Ouvrir la console DNS.
2. Développer **Zones de recherche directes**.
3. Identifier la zone `TSSR-MEN.LAB`.
4. Observer les enregistrements créés automatiquement par Active Directory.


> [!question] Question À quoi correspondent ces enregistrements ?
> Ils correspondent aux IP du serveur et du client pour les Hosts A records.
> ![](attachments/Pasted%20image%2020261006092229.png)
> NameServer est le nom résolu qui correspond à l'IP du serveur 
> Je ne connais pas Start of Authority

> [!tip] Guidage
> 
> - Repère les dossiers/sous-dossiers de la zone (`_msdcs`, `_sites`, `_tcp`, `_udp`…).
> - Distingue les enregistrements de type **A**, **NS**, **SOA** et **SRV**.
> - Pose-toi la question : comment un client trouve-t-il un contrôleur de domaine ou un service Kerberos / LDAP ?

**Capture(s)![](attachments/Pasted%20image%2020261006092001.png)**





---

### 2.2 Créer un enregistrement A

**Enregistrement à créer**

|Type|Nom|Adresse|
|---|---|---|
|A|`test`|`192.168.100.99`|

**Test depuis le client**

```powershell
nslookup test.TSSR-MEN.LAB
```

> [!question] Question Expliquez le résultat obtenu.

> [!tip] Guidage
> 
> - Décris les deux blocs de la sortie : le serveur qui répond, puis la réponse à ta question.
> - Note le nom et l'adresse du serveur DNS interrogé : est-ce cohérent avec ce que tu attendais ?
> - Indique si la réponse est **faisant autorité** ou non.

**Capture(s)**

![](attachments/Pasted%20image%2020261006092555.png) ![](attachments/Pasted%20image%2020261006092609.png)
Première tentative en échec, typo.
![](attachments/Pasted%20image%2020261006092946.png)
Le A record est trouvé.


---

### 2.3 Mettre en place la résolution inverse

**Étapes**

1. Tester depuis le client :
    
    ```powershell
    nslookup 192.168.100.99
    ```
    
2. Expliquer pourquoi le résultat n'est pas nécessairement exploitable à ce stade.
    
3. Créer une zone de recherche inversée correspondant au réseau `192.168.100.0/24`.
    
4. Créer le PTR correspondant à `test.TSSR-MEN.LAB`.
    
5. Relancer le test.
    

> [!tip] Guidage
> 
> - **Avant** la création de la zone : relève précisément le message obtenu (nom du serveur affiché ? message d'erreur ? type d'erreur ?).
> - Pour la zone inversée, fais attention à la notation du **réseau** (l'ordre des octets) et au type de zone choisi (intégrée à AD ou non, réplication).
> - Pour le PTR : tu peux le créer manuellement, ou en cochant l'option associée lors de la création de l'enregistrement A. Précise quelle méthode tu as utilisée.
> - **Après** : compare le résultat avec le test initial.

**Test initial (avant zone inversée)**

![](attachments/Pasted%20image%2020261006093437.png)

**Explication : pourquoi le résultat n'est pas exploitable ?**
Il faut créer une zone inversée ?
**Création de la zone inversée**

| Paramètre               | Valeur choisie           |
| ----------------------- | ------------------------ |
| Type de zone            | Primary                  |
| Réplication             | To all DNS on domain     |
| ID réseau               | 192.168.100              |
| Nom de la zone obtenue  | 100.168.192.in-addr.arpa |
| Mises à jour dynamiques |                          |
|                         |                          |

![](attachments/Pasted%20image%2020261006093528.png)
![](attachments/Pasted%20image%2020261006093647.png)
![](attachments/Pasted%20image%2020261006093944.png)
**Création du PTR**

![](attachments/Pasted%20image%2020261006094039.png)

**Test final (après PTR)**

![](attachments/Pasted%20image%2020261006094058.png)

>[!tip] C'est quoi PTR
>Le PTR est le traducteur du DNS de l'IP vers l'hostname.
>Le PTR record ne génère pas de A record associé automatiquement.
> [PTR](../PTR.md)

>[!tip] Reverse zone
>La zone inversée (`100.168.192.in-addr.arpa`) est le conteneur des PTR. Un serveur DNS ne répond de façon autoritaire que pour les zones qu'il héberge : créer la zone inversée le rend responsable de la plage IP `192.168.100.x`. Sans elle, il n'a aucune autorité sur ces adresses (→ timeout). Zone créée mais vide → `Non-existent domain`. Zone + PTR → le nom est renvoyé.



---

## 3. Partie B — DHCP

### 3.1 Installer le rôle

**Étapes**

1. Installer le rôle **Serveur DHCP**.
2. Effectuer la configuration post-déploiement.
3. Autoriser le serveur DHCP dans Active Directory.

> [!tip] Guidage
> 
> - Utilise le _Gestionnaire de serveur_ (Ajouter des rôles et fonctionnalités) ou PowerShell : `Install-WindowsFeature`.
> - La configuration post-déploiement crée les groupes de sécurité DHCP et autorise le serveur. Note ce que fait chacune des deux actions proposées.
> - Vérifie dans la console DHCP que l'état du serveur est correct (indicateur visuel sur le nœud IPv4).

**Captures**

![](attachments/Pasted%20image%2020261006094436.png) ![](attachments/Pasted%20image%2020261006095239.png) ![](attachments/Pasted%20image%2020261006095305.png)

**Commentaires**

---

### 3.2 Créer une étendue IPv4

**Paramètres demandés**

| Paramètre   | Valeur proposée                       | Valeur configurée                     |
| ----------- | ------------------------------------- | ------------------------------------- |
| Nom         | `LAN-TSSR`                            | `LAN-TSSR`                            |
| Réseau      | `192.168.100.0/24`                    | `192.168.100.0/24`                    |
| Plage       | `192.168.100.150` à `192.168.100.200` | `192.168.100.150` à `192.168.100.200` |
| DNS         | `192.168.100.10`                      | `192.168.100.10`                      |
| Suffixe DNS | `TSSR-MEN.LAB`                        | `TSSR-MEN.LAB`                        |

> [!tip] Guidage
> 
> - Pense aux **options d'étendue** : le DNS et le suffixe sont des options DHCP, pas des propriétés de la plage.
> - Pose-toi la question de la **passerelle** (option 003) : est-elle nécessaire dans ce laboratoire ?
> - Vérifie que l'étendue est bien **activée** à la fin de l'assistant.
> - Note la durée de bail choisie et justifie-la si tu la modifies.

**Captures**

![](attachments/Pasted%20image%2020261006100416.png) 
![](attachments/Pasted%20image%2020261006100540.png)
>Gateway non nécessaire puisqu'on est sur un réseau LAN Segment, les deux machines se parlent directement et n'ont pas besoin d'un routeur en intermédiaire.
![](attachments/Pasted%20image%2020261006101202.png)
> Je ne pense pas que le WINS serveur soit nécessaire donc je laisse vierge.
> 
![](attachments/Pasted%20image%2020261006101250.png)

**Commentaires**

---

### 3.3 Basculer le client en DHCP

**Étapes**

1. Configurer IPv4 et DNS en obtention automatique sur le client.
    
2. Vérifier la configuration :
    
    ```powershell
    ipconfig /all
    ```
    
3. Retrouver le bail dans la console DHCP.
    
4. Vérifier que le DNS distribué est bien le serveur Active Directory.
    

> [!tip] Guidage Dans la sortie de `ipconfig /all`, relève au minimum :
> 
> - `DHCP activé`
> - `Adresse IPv4`
> - `Serveur DHCP`
> - `Serveurs DNS`
> - `Suffixe DNS propre à la connexion`
> - `Bail obtenu` / `Bail expirant`
> 
> Dans la console DHCP : _Étendue > Baux d'adresse_. Compare l'adresse MAC et le nom d'hôte avec ceux du client.

**Captures**


Avant: 
![](attachments/Pasted%20image%2020261006114420.png)![](attachments/Pasted%20image%2020261006114005.png)`PS C:\WINDOWS\system32> ipconfig /all`

`Configuration IP de Windows`

   `Nom de l’hôte . . . . . . . . . . : CLI-WIN-MEN-01`
   `Suffixe DNS principal . . . . . . : TSSR-MEN.LAB`
   `Type de noeud. . . . . . . . . .  : Hybride`
   `Routage IP activé . . . . . . . . : Non`
   `Proxy WINS activé . . . . . . . . : Non`
   `Liste de recherche du suffixe DNS.: TSSR-MEN.LAB`

`Carte Ethernet Ethernet0 :`

   `Suffixe DNS propre à la connexion. . . : TSSR-MEN.LAB`
   `Description. . . . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection`
   `Adresse physique . . . . . . . . . . . : 00-0C-29-E4-BD-1D`
   `DHCP activé. . . . . . . . . . . . . . : Oui`
   `Configuration automatique activée. . . : Oui`
   `Adresse IPv6 de liaison locale. . . . .: fe80::94ad:cbc5:9b96:ca9e%7(préféré)`
   `Adresse IPv4. . . . . . . . . . . . . .: 192.168.100.150(préféré)`
   `Masque de sous-réseau. . . . . . . . . : 255.255.255.0`
   `Bail obtenu. . . . . . . . . . . . . . : mardi 6 octobre 2026 11:45:26`
   `Bail expirant. . . . . . . . . . . . . : mercredi 14 octobre 2026 11:45:25`
   `Passerelle par défaut. . . . . . . . . :`
   `Serveur DHCP . . . . . . . . . . . . . : 192.168.100.10`
   `IAID DHCPv6 . . . . . . . . . . . : 83889193`
   `DUID de client DHCPv6. . . . . . . . : 00-01-00-01-32-50-07-B0-00-0C-29-E4-BD-1D`
   `Serveurs DNS. . .  . . . . . . . . . . : 192.168.100.10`
   `NetBIOS sur Tcpip. . . . . . . . . . . : Activé`  ![](attachments/Pasted%20image%2020261006115150.png)

**Relevés**


| Élément                | Valeur constatée                                                                 |
| ---------------------- | -------------------------------------------------------------------------------- |
| Adresse IPv4 obtenue   | 192.168.100.150                                                                  |
| Dans la plage prévue ? | Oui                                                                              |
| Serveur DHCP           | 192.168.100.10                                                                   |
| Serveur DNS            | 192.168.100.10                                                                   |
| Suffixe DNS            | TSSR-MEN.LAB                                                                     |
| Bail obtenu            | 6 Oct 11:45 → 14 Oct 11:45, 8 jours, conforme à ce qui a été vu dans le serveur. |
| Bail expirant          | 14 Oct 11:45                                                                     |

**Commentaires**

---

### 3.4 Manipuler le bail

**Commandes à exécuter (dans l'ordre)**

```powershell
ipconfig /release
ipconfig /all
ipconfig /renew
ipconfig /all
```

> [!question] Question Expliquez ce que fait chaque commande et observez l'évolution du bail côté serveur.

> [!tip] Guidage
> 
> - Garde la console DHCP ouverte sur _Baux d'adresse_ et **rafraîchis** (F5) après chaque commande.
> - Après le `release` : qu'affiche `ipconfig /all` pour l'adresse IPv4 ? Que devient le bail côté serveur ?
> - Après le `renew` : le client récupère-t-il la **même adresse** ? Pourquoi (ou pourquoi pas) ?
> - Si tu veux aller plus loin, relie ces commandes aux 4 étapes **DORA** (Discover, Offer, Request, Acknowledge).

**Tableau d'analyse**

| Commande            | Rôle / explication | Client (`ipconfig /all`)                                                | Serveur (console DHCP) |
| ------------------- | ------------------ | ----------------------------------------------------------------------- | ---------------------- |
| `ipconfig /release` |                    | Le masque est passé à 255.255.0.0 et l'ipv4 n'est plus bonne.           | Le bail a disparu      |
| `ipconfig /all` (1) |                    |                                                                         |                        |
| `ipconfig /renew`   |                    | Les paramètres sont revenus comme ils l'étaient avant de faire /release | Le bail est revenu     |
| `ipconfig /all` (2) |                    |                                                                         |                        |

**Captures**

![](attachments/Pasted%20image%2020261006115634.png) ![](attachments/Pasted%20image%2020261006115650.png) Le bail est revenu :![](attachments/Pasted%20image%2020261006115704.png)  


---

## 4. Vérifications finales

> [!check] À valider avant de rendre le TP Coche chaque point uniquement si tu peux le **prouver** par une capture ou une commande.

| Vérification                                     | Validé | Preuve                                     |
| ------------------------------------------------ | ------ | ------------------------------------------ |
| La résolution directe fonctionne                 | ☐      | [[capture-2.2-nslookup-direct.png]]        |
| La résolution inverse fonctionne                 | ☐      | [[capture-2.3-nslookup-inverse-apres.png]] |
| Le serveur DHCP est autorisé                     | ☐      | [[capture-3.1-autorisation.png]]           |
| Le client obtient une adresse de la plage prévue | ☐      | [[capture-3.3-ipconfig-all.png]]           |
| Le DNS est correctement distribué                | ☐      | [[capture-3.3-ipconfig-all.png]]           |

Version à cocher :

- [ ] La résolution directe fonctionne.
- [ ] La résolution inverse fonctionne.
- [ ] Le serveur DHCP est autorisé.
- [ ] Le client obtient une adresse de la plage prévue.
- [ ] Le DNS est correctement distribué.

---

## 5. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu'un TP « sans problème ».

|Problème|Cause|Solution|
|---|---|---|
||||

### Ce que j'ai retenu

Le DHCP distribue son idendité aux appareils du réseau et leur indique l'adresse du DNS.
Le DNS indique aux clients l'adresse que les clients requierent, il ne donne pas le chemin, juste l'adresse. 

### Commandes utiles (aide-mémoire) 

```powershell
# DNS
nslookup <nom ou IP>
ipconfig /flushdns
ipconfig /displaydns

# DHCP
ipconfig /all
ipconfig /release
ipconfig /renew
```

---

> [!note] Rendu
> 
> - [ ] Placeholders `MEN` remplacés
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs `[!tip]` supprimés
> - [ ] Export PDF réalisé (si demandé)