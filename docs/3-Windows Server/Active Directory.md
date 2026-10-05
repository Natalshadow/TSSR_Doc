## Active Directory et LDAP



---

## 1. Qu'est-ce qu'Active Directory (AD DS) ?

* **Définition :** service d'annuaire développé par Microsoft pour les réseaux d'entreprise Windows.
* **Rôle principal :** centraliser la gestion des identités, des accès et des ressources sur un réseau local.
* **Objets gérés :** utilisateurs, ordinateurs, groupes, imprimantes, dossiers partagés, etc.
* **Bénéfices clés :**
  * **SSO (*Single Sign-On*) :** un seul identifiant pour accéder à toutes les ressources autorisées du domaine.
  * **Gestion centralisée :** application de politiques de sécurité globales via les [[GPO]] (*Group Policy Objects*).

---

## 2. Architecture AD : forêt et domaine

### A. Qu'est-ce qu'un domaine ?
* **Définition :** la brique de base administrative d'Active Directory.
* **Rôle :** regroupe un ensemble d'objets (utilisateurs, machines) qui partagent la même base de données et les mêmes politiques de sécurité.
* **Exemple :** `entreprise.local` ou `lab.tssr.fr`.

### B. Qu'est-ce qu'une forêt ?
* **Définition :** le conteneur de plus haut niveau dans Active Directory.
* **Structure :** regroupe un ou plusieurs domaines (organisés en un ou plusieurs « arbres ») qui partagent un schéma commun (la structure de la base de données) et un catalogue global.
* **Relations :** les domaines d'une même forêt se font confiance mutuellement par défaut (relations approuvées et transitives).

---

## 3. Le contrôleur de domaine (DC — *Domain Controller*)

* **Définition :** serveur (Windows Server) sur lequel le rôle AD DS (*Active Directory Domain Services*) est installé.
* **À quoi sert-il ?**
  1. **Héberger la base de données AD :** stocke le fichier `ntds.dit` contenant tous les objets et identifiants.
  2. **Authentifier les utilisateurs :** vérifie les mots de passe lors de la connexion (via le protocole [Kerberos](Kerberos.md) ou [[NTLM]]).
  3. **Appliquer la sécurité :** distribue les GPO aux machines du domaine.
  4. **Réplication :** synchronise ses données avec les autres contrôleurs de domaine du même réseau.

---

## 4. Les protocoles LDAP et LDAPS

### A. Protocole LDAP (*Lightweight Directory Access Protocol*)
* **Définition :** protocole standard ouvert permettant d'interroger et de modifier les données d'un annuaire (comme Active Directory ou OpenLDAP).
* **Usage :** utilisé par les applications (ex. : VPN, Wi-Fi d'entreprise, outils tiers) pour vérifier si un utilisateur existe dans l'annuaire.
* **Port par défaut :** TCP 389 (non sécurisé — données et mots de passe en clair sur le réseau).

### B. Protocole LDAPS (*LDAP over SSL/TLS*)
* **Définition :** version sécurisée et chiffrée du protocole LDAP via un certificat numérique (TLS/SSL).
* **Usage :** garantit la confidentialité et l'intégrité des échanges entre une application et le contrôleur de domaine.
* **Port par défaut :** TCP 636.

---

## 💡 Résumé visuel / Analogie rapide

| Élément | Analogie | Rôle dans le réseau |
| :--- | :--- | :--- |
| **Active Directory** | L'annuaire téléphonique global de la ville | Le service d'annuaire complet |
| **Domaine** | Un quartier de la ville | La frontière administrative de sécurité |
| **Forêt** | La ville entière | Le regroupement de tous les domaines |
| **Contrôleur de domaine (DC)** | Le gardien / réceptionniste | Le serveur qui vérifie les pièces d'identité |
| **LDAP / LDAPS** | La langue parlée pour poser une question au gardien | Le protocole pour interroger l'annuaire (non chiffré / chiffré) |


![](attachments/Pasted%20image%2020261005075958.png)


![](attachments/Pasted%20image%2020261005080004.png)


![](attachments/Pasted%20image%2020261005080013.png)



![](attachments/Pasted%20image%2020261005080020.png)

