

> [!abstract] Objectif 
> Configurer le domaine `TSSR-MEN.LAB` avec des stratégies de groupe : des GPO communes à tout le monde, des GPO propres à chaque service, puis une validation à l'aide des commandes dédiées.

> [!info] Comment utiliser ce document
> 
> - Chaque section contient un espace **Réponse / Captures** à compléter.
> - Les blocs `> [!tip]` et `> [!warning]` sont des pistes de guidage : à supprimer dans la version rendue.
> - Place les captures dans `attachments/` et insère-les avec `![[nom-capture.png]]`.
> - Pour chaque GPO, remplis le petit tableau « Paramètres de la GPO » : il sert aussi de pense-bête pour la validation.

---

## Sommaire

- [[#0. Préparation]]
- [[#1. GPO communes]]
- [[#2. GPO par service]]
- [[#3. Validation]]
- [[#4. Récapitulatif]]
- [[#5. Conclusion et difficultés rencontrées]]

---

## Environnement du laboratoire

|Élément|Valeur|
|---|---|
|Domaine|`TSSR-MEN.LAB`|
|Serveur AD / DNS / DHCP / fichiers|`srv-win-men-01` (`192.168.100.10`)|
|Poste client|`CLI-WIN-MEN-01`|
|Console utilisée|_Gestion de stratégie de groupe_ (GPMC)|
|Partage des installateurs||
|Partage de l'image de fond||

---

## 0. Préparation

> [!warning] Avant de commencer Certaines GPO de ce TP peuvent te verrouiller l'accès (Panneau de configuration, gestionnaire des tâches, lecteurs, date et heure…). **Fais un snapshot des deux VM** et garde un compte administrateur qui n'est visé par aucune restriction.

- [ ] Snapshot du serveur et du client
- [ ] Arborescence d'OU et comptes du TP précédent présents (capture ci-dessous)
- [ ] Installateurs `.msi` récupérés : Google Chrome, 7-Zip, mRemoteNG
- [ ] Modèles d'administration (ADMX) de Chrome récupérés
- [ ] Image de fond d'écran choisie
- [ ] Convention de nommage des GPO décidée

> [!tip] Guidage
> 
> - Les VM sont sur un **LAN Segment sans accès Internet** : prévois comment amener les fichiers (dossier partagé de l'hyperviseur, glisser-déposer, ISO…). Note la méthode utilisée.
> - Choisis une convention de nommage lisible : par exemple type (utilisateur / ordinateur), périmètre et objet. Applique-la à **toutes** les GPO.
> - Rappelle-toi où sont tes objets : les **utilisateurs** sont dans `UTILISATEURS/<service>`, l'**ordinateur** `CLI-WIN-MEN-01` dans `ORDINATEURS`. Une GPO ne s'applique que si elle est liée à une OU qui contient l'objet visé (ou l'un de ses parents).

**Convention de nommage retenue :**

**Comptes de test**

|Service|Compte de test|Remarque|
|---|---|---|
|ADMINISTRATIF|||
|DIRECTION|||
|COMPTABILITE|||
|INFORMATIQUE|||
|RH|||
|PRODUCTION|||

> [!tip] Guidage Dans le TP précédent, le compte `t.stark` a été désactivé et déplacé dans `Utilisateurs Désactivés` (départ de l'entreprise). Pour tester les GPO d'ADMINISTRATIF, soit tu utilises un autre compte, soit tu réactives et replaces celui-ci : note ce que tu choisis.

**Capture(s)**

![[capture-0-arborescence.png]] ![[capture-0-snapshots.png]]

---

## 1. GPO communes

### 1.1 Empêcher les utilisateurs non informatiques d'accéder au Panneau de configuration / Paramètres

**Consigne :** les utilisateurs non informatiques ne doivent pas accéder au Panneau de configuration ni à l'application Paramètres.

> [!tip] Guidage
> 
> - Ce paramètre est-il dans _Configuration ordinateur_ ou _Configuration utilisateur_ ? Cherche dans _Modèles d'administration_ un nom qui mentionne le Panneau de configuration **et** les paramètres du PC.
> - « Non informatiques » veut dire que l'OU `INFORMATIQUE` doit rester **exclue**. Plusieurs approches existent : lier la GPO uniquement aux OU concernées, ou la lier à `UTILISATEURS` et exclure le service informatique par le filtrage de sécurité. Compare-les, choisis, et justifie (que se passe-t-il quand un nouveau service arrive ?).
> - Si tu utilises un filtrage par groupe, pense à l'onglet **Délégation** : depuis les correctifs de sécurité de 2016, une GPO côté utilisateur doit rester **lisible** par `Utilisateurs authentifiés` (ou `Ordinateurs du domaine`) même si elle est appliquée à un groupe précis.
> - Teste avec un compte informatique **et** un compte non informatique.

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

**Capture(s)**

![[capture-1-1-gpo.png]] ![[capture-1-1-lien-filtrage.png]] ![[capture-1-1-test-non-it.png]] ![[capture-1-1-test-it.png]]

**Commentaires (approche retenue et justification)**

---

### 1.2 Autoriser le Bureau à distance et créer la règle de pare-feu associée

**Consigne :** autoriser les connexions Bureau à distance sur les postes et créer la règle de pare-feu qui va avec.

> [!tip] Guidage
> 
> - Il y a **deux** choses distinctes : autoriser le service d'accès à distance, et laisser passer le trafic dans le pare-feu. Elles se règlent toutes les deux côté **ordinateur**.
> - Pour le pare-feu, la GPO contient une règle **entrante** : tu peux la définir par programme, par port ou par règle prédéfinie. Précise ton choix et le profil réseau (domaine, privé, public).
> - Lie la GPO à l'OU qui contient les **ordinateurs**.
> - Autoriser le service ne donne pas le droit de se connecter à tous : regarde quel groupe local détermine qui peut ouvrir une session à distance, et note qui y a accès chez toi.
> - Teste depuis le serveur avec `mstsc`, et prouve l'ouverture du port avec `Test-NetConnection -ComputerName CLI-WIN-MEN-01 -Port 3389`.

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

**Règle de pare-feu**

|Propriété|Valeur|
|---|---|
|Sens||
|Type de règle||
|Port / programme||
|Action||
|Profils||

**Capture(s)**

![[capture-1-2-parametre-rdp.png]] ![[capture-1-2-regle-pare-feu.png]] ![[capture-1-2-test-connexion.png]]

**Commentaires**

---

### 1.3 Mettre en place un fond d'écran commun à tous les utilisateurs

**Consigne :** tous les utilisateurs doivent avoir le même fond d'écran.

> [!tip] Guidage
> 
> - Paramètre côté **utilisateur**, dans une catégorie _Bureau_ des _Modèles d'administration_.
> - L'image doit être accessible par **tous** les utilisateurs au moment de l'ouverture de session : un chemin local du serveur ne marchera pas. Utilise un chemin **UNC** vers un partage lisible par les utilisateurs du domaine, et note les permissions de partage et NTFS choisies.
> - Choisis un style d'affichage cohérent avec les dimensions de ton image.
> - L'effet peut n'apparaître qu'après déconnexion / reconnexion.

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

**Partage de l'image**

|Propriété|Valeur|
|---|---|
|Chemin UNC||
|Permissions de partage||
|Permissions NTFS||

**Capture(s)**

![[capture-1-3-gpo.png]] ![[capture-1-3-partage.png]] ![[capture-1-3-resultat.png]]

**Commentaires**

---

### 1.4 Déployer `IMP-MEN-01` aux utilisateurs

**Consigne :** l'imprimante `IMP-MEN-01` doit être automatiquement disponible pour les utilisateurs.

> [!tip] Guidage
> 
> - Deux voies existent : le déploiement depuis la console de **gestion de l'impression** (« déployer avec la stratégie de groupe »), et les **préférences** de stratégie de groupe pour les imprimantes. Compare-les et note celle que tu retiens.
> - Pour une vraie preuve, **retire l'imprimante** que tu avais ajoutée à la main sur le client lors du TP précédent. Sinon, tu ne sauras pas si la GPO a fonctionné.
> - Vérifie que le client peut joindre `\\srv-win-men-01\IMP-MEN-01` et que le pilote nécessaire peut être récupéré par le client.
> - Précise si tu déploies **par utilisateur** ou **par ordinateur**, et ce que cela change pour qui voit l'imprimante.

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Méthode (gestion de l'impression / préférences)||
|Configuration (ordinateur / utilisateur)||
|Lien et filtrage||

**Capture(s)**

![[capture-1-4-deploiement.png]] ![[capture-1-4-client-avant.png]] ![[capture-1-4-client-apres.png]]

**Commentaires**

---

### 1.5 Déployer Google Chrome et 7-Zip sur tous les postes

**Consigne :** installer Google Chrome et 7-Zip automatiquement sur tous les postes.

> [!tip] Guidage
> 
> - L'installation de logiciels par GPO (_Paramètres du logiciel > Installation de logiciel_) ne gère que les paquets **`.msi`**. Vérifie qu'un `.msi` existe pour chaque logiciel.
> - Le dossier de distribution est un **partage réseau** dont le chemin est donné en **UNC**. Ce sont les **comptes ordinateur** qui lisent le paquet : ils doivent avoir un accès en lecture, pas seulement les utilisateurs.
> - Observe la différence entre **publié** et **attribué** et ce que chaque option permet pour une configuration **ordinateur**.
> - Une installation attribuée à un ordinateur se fait au **démarrage** de la machine, pas à l'ouverture de session : il faut redémarrer.
> - Pour vérifier : _Programmes et fonctionnalités_, ou l'**Observateur d'événements** (journal Application) si l'installation échoue.

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Logiciels et mode (publié / attribué)||
|Lien et filtrage||

**Partage de distribution**

|Propriété|Valeur|
|---|---|
|Chemin UNC||
|Permissions de partage||
|Permissions NTFS||
|Méthode pour amener les `.msi` dans les VM||

**Capture(s)**

![[capture-1-5-gpo-logiciels.png]] ![[capture-1-5-partage.png]] ![[capture-1-5-installe.png]]

**Commentaires**

---

### 1.6 Lecteurs réseau par service

**Consigne :** chaque service doit avoir le lecteur réseau correspondant au dossier auquel il a accès en lecture ou en écriture.

> [!tip] Guidage
> 
> - Le travail se fait en **deux temps** : l'infrastructure (dossiers, partages, permissions), puis le **mappage** par GPO.
> - L'énoncé ne dit pas quels dossiers existent ni qui y accède. À toi de définir ta **matrice d'accès** (au minimum : chaque service accède à son dossier en lecture/écriture ; décide si certains services lisent aussi d'autres dossiers, par exemple la direction) et de la justifier.
> - Pour les permissions, applique le principe **A G DL P** : utilisateurs → groupe global du service (`GG-...`) → groupe de domaine local de la ressource (`GDL-...`, dans l'OU `GDL`) → permission. Prévois un GDL par dossier et par niveau d'accès.
> - Décide où poser les permissions : partage et NTFS ensemble, ou partage large et NTFS restrictif. Justifie.
> - Le mappage se fait côté **utilisateur**, dans les _Préférences_ de stratégie de groupe (mappages de lecteurs). Deux modèles : une GPO par service liée à son OU, ou une seule GPO avec **ciblage au niveau de l'élément** par groupe de sécurité. Compare-les.
> - Pour la preuve : `net use`, l'Explorateur, et un test d'écriture dans un dossier en lecture seule + un test d'accès au dossier d'un autre service.

**Matrice d'accès**

|Service|Dossier (UNC)|Lettre|Accès|GG|GDL|
|---|---|---|---|---|---|
|ADMINISTRATIF||||`GG-ADMINISTRATIF`||
|DIRECTION||||`GG-DIRECTION`||
|COMPTABILITE||||`GG-COMPTABILITE`||
|INFORMATIQUE||||`GG-INFORMATIQUE`||
|RH||||`GG-RH`||
|PRODUCTION||||`GG-PRODUCTION`||

**Paramètres de la GPO**

|Élément|Valeur|
|---|---|
|Nom(s) de la GPO||
|Modèle (une par service / ciblage)||
|Action utilisée (créer, remplacer, mettre à jour)||
|Lien et filtrage||

**Capture(s)**

![[capture-1-6-dossiers-partages.png]] ![[capture-1-6-permissions.png]] ![[capture-1-6-gpo-mappages.png]] ![[capture-1-6-net-use.png]] ![[capture-1-6-test-ecriture.png]]

**Commentaires (choix d'architecture et justification)**

---

## 2. GPO par service

|Service|Action|
|---|---|
|ADMINISTRATIF|Empêcher la modification de la date et de l'heure|
|DIRECTION|Page d'accueil de Google Chrome définie sur `mon-entreprise.tssr-men.lab`|
|COMPTABILITE|Interdire le Gestionnaire des tâches|
|INFORMATIQUE|Déployer mRemoteNG|
|RH|Masquer le lecteur C:|
|PRODUCTION|Bloquer l'utilisation du stockage amovible|

### 2.1 ADMINISTRATIF : empêcher la modification de la date et de l'heure

> [!tip] Guidage
> 
> - Le droit de modifier l'heure est un **droit d'utilisateur** (_Paramètres de sécurité > Stratégies locales_). Il se règle côté **ordinateur** : une GPO liée à l'OU des utilisateurs ne suffira donc pas. Réfléchis aux solutions possibles (liaison à l'OU des ordinateurs avec filtrage, traitement par **bouclage**) et à leurs effets de bord : qui d'autre est touché ?
> - Regarde la **liste par défaut** avant de la modifier, et ne retire pas ce dont le système a besoin (le service de temps en dépend).
> - Pour le test : essaie de changer l'heure depuis l'horloge, avec un compte du service.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

![[capture-2-1-gpo.png]] ![[capture-2-1-test.png]]

**Commentaires**

---

### 2.2 DIRECTION : page d'accueil de Chrome

> [!tip] Guidage
> 
> - Les paramètres de Chrome **n'existent pas** dans les modèles d'administration de Windows : il faut importer les **modèles ADMX de Chrome** dans les définitions de stratégie du domaine. Note où tu les as placés et comment tu as vérifié leur présence dans l'éditeur.
> - Chrome distingue la **page d'accueil** des **pages ouvertes au démarrage**. Lis ce que fait chaque paramètre et choisis celui qui correspond à l'énoncé.
> - Chrome doit être installé (section 1.5) avant le test.
> - Le nom `mon-entreprise.tssr-men.lab` existe-t-il dans ton DNS ? Chrome appliquera la stratégie même si la page ne répond pas : note-le.
> - Preuve côté client : `chrome://policy` liste les stratégies reçues.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||
|Emplacement des ADMX||

![[capture-2-2-admx.png]] ![[capture-2-2-gpo.png]] ![[capture-2-2-chrome-policy.png]]

**Commentaires**

---

### 2.3 COMPTABILITE : interdire le Gestionnaire des tâches

> [!tip] Guidage
> 
> - Paramètre **utilisateur** dans les _Modèles d'administration_ (options liées à `Ctrl+Alt+Suppr`).
> - Teste par plusieurs chemins : `Ctrl+Maj+Échap`, clic droit sur la barre des tâches, `taskmgr` dans _Exécuter_. Capture le message affiché.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

![[capture-2-3-gpo.png]] ![[capture-2-3-test.png]]

**Commentaires**

---

### 2.4 INFORMATIQUE : déployer mRemoteNG

> [!tip] Guidage
> 
> - Vérifie le **format du paquet** : l'installation de logiciels par GPO ne prend que les `.msi`. Si le format n'est pas bon, note l'alternative que tu envisages.
> - Ici, c'est le **service** qui doit recevoir le logiciel, pas tous les postes. Compare une installation **attribuée à l'utilisateur** avec une installation **attribuée à l'ordinateur** : quel est le périmètre réel de chaque option ?
> - Compare aussi les modes **publié** et **attribué** pour un utilisateur : quand l'application est-elle réellement installée ?
> - Teste avec un compte informatique **et** un compte d'un autre service.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Mode (publié / attribué)||
|Lien et filtrage||

![[capture-2-4-gpo.png]] ![[capture-2-4-test-it.png]] ![[capture-2-4-test-autre.png]]

**Commentaires**

---

### 2.5 RH : masquer le lecteur C:

> [!tip] Guidage
> 
> - Paramètre **utilisateur**, dans la catégorie de l'Explorateur de fichiers.
> - **Masquer n'est pas interdire.** Teste : le lecteur disparaît-il de l'Explorateur ? Peux-tu quand même ouvrir `C:\` en tapant le chemin dans la barre d'adresse ? Un paramètre voisin sert à empêcher l'accès : note la différence et dis si l'énoncé demande l'un, l'autre, ou les deux.
> - Les valeurs de ce paramètre correspondent à des **combinaisons de lecteurs** : choisis celle qui ne cache que `C:`.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

![[capture-2-5-gpo.png]] ![[capture-2-5-explorateur.png]] ![[capture-2-5-acces-direct.png]]

**Commentaires**

---

### 2.6 PRODUCTION : bloquer le stockage amovible

> [!tip] Guidage
> 
> - Le paramètre existe côté **ordinateur** _et_ côté **utilisateur**. Choisis-en un et explique pourquoi (le service doit être visé, pas toutes les machines).
> - Cherche le nom qui mentionne « stockage amovible », et lis la différence entre refuser **tous** les accès et refuser la lecture ou l'écriture seulement.
> - Pour le test, connecte un périphérique USB à la VM si ton hyperviseur le permet. Sinon, prouve l'application par `gpresult` et note cette limite.

|Élément|Valeur|
|---|---|
|Nom de la GPO||
|Configuration (ordinateur / utilisateur)||
|Paramètre(s) et valeur||
|Lien et filtrage||

![[capture-2-6-gpo.png]] ![[capture-2-6-test.png]]

**Commentaires**

---

## 3. Validation

**Consigne :** manipuler les commandes liées aux GPO pour vérifier la bonne exécution des stratégies.

### 3.1 Commandes à manipuler

```powershell
gpupdate /force
gpupdate /target:user
gpupdate /target:computer
gpresult /r
gpresult /r /scope user
gpresult /r /scope computer
gpresult /h C:\gpo-rapport.html
rsop.msc
```

> [!tip] Guidage
> 
> - Pour chaque commande, note **ce qu'elle fait** et **ce qu'elle t'a appris** (pas seulement la commande).
> - `gpresult` donne deux parties : celle de l'**ordinateur** et celle de l'**utilisateur**. La partie ordinateur demande une invite de commandes **administrateur**.
> - Cherche dans la sortie les GPO **appliquées** et les GPO **filtrées** avec la raison du filtrage : c'est ce qui prouve ton ciblage.
> - Certains paramètres ne s'appliquent qu'après **déconnexion** ou **redémarrage** (installation de logiciels notamment). `gpupdate` te le dit : relève le message.
> - Dans la console GPMC, regarde aussi _Résultats de stratégie de groupe_ (données réelles d'un poste) et _Modélisation de stratégie de groupe_ (simulation) : quelle différence ?

|Commande|Rôle|Ce qui a été observé|
|---|---|---|
|`gpupdate /force`|||
|`gpupdate /target:user`|||
|`gpupdate /target:computer`|||
|`gpresult /r`|||
|`gpresult /r /scope user`|||
|`gpresult /r /scope computer`|||
|`gpresult /h`|||
|`rsop.msc`|||

**Capture(s)**

![[capture-3-gpupdate.png]] ![[capture-3-gpresult-user.png]] ![[capture-3-gpresult-computer.png]] ![[capture-3-rapport-html.png]]

### 3.2 Validation GPO par GPO

|GPO|Compte / poste testé|Preuve (commande ou action)|Résultat attendu|Résultat obtenu|Capture|
|---|---|---|---|---|---|
|Panneau de configuration||||||
|Bureau à distance + pare-feu||||||
|Fond d'écran||||||
|Imprimante `IMP-MEN-01`||||||
|Chrome et 7-Zip||||||
|Lecteurs réseau||||||
|ADMINISTRATIF : date et heure||||||
|DIRECTION : page d'accueil Chrome||||||
|COMPTABILITE : gestionnaire des tâches||||||
|INFORMATIQUE : mRemoteNG||||||
|RH : lecteur C:||||||
|PRODUCTION : stockage amovible||||||

### 3.3 Ordre d'application et héritage

> [!tip] Guidage Réponds avec tes mots, en t'appuyant sur ce que tu as vu dans `gpresult` ou dans l'onglet _Héritage de stratégie de groupe_ de GPMC :
> 
> - Dans quel ordre les GPO s'appliquent-elles (local, site, domaine, OU) et laquelle l'emporte en cas de conflit ?
> - Que se passe-t-il pour un utilisateur dans `UTILISATEURS/RH` : quelles GPO reçoit-il, et d'où viennent-elles ?
> - À quoi servent le blocage d'héritage, l'option « appliquée », et l'ordre de liaison ? En as-tu eu besoin ?
> - Commande utile côté serveur : `Get-GPInheritance -Target "OU=RH,OU=UTILISATEURS,DC=TSSR-MEN,DC=LAB"`.

**Réponse**

---

## 4. Récapitulatif

|GPO|Configuration|Lien (OU)|Filtrage|Validée|
|---|---|---|---|---|
|Panneau de configuration||||☐|
|Bureau à distance + pare-feu||||☐|
|Fond d'écran||||☐|
|Imprimante `IMP-MEN-01`||||☐|
|Chrome et 7-Zip||||☐|
|Lecteurs réseau||||☐|
|ADMINISTRATIF||||☐|
|DIRECTION||||☐|
|COMPTABILITE||||☐|
|INFORMATIQUE||||☐|
|RH||||☐|
|PRODUCTION||||☐|

> [!check] À valider avant de rendre le TP Coche chaque point uniquement si tu peux le **prouver** par une capture ou une commande.

- [ ] Les GPO communes sont créées, liées et testées
- [ ] Les six GPO par service sont créées, liées et testées
- [ ] Chaque GPO a un nom conforme à la convention
- [ ] Les exclusions (non informatiques, service ciblé) sont prouvées par `gpresult`
- [ ] Les lecteurs réseau reflètent la matrice d'accès, avec test de lecture et d'écriture
- [ ] Les commandes de la section 3 ont été exécutées et commentées

**Capture de GPMC avec toutes les GPO et leurs liens**

![[capture-4-gpmc-vue-globale.png]]

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
# Côté client
gpupdate /force
gpresult /r /scope user
gpresult /h C:\gpo-rapport.html
net use
chrome://policy   # à ouvrir dans Chrome

# Côté serveur (module GroupPolicy)
Get-GPO -All | Select-Object DisplayName, GpoStatus
Get-GPInheritance -Target "OU=RH,OU=UTILISATEURS,DC=TSSR-MEN,DC=LAB"
Get-GPOReport -All -ReportType Html -Path C:\gpo-toutes.html
```

---

> [!note] Rendu
> 
> - [ ] Toutes les captures insérées
> - [ ] Tous les tableaux « Paramètres de la GPO » remplis
> - [ ] Aucun blocage d'accès laissé actif sur ton compte d'administration
> - [ ] Tous les blocs `[!tip]` et `[!warning]` supprimés
> - [ ] Export PDF réalisé (si demandé)