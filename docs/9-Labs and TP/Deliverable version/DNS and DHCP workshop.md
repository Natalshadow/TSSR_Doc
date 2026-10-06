---

## title: TP - Exploiter DHCP et DNS tags: [tssr, windows-server, active-directory, dns, dhcp, tp] date: 2026-10-06 auteur: trigramme: MEN

# TP - Exploiter DHCP et DNS

> [!abstract] Contexte Le domaine Active Directory est opérationnel. L'objectif est d'exploiter DNS, puis de mettre en place DHCP pour automatiser la configuration réseau du poste client.

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur AD / DNS / DHCP|`srv-win-men-01` (`192.168.100.10`)|
|Poste client|`CLI-WIN-MEN-01`|
|Réseau|`192.168.100.0/24` (LAN Segment, sans routeur)|

## Objectifs

- [x] Créer et tester des enregistrements DNS directs et inverses.
- [x] Installer et autoriser le serveur DHCP.
- [x] Créer une étendue adaptée au laboratoire.
- [x] Distribuer au client son adresse IPv4 et le DNS du domaine.
- [x] Observer le cycle d'un bail DHCP.

---

## Partie A — DNS

### 2.1 Observer la zone existante

**Question :** à quoi correspondent les enregistrements créés automatiquement par Active Directory ?

**Réponse :** Les enregistrements de type Host (A) correspondent aux adresses IP du serveur et du client. L'enregistrement NameServer (NS) indique le nom du serveur DNS, résolu vers l'IP du serveur. 

**Captures**

![](attachments/Pasted%20image%2020261006092229.png) ![](attachments/Pasted%20image%2020261006092001.png)

---

### 2.2 Créer un enregistrement A

|Type|Nom|Adresse|
|---|---|---|
|A|`test`|`192.168.100.99`|

Test depuis le client :

```powershell
nslookup test.TSSR-MEN.LAB
```

**Captures**

Première tentative : échec dû à une faute de frappe dans le nom.

![](attachments/Pasted%20image%2020261006092555.png) ![](attachments/Pasted%20image%2020261006092609.png)

Deuxième tentative : l'enregistrement A est trouvé.

![](attachments/Pasted%20image%2020261006092946.png)



---

### 2.3 Mettre en place la résolution inverse

**Test initial (avant la zone inversée)**

```powershell
nslookup 192.168.100.99
```

![](attachments/Pasted%20image%2020261006093437.png)

**Pourquoi le résultat n'est pas exploitable à ce stade :** Aucune zone inversée n'existe : le serveur DNS n'est responsable d'aucune plage d'adresses en résolution inverse et ne peut donc pas répondre. 

**Création de la zone inversée**

| Paramètre               | Valeur choisie                       |
| ----------------------- | ------------------------------------ |
| Type de zone            | Primary                              |
| Réplication             | To all DNS on domain                 |
| ID réseau               | `192.168.100`                        |
| Nom de la zone obtenue  | `100.168.192.in-addr.arpa`           |
| Mises à jour dynamiques | ? Je n'ai pas trouvé ce que c'était  |

![](attachments/Pasted%20image%2020261006093528.png) ![](attachments/Pasted%20image%2020261006093647.png) ![](attachments/Pasted%20image%2020261006093944.png)

**Création du PTR**

![](attachments/Pasted%20image%2020261006094039.png)

**Test final (après PTR)**

![](attachments/Pasted%20image%2020261006094058.png)

**Notes**

> [!note] PTR 
> Le PTR est le traducteur du DNS de l'IP vers le nom d'hôte. Il ne génère pas d'enregistrement A associé automatiquement : A et PTR sont indépendants.

> [!note] Zone de recherche inversée 
> La zone inversée (`100.168.192.in-addr.arpa`) est le conteneur des enregistrements PTR. Un serveur DNS ne répond de façon autoritaire que pour les zones qu'il héberge : créer la zone inversée le rend responsable de la plage IP `192.168.100.x`.
> 
> - Sans zone : aucune autorité sur ces adresses (timeout).
> - Zone créée mais vide : `Non-existent domain`.
> - Zone + PTR : le nom d'hôte est renvoyé.

---

## Partie B — DHCP

### 3.1 Installer le rôle

Installation du rôle Serveur DHCP, configuration post-déploiement, puis autorisation du serveur dans Active Directory.

![](attachments/Pasted%20image%2020261006094436.png) ![](attachments/Pasted%20image%2020261006095239.png) ![](attachments/Pasted%20image%2020261006095305.png)

---

### 3.2 Créer une étendue IPv4

|Paramètre|Valeur configurée|
|---|---|
|Nom|`LAN-TSSR`|
|Réseau|`192.168.100.0/24`|
|Plage|`192.168.100.150` à `192.168.100.200`|
|DNS|`192.168.100.10`|
|Suffixe DNS|`TSSR-MEN.LAB`|

![](attachments/Pasted%20image%2020261006100416.png) ![](attachments/Pasted%20image%2020261006100540.png)

**Passerelle :** non configurée. Les deux machines sont sur un LAN Segment, communiquent directement et n'ont pas besoin d'un routeur intermédiaire.

![](attachments/Pasted%20image%2020261006101202.png)

**Serveur WINS :** non nécessaire je pense, laissé vide.

