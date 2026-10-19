



---
> [!abstract] Contexte
> L’entreprise souhaite déployer un serveur Windows Server 2025 en mode Core afin de privilégier l’administration en ligne de commande et à distance. Vous devez installer le serveur, réaliser sa configuration initiale avec PowerShell, puis l’intégrer à Windows Admin Center. Ce serveur sera réutilisé lors des prochains TP pour renforcer les services Active Directory.


---

## Sommaire

- [[#1. Objectifs]]
- [[#2. Installer Windows Server Core]]
- [[#3. Installer VMware Tools et mettre à jour Windows]]
- [[#4. Configurer le réseau du laboratoire]]
- [[#5. Renommer le serveur et créer des comptes locaux]]
- [[#6. Configurer le pare-feu Windows]]
- [[#7. Administrer le serveur avec Windows Admin Center]]
- [[#8. Validation]]
- [[#9. Documentation]]
- [[#10. Conclusion et difficultés rencontrées]]

---

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Édition Windows|Windows Server 2025 Standard Core|
|Nom initial du serveur||
|Nom attendu|`SRV-WIN-[TRI]-02`|
|Nom du serveur graphique|`SRV-WIN-[TRI]-01`|
|Nom du poste client|`CLI-WIN-[TRI]-01`|
|Domaine|`TSSR-[TRI].LAB`|
|Adresse IPv4 du serveur Core|`192.168.100.11/24`|
|Passerelle par défaut|Aucune|
|Serveur DNS|`192.168.100.10`|
|Réseau VMware initial|NAT|
|Réseau VMware du laboratoire|`LAB-TSSR-[TRI]`|
|Ressources VM|2 vCPU, 2 Go RAM, disque 64 Go dynamique|
|Outils d’administration|PowerShell, Windows Admin Center|

---

## 1. Objectifs

- [ ] Installer Windows Server 2025 Standard en mode Core, sans Desktop Experience.
- [ ] Identifier les outils d’administration disponibles dans Server Core.
- [ ] Utiliser PowerShell pour consulter les informations système et réseau.
- [ ] Installer VMware Tools et vérifier son fonctionnement.
- [ ] Installer les mises à jour Windows applicables.
- [ ] Configurer le réseau statique du laboratoire.
- [ ] Renommer le serveur et créer un compte administrateur local.
- [ ] Autoriser les requêtes ICMPv4 entrantes dans le pare-feu.
- [ ] Vérifier la connectivité avec le serveur graphique et le client Windows 11.
- [ ] Vérifier la résolution DNS du domaine.
- [ ] Ajouter le serveur à Windows Admin Center et contrôler sa configuration.
- [ ] Mettre à jour la fiche d’identification de la VM.

---

## 2. Installer Windows Server Core

### 2.1 Créer la machine virtuelle

**Paramètres de la machine virtuelle**

| Ressource | Configuration prévue | Configuration constatée |
|---|---|---|
| Processeur | 2 vCPU | |
| Mémoire vive | 2 Go | |
| Disque dur | 64 Go, allocation dynamique | |
| Carte réseau | NAT pour l’installation et les mises à jour | |
| Lecteur CD/DVD | ISO Windows Server 2025 | |
| Édition | Windows Server 2025 Standard (Core) | |

**Étapes**

1. Créer une nouvelle machine virtuelle dans VMware Workstation.
2. Configurer les ressources indiquées dans le tableau.
3. Monter l’ISO Windows Server 2025.
4. Installer **Windows Server 2025 Standard**, sans Desktop Experience.
5. Définir le mot de passe du compte Administrateur local.
6. Ouvrir une session sur le serveur.

> [!question] Question
> Qu’est-ce qui distingue l’installation Server Core d’une installation avec Desktop Experience ?

> [!tip] Guidage
>
> - Observe l’interface disponible après l’ouverture de session.
> - Identifie les outils d’administration accessibles sans interface graphique complète.
> - Explique pourquoi PowerShell est particulièrement important dans cet environnement.

**Captures**

![[Pasted image 20261019140213.png]]

![[Pasted image 20261019135634.png]]

![](attachments/Pasted%20image%2020261019142224.png)

**Commentaires**
```powershell
Correct123-
```


---

### 2.2 Identifier les outils d’administration disponibles

**Étapes**

1. Examiner l’interface affichée après la connexion.
2. Identifier les outils proposés pour la configuration initiale.
3. Ouvrir PowerShell.
4. Rechercher les commandes permettant d’afficher :
   - la version du système d’exploitation ;
   - les caractéristiques de la machine ;
   - les interfaces réseau disponibles.

**Commandes à tester**

```powershell
# Informations sur le système d'exploitation
Get-ComputerInfo

# Nom actuel de la machine
hostname

# Interfaces réseau
Get-NetAdapter

# Configuration IP
Get-NetIPConfiguration
```

> [!question] Questions
> - Quelle version et quelle édition de Windows Server sont installées ?
> - Quel est le nom actuel de la machine ?
> - Quelles interfaces réseau sont présentes et dans quel état se trouvent-elles ?

> [!tip] Guidage
>
> - Repère les propriétés utiles dans la sortie de `Get-ComputerInfo`.
> - Distingue une interface réseau physique/virtuelle de sa configuration IP.
> - Ne recopie que les informations pertinentes dans le tableau.

**Relevés**

| Élément               | Valeur constatée       |
| --------------------- | ---------------------- |
| Nom de l’ordinateur   | WIN-66PKHJ51NC6        |
| Édition Windows       | Server 2025 Datacenter |
| Version / build       | 2009/24H2              |
| Processeur            | 1 cpu 4 cores          |
| Mémoire installée     | 6Go                    |
| Interface réseau      | NAT                    |
| État de l’interface   | OK                     |
| Adresse IPv4 actuelle | 10.0.2.15              |

**Captures**
![](attachments/Pasted%20image%2020261019143758.png)
![](attachments/Pasted%20image%2020261019143851.png)

![](attachments/Pasted%20image%2020261019144131.png)

**Commentaires**

---

## 3. Installer VMware Tools et mettre à jour Windows

### 3.1 Installer VMware Tools

**Étapes**

1. Dans VMware Workstation, monter le média **VMware Tools**.
2. Utiliser PowerShell pour identifier le lecteur contenant les fichiers d’installation.
3. Repérer le programme d’installation.
4. Lancer l’installation depuis PowerShell.
5. Redémarrer le serveur si nécessaire.
6. Vérifier que VMware Tools est installé et que son service fonctionne.

**Commandes à rechercher / compléter**

```powershell
# Lister les volumes disponibles
Get-Volume

# Examiner les lecteurs et leurs fichiers
Get-ChildItem <lettre_du_lecteur>:\

# Rechercher le service VMware Tools
Get-Service *VMware*
```

> [!question] Questions
> - Quelle lettre de lecteur contient le média VMware Tools ?
> - Quel fichier permet de lancer l’installation ?
> - Quel est le nom du service VMware Tools et quel est son état après l’installation ?

> [!tip] Guidage
>
> - Vérifie le contenu du média avant de lancer l’installation.
> - Note la commande réellement utilisée pour démarrer l’installateur.
> - Si un redémarrage est demandé, effectue-le avant de vérifier le service.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Lecteur du média VMware Tools | |
| Programme d’installation | |
| Commande utilisée | |
| Redémarrage nécessaire ? | |
| Nom du service | |
| État du service | |

**Captures**

![](attachments/Pasted%20image%2020261019144842.png)

![](attachments/capture-3.1-installation-vmware-tools.png)

![](attachments/capture-3.1-service-vmware-tools.png)

**Commentaires**

---

### 3.2 Installer les mises à jour Windows

La VM utilise temporairement le réseau NAT de VMware Workstation afin de disposer d’un accès Internet.

**Étapes**

1. Vérifier que la configuration réseau permet l’accès au réseau NAT.
2. Tester la connectivité Internet.
3. Identifier l’outil natif de Server Core permettant de rechercher et d’installer les mises à jour Windows.
4. Rechercher et installer les mises à jour applicables.
5. Redémarrer le serveur si nécessaire.
6. Vérifier l’état des mises à jour après le redémarrage.

**Commandes de vérification réseau**

```powershell
# Vérifier la configuration réseau
Get-NetIPConfiguration

# Tester la connectivité vers une adresse IP publique
Test-NetConnection 1.1.1.1

# Tester la résolution DNS
Resolve-DnsName www.microsoft.com
```

> [!question] Questions
> - Quel outil natif permet de rechercher et d’installer les mises à jour sur Server Core ?
> - L’accès Internet fonctionne-t-il ? Quelle preuve as-tu relevée ?
> - Des redémarrages ont-ils été nécessaires ?
> - Comment as-tu vérifié que les mises à jour sont installées ?

> [!tip] Guidage
>
> - Identifie l’outil disponible sur cette version de Windows Server avant de lancer les mises à jour.
> - Distingue un problème de connectivité IP d’un problème de résolution DNS.
> - Note le résultat des mises à jour et tout redémarrage effectué.
> - Termine les mises à jour **avant de retirer le serveur du réseau NAT**.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Adresse IPv4 pendant la phase NAT | |
| Test de connectivité Internet | |
| Résolution DNS Internet | |
| Outil de mise à jour utilisé | |
| Mises à jour installées | |
| Redémarrage(s) effectué(s) | |
| État final des mises à jour | |

**Captures**

![](attachments/Pasted%20image%2020261019145033.png)

![](attachments/Pasted%20image%2020261019151743.png)

![](attachments/capture-3.2-etat-final-mises-a-jour.png)

> [!warning] Avant de poursuivre
> Termine les mises à jour et les redémarrages nécessaires avant de retirer le serveur du réseau NAT.

**Commentaires**

---

## 4. Configurer le réseau du laboratoire

### 4.1 Modifier le réseau VMware

**Étapes**

1. Arrêter proprement la machine virtuelle.
2. Dans VMware Workstation, modifier sa carte réseau pour utiliser le LAN Segment `LAB-TSSR-[TRI]`.
3. Redémarrer le serveur.
4. Vérifier que l’interface réseau est détectée.

> [!question] Question
> Pourquoi faut-il changer le réseau VMware après les mises à jour ?

> [!tip] Guidage
>
> - Compare l’objectif du réseau NAT avec celui du LAN Segment du laboratoire.
> - Vérifie que le nom du LAN Segment correspond exactement à celui demandé.
> - Note tout changement d’état de l’interface après le redémarrage.

**Captures**

![](attachments/Pasted%20image%2020261019153009.png)

![](attachments/Pasted%20image%2020261019153413.png)

**Commentaires**

---
### 4.2a Préparer SSHD pour controler le serveur depuis mon terminal
1) Installation the open ssh
2) Configuration de open ssh , auto start du service, ouverture firewall
3) Connection via SSH depuis linux, confirmer fingerprints
4) ![](attachments/Pasted%20image%2020261019161318.png)

![](attachments/Pasted%20image%2020261019161333.png)
### 4.2 Configurer l’adresse IPv4 statique avec PowerShell

**Paramètres demandés**

| Paramètre             | Valeur attendue                 | Valeur configurée                                                                                                 |
| --------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Interface réseau      | Interface du LAN du laboratoire |                                                                                                                   |
| Adresse IPv4          | `192.168.100.11`                | PS C:\Users\Administrator> Set-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.100.11 -PrefixLength 24 |
| Préfixe réseau        | `/24`                           | Oui                                                                                                               |
| Masque de sous-réseau | `255.255.255.0`                 |                                                                                                                   |
| Passerelle par défaut | Aucune                          |                                                                                                                   |
| DNS préféré           | `192.168.100.10`                |                                                                                                                   |

**Étapes**

1. Identifier l’interface réseau disponible.
2. Vérifier si une configuration IPv4 automatique est encore active.
3. Désactiver ou supprimer la configuration automatique si nécessaire.
4. Attribuer l’adresse IPv4 statique.
5. Configurer le serveur DNS.
6. Afficher et vérifier la configuration obtenue.

**Commandes à rechercher / compléter**

```powershell
# Identifier les interfaces réseau
Get-NetAdapter

# Afficher la configuration IP
Get-NetIPConfiguration
Get-NetIPAddress -AddressFamily IPv4

# Examiner les paramètres IPv4 de l'interface
Get-NetIPInterface -AddressFamily IPv4

# Configurer une adresse IPv4 statique
New-NetIPAddress -InterfaceAlias "Ethernet" `
  -IPAddress 192.168.100.11 `
  -PrefixLength 24

# Configurer le serveur DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
  -ServerAddresses 192.168.100.10

# Vérifier la configuration finale
Get-NetIPConfiguration
Get-DnsClientServerAddress -AddressFamily IPv4
```

> [!question] Questions
> - Quelle interface réseau as-tu configurée ?
> - La configuration IPv4 automatique était-elle active ?
> - Pourquoi aucune passerelle par défaut n’est-elle demandée dans ce laboratoire ?
> - Quel serveur DNS est configuré et quel rôle joue-t-il dans le domaine ?

> [!tip] Guidage
>
> - Utilise le nom ou l’index réel de l’interface obtenu avec `Get-NetAdapter`.
> - Vérifie l’existence d’une adresse IPv4 déjà configurée avant d’en ajouter une nouvelle.
> - Assure-toi que l’adresse est `192.168.100.11/24` et que le DNS est `192.168.100.10`.
> - Vérifie qu’aucune passerelle par défaut n’a été ajoutée.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Nom de l’interface | |
| Index de l’interface | |
| Configuration IPv4 automatique avant modification | |
| Adresse IPv4 finale | |
| Préfixe | |
| Passerelle par défaut | |
| Serveur DNS | |

**Captures**

![](attachments/capture-4.2-interfaces-reseau.png)

![](attachments/capture-4.2-configuration-ipv4.png)

![](attachments/capture-4.2-configuration-dns.png)

**Commentaires**

---

## 5. Renommer le serveur et créer des comptes locaux

### 5.1 Renommer le serveur

**Étapes**

1. Afficher le nom actuel de la machine.
2. Renommer le serveur en `SRV-WIN-[TRI]-02`.
3. Redémarrer le serveur.
4. Vérifier que le nouveau nom est pris en compte.

**Commandes**

```powershell
# Afficher le nom actuel
hostname
$env:COMPUTERNAME

# Renommer le serveur
Rename-Computer -NewName "SRV-WIN-[TRI]-02"

# Redémarrer le serveur
Restart-Computer
```

> [!question] Question
> Pourquoi faut-il redémarrer le serveur après le changement de nom ?

> [!tip] Guidage
>
> - Remplace `[TRI]` par le code demandé pour ton environnement.
> - Note le nom avant et après le redémarrage.
> - Vérifie que le nom est bien celui attendu avant de poursuivre.

**Relevés**

| Élément | Valeur |
|---|---|
| Nom avant modification | |
| Nom demandé | `SRV-WIN-[TRI]-02` |
| Nom après redémarrage | |
| Redémarrage effectué | |

**Captures**

![](attachments/capture-5.1-nom-avant.png)

![](attachments/capture-5.1-nom-apres-redemarrage.png)

**Commentaires**

---

### 5.2 Créer un compte utilisateur local administrateur

**Étapes**

1. Afficher les comptes utilisateurs locaux existants.
2. Choisir un nom de compte local conforme aux consignes du laboratoire.
3. Créer le compte et définir son mot de passe.
4. Ajouter le compte au groupe local **Administrateurs**.
5. Vérifier que le compte existe, qu’il est activé et qu’il appartient au bon groupe.

**Commandes à rechercher / compléter**

```powershell
# Afficher les comptes locaux
Get-LocalUser

# Créer un mot de passe sécurisé
$Password = Read-Host "Mot de passe du compte local" -AsSecureString

# Créer le compte local
New-LocalUser -Name "<nom_du_compte>" -Password $Password

# Ajouter le compte au groupe Administrateurs
Add-LocalGroupMember -Group "Administrateurs" -Member "<nom_du_compte>"

# Vérifier le compte et les membres du groupe
Get-LocalUser -Name "<nom_du_compte>"
Get-LocalGroupMember -Group "Administrateurs"
```

> [!question] Questions
> - Quel compte local as-tu créé ?
> - Comment vérifier que le compte est activé ?
> - Comment confirmer qu’il appartient au groupe Administrateurs ?
> - Pourquoi est-il utile de disposer d’un compte administrateur local dédié à l’administration distante ?

> [!tip] Guidage
>
> - Utilise un mot de passe conforme aux exigences de sécurité du laboratoire.
> - Vérifie le nom exact du groupe local sur le système.
> - Ne note pas le mot de passe en clair dans ce document.
> - Vérifie à la fois l’état du compte et son appartenance au groupe.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Nom du compte créé | |
| Compte activé | |
| Groupe local | |
| Appartenance au groupe Administrateurs confirmée | |

**Captures**

![](attachments/capture-5.2-comptes-locaux.png)

![](attachments/capture-5.2-compte-administrateur-local.png)

**Commentaires**

---

## 6. Configurer le pare-feu Windows

### 6.1 Autoriser les requêtes ICMPv4 entrantes

**Étapes**

1. Identifier le profil réseau actif.
2. Vérifier l’état du pare-feu Windows.
3. Créer une règle autorisant les requêtes ICMPv4 entrantes.
4. Vérifier que la règle est activée.

**Commandes à tester / compléter**

```powershell
# Identifier le profil réseau actif
Get-NetConnectionProfile

# Vérifier l'état du pare-feu
Get-NetFirewallProfile

# Examiner les règles liées à ICMP
Get-NetFirewallRule | Where-Object DisplayName -Match "ICMP|Echo"

# Créer une règle entrante pour les requêtes ICMPv4
New-NetFirewallRule -DisplayName "Autoriser ICMPv4 entrant - Laboratoire" `
  -Protocol ICMPv4 `
  -IcmpType 8 `
  -Direction Inbound `
  -Action Allow `
  -Enabled True

# Vérifier la règle créée
Get-NetFirewallRule -DisplayName "Autoriser ICMPv4 entrant - Laboratoire"
```

> [!question] Questions
> - Quel profil réseau est actif ?
> - Le pare-feu est-il activé ?
> - Quel type de message ICMPv4 est autorisé par la règle ?
> - Comment vérifier que la règle est activée et qu’elle autorise le trafic entrant ?

> [!tip] Guidage
>
> - Distingue l’état général du pare-feu de l’état d’une règle particulière.
> - Les requêtes Echo ICMPv4 servent aux tests de type `ping`.
> - Vérifie les propriétés `Enabled`, `Direction` et `Action` de la règle.
> - Si une règle équivalente existe déjà, note son nom et vérifie sa configuration.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Profil réseau actif | |
| Pare-feu activé | |
| Nom de la règle ICMPv4 | |
| Règle activée | |
| Direction | |
| Action | |

**Captures**

![](attachments/capture-6.1-profil-reseau.png)

![](attachments/capture-6.1-etat-pare-feu.png)

![](attachments/capture-6.1-regle-icmpv4.png)

**Commentaires**

---

### 6.2 Vérifier la connectivité du laboratoire

**Tests depuis les autres machines**

Depuis `SRV-WIN-[TRI]-01`, tester la réponse ICMP du serveur Core.

```powershell
ping 192.168.100.11
```

Depuis `CLI-WIN-[TRI]-01`, effectuer le même test.

```powershell
ping 192.168.100.11
```

**Tests depuis le serveur Core**

```powershell
# Tester la connectivité IP avec le serveur graphique
Test-NetConnection 192.168.100.10

# Tester la connectivité IP avec le client Windows 11
Test-NetConnection <adresse_IP_du_client>

# Tester la résolution DNS du domaine
Resolve-DnsName TSSR-[TRI].LAB
```

> [!question] Questions
> - Le serveur Core répond-il aux requêtes ICMP provenant du serveur graphique ?
> - Le client Windows 11 obtient-il le même résultat ?
> - Le serveur Core peut-il joindre les deux machines existantes ?
> - La résolution DNS du domaine fonctionne-t-elle ?
> - Si un test échoue, quelles causes possibles faut-il vérifier ?

> [!tip] Guidage
>
> - Note l’adresse IP réelle du client avant le test.
> - Distingue un échec de connectivité IP d’un échec de résolution DNS.
> - Vérifie l’adresse, le préfixe, le LAN Segment VMware et les règles du pare-feu.
> - Pour les tests de nom, relève le serveur DNS interrogé et le résultat retourné.

**Tableau des tests**

| Machine source | Cible | Test effectué | Résultat | Commentaire |
|---|---|---|---|---|
| `SRV-WIN-[TRI]-01` | `192.168.100.11` | `ping` | | |
| `CLI-WIN-[TRI]-01` | `192.168.100.11` | `ping` | | |
| Serveur Core | `192.168.100.10` | `Test-NetConnection` | | |
| Serveur Core | IP du client | `Test-NetConnection` | | |
| Serveur Core | `TSSR-[TRI].LAB` | `Resolve-DnsName` | | |

**Captures**

![](attachments/capture-6.2-ping-depuis-serveur.png)

![](attachments/capture-6.2-ping-depuis-client.png)

![](attachments/capture-6.2-tests-depuis-core.png)

![](attachments/capture-6.2-resolution-dns.png)

**Commentaires**

---

## 7. Administrer le serveur avec Windows Admin Center

### 7.1 Ajouter le serveur à Windows Admin Center

**Étapes**

1. Accéder à la console Windows Admin Center déjà présente dans l’infrastructure.
2. Ajouter une connexion de type **Windows Server**.
3. Renseigner l’adresse IPv4 du serveur Core : `192.168.100.11`.
4. Utiliser un compte administrateur local du serveur Core pour établir la connexion.
5. Vérifier que la connexion fonctionne.

> [!question] Questions
> - La connexion au serveur Core fonctionne-t-elle ?
> - Quel compte a été utilisé pour l’authentification ?
> - Quelles vérifications effectuer si Windows Admin Center ne parvient pas à se connecter ?

> [!tip] Guidage
>
> - Vérifie que le serveur est joignable sur le réseau avant de diagnostiquer Windows Admin Center.
> - Utilise le compte administrateur local créé dans la section 5.2.
> - Note le message affiché en cas d’échec, sans consigner de mot de passe ni d’information sensible.
> - Distingue la connectivité réseau de l’authentification et de la configuration de l’administration distante.

**Relevés**

| Élément | Valeur constatée |
|---|---|
| Adresse renseignée | `192.168.100.11` |
| Type de connexion | Windows Server |
| Compte utilisé | |
| Connexion établie | |
| Message éventuel en cas d’échec | |

**Captures**

![](attachments/capture-7.1-ajout-connexion-wac.png)

![](attachments/capture-7.1-connexion-reussie-wac.png)

**Commentaires**

---

### 7.2 Vérifier la configuration depuis Windows Admin Center

**Éléments à contrôler**

| Élément | Valeur relevée dans Windows Admin Center | Conforme ? |
|---|---|---|
| Nom du serveur | | |
| Version de Windows Server | | |
| Processeurs / vCPU | | |
| Mémoire | | |
| Adresse IPv4 | | |
| Serveur DNS | | |
| Services Windows | | |
| Service VMware Tools | | |
| État du service VMware Tools | | |
| Règle de pare-feu ICMPv4 | | |

> [!question] Question
> Quelles informations peux-tu consulter depuis Windows Admin Center sans ouvrir directement une session PowerShell sur le serveur ?

> [!tip] Guidage
>
> - Compare les informations affichées avec les valeurs relevées dans les sections précédentes.
> - Vérifie particulièrement le nom, la version, la configuration réseau, les services et les règles de pare-feu.
> - Note toute différence et vérifie-la depuis le serveur si nécessaire.

**Captures**

![](attachments/capture-7.2-informations-systeme-wac.png)

![](attachments/capture-7.2-reseau-wac.png)

![](attachments/capture-7.2-services-wac.png)

![](attachments/capture-7.2-pare-feu-wac.png)

**Commentaires**

---

## 8. Validation

> [!check] À valider avant de rendre le TP
> Coche chaque point uniquement si tu peux le **prouver** par une capture, une commande ou une vérification dans Windows Admin Center.

| Vérification | Validé | Preuve |
|---|---|---|
| Windows Server 2025 Standard Core est installé | ☐ | `[[capture-2.1-premiere-session-core.png]]` |
| Les caractéristiques système ont été relevées | ☐ | `[[capture-2.2-get-computerinfo.png]]` |
| VMware Tools est installé et fonctionne | ☐ | `[[capture-3.1-service-vmware-tools.png]]` |
| Les mises à jour applicables ont été installées | ☐ | `[[capture-3.2-etat-final-mises-a-jour.png]]` |
| Le serveur utilise le LAN Segment du laboratoire | ☐ | `[[capture-4.1-lan-segment-vmware.png]]` |
| Le nom du serveur est conforme | ☐ | `[[capture-5.1-nom-apres-redemarrage.png]]` |
| L’adresse IPv4 et le préfixe sont conformes | ☐ | `[[capture-4.2-configuration-ipv4.png]]` |
| Le DNS est configuré sur `192.168.100.10` | ☐ | `[[capture-4.2-configuration-dns.png]]` |
| Un compte administrateur local est présent et activé | ☐ | `[[capture-5.2-compte-administrateur-local.png]]` |
| La règle ICMPv4 entrante est activée | ☐ | `[[capture-6.1-regle-icmpv4.png]]` |
| Le serveur répond au serveur graphique | ☐ | `[[capture-6.2-ping-depuis-serveur.png]]` |
| Le serveur répond au client Windows 11 | ☐ | `[[capture-6.2-ping-depuis-client.png]]` |
| Les tests IP et DNS depuis le Core sont réalisés | ☐ | `[[capture-6.2-tests-depuis-core.png]]` |
| L’administration via Windows Admin Center fonctionne | ☐ | `[[capture-7.1-connexion-reussie-wac.png]]` |
| Les informations système sont vérifiées dans Windows Admin Center | ☐ | `[[capture-7.2-informations-systeme-wac.png]]` |
| La fiche d’identification de la VM est mise à jour | ☐ | |

**Version à cocher**

- [ ] Windows Server 2025 Core est installé et opérationnel.
- [ ] VMware Tools fonctionne.
- [ ] Les mises à jour applicables ont été installées.
- [ ] Le serveur utilise le LAN Segment du laboratoire.
- [ ] Le nom, l’adresse IPv4 et le DNS respectent les consignes.
- [ ] Un compte administrateur local est présent et fonctionnel.
- [ ] Le serveur répond aux requêtes ICMP depuis le serveur graphique et le client Windows 11.
- [ ] Les tests de connectivité IP et de résolution DNS sont réalisés.
- [ ] L’administration distante fonctionne.
- [ ] Le serveur est accessible depuis Windows Admin Center.
- [ ] La fiche d’identification de la VM est à jour.

---

## 9. Documentation

### 9.1 Fiche d’identification de la VM

Mettre à jour la fiche d’identification de la nouvelle VM avec les informations suivantes.

| Élément | Valeur |
|---|---|
| Nom de la VM VMware | |
| Nom Windows | `SRV-WIN-[TRI]-02` |
| Système d’exploitation | Windows Server 2025 Standard Core |
| Version / build | |
| vCPU | 2 |
| Mémoire vive | 2 Go |
| Taille du disque | 64 Go, allocation dynamique |
| Réseau VMware | `LAB-TSSR-[TRI]` |
| Adresse IPv4 / préfixe | `192.168.100.11/24` |
| Passerelle | Aucune |
| Serveur DNS | `192.168.100.10` |
| VMware Tools installé | |
| État des mises à jour | |
| Comptes locaux créés | |
| Administration locale | PowerShell / Server Core |
| Administration distante | Windows Admin Center |
| Connectivité ICMPv4 | |
| Résolution DNS | |

### 9.2 Méthodes d’administration disponibles

| Méthode | Disponible ? | Commentaire |
|---|---|---|
| Console VMware / session locale | | |
| PowerShell | | |
| Windows Admin Center | | |
| Administration distante | | |

**Captures / document de référence**

![](attachments/capture-9.1-fiche-identification-vm.png)

**Commentaires**

---

## 10. Conclusion et difficultés rencontrées

### Difficultés / erreurs rencontrées

> [!tip] Guidage
> Décris le symptôme, la cause identifiée et la correction appliquée. Un incident bien documenté vaut mieux qu’un TP « sans problème ».

| Problème | Cause | Solution |
|---|---|---|
| | | |
| | | |
| | | |

### Ce que j’ai retenu

- 
- 
- 

### Commandes utiles (aide-mémoire)

```powershell
# Informations système
Get-ComputerInfo
hostname

# Réseau
Get-NetAdapter
Get-NetIPConfiguration
Get-NetIPAddress -AddressFamily IPv4
Get-NetIPInterface -AddressFamily IPv4
Get-DnsClientServerAddress -AddressFamily IPv4
Test-NetConnection <adresse_IP>
Resolve-DnsName <nom_DNS>

# VMware Tools
Get-Volume
Get-Service *VMware*

# Comptes locaux
Get-LocalUser
Get-LocalGroupMember -Group "Administrateurs"

# Pare-feu
Get-NetConnectionProfile
Get-NetFirewallProfile
Get-NetFirewallRule

# Nom du serveur
Rename-Computer -NewName "<nouveau_nom>"
Restart-Computer
```

---

> [!note] Rendu
>
> - [ ] Remplacer tous les placeholders `[TRI]` et les valeurs entre chevrons.
> - [ ] Toutes les captures sont insérées et portent des noms cohérents.
> - [ ] Les tableaux de relevés sont remplis avec les valeurs réellement constatées.
> - [ ] Tous les blocs `[!tip]` de guidage sont supprimés ou transformés en notes personnelles.
> - [ ] Les tests de connectivité et DNS sont documentés.
> - [ ] La fiche d’identification de la VM est mise à jour.
> - [ ] Les identifiants et mots de passe ne sont pas consignés dans les notes.
> - [ ] Export PDF réalisé (si demandé).
