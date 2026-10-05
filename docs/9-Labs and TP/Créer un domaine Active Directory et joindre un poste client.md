## 1. Informations de l'environnement

|**Élément**|**Valeur**|
|---|---|
|**Serveur**|`SRV-WIN-MEN-01`|
|**Client**|`CLI-WIN-MEN-01`|
|**Réseau**|`LAB-TSSR-MEN`|
|**IP Serveur**|`192.168.100.10/24`|
|**IP Client**|`192.168.100.100/24`|
|**Domaine**|`TSSR-MEN.LAB`|

---

## 2. Étape 1 : Installation des RSAT sur le client

Depuis `CLI-WIN-MEN-01`, installation des outils RSAT nécessaires :

- **Active Directory Users and Computers**
- **DNS**

> _[Insérer ici une capture d'écran de l'installation des RSAT depuis Paramètres > Fonctionnalités facultatives ou via PowerShell]_
![](attachments/Pasted%20image%2020261005135349.png)
 Ajout d'une nouvelle carte réseau pour accès WAN.
![](attachments/Pasted%20image%2020261005135651.png)

![](attachments/Pasted%20image%2020261005135849.png)

![](attachments/Pasted%20image%2020261005135857.png)

RSAT s'affiche bien dans les fonctionnalités installées :
![](attachments/Pasted%20image%2020261005142008.png)

---
## 3. Étape 2 : Création du domaine Active Directory

### 3.1 Vérification de la configuration IP du serveur

> [!note] Guide étudiant Avant toute chose, confirmer que le serveur a bien son IP statique en place depuis le TP précédent. Un contrôleur de domaine ne doit jamais changer d'IP après promotion — le DNS et les clients dépendent de cette adresse.

```
ipconfig /all
```

