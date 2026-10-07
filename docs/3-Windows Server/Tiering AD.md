# Active Directory : les fondamentaux du Tiering Model

[20/03/2025](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/ "13:00") [Florian BURNEL](https://www.it-connect.fr/author/florian/ "Florian BURNEL") [5 commentaires](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#comments) [Active Directory](https://www.it-connect.fr/tag/active-directory/),  [Cybersécurité](https://www.it-connect.fr/tag/cybersecurite/)

Sommaire [[-](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#)]

- [I. Présentation](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#I_Presentation)
- [II. L'administration traditionnelle d'un domaine Active Directory](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#II_Ladministration_traditionnelle_dun_domaine_Active_Directory)
- [III. Privileged Access Management](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#III_Privileged_Access_Management)
- [IV. Active Directory : qu'est-ce que le modèle en couches ?](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#IV_Active_Directory_quest-ce_que_le_modele_en_couches)
- [V. Les 3 niveaux du Tiering Model pour l'AD](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#V_Les_3_niveaux_du_Tiering_Model_pour_lAD)
    - [A. Le Tier 0](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#A_Le_Tier_0)
    - [B. Le Tier 1](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#B_Le_Tier_1)
    - [C. Le Tier 2](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#C_Le_Tier_2)
    - [D. Les interactions entre les niveaux du Tiering Model](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#D_Les_interactions_entre_les_niveaux_du_Tiering_Model)
- [VI. Le Tiering Model n'est pas la solution à tous les problèmes](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#VI_Le_Tiering_Model_nest_pas_la_solution_a_tous_les_problemes)
- [VII. Conclusion](https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/#VII_Conclusion)

## I. Présentation

**Dans un environnement Active Directory, la sécurité des comptes à privilèges et leur cloisonnement représente un enjeu majeur. La compromission d'un seul compte administrateur membre du groupe "Admins du domaine" peut avoir d'énormes conséquences sur l'ensemble du système d'information d'une entreprise. En effet, comme nous le verrons, l'attaquant détient alors les clés du royaume...**

Pour répondre à cette problématique, le **modèle en couches**, que l'on appelle aussi **Tiering Model**, propose une **segmentation stricte des comptes** afin de limiter l'impact d'une intrusion ou d'une compromission de compte. Ce modèle, recommandé par Microsoft, l'ANSSI et de nombreux experts en Active Directory, repose sur un découpage en plusieurs niveaux (couches).

> **Note** : ce concept s'inscrit dans une approche plus large de la **gestion des accès à privilèges**, appelée **Privileged Access Management** (PAM).

## II. L'administration traditionnelle d'un domaine Active Directory

Commençons par évoquer l'administration dite traditionnelle d'un domaine Active Directory, c'est-à-dire sans aucun cloisonnement des privilèges. Nous pouvons constater la situation suivante : **chaque administrateur système dispose d'un compte membre du groupe "Admins du domaine"** (ou tous les admins utilisent le même compte, cela existe aussi...). L'administrateur utilise ce compte pour accomplir diverses actions, telles que :

- Administrer l'Active Directory
- Effectuer la maintenance sur les serveurs métiers
- Dépanner les utilisateurs dans le cadre de missions de support

Dans le meilleur des mondes, quand tout se passe bien, il dispose donc d'un seul compte pour administrer le système d'information. C'est diablement pratique, mais tout aussi dangereux...

[![](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Administration-traditionnelle-dun-Active-Directory.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Administration-traditionnelle-dun-Active-Directory.png.webp)

Être membre du groupe "**Admins du domaine**" dans un environnement sans cloisonnement des privilèges, cela revient à **disposer des clés du royaume** (du SI). Ainsi, si l'**administrateur système**, alias l'**admin du domaine**, alias le **roi**, se fait compromettre son compte, l'attaquant hérite d'un niveau de privilèges équivalent.

Cela peut arriver plus vite qu'on le croit, surtout sur une infrastructure où des protocoles obsolètes sont actifs et l'infection du poste de travail par un malware peut suffire. L'attaquant n'a qu'à attendre la prochaine intervention de l'administrateur sur le poste de travail (qu'il pourrait provoquer...). Les identifiants sont présents en mémoire et dans la base de Registre (suivant le type d'accès), l'attaquant peut retrouver le compte et le compromettre sans bruit ; il peut aussi capturer le compte lors de la prochaine connexion.

La **compromission du compte est alors dramatique** puisque l'attaquant peut accéder, sans restriction, à l'ensemble des ressources. Il peut effectuer des déplacements latéraux sur l'infrastructure, déployer des logiciels malveillants et même se créer son propre compte administrateur du domaine.

[![](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Active-Directory-sans-cloisonnement-des-privileges-Compromission.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Active-Directory-sans-cloisonnement-des-privileges-Compromission.png.webp)

Face à cette problématique, il est donc indispensable de s'orienter vers la **gestion des accès à privilèges** et le **cloisonnement des identités**. Autrement dit de revoir sa stratégie d'administration du SI.

> **Note** : ici, nous mettons de côté le filtrage réseau qui pourrait être mis en place pour limiter les flux et pourrait freiner la progression de l'attaquant.

## III. Privileged Access Management

La **gestion des accès à privilèges**, ou **P**rivileged **A**ccess **M**anagement (**PAM**), est une approche incontournable lorsqu'il est question de protéger les ressources critiques d'un système d'information. Elle repose notamment sur l'application du **principe du moindre privilège**.

Le PAM permet notamment de :

- Restreindre l'utilisation des comptes à privilèges aux seules actions nécessaires,
- Implémenter des solutions de gestion des accès temporaires,
- Surveiller et auditer les activités des comptes d'administration

Le **Tiering Model** s'inscrit dans cette logique de protection des comptes à privilèges en imposant **un cloisonnement strict** des différents niveaux d'administration.

## IV. Active Directory : qu'est-ce que le modèle en couches ?

Le **tiering** est un **modèle de sécurité** applicable à l'Active Directory visant à **segmenter les comptes à privilèges en plusieurs niveaux (Tier)** et périmètres fonctionnels. L'objectif est de limiter leur utilisation à leur Tier d’origine afin de **contenir toute compromission** et éviter qu’elle ne se propage aux autres niveaux.

Prenons un exemple évocateur : une attaque par ransomware ciblant le poste de travail d'un utilisateur. Si l'attaquant parvient à compromettre la machine, le cloisonnement des privilèges empêche l'attaquant d'exploiter ce point d'entrée pour compromettre les comptes administrateurs du domaine et propager l’infection à l’ensemble du SI.

Avec un modèle en couches, un compte d'administration des machines utilisateur (Tier 2) ne pourra jamais s'authentifier sur un contrôleur de domaine (Tier 0), ce qui empêche l'escalade des privilèges. Ce privilège étant réservé à certains comptes liés au Tier 0.

Le **modèle de base** repose sur **trois niveaux**, chacun correspondant à un type de composant du système d'information : **Tier 0**, **Tier 1** et **Tier 2**. Nous verrons quel est le rôle de chacun de ces Tier dans la suite de cet article.

## V. Les 3 niveaux du Tiering Model pour l'AD

### A. Le Tier 0

Le **Tier 0** comprend **les actifs les plus sensibles du système d'information**, à savoir ceux liés à la **gestion des identités**. Il représente le haut de la pyramide ! Les privilèges d'administration de ce Tier sont les plus élevés puisqu'ils offrent un contrôle sur l'annuaire Active Directory, ainsi que la possibilité de **reprendre la main sur les autres Tier** (insistons sur le terme "**reprendre**").

Il est donc évident que le Tier 0 contiendra **les contrôleurs de domaine Active Directory**. Néanmoins, et même si les actifs présents dans ce Tier doivent être limités, ce ne sont pas les seuls serveurs qui seront présents dans le Tier 0. Nous pourrons y trouver également :

- [Les autorités de certification AD CS](https://www.it-connect.fr/cours/ad-cs-autorite-de-certification-windows-server/ "Maîtrisez l’Autorité de certification avec AD CS sous Windows Server") (PKI)
- Les serveurs d'authentification (Radius / NPS)
- Les serveurs de synchronisation (Microsoft Entra Connect, Google Cloud Directory Sync, etc.)
- Les serveurs ADFS (Active Directory Federation Services)
- Les hyperviseurs intégrés au domaine Active Directory
- L'infrastructure de sauvegarde si elle est commune à tous les Tiers

Ces composants doivent être isolés des autres niveaux pour éviter toute compromission vis-à-vis d'un Tier de niveau inférieur.

> **Remarque** : les **équipements réseaux**, tels que les **commutateurs** (switchs) représentent un cas particulier. Ils doivent appartenir à **leur propre Tier**, via un **VLAN de Management** et une authentification non liée à l'Active Directory. Si l'authentification AD est en place ou qu'ils ne peuvent pas être isolés, ils doivent être rattachés au Tier 0 (leur fonction étant transverse).

### B. Le Tier 1

Le **Tier 1** correspond au **niveau intermédiaire** de notre pyramide. Il concerne **les serveurs**, notamment ceux liés à **l'activité de l'entreprise** et qui ont une **dimension « métier »**. Nous n'irons pas jusqu'à dire que ce Tier est un « fourre-tout » pour les serveurs, mais il y a **une grande hétérogénéité**. Il accueillera notamment les serveurs qui n'ont pas leur place dans le Tier 0.

Nous pouvons citer les exemples suivants :

- Les serveurs applicatifs,
- Les serveurs de bases de données,
- Les serveurs de fichiers

Les comptes d'administration de ce Tier peuvent gérer uniquement leurs propres ressources et ils n'ont pas de permissions sur le Tier 0.

### C. Le Tier 2

Le **Tier 2** correspond au troisième niveau, c'est-à-dire le plus bas de notre pyramide. Ce Tier contient **les appareils et périphériques des utilisateurs**, incluant :

- Les postes de travail de bureau et portables,
- Les imprimantes

Les administrateurs de postes de travail disposeront de permissions au niveau du Tier 2, au même titre que les comptes utilisateurs standard (de façon moindre). Ils sont cloisonnés dans ce Tier et ne doivent jamais avoir de privilèges sur le Tier 1 ou le Tier 0.

### D. Les interactions entre les niveaux du Tiering Model

Le **Tiering Model** repose sur la mise en place de **3 niveaux** où chaque niveau correspond à un **silo d'identité**. Ce dernier doit permettre d'**interdire l'escalade vers un Tier supérieur** ou l'**action sur un Tier de niveau inférieur**. Il y a un cloisonnement entre les différents niveaux de notre pyramide, comme l'illustre le schéma ci-dessous.

- **Tier 0** : Les serveurs critiques liés à la gestion des identités, dont les contrôleurs de domaine.
- **Tier 1** : Les serveurs métiers (applicatifs).
- **Tier 2** : Les postes de travail et utilisateurs standard.

[![Le Tiering Model de l'Active Directory](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Representation-du-Tiering-Model-de-lActive-Directory.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Representation-du-Tiering-Model-de-lActive-Directory.png.webp)

Dans la pratique, il y aura donc **des comptes d'administration pour chaque Tier.** Ces comptes auront **des permissions strictes** correspondantes aux attentes du silo d'identité auxquels ils appartiennent.

Les comptes d'administration du Tier 0 pourront être utilisés pour effectuer l'administration à distance des serveurs du Tier 0 (et c'est tout !). Cette logique se répète pour les deux autres niveaux. Ainsi, un compte T0 ne pourra pas administrer un poste de travail : il n'a pas ce privilège ! À l'inverse, un compte T2 permettra à l'administrateur système d'agir sur un poste de travail dans le cadre d'un dépannage, mais ne lui permettra de se connecter sur un serveur du T1 ou du T0.

[![](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Ladministration-Active-Directory-avec-le-Tiering-Model.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Ladministration-Active-Directory-avec-le-Tiering-Model.png.webp)

Vous devez donc comprendre qu'**un seul et même administrateur système** doit disposer d'**au moins 4 comptes Active Directory**. À condition qu'il soit habilité à **administrer les différents Tiers**.

- Un compte utilisateur standard pour l'usage courant (navigation Internet, consultation des e-mails, etc.)
- Un compte d'administration pour le Tier 0
- Un compte d'administration pour le Tier 1
- Un compte d'administration pour le Tier 2

> **Remarque** : la **délégation des permissions** sera effectuée selon plusieurs **types de comptes** afin d'apporter de la granularité au niveau de chaque Tier. Il y a les comptes **utilisateurs** et **administrateurs locaux**, ainsi que les comptes **Opérateur**, **Administrateur** et **Manager**.

Désormais, il y a **un réel cloisonnement pour l'administration des ressources**, où chaque compte dispose de **privilèges limités, mais suffisants** pour les actions qu'il doit accomplir. Si le compte de notre administrateur système venait à être compromis lors d'une session de dépannage effectuée sur le poste de travail d'un utilisateur, que se passe-t-il ?

À la différence du premier exemple où l'attaquant devenait directement administrateur du domaine, là, ce n'est plus le cas. Désormais, l'attaquant, bien qu'il progresse (d'un point de vue des privilèges qu'il a en sa possession) est cloisonné dans le Tier 2. Ainsi, il peut effectuer des mouvements latéraux d'un poste de travail à un autre, mais il ne dispose pas de privilèges suffisants pour se connecter sur un serveur du T1 ou du T0.

[![](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Active-Directory-Tiering-Model-Compromission-dun-compte-T2.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Active-Directory-Tiering-Model-Compromission-dun-compte-T2.png.webp)

Pour autant, **l'attaquant finira peut-être par atteindre son objectif**, à savoir prendre le contrôle du domaine, mais il devra **passer par des étapes supplémentaires**. Cela va lui prendre du temps : un temps précieux qui pourra profiter aux équipes techniques, à condition d'être en mesure de détecter l'intrusion. En fonction du contexte, l'attaquant pourrait également renoncer à la compromission de l'environnement et passer à une autre cible plus accessible.

## VI. Le Tiering Model n'est pas la solution à tous les problèmes

La **bonne gestion des privilèges**, associée à la mise en place de **silos d'identité** via le Tiering Model, **n'est pas une solution miracle**. La sécurisation d'un domaine Active Directory passe par d'autres étapes intermédiaires. La mise en place de **ce cloisonnement** intervient plutôt **à la fin du parcours de sécurisation**.

Pour **passer d'un Tier à un autre**, malgré la mise en place de ce cloisonnement, l'attaquant pourrait tirer profit de certaines faiblesses du système d'information :

- **Vulnérabilités** connues dans les **protocoles**
- **Vulnérabilités** connues dans les **applications** et les **systèmes d'exploitation**
- **Défauts de configuration**

Cela peut s'expliquer par un **certain laxisme de la part de l'administrateur** dans le **suivi des mises à jour** des systèmes et des applications. Mais aussi le **non-respect des bonnes pratiques** de configuration, ce qui peut dangereusement exposer certains services. Par ailleurs, et malgré la bonne volonté de l'administrateur système, ce dernier peut être **contraint de continuer à faire tourner des applications et systèmes d'exploitation obsolètes** (pour des besoins métiers, notamment dans le secteur de l'Industrie).

[![Outillage pour la sécurité Active Directory](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Outillage-pour-la-securite-Active-Directory.png.webp)](https://www.it-connect.fr/wp-content-itc/uploads/2025/02/Outillage-pour-la-securite-Active-Directory.png.webp)

Avant d'entamer la mise en œuvre du Tiering Model, commencez par **auditer votre annuaire Active Directory** avec des logiciels faciles à prendre en main comme [**Ping Castle**](https://www.it-connect.fr/comment-auditer-lactive-directory-avec-pingcastle/ "Comment auditer l’Active Directory avec PingCastle ?"), [**Purple Knight**](https://www.it-connect.fr/comment-auditer-lactive-directory-avec-purple-knight/ "Comment auditer l’Active Directory avec Purple Knight ?") et [**GPOZaurr**](https://www.it-connect.fr/gpozaurr-outil-ultime-pour-audit-analyser-gpo/ "GPOZaurr, l’outil ultime pour analyser vos stratégies de groupe"). Vous pouvez aussi lancer une analyse du partage SYSVOL de votre domaine avec un outil comme **[HardenSysvol](https://www.it-connect.fr/securite-active-directory-hardensysvol-scanner-vulnerabilites-partage-sysvol/ "Sécurité Active Directory : détectez les vulnérabilités dans les GPO et les scripts avec HardenSysvol !")** ou une analyse plus globale avec **[Snaffler](https://www.it-connect.fr/snaffler-recherche-des-informations-sensibles-dans-les-partages-fichiers-active-directory/ "Analysez vos partages de fichiers Active Directory avec Snaffler pour protéger vos données")**, dans le but de détecter des secrets d'identification stockés au mauvais endroit... Et, pour aller encore plus loin, une analyse approfondie avec **[Bloodhound](https://www.it-connect.fr/cours/bloodhound-identifier-faiblesses-de-votre-active-directory/)** pourra être utile pour déceler les chemins d'attaque potentiels.

Cette nécessité d'associer le Tiering Model à des actions de sécurisation connexes, a été parfaitement prise en compte dans l'élaboration de la **solution [HardenAD](https://www.it-connect.fr/securite-active-directory-comment-atteindre-un-score-de-0-100-dans-pingcastle/ "Sécurité Active Directory : comment atteindre un score de 0/100 dans PingCastle ?")**. Cet outil, au-delà de **préparer votre domaine Active Directory à la mise en place du Tiering** (via la création d'OU, de comptes, etc.), va également **préparer des stratégies de groupe** pour **améliorer la sécurité globale** de votre environnement. Par exemple, il va vous aider à **désactiver (ou à limiter) l'usage des protocoles obsolètes**, comme **SMBv1**, **[LLMNR](https://www.it-connect.fr/active-directory-comment-et-pourquoi-desactiver-les-llmnr-et-netbios/ "Active Directory : comment et pourquoi désactiver les protocoles LLMNR et NetBIOS ?")** ou encore **[NTLMv1](https://www.it-connect.fr/comment-desactiver-le-protocole-ntlm-dans-un-domaine-active-directory/ "Comment désactiver le protocole NTLM dans un domaine Active Directory ?")**.

> **Remarque** : la solution HardenAD s'appuie également sur un 4ème Tier nommé "**Tier Legacy**" permettant d'adresser la problématique des systèmes d'exploitation obsolètes, sans remettre en cause la sécurité générale du SI.

Si vous envisagez de déployer un nouveau domaine Active Directory, vous pouvez utiliser l'outil **[Hello My DIR!](https://www.it-connect.fr/comment-creer-un-domaine-active-directory-respectueux-des-bonnes-pratiques-de-securite/ "Comment créer un domaine Active Directory respectueux des bonnes pratiques de sécurité ?")** pour bénéficier d'un AD qui respecte déjà les bonnes pratiques essentielles en matière de sécurité.

## VII. Conclusion

**Cette introduction à la notion de Tiering Model appliqué à l'Active Directory touche à sa fin !** Dans un prochain tutoriel, nous pourrons aborder la mise en œuvre technique initiale de ce modèle au sein d'un domaine Active Directory. L'idée n'étant pas de faire confiance aux administrateurs, mais bien d'imposer ces restrictions grâce à la mise en place d'une configuration au niveau du domaine.

Nous pourrions également consacrer un article à l'utilisation de **machines de rebond** pour **effectuer l'administration des Tiers**, car c'est une pratique recommandée (notamment pour limiter les flux et les interactions). Ces **machines durcies**, situées dans un environnement sécurisé, permettent aux administrateurs de **se connecter uniquement aux systèmes de leur Tier respectif**. L'utilisation d'un **bastion d'administration** comme **[Apache Guacamole](https://www.it-connect.fr/tuto-apache-guacamole-bastion-rdp-ssh-debian/ "Apache Guacamole, un bastion d’administration pour vos accès RDP, SSH, etc.")** et **[Teleport](https://www.it-connect.fr/comment-deployer-un-bastion-dadministration-avec-la-solution-open-source-teleport/ "Comment déployer un bastion d’administration avec la solution open source Teleport ?")** est aussi une possibilité à explorer lors de la mise en place d'une stratégie PAM.

https://www.it-connect.fr/active-directory-tiering-model-les-fondamentaux/