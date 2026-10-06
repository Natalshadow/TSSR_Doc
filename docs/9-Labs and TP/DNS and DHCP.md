---

## title: TP - Exploiter DHCP et DNS tags: [tssr, windows-server, active-directory, dns, dhcp, tp] date: auteur: trigramme: statut: en-cours

# TP - Exploiter DHCP et DNS

> [!abstract] Contexte Le domaine Active Directory est opérationnel. Vous devez maintenant exploiter DNS, puis mettre en place DHCP pour automatiser la configuration réseau du poste client.

> [!info] Comment utiliser ce document
> 
> - Remplace `[MEN]` par ton trigramme partout (zone : `TSSR-[MEN].LAB`).
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
|Domaine|`TSSR-[MEN].LAB`|
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
3. Identifier la zone `TSSR-[MEN].LAB`.
4. Observer les enregistrements créés automatiquement par Active Directory.

> [!question] Question À quoi correspondent ces enregistrements ?

> [!tip] Guidage
> 
> - Repère les dossiers/sous-dossiers de la zone (`_msdcs`, `_sites`, `_tcp`, `_udp`…).
> - Distingue les enregistrements de type **A**, **NS**, **SOA** et **SRV**.
> - Pose-toi la question : comment un client trouve-t-il un contrôleur de domaine ou un service Kerberos / LDAP ?

**Capture(s)**

![[capture-2.1-zone-directe.png]]

**Réponse**

---

### 2.2 Créer un enregistrement A

**Enregistrement à créer**

|Type|Nom|Adresse|
|---|---|---|
|A|`test`|`192.168.100.99`|

**Test depuis le client**

```powershell
nslookup test.TSSR-[MEN].LAB
```

> [!question] Question Expliquez le résultat obtenu.

> [!tip] Guidage
> 
> - Décris les deux blocs de la sortie : le serveur qui répond, puis la réponse à ta question.
> - Note le nom et l'adresse du serveur DNS interrogé : est-ce cohérent avec ce que tu attendais ?
> - Indique si la réponse est **faisant autorité** ou non.

**Capture(s)**

![[capture-2.2-creation-A.png]] ![[capture-2.2-nslookup-direct.png]]

**Réponse**

---

### 2.3 Mettre en place la résolution inverse

**Étapes**

1. Tester depuis le client :
    
    ```powershell
    nslookup 192.168.100.99
    ```
    
2. Expliquer pourquoi le résultat n'est pas nécessairement exploitable à ce stade.
    
3. Créer une zone de recherche inversée correspondant au réseau `192.168.100.0/24`.
    
4. Créer le PTR correspondant à `test.TSSR-[MEN].LAB`.
    
5. Relancer le test.
    

> [!tip] Guidage
> 
> - **Avant** la création de la zone : relève précisément le message obtenu (nom du serveur affiché ? message d'erreur ? type d'erreur ?).
> - Pour la zone inversée, fais attention à la notation du **réseau** (l'ordre des octets) et au type de zone choisi (intégrée à AD ou non, réplication).
> - Pour le PTR : tu peux le créer manuellement, ou en cochant l'option associée lors de la création de l'enregistrement A. Précise quelle méthode tu as utilisée.
> - **Après** : compare le résultat avec le test initial.

**Test initial (avant zone inversée)**

![[capture-2.3-nslookup-inverse-avant.png]]

**Explication : pourquoi le résultat n'est pas exploitable ?**

**Création de la zone inversée**

|Paramètre|Valeur choisie|
|---|---|
|Type de zone||
|Réplication||
|ID réseau||
|Nom de la zone obtenue||
|Mises à jour dynamiques||

![[capture-2.3-zone-inverse.png]]

**Création du PTR**

![[capture-2.3-ptr.png]]

**Test final (après PTR)**

![[capture-2.3-nslookup-inverse-apres.png]]

**Analyse**

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

![[capture-3.1-installation-role.png]] ![[capture-3.1-post-deploiement.png]] ![[capture-3.1-autorisation.png]]

**Commentaires**

---

### 3.2 Créer une étendue IPv4

**Paramètres demandés**

|Paramètre|Valeur proposée|Valeur configurée|
|---|---|---|
|Nom|`LAN-TSSR`||
|Réseau|`192.168.100.0/24`||
|Plage|`192.168.100.150` à `192.168.100.200`||
|DNS|`192.168.100.10`||
|Suffixe DNS|`TSSR-[MEN].LAB`||

> [!tip] Guidage
> 
> - Pense aux **options d'étendue** : le DNS et le suffixe sont des options DHCP, pas des propriétés de la plage.
> - Pose-toi la question de la **passerelle** (option 003) : est-elle nécessaire dans ce laboratoire ?
> - Vérifie que l'étendue est bien **activée** à la fin de l'assistant.
> - Note la durée de bail choisie et justifie-la si tu la modifies.

**Captures**

![[capture-3.2-assistant-etendue.png]] ![[capture-3.2-options-etendue.png]]

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

![[capture-3.3-config-auto-client.png]] ![[capture-3.3-ipconfig-all.png]] ![[capture-3.3-bail-console.png]]

**Relevés**

|Élément|Valeur constatée|
|---|---|
|Adresse IPv4 obtenue||
|Dans la plage prévue ?||
|Serveur DHCP||
|Serveur DNS||
|Suffixe DNS||
|Bail obtenu||
|Bail expirant||

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

|Commande|Rôle / explication|Client (`ipconfig /all`)|Serveur (console DHCP)|
|---|---|---|---|
|`ipconfig /release`||||
|`ipconfig /all` (1)||||
|`ipconfig /renew`||||
|`ipconfig /all` (2)||||

**Captures**

![[capture-3.4-release.png]] ![[capture-3.4-all-apres-release.png]] ![[capture-3.4-renew.png]] ![[capture-3.4-all-apres-renew.png]] ![[capture-3.4-bail-serveur.png]]

**Observations**

---

## 4. Vérifications finales

> [!check] À valider avant de rendre le TP Coche chaque point uniquement si tu peux le **prouver** par une capture ou une commande.

|Vérification|Validé|Preuve|
|---|---|---|
|La résolution directe fonctionne|☐|[[capture-2.2-nslookup-direct.png]]|
|La résolution inverse fonctionne|☐|[[capture-2.3-nslookup-inverse-apres.png]]|
|Le serveur DHCP est autorisé|☐|[[capture-3.1-autorisation.png]]|
|Le client obtient une adresse de la plage prévue|☐|[[capture-3.3-ipconfig-all.png]]|
|Le DNS est correctement distribué|☐|[[capture-3.3-ipconfig-all.png]]|

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
> - [ ] Placeholders `[MEN]` remplacés
> - [ ] Toutes les captures insérées
> - [ ] Tous les blocs `[!tip]` supprimés
> - [ ] Export PDF réalisé (si demandé)