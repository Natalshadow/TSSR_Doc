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


### 3.1 Installation du rôle AD DS


Installation du rôle **Services de domaine Active Directory (AD DS)** via le Gestionnaire de serveur.

> _[Insérer ici une capture de l'assistant d'ajout de rôles avec AD DS sélectionné]_ 
![](attachments/Pasted%20image%2020261005142239.png)

J'ai pensé à vérifié dans l'installation ADDS si c'est aussi ici que se trouve RSAT pour le côté serveur et c'est effectivement le cas:
![](attachments/Pasted%20image%2020261005142338.png)
Installation en cours
![](attachments/Pasted%20image%2020261005142434.png)
> _[Insérer ici une capture de la fin d'installation du rôle]_

![](attachments/Pasted%20image%2020261005142847.png)

![](attachments/Pasted%20image%2020261005142916.png)

Une fois ADDS installé, une icone de notification s'affiche en haut du dashboard server:
![](attachments/Pasted%20image%2020261005143004.png)



### 3.3 Promotion en contrôleur de domaine


Lancement de l'assistant de promotion du serveur en contrôleur de domaine :

- Création d'une **nouvelle forêt**
- Domaine : `TSSR-MEN.LAB`
- Installation de **DNS** lors de l'assistant
- Reboot pour confirmer

### 3.4 Contrôles après redémarrage


| **Contrôle**                                          | **Résultat** |
| ----------------------------------------------------- | ------------ |
| Serveur contrôleur du domaine `TSSR-MEN.LAB`          | ✅            |
| Console Utilisateurs et ordinateurs AD opérationnelle | ✅            |
| Zone DNS correspondant au domaine présente            | ✅ Je pense?  |

> ![](attachments/Pasted%20image%2020261005150131.png)
> ![](attachments/Pasted%20image%2020261005150616.png)![](attachments/Pasted%20image%2020261005150240.png)

> _[Insérer ici une capture de la console DNS avec la zone TSSR-MEN.LAB]_

```
 dcdiag /test:services

Directory Server Diagnosis

Performing initial setup:
   Trying to find home server...
   Home Server = SRV-WIN-MEN-01
   * Identified AD Forest.
   Done gathering initial info.

Doing initial required tests

   Testing server: Default-First-Site-Name\SRV-WIN-MEN-01
      Starting test: Connectivity
         ......................... SRV-WIN-MEN-01 passed test Connectivity

Doing primary tests

   Testing server: Default-First-Site-Name\SRV-WIN-MEN-01
      Starting test: Services
         ......................... SRV-WIN-MEN-01 passed test Services


   Running partition tests on : ForestDnsZones

   Running partition tests on : DomainDnsZones

   Running partition tests on : Schema

   Running partition tests on : Configuration

   Running partition tests on : TSSR-MEN

   Running enterprise tests on : TSSR-MEN.LAB
```

---

## 4. Étape 3 : Jonction du poste Windows 11 au domaine

### 4.1 Configuration du DNS préféré sur le client

Sur `CLI-WIN-MEN-01`, configuration du DNS préféré sur `192.168.100.10`.

> _[Insérer ici une capture des paramètres réseau du client avec le DNS configuré]![](attachments/Pasted%20image%2020261005152225.png)_

> _[Insérer ici une capture du résultat de `nslookup TSSR-MEN.LAB`]![](attachments/Pasted%20image%2020261005152245.png)_

Je ne sais pas encore pourquoi il y a du timeout et si c'est gênant pour finir la configuration, n'étant pas familié avec le Segment LAN et ne sachant pas si le fait que ADDS soit sur une VM puisse ralentir ses performances au point d'être visible dans le lookup.
### 4.2 Jonction au domaine

Jonction au domaine `TSSR-MEN.LAB` avec un compte autorisé.

> _[Insérer ici une capture de la fenêtre de jonction au domaine]![](attachments/Pasted%20image%2020261005152634.png)_
![](attachments/Pasted%20image%2020261005152733.png)
> _[Insérer ici une capture de la demande d'identifiants]_
![](attachments/Pasted%20image%2020261005152743.png)
> ![](attachments/Pasted%20image%2020261005152820.png)
> _[Insérer ici une capture du message de confirmation de jonction au domaine]_

### 4.3 Redémarrage et ouverture de session domaine

Redémarrage du poste, puis ouverture de session avec un compte du domaine `TSSR-MEN.LAB`.

`PS C:\WINDOWS\system32> whoami`
`tssr-men\administrator`


> _[Insérer ici une capture du bureau confirmant la session domaine active]![](attachments/Pasted%20image%2020261005153210.png)_


---

## 5. Étape 4 : Création d'une console MMC d'administration

Création d'une console MMC personnalisée contenant :

- **Utilisateurs et ordinateurs Active Directory**
- **DNS**


> _[Insérer ici une capture de la console MMC personnalisée avec les deux composants logiciels enfichables]
> ![](attachments/Pasted%20image%2020261005155156.png)_

La fonction DNS semble défectueuse. Troubleshooting.
Correctif:
Il faut cliquer sur DNS dans la console MMC, "établir une connexion", "l'ordinateur suivant: " et indiquer l'ip local 192.168 ou le hostname du server.
![](attachments/Pasted%20image%2020261005160601.png)

---

## 6. Étape 5 : Bureau à distance (RDP)

### 6.1 Activation de RDP

Activation du Bureau à distance sur le serveur et le client.

> _[Insérer ici une capture des paramètres RDP activés sur `SRV-WIN-MEN-01`]_
> ![](attachments/Pasted%20image%2020261005160703.png)

> _[Insérer ici une capture des paramètres RDP activés sur `CLI-WIN-MEN-01`]
> ![](attachments/Pasted%20image%2020261005160730.png)_

### 6.2 Test RDP Client → Serveur


```
mstsc
```

Connexion de `CLI-WIN-MEN-01` vers `SRV-WIN-MEN-01` (`192.168.100.10`).

> _[Insérer ici une capture de la session RDP client → serveur établie
> ![](attachments/Pasted%20image%2020261005160900.png)]_

### 6.3 Test RDP Serveur → Client

Connexion de `SRV-WIN-MEN-01` vers `CLI-WIN-MEN-01` (`192.168.100.100`). CLI-WIN-MEN-01.TSSR-MEN.LAB

> _[Insérer ici une capture de la session RDP serveur → client établie]
> ![](attachments/Pasted%20image%2020261005161213.png)_

---

## 7. Validation finale

| **Critère de validation**                                            | **Résultat** |
| -------------------------------------------------------------------- | ------------ |
| Le domaine `TSSR-MEN.LAB` existe                                     | ✅            |
| Le client est membre du domaine                                      | ✅            |
| Le client utilise le DNS du serveur (`192.168.100.10`)               | ✅            |
| Les consoles AD et DNS sont administrables depuis le client via RSAT | ✅            |
| La console MMC personnalisée fonctionne                              | ✅            |
| RDP fonctionnel dans les deux sens                                   | ✅            |

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

C'est loin d'être naturel pour le moment sans avoir une doc sous les yeux.
