
## Fiche de Recherche : Active Directory & LDAP
- Qu'est-ce que Active Directory
- Qu’est-ce qu’une Forêt ? Un domaine ?
- Qu’est-ce qu’un contrôleur de domaine ? A quoi sert-il ?
- Le protocole LDAP/LDAPS

---

## 1. Qu'est-ce que Active Directory (AD DS) ?

* **Définition :** Service d'annuaire développé par Microsoft pour les réseaux d'entreprise Windows.
* **Rôle principal :** Centraliser la gestion des identités, des accès et des ressources sur un réseau local.
* **Objets gérés :** Utilisateurs, ordinateurs, groupes, imprimantes, dossiers partagés, etc.
* **Bénéfices clés :**
  * **SSO (Single Sign-On) :** Un seul identifiant pour accéder à toutes les ressources autorisées du domaine.
  * **Gestion centralisée :** Application de politiques de sécurité globales via les **GPO** (Group Policy Objects).

---

## 2. Architecture AD : forêt et domaine

### A. Qu'est-ce qu'un Domaine ?
* **Définition :** La brique de base administrative d'Active Directory.
* **Rôle :** Regroupe un ensemble d'objets (utilisateurs, machines) qui partagent la même base de données et les mêmes politiques de sécurité.
* **Exemple :** `entreprise.local` ou `lab.tssr.fr`.

### B. Qu'est-ce qu'une Forêt ?
* **Définition :** Le conteneur de plus haut niveau dans Active Directory.
* **Structure :** Regroupe un ou plusieurs domaines (organisés en un ou plusieurs "arbres") qui partagent un **schéma commun** (la structure de la base de données) et un **catalogue global**.
* **Relations :** Les domaines d'une même forêt se font confiance mutuellement par défaut (approuvées/transitives).

---

## 3. Le Contrôleur de Domaine (DC - Domain Controller)

* **Définition :** Serveur (Windows Server) sur lequel le rôle **AD DS** (Active Directory Domain Services) est installé.
* **À quoi sert-il ?**
  1. **Héberger la base de données AD :** Stocke le fichier `ntds.dit` contenant tous les objets et identifiants.
  2. **Authentifier les utilisateurs :** Vérifie les mots de passe lors de la connexion (via le protocole **Kerberos** ou NTLM).
  3. **Appliquer la sécurité :** Distribue les GPO aux machines du domaine.
  4. **Réplication :** Synchronise ses données avec les autres contrôleurs de domaine du même réseau.

---

## 4. Les Protocoles LDAP et LDAPS

### A. Protocole LDAP (Lightweight Directory Access Protocol)
* **Définition :** Protocole standard ouvert permettant d'interroger et de modifier les données d'un annuaire (comme Active Directory ou OpenLDAP).
* **Usage :** Utilisé par les applications (ex: VPN, Wi-Fi d'entreprise, outils tiers) pour vérifier si un utilisateur existe dans l'annuaire.
* **Port par défaut :** **TCP 389** (Non sécurisé - données et mots de passe en clair sur le réseau).

### B. Protocole LDAPS (LDAP over SSL/TLS)
* **Définition :** Version sécurisée et chiffrée du protocole LDAP via un certificat numérique (TLS/SSL).
* **Usage :** Garantit la confidentialité et l'intégrité des échanges entre une application et le contrôleur de domaine.
* **Port par défaut :** **TCP 636**

---

## Résumé Visuel / Analogie rapide

| Élément | Analogie | Rôle dans le réseau |
| :--- | :--- | :--- |
| **Active Directory** | L'annuaire téléphonique global de la ville | Le service d'annuaire complet |
| **Domaine** | Un quartier de la ville | La frontière administrative de sécurité |
| **Forêt** | La ville entière | Le regroupement de tous les domaines |
| **Contrôleur de Domaine (DC)** | Le gardien / Réceptionniste | Le serveur qui vérifie les pièces d'identité |
| **LDAP / LDAPS** | La langue parlée pour poser une question au gardien | Le protocole pour requêter l'annuaire (non chiffré / chiffré) |