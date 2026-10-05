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


---

## 3. Étape 2 : Création du domaine Active Directory

### 3.1 Vérification de la configuration IP du serveur

```
ipconfig /all
```

> _[Insérer ici la capture de ipconfig /all sur SRV-WIN-MEN-01 confirmant l'IP 192.168.100.10]_

### 3.2 Installation du rôle AD DS

Installation du rôle **Services de domaine Active Directory (AD DS)** via le Gestionnaire de serveur.

> _[Insérer ici une capture de l'assistant d'ajout de rôles avec AD DS sélectionné]_

> _[Insérer ici une capture de la fin d'installation du rôle]_

### 3.3 Promotion en contrôleur de domaine

Lancement de l'assistant de promotion du serveur en contrôleur de domaine.

- Création d'une **nouvelle forêt**
- Domaine : `TSSR-MEN.LAB`
- Installation de **DNS** lors de l'assistant

> _[Insérer ici une capture de l'assistant de promotion — étape nouvelle forêt]_

> _[Insérer ici une capture de la configuration DNS dans l'assistant]_

> _[Insérer ici une capture de la vérification des prérequis avant promotion]_

> _[Insérer ici une capture du redémarrage automatique post-promotion]_

### 3.4 Contrôles après redémarrage

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

Sur `CLI-WIN-MEN-01`, configuration du DNS préféré sur `192.168.100.10`.

> _[Insérer ici une capture des paramètres réseau du client avec le DNS configuré]_

### 4.2 Jonction au domaine

Jonction au domaine `TSSR-MEN.LAB` avec un compte autorisé.

> _[Insérer ici une capture de la fenêtre de jonction au domaine]_

> _[Insérer ici une capture de la demande d'identifiants]_

> _[Insérer ici une capture du message de confirmation de jonction au domaine]_

### 4.3 Redémarrage et ouverture de session domaine

Redémarrage du poste, puis ouverture de session avec un compte du domaine `TSSR-MEN.LAB`.

> _[Insérer ici une capture de l'écran de connexion avec le compte domaine]_

> _[Insérer ici une capture du bureau confirmant la session domaine active]_

### 4.4 Réflexe de diagnostic

En cas d'échec de jonction, ordre de vérification :

1. Connectivité IP → `ping 192.168.100.10`
2. DNS du client → `nslookup TSSR-MEN.LAB`
3. Résolution du domaine
4. Identifiants utilisés

---

## 5. Étape 4 : Création d'une console MMC d'administration

Création d'une console MMC personnalisée contenant :

- **Utilisateurs et ordinateurs Active Directory**
- **DNS**

Console enregistrée sous : `_[Nom de la console]_`

> _[Insérer ici une capture de la console MMC personnalisée avec les deux composants logiciels enfichables]_

---

## 6. Étape 5 : Bureau à distance (RDP)

### 6.1 Activation de RDP

Activation du Bureau à distance sur le serveur et le client.

> _[Insérer ici une capture des paramètres RDP activés sur SRV-WIN-MEN-01]_

> _[Insérer ici une capture des paramètres RDP activés sur CLI-WIN-MEN-01]_

### 6.2 Test RDP Client → Serveur

```
mstsc
```

Connexion de `CLI-WIN-MEN-01` vers `SRV-WIN-MEN-01` (`192.168.100.10`).

> _[Insérer ici une capture de la session RDP client → serveur établie]_

### 6.3 Test RDP Serveur → Client

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
|OS|Windows 11|
|Outils installés|RSAT (AD, DNS)|
|IP|`192.168.100.100/24`|
|DNS préféré|`192.168.100.10`|
|Domaine|`TSSR-MEN.LAB` (membre)|
|RDP|Activé|

---

## 9. Difficultés rencontrées / Remarques

_[À compléter]_