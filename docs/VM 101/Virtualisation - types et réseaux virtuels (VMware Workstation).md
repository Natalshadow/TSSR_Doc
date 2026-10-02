

> **Recherches en autonomie**
> 
> 1. Types de virtualisation (définition, rôle, exemples)
> 2. Les différents types de réseaux virtuels (VMware Workstation)

---

## Sommaire

1. [Partie 1 : La virtualisation](#partie-1--la-virtualisation)
    - [Définition](#11-d%C3%A9finition)
    - [Rôle et intérêts](#12-r%C3%B4le-et-int%C3%A9r%C3%AAts)
    - [Les hyperviseurs : type 1 et type 2](#13-les-hyperviseurs--type-1-et-type-2)
    - [Les types de virtualisation](#14-les-types-de-virtualisation)
    - [Tableau récapitulatif](#15-tableau-r%C3%A9capitulatif)
2. [Partie 2 : Les réseaux virtuels sous VMware Workstation](#partie-2--les-r%C3%A9seaux-virtuels-sous-vmware-workstation)
    - [Vue d'ensemble](#21-vue-densemble)
    - [NAT](#22-nat)
    - [Bridged](#23-bridged-acc%C3%A8s-par-pont)
    - [Host-only](#24-host-only)
    - [LAN Segment](#25-lan-segment)
    - [Custom](#26-custom)
    - [Déconnecter la VM](#27-d%C3%A9connecter-la-vm)
    - [Tableau récapitulatif des flux](#28-tableau-r%C3%A9capitulatif-des-flux)
    - [Quel mode choisir ?](#29-quel-mode-choisir-)
3. [Questions de révision](#questions-de-r%C3%A9vision)
4. [Sources](#sources)

---

# Partie 1 : La virtualisation

## 1.1 Définition

La **virtualisation** consiste à créer, grâce à une couche logicielle, une **version virtuelle** d'une ressource informatique (machine, système d'exploitation, stockage, réseau, application…) à la place d'une ressource physique dédiée.

Le principe central : **abstraire** les ressources matérielles (CPU, RAM, disque, carte réseau) pour les **partager** entre plusieurs environnements isolés les uns des autres.

Quelques termes à connaître :

|Terme|Définition|
|---|---|
|**Hôte (host)**|La machine physique (ou le système) qui fournit les ressources.|
|**Invité (guest)**|La machine virtuelle (VM) ou l'environnement qui consomme ces ressources.|
|**Machine virtuelle (VM)**|Un ordinateur logiciel complet (CPU, RAM, disque, carte réseau virtuels) avec son propre OS.|
|**Hyperviseur**|Le logiciel qui crée et fait fonctionner les VM en répartissant les ressources de l'hôte.|

## 1.2 Rôle et intérêts

**Rôle** : faire fonctionner plusieurs systèmes ou services isolés sur un même matériel, et rendre l'infrastructure plus souple.

**Principaux avantages**

- **Mutualisation / consolidation** : moins de serveurs physiques, donc moins de coûts (matériel, énergie, place, refroidissement).
- **Isolation** : un plantage ou une compromission dans une VM n'affecte pas (en principe) les autres.
- **Flexibilité** : création, clonage, déplacement ou suppression d'une VM en quelques minutes.
- **Snapshots et sauvegardes** : retour à un état antérieur facile, utile pour les tests.
- **Environnements de test et de labo** : on peut casser sans risque une installation.
- **Continuité de service** : migration à chaud, haute disponibilité, reprise après sinistre.
- **Compatibilité** : faire tourner un ancien OS ou un autre système (ex. Linux sur un PC Windows).

**Limites à garder en tête**

- Perte de performance (faible mais réelle) par rapport au matériel nu.
- L'hôte devient un **point de défaillance unique** s'il n'est pas redondé.
- Risque de **« VM sprawl »** (prolifération de VM mal suivies).
- Gestion des licences et de la sécurité de l'hyperviseur.

## 1.3 Les hyperviseurs : type 1 et type 2

L'hyperviseur est le cœur de la virtualisation de machines. On en distingue deux familles.

### Hyperviseur de type 1 (« bare metal »)

Il s'installe **directement sur le matériel**, sans système d'exploitation intermédiaire. Il est plus performant et est utilisé en **production** (datacenters).

```
┌────────┐ ┌────────┐ ┌────────┐
│  VM 1  │ │  VM 2  │ │  VM 3  │
├────────┴─┴────────┴─┴────────┤
│    Hyperviseur (type 1)      │
├──────────────────────────────┤
│       Matériel physique      │
└──────────────────────────────┘
```

**Exemples** : VMware ESXi, Microsoft Hyper-V, Proxmox VE / KVM, Xen, Citrix Hypervisor.

### Hyperviseur de type 2 (« hosted »)

Il s'installe **comme une application** au-dessus d'un système d'exploitation existant. Plus simple à mettre en place, il est adapté au **poste de travail**, aux tests et à l'apprentissage, mais avec un peu plus de surcharge.

```
┌────────┐ ┌────────┐ ┌────────┐
│  VM 1  │ │  VM 2  │ │  VM 3  │
├────────┴─┴────────┴─┴────────┤
│    Hyperviseur (type 2)      │
├──────────────────────────────┤
│   Système d'exploitation hôte│
├──────────────────────────────┤
│       Matériel physique      │
└──────────────────────────────┘
```

**Exemples** : **VMware Workstation**, VMware Fusion, Oracle VirtualBox, Parallels Desktop.

### Comparatif

|Critère|Type 1 (bare metal)|Type 2 (hosted)|
|---|---|---|
|Installation|Directement sur le matériel|Sur un OS existant|
|Performances|Meilleures|Un peu inférieures|
|Usage typique|Serveurs, production|Poste de travail, labo, tests|
|Exemples|ESXi, Hyper-V, Proxmox/KVM, Xen|VMware Workstation, VirtualBox|

> **Remarque** : la frontière n'est pas toujours nette. KVM, par exemple, est un module du noyau Linux : on le classe généralement en type 1, car le noyau lui-même joue le rôle d'hyperviseur.

## 1.4 Les types de virtualisation

### a) Virtualisation de serveurs / de machines (matérielle)

- **Définition** : une machine physique héberge plusieurs VM, chacune avec son propre OS complet.
- **Rôle** : consolider les serveurs, isoler les services, disposer de labos.
- **Exemples** : VMware vSphere/ESXi, Hyper-V, Proxmox, KVM, VMware Workstation, VirtualBox.

Cette virtualisation peut elle-même se décliner selon la technique employée :

|Technique|Principe|Remarque|
|---|---|---|
|**Virtualisation complète** (full virtualization)|L'OS invité n'est pas modifié et ne « sait » pas qu'il est virtualisé.|Cas le plus courant aujourd'hui.|
|**Paravirtualisation**|L'OS invité est adapté pour dialoguer directement avec l'hyperviseur.|Meilleures performances, mais OS modifié (ex. Xen).|
|**Virtualisation assistée par le matériel**|Utilise les extensions du processeur (Intel VT-x, AMD-V).|Indispensable pour les hyperviseurs modernes.|

### b) Virtualisation au niveau du système d'exploitation (conteneurs)

- **Définition** : au lieu de virtualiser une machine entière, on isole des **processus** qui partagent **le même noyau** que l'hôte. On parle de **conteneurs**.
- **Rôle** : déployer des applications de façon légère, rapide et reproductible (DevOps, microservices).
- **Avantages** : démarrage en secondes, très léger, forte densité. **Limite** : isolation moins forte qu'une VM et noyau partagé (un conteneur Linux a besoin d'un noyau Linux).
- **Exemples** : Docker, Podman, LXC/LXD, Kubernetes (orchestrateur de conteneurs).

|           | Machine virtuelle             | Conteneur                  |
| --------- | ----------------------------- | -------------------------- |
| OS invité | Complet, noyau propre         | Partage le noyau de l'hôte |
| Poids     | Lourd (Go)                    | Léger (Mo)                 |
| Démarrage | Quelques dizaines de secondes | Quelques secondes          |
| Isolation | Forte                         | Plus faible                |

### c) Virtualisation de postes de travail (VDI)

- **Définition** : le bureau de l'utilisateur tourne sur un **serveur central** et s'affiche à distance sur un terminal léger ou un PC.
- **Rôle** : centraliser la gestion des postes, sécuriser les données, faciliter le télétravail.
- **Exemples** : VMware Horizon, Citrix Virtual Apps and Desktops, Microsoft Azure Virtual Desktop, Windows 365.

### d) Virtualisation d'applications

- **Définition** : l'application est exécutée dans un environnement isolé ou diffusée depuis un serveur, **sans être installée** de façon classique sur le poste.
- **Rôle** : éviter les conflits entre applications, simplifier le déploiement et les mises à jour.
- **Exemples** : Microsoft App-V, Citrix Virtual Apps, VMware ThinApp, applications Flatpak/Snap (isolation).

### e) Virtualisation du stockage

- **Définition** : regrouper plusieurs supports physiques (disques, baies) en un **espace logique unique**, géré indépendamment du matériel.
- **Rôle** : simplifier la gestion, l'extension et la redondance des données.
- **Exemples** : SAN, LVM sous Linux, ZFS, VMware vSAN, Ceph, RAID logiciel.

### f) Virtualisation du réseau

- **Définition** : reproduire par logiciel les composants d'un réseau (commutateurs, routeurs, pare-feu, réseaux locaux) indépendamment de l'infrastructure physique.
- **Rôle** : créer des réseaux isolés ou complexes sans toucher au câblage, segmenter, tester.
- **Exemples** : VLAN, VPN, SDN (_Software Defined Networking_), VMware NSX, Open vSwitch, **réseaux virtuels de VMware Workstation** (voir partie 2).

### g) Émulation (à ne pas confondre)

- **Définition** : un logiciel **imite** une architecture matérielle différente (par exemple faire tourner un programme ARM sur un PC x86).
- **Différence** : la virtualisation partage le matériel **réel** avec la même architecture ; l'émulation **simule** un matériel, ce qui est plus lent.
- **Exemples** : QEMU (en mode émulation), émulateurs de consoles, Android Studio Emulator.

## 1.5 Tableau récapitulatif

|Type|Ce qui est virtualisé|Exemples|
|---|---|---|
|Serveurs / machines|Un ordinateur complet (VM)|ESXi, Hyper-V, Proxmox, VMware Workstation, VirtualBox|
|Conteneurs (niveau OS)|L'espace utilisateur, noyau partagé|Docker, Podman, LXC, Kubernetes|
|Postes de travail (VDI)|Le bureau de l'utilisateur|VMware Horizon, Citrix, Azure Virtual Desktop|
|Applications|L'exécution/déploiement d'une appli|App-V, ThinApp, Flatpak|
|Stockage|Les supports de données|LVM, ZFS, SAN, vSAN, Ceph|
|Réseau|Commutateurs, routeurs, LAN|VLAN, SDN, NSX, Open vSwitch|

---

# Partie 2 : Les réseaux virtuels sous VMware Workstation

## 2.1 Vue d'ensemble

**VMware Workstation Pro** est un hyperviseur de **type 2**. Chaque VM dispose d'une ou plusieurs **cartes réseau virtuelles**, que l'on relie à un **réseau virtuel** (un commutateur logiciel géré par VMware).

Selon le mode choisi, la VM pourra ou non :

- communiquer avec les **autres VM**,
- joindre l'**hôte physique**,
- joindre le **réseau local** (LAN) réel,
- accéder à **Internet**,
- être **jointe depuis l'extérieur**.

Dans les paramètres réseau d'une VM, on trouve 5 modes : **Bridged, NAT, Host-only, Custom, LAN Segment**.

La configuration globale des réseaux virtuels se fait dans le **Virtual Network Editor** :

> **Edit → Virtual Network Editor** (droits administrateur requis pour modifier : bouton _Change Settings_)

## 2.2 NAT

> _Option dans la VM : « NAT: Used to share the host's IP address »_

**C'est le mode par défaut** quand on crée une VM.

**Fonctionnement**

- VMware crée un **réseau local virtuel privé** et fait office de **routeur NAT** entre ce réseau et le réseau de l'hôte.
- Un **serveur DHCP intégré à VMware** attribue les adresses aux VM : le DHCP de la box/du routeur n'est pas sollicité.
- Vers l'extérieur, la VM **partage l'adresse IP de l'hôte** (principe du NAT).

**Ce qui est possible**

- VM ↔ autres VM du même réseau NAT.
- VM → hôte, réseau local, Internet.

**Limite**

- Une machine du réseau local **ne peut pas initier** de connexion vers la VM (RDP, site web…), car la VM est cachée derrière le NAT.
- **Contournement** : créer une **règle de redirection de port** (_Port Forwarding_).

**Configuration utile** (Virtual Network Editor → sélectionner _NAT_ → _Change Settings_)

- Il ne peut exister **qu'un seul réseau NAT**.
- Le sous-réseau est modifiable (exemple de l'article : `192.168.145.0/24`).
- **DHCP Settings** : modifier l'étendue DHCP.
- Pour tester son propre serveur DHCP dans une VM, **décocher** _Use local DHCP service to distribute IP address to VMs_.
- **NAT Settings → Port Forwarding** : par exemple, rediriger le port `8080` de l'hôte vers le port `80` d'une VM en `192.168.145.128`.

> **Astuce** : si la VM change d'adresse IP, la règle de redirection devient fausse. On utilise donc de préférence une **adresse IP fixe** pour la VM concernée.

```
 Internet / LAN
       │
 [ Hôte physique ]  ← IP de l'hôte partagée
       │  (NAT VMware + DHCP VMware)
 ┌─────┴──────┐
 │ Réseau NAT │ 192.168.145.0/24
 └──┬──────┬──┘
   VM1    VM2
```

## 2.3 Bridged (accès par pont)

> _Option dans la VM : « Bridged: Connected directly to the physical network »_

**Fonctionnement**

- La carte virtuelle est **« pontée »** avec la carte physique de l'hôte : la VM apparaît comme **une machine à part entière sur le réseau local**.
- En DHCP, elle obtient son adresse auprès du **DHCP du réseau local** (box, routeur, serveur).

**Ce qui est possible**

- VM ↔ autres VM, hôte, **autres machines du LAN**, Internet.
- Contrairement au NAT, la VM **peut être jointe** par les autres machines du réseau.

**Points d'attention**

- Option **Replicate physical network connection state** : la VM renouvelle son IP quand l'hôte change de réseau ou de carte (utile sur un portable).
- Dans le Virtual Network Editor, le pont est en **Auto-bridging** par défaut : VMware se lie à la carte réseau utilisée par l'hôte (par exemple le Wi-Fi si l'hôte est en Wi-Fi). On peut aussi **choisir manuellement** la carte.
- On peut créer **plusieurs réseaux Bridged**, mais **chacun doit être associé à une interface physique différente** (par exemple un pour la carte filaire, un pour le Wi-Fi).
- La VM étant visible sur le réseau réel, elle est **exposée** : à n'utiliser qu'en connaissance de cause (sécurité, conflits d'adresses IP).

```
 Internet ── Box/Routeur ── LAN ── [ Hôte ]
                             │
                             └──────── VM (a une IP du LAN)
```

## 2.4 Host-only

> _Option dans la VM : « Host-only: A private network shared with the host »_

**Fonctionnement**

- Réseau **privé** entre l'hôte physique et les VM connectées.
- **Aucun lien** avec la carte physique : pas d'accès au réseau local ni à Internet.
- Un **serveur DHCP VMware** est actif sur un sous-réseau **différent de celui du NAT** (personnalisable ou désactivable).

**Ce qui est possible**

- VM ↔ autres VM du même réseau Host-only.
- VM ↔ hôte physique.
- ❌ VM → LAN / Internet.

**Usage typique** : tester une application ou un service que l'on administre depuis l'hôte, dans un environnement fermé.

On peut créer **d'autres réseaux Host-only** via _Add Network_ dans le Virtual Network Editor.

## 2.5 LAN Segment

> _Option dans la VM : « LAN Segment »_

**Fonctionnement**

- Crée un réseau interne **totalement isolé** : seules les VM rattachées au **même segment** peuvent communiquer.
- Pas d'accès à l'**hôte**, ni au **LAN**, ni à **Internet**.
- **Pas de DHCP VMware** : c'est à vous de gérer le plan d'adressage (serveur DHCP dans une VM, ou IP fixes).

**Intérêt**

- Reproduire un **vrai réseau d'entreprise** en laboratoire.
- Tester son propre **serveur DHCP** sans risque de perturber le réseau de production et sans interférence du DHCP de la box ou de VMware.
- On peut créer **plusieurs segments** isolés les uns des autres (_LAN Segments… → Add_, puis rattacher chaque VM au segment voulu).

**Donner un accès Internet à un LAN Segment**

On ajoute une **VM routeur/pare-feu** à **deux cartes réseau** :

- carte 1 → **LAN Segment** (côté réseau interne),
- carte 2 → **NAT** (côté Internet).

Cette VM (pfSense, OPNsense, ou un Linux/Windows avec routage activé) route le trafic du réseau interne vers l'extérieur, comme dans un vrai réseau.

```
 VM1 ─┐
      ├─ [LAN Segment "LAN_VM"] ─ VM3 (routeur/pare-feu) ─ [NAT] ─ Internet
 VM2 ─┘
```

## 2.6 Custom

> _Option dans la VM : « Custom: Specific virtual network »_

**Principe** : on choisit **directement un adaptateur virtuel précis** (VMnet) déclaré dans le Virtual Network Editor.

Chaque adaptateur est associé à un type de réseau (NAT, Host-only ou Bridged). Les modes classiques suffisent tant qu'on n'a qu'un réseau de chaque type. **Dès qu'on crée plusieurs réseaux Host-only ou Bridged**, le mode **Custom** devient nécessaire pour désigner le bon.

## 2.7 Déconnecter la VM

Pour simuler un câble réseau débranché, on **décoche** l'option **Connect at power on** dans les options de l'adaptateur réseau de la VM.

## 2.8 Tableau récapitulatif des flux

Synthèse construite à partir des explications ci-dessus.

|Mode|VM ↔ VM (même réseau)|VM → Hôte|VM → LAN|VM → Internet|LAN → VM|DHCP|
|---|:-:|:-:|:-:|:-:|:-:|---|
|**NAT**|✅|✅|✅ (via NAT)|✅ (via NAT)|❌ (sauf redirection de port)|VMware|
|**Bridged**|✅|✅|✅|✅|✅|Réseau local (box/routeur)|
|**Host-only**|✅|✅|❌|❌|❌|VMware (sous-réseau propre)|
|**LAN Segment**|✅|❌|❌|❌|❌|Aucun (à gérer soi-même)|
|**Custom**|Dépend du VMnet choisi||||||

## 2.9 Quel mode choisir ?

|Besoin|Mode conseillé|
|---|---|
|Donner Internet à la VM simplement|**NAT**|
|Héberger un service accessible depuis le LAN (serveur web, RDP…)|**Bridged** (ou NAT + redirection de port)|
|Isoler la VM d'Internet tout en la gérant depuis l'hôte|**Host-only**|
|Monter un lab réseau complet, isolé, avec son propre DHCP / routeur|**LAN Segment**|
|Choisir un réseau précis parmi plusieurs|**Custom**|

---

# Questions de révision

1. Qu'est-ce que la virtualisation ? Quels sont ses principaux avantages ?
2. Quelle est la différence entre un hyperviseur de type 1 et de type 2 ? Dans quelle catégorie classe-t-on VMware Workstation ?
3. Quelle est la différence entre une VM et un conteneur ?
4. En quoi la virtualisation diffère-t-elle de l'émulation ?
5. Quel est le mode réseau par défaut d'une VM sous VMware Workstation ?
6. Une VM en NAT peut-elle être jointe depuis le réseau local ? Comment contourner cette limite ?
7. Quelle différence d'adressage IP entre le mode NAT et le mode Bridged ?
8. Pourquoi le mode LAN Segment est-il idéal pour tester un serveur DHCP ?
9. Comment donner un accès Internet à des VM placées dans un LAN Segment ?
10. Dans quel cas faut-il utiliser le mode Custom ?

<details> <summary>Éléments de réponse</summary>

1. Création par logiciel de ressources virtuelles à partir de ressources physiques partagées ; avantages : mutualisation, isolation, flexibilité, snapshots, labos de test.
2. Type 1 : directement sur le matériel (ESXi, Hyper-V, KVM). Type 2 : installé sur un OS hôte (Workstation, VirtualBox). Workstation = type 2.
3. La VM embarque un OS complet avec son noyau (lourde, forte isolation) ; le conteneur partage le noyau de l'hôte (léger, démarrage rapide).
4. La virtualisation partage le matériel réel (même architecture) ; l'émulation simule un autre matériel (plus lente).
5. NAT.
6. Non par défaut ; il faut une règle de redirection de port (_Port Forwarding_) dans les paramètres NAT.
7. NAT : IP attribuée par le DHCP de VMware, dans un réseau privé virtuel. Bridged : IP du réseau local, attribuée par son DHCP (box/routeur).
8. Réseau totalement isolé : aucun DHCP VMware n'interfère, et le réseau de production n'est pas perturbé.
9. Ajouter une VM routeur/pare-feu avec une carte dans le LAN Segment et une carte en NAT.
10. Quand on a créé plusieurs réseaux virtuels (par exemple plusieurs Host-only ou Bridged) et qu'il faut désigner le bon.

</details>

---

# Sources

- IT-Connect, _Comprendre les différents types de réseaux de VMware Workstation Pro_ (Florian Burnel) : https://www.it-connect.fr/comprendre-les-differents-types-de-reseaux-de-vmware-workstation-pro/ : base de la partie 2.
- Partie 1 : connaissances générales sur la virtualisation, à compléter avec la documentation officielle de VMware, Microsoft, Docker, etc. si votre cours exige des sources citées.