> _[Insérer ici la capture de `ipconfig /all` sur `SRV-WIN-MEN-01` confirmant l'IP `192.168.100.10`]_

### 3.2 Installation du rôle AD DS

> [!note] Guide étudiant **Dans le Gestionnaire de serveur (`Server Manager`) :**
> 
> 1. Cliquer sur **Gérer** (en haut à droite) > **Ajouter des rôles et fonctionnalités**
> 2. Type d'installation : **Installation basée sur un rôle ou une fonctionnalité**
> 3. Sélectionner `SRV-WIN-MEN-01` dans le pool de serveurs
> 4. Cocher **Services de domaine Active Directory (AD DS)**
> 5. Quand la fenêtre propose d'ajouter les fonctionnalités requises, cliquer **Ajouter des fonctionnalités**
> 6. Laisser les fonctionnalités par défaut, ne rien cocher de plus
> 7. Cliquer **Suivant** jusqu'à **Installer**
> 8. Attendre la fin de l'installation — ne pas fermer la fenêtre

Installation du rôle **Services de domaine Active Directory (AD DS)** via le Gestionnaire de serveur.

> _[Insérer ici une capture de l'assistant d'ajout de rôles avec AD DS sélectionné]_
![](attachments/Pasted%20image%2020261005142239.png)
j J'ai pensé à vérifié dans l'installation ADDS si c'est aussi ici que se trouve RSAT pour le côté serveur et c'est effectivement le cas:
![](attachments/Pasted%20image%2020261005142338.png)
Installation en cours
![](attachments/Pasted%20image%2020261005142434.png)
> _[Insérer ici une capture de la fin d'installation du rôle]_

### 3.3 Promotion en contrôleur de domaine

> [!note] Guide étudiant Une fois le rôle installé, une notification apparaît dans le Gestionnaire de serveur (icône drapeau en haut). Cliquer dessus > **Promouvoir ce serveur en contrôleur de domaine**.
> 
> **Dans l'assistant de configuration AD DS :**
> 
> 1. Choisir **Ajouter une nouvelle forêt**
> 2. Nom de domaine racine : `TSSR-MEN.LAB`
> 3. Cliquer **Suivant**
> 4. Niveau fonctionnel forêt/domaine : laisser la valeur par défaut (Windows Server 2016 ou supérieur)
> 5. Cocher **Serveur DNS** si ce n'est pas déjà fait
> 6. Définir un mot de passe DSRM (mot de passe de restauration des services d'annuaire) — le noter
> 7. Ignorer l'avertissement de délégation DNS — normal à ce stade
> 8. Le nom NetBIOS se remplit automatiquement : `TSSR-MEN` — vérifier et laisser
> 9. Chemins des dossiers NTDS, SYSVOL, logs : laisser par défaut
> 10. Passer en revue les options, puis cliquer **Suivant**
> 11. Vérification des prérequis — des avertissements en jaune sont normaux, les erreurs en rouge bloquent
> 12. Cliquer **Installer** — le serveur redémarre automatiquement à la fin
> 
> ⚠️ Ne pas interrompre le redémarrage.

Lancement de l'assistant de promotion du serveur en contrôleur de domaine :

- Création d'une **nouvelle forêt**
- Domaine : `TSSR-MEN.LAB`
- Installation de **DNS** lors de l'assistant

> _[Insérer ici une capture de l'assistant de promotion — étape nouvelle forêt]_

> _[Insérer ici une capture de la configuration DNS dans l'assistant]_

> _[Insérer ici une capture de la vérification des prérequis avant promotion]_

> _[Insérer ici une capture du redémarrage automatique post-promotion]_

### 3.4 Contrôles après redémarrage

> [!note] Guide étudiant Après redémarrage, se connecter avec `TSSR-MEN\Administrator` (le compte local est maintenant le compte Administrateur du domaine).
> 
> **Vérifications à effectuer :**
> 
> - Gestionnaire de serveur > Outils > **Utilisateurs et ordinateurs Active Directory** — doit s'ouvrir et afficher `TSSR-MEN.LAB`
> - Gestionnaire de serveur > Outils > **DNS** — doit afficher une zone de recherche directe `TSSR-MEN.LAB`
> - En ligne de commande : `dcdiag /test:services` pour vérifier l'état des services AD

|**Contrôle**|**Résultat**|
|---|---|
|Serveur contrôleur du domaine `TSSR-MEN.LAB`|✅ / ❌|
|Console Utilisateurs et ordinateurs AD opérationnelle|✅ / ❌|
|Zone DNS correspondant au domaine présente|✅ / ❌|

> _[Insérer ici une capture de la console Utilisateurs et ordinateurs Active Directory]_

> _[Insérer ici une capture de la console DNS avec la zone TSSR-MEN.LAB]_

---

## 4. Étape 3 : Jonction du poste Windows 11 au domaine

### 4.1 Configuration du DNS préféré sur le client

> [!note] Guide étudiant **Critique :** le client doit utiliser le serveur comme DNS avant de tenter la jonction. Sans ça, Windows 11 ne pourra pas résoudre `TSSR-MEN.LAB` et la jonction échouera.
> 
> **Procédure :**
> 
> 1. Panneau de configuration > Centre Réseau et partage > Modifier les paramètres de la carte
> 2. Clic droit sur la carte réseau du LAN Segment > Propriétés
> 3. Sélectionner **Protocole Internet version 4 (TCP/IPv4)** > Propriétés
> 4. Serveur DNS préféré : `192.168.100.10`
> 5. Valider
> 
> **Tester la résolution DNS :**
> 
> ```
> nslookup TSSR-MEN.LAB
> ```
> 
> Le résultat doit retourner l'IP `192.168.100.10`. Si ce n'est pas le cas, ne pas continuer.

Sur `CLI-WIN-MEN-01`, configuration du DNS préféré sur `192.168.100.10`.

> _[Insérer ici une capture des paramètres réseau du client avec le DNS configuré]_

> _[Insérer ici une capture du résultat de `nslookup TSSR-MEN.LAB`]_

### 4.2 Jonction au domaine

> [!note] Guide étudiant **Deux méthodes possibles :**
> 
> **Méthode 1 — Via les Paramètres Windows 11 :** Paramètres > Comptes > Accès professionnel ou scolaire > Connecter > Joindre ce périphérique à un domaine Active Directory local > entrer `TSSR-MEN.LAB`
> 
> **Méthode 2 — Via le Panneau de configuration (classique) :**
> 
> 1. Clic droit sur le menu Démarrer > Système
> 2. Paramètres système avancés > Nom de l'ordinateur > Modifier
> 3. Cocher **Domaine** > entrer `TSSR-MEN.LAB`
> 4. Entrer les identifiants : `Administrator` / mot de passe du domaine
> 5. Message de bienvenue dans le domaine = succès
> 6. Redémarrer quand demandé
> 
> ⚠️ Si la jonction échoue, appliquer le réflexe de diagnostic (section 4.4).

Jonction au domaine `TSSR-MEN.LAB` avec un compte autorisé.

> _[Insérer ici une capture de la fenêtre de jonction au domaine]_

> _[Insérer ici une capture de la demande d'identifiants]_

> _[Insérer ici une capture du message de confirmation de jonction au domaine]_

### 4.3 Redémarrage et ouverture de session domaine

> [!note] Guide étudiant À l'écran de connexion Windows 11, cliquer sur **Autre utilisateur** pour voir apparaître le champ domaine. Se connecter avec : `TSSR-MEN\Administrator` (ou tout autre compte du domaine créé sur le serveur). Vérification rapide : ouvrir un terminal et taper `whoami` — le résultat doit afficher `tssr-men\administrator`.

Redémarrage du poste, puis ouverture de session avec un compte du domaine `TSSR-MEN.LAB`.

> _[Insérer ici une capture de l'écran de connexion avec le compte domaine]_

> _[Insérer ici une capture du bureau confirmant la session domaine active]_

### 4.4 Réflexe de diagnostic

En cas d'échec de jonction, ordre de vérification :

1. Connectivité IP → `ping 192.168.100.10`
2. DNS du client → `nslookup TSSR-MEN.LAB`
3. Résolution du domaine → `nslookup -type=SRV _ldap._tcp.TSSR-MEN.LAB`
4. Identifiants utilisés

---

## 5. Étape 4 : Création d'une console MMC d'administration

> [!note] Guide étudiant La console MMC (Microsoft Management Console) permet de regrouper plusieurs outils d'administration dans une interface unique. Utile pour administrer AD et DNS sans ouvrir deux fenêtres séparées.
> 
> **Procédure depuis `CLI-WIN-MEN-01` :**
> 
> 1. `Win + R` > taper `mmc` > Entrée (en tant qu'Administrateur si demandé)
> 2. Fichier > **Ajouter/Supprimer un composant logiciel enfichable**
> 3. Dans la liste de gauche, sélectionner **Utilisateurs et ordinateurs Active Directory** > Ajouter
> 4. Sélectionner **DNS** > Ajouter > choisir `CLI-WIN-MEN-01` ou `SRV-WIN-MEN-01`
> 5. Valider avec OK
> 6. Fichier > **Enregistrer sous** > donner un nom explicite, ex : `Admin-TSSR-MEN.msc`
> 7. Enregistrer dans un emplacement accessible, ex : le Bureau ou Documents
> 
> Vérification : fermer la console et la rouvrir depuis le fichier `.msc` enregistré — les deux composants doivent être présents.

Création d'une console MMC personnalisée contenant :

- **Utilisateurs et ordinateurs Active Directory**
- **DNS**

Console enregistrée sous : `_[Nom de la console]_`

> _[Insérer ici une capture de la console MMC personnalisée avec les deux composants logiciels enfichables]_

---

## 6. Étape 5 : Bureau à distance (RDP)

### 6.1 Activation de RDP

> [!note] Guide étudiant **Sur Windows Server 2025 (`SRV-WIN-MEN-01`) :** Gestionnaire de serveur > Serveur local > Bureau à distance : cliquer sur **Désactivé** pour basculer sur **Activé**. Accepter la règle de pare-feu automatiquement proposée.
> 
> **Sur Windows 11 (`CLI-WIN-MEN-01`) :** Paramètres > Système > Bureau à distance > activer le bouton.
> 
> ⚠️ Sur Windows 11 Famille (Home), RDP entrant n'est pas disponible. Windows 11 Pro est requis — ce qui est le cas dans ce lab.
> 
> **Vérification pare-feu :** si RDP échoue, vérifier que la règle **Bureau à distance (TCP-In)** est active dans le pare-feu Windows des deux machines.

Activation du Bureau à distance sur le serveur et le client.

> _[Insérer ici une capture des paramètres RDP activés sur `SRV-WIN-MEN-01`]_

> _[Insérer ici une capture des paramètres RDP activés sur `CLI-WIN-MEN-01`]_

### 6.2 Test RDP Client → Serveur

> [!note] Guide étudiant Depuis `CLI-WIN-MEN-01` :
> 
> 1. `Win + R` > `mstsc`
> 2. Ordinateur : `192.168.100.10` (ou `SRV-WIN-MEN-01.TSSR-MEN.LAB`)
> 3. Se connecter avec les identifiants du domaine
> 4. Accepter le certificat si demandé

```
mstsc
```

Connexion de `CLI-WIN-MEN-01` vers `SRV-WIN-MEN-01` (`192.168.100.10`).

> _[Insérer ici une capture de la session RDP client → serveur établie]_

### 6.3 Test RDP Serveur → Client

> [!note] Guide étudiant Depuis `SRV-WIN-MEN-01`, même procédure avec l'IP `192.168.100.100`. S'assurer que le compte utilisé est membre du groupe **Utilisateurs du Bureau à distance** sur le client, ou un compte Administrateur du domaine.

Connexion de `SRV-WIN-MEN-01` vers `CLI-WIN-MEN-01` (`192.168.100.100`).

> _[Insérer ici une capture de la session RDP serveur → client établie]_

---

## 7. Validation finale

|**Critère de validation**|**Résultat**|
|---|---|
|Le domaine `TSSR-MEN.LAB` existe|✅ / ❌|
|Le client est membre du domaine|✅ / ❌|
|Le client utilise le DNS du serveur (`192.168.100.10`)|✅ / ❌|
|Les consoles AD et DNS sont administrables depuis le client via RSAT|✅ / ❌|
|La console MMC personnalisée fonctionne|✅ / ❌|
|RDP fonctionnel dans les deux sens|✅ / ❌|

---

## 8. Mise à jour des fiches d'identification des VMs

### SRV-WIN-MEN-01

|**Élément**|**Valeur**|
|---|---|
|OS|Windows Server 2025|
|Rôles installés|AD DS, DNS|
|IP|`192.168.100.10/24`|
|Domaine|`TSSR-MEN.LAB` (Contrôleur de domaine)|
|RDP|Activé|

### CLI-WIN-MEN-01

|**Élément**|**Valeur**|
|---|---|
|OS|Windows 11 Pro|
|Outils installés|RSAT (AD, DNS)|
|IP|`192.168.100.100/24`|
|DNS préféré|`192.168.100.10`|
|Domaine|`TSSR-MEN.LAB` (membre)|
|RDP|Activé|

---

## 9. Difficultés rencontrées / Remarques

_[À compléter]_