![](attachments/Pasted%20image%2020261006101250.png)

---

### 3.3 Basculer le client en DHCP

**Avant** (configuration statique)

![](attachments/Pasted%20image%2020261006114420.png) ![](attachments/Pasted%20image%2020261006114005.png)

**Après** (obtention automatique)

```powershell
PS C:\WINDOWS\system32> ipconfig /all

Configuration IP de Windows

   Nom de l'hôte . . . . . . . . . . : CLI-WIN-MEN-01
   Suffixe DNS principal . . . . . . : TSSR-MEN.LAB
   Type de noeud. . . . . . . . . .  : Hybride
   Routage IP activé . . . . . . . . : Non
   Proxy WINS activé . . . . . . . . : Non
   Liste de recherche du suffixe DNS.: TSSR-MEN.LAB

Carte Ethernet Ethernet0 :

   Suffixe DNS propre à la connexion. . . : TSSR-MEN.LAB
   Description. . . . . . . . . . . . . . : Intel(R) 82574L Gigabit Network Connection
   Adresse physique . . . . . . . . . . . : 00-0C-29-E4-BD-1D
   DHCP activé. . . . . . . . . . . . . . : Oui
   Configuration automatique activée. . . : Oui
   Adresse IPv6 de liaison locale. . . . .: fe80::94ad:cbc5:9b96:ca9e%7(préféré)
   Adresse IPv4. . . . . . . . . . . . . .: 192.168.100.150(préféré)
   Masque de sous-réseau. . . . . . . . . : 255.255.255.0
   Bail obtenu. . . . . . . . . . . . . . : mardi 6 octobre 2026 11:45:26
   Bail expirant. . . . . . . . . . . . . : mercredi 14 octobre 2026 11:45:25
   Passerelle par défaut. . . . . . . . . :
   Serveur DHCP . . . . . . . . . . . . . : 192.168.100.10
   IAID DHCPv6 . . . . . . . . . . . : 83889193
   DUID de client DHCPv6. . . . . . . . : 00-01-00-01-32-50-07-B0-00-0C-29-E4-BD-1D
   Serveurs DNS. . .  . . . . . . . . . . : 192.168.100.10
   NetBIOS sur Tcpip. . . . . . . . . . . : Activé
```

Bail dans la console DHCP du serveur :

![](attachments/Pasted%20image%2020261006115150.png)

**Relevés**

|Élément|Valeur constatée|
|---|---|
|Adresse IPv4 obtenue|`192.168.100.150`|
|Dans la plage prévue ?|Oui|
|Serveur DHCP|`192.168.100.10`|
|Serveur DNS|`192.168.100.10` (serveur Active Directory)|
|Suffixe DNS|`TSSR-MEN.LAB`|
|Bail obtenu|6 octobre 2026, 11:45|
|Bail expirant|14 octobre 2026, 11:45 (durée de 8 jours, conforme à la console du serveur)|

---

### 3.4 Manipuler le bail

```powershell
ipconfig /release
ipconfig /all
ipconfig /renew
ipconfig /all
```

| Commande            | Rôle                                                                                                                                                                                        | Client (`ipconfig /all`)                                                    | Serveur (console DHCP) |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ---------------------- |
| `ipconfig /release` | Libère le bail : le client informe le serveur DHCP qu'il rend son adresse, qui redevient disponible. Sans bail, le client retombe sur une autre adresse mais je ne sais pas d'où elle sort. | Le masque passe à `255.255.0.0` et l'adresse IPv4 n'est plus celle du bail. | Le bail a disparu.     |
| `ipconfig /all` (1) | Affiche la configuration complète et permet de constater l'absence de bail.                                                                                                                 | —                                                                           | —                      |
| `ipconfig /renew`   | Demande un nouveau bail au serveur DHCP (échange Discover, Offer, Request, Acknowledge). Le client récupère son adresse, son DNS et son suffixe.                                            | Les paramètres sont revenus comme avant le `/release`.                      | Le bail est revenu.    |
| `ipconfig /all` (2) | Permet de vérifier le bail restauré : adresse dans la plage, serveur DHCP, nouvelles dates d'obtention et d'expiration.                                                                     | —                                                                           | —                      |

**Captures**

![](attachments/Pasted%20image%2020261006115634.png) ![](attachments/Pasted%20image%2020261006115650.png)

Le bail est revenu côté serveur :

![](attachments/Pasted%20image%2020261006115704.png)

---

## Vérifications finales

|Vérification|Validé|Preuve|
|---|---|---|
|La résolution directe fonctionne|✅|[[#2.2 Créer un enregistrement A]]|
|La résolution inverse fonctionne|✅|[[#2.3 Mettre en place la résolution inverse]]|
|Le serveur DHCP est autorisé|✅|[[#3.1 Installer le rôle]]|
|Le client obtient une adresse de la plage prévue|✅|[[#3.3 Basculer le client en DHCP]]|
|Le DNS est correctement distribué|✅|[[#3.3 Basculer le client en DHCP]]|

---

## Conclusion

### Difficultés rencontrées

|Problème|Cause|Solution|
|---|---|---|
|`nslookup` en échec lors du premier test de résolution directe|Faute de frappe dans le nom interrogé|Saisie correcte de `test.TSSR-MEN.LAB`|

