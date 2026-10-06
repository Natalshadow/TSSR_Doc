Recherches en autonomie :

- DNS (Rôle, Port, Fonctionnement)
- DHCP (Rôle, Port, Fonctionnement)

## DNS

## Qu'est-ce que le DNS ?

Le DNS (Domain Name System) est en quelque sorte l'annuaire téléphonique d'Internet. Les internautes accèdent aux informations en ligne via des [noms de domaine](https://www.cloudflare.com/learning/dns/glossary/what-is-a-domain-name/) (par exemple, nytimes.com ou espn.com), tandis que les navigateurs interagissent par l'intermédiaire d'[adresses IP](https://www.cloudflare.com/learning/network-layer/internet-protocol/) (Internet Protocol). Le DNS traduit les noms de domaine en [adresses IP](https://www.cloudflare.com/learning/dns/glossary/what-is-my-ip-address/) afin que les navigateurs puissent charger les ressources web.

Chaque appareil connecté à Internet dispose d'une adresse IP unique que les autres appareils utilisent afin de le trouver. Grâce aux serveurs DNS, les internautes n'ont pas besoin de mémoriser les adresses IP (par exemple, 192.168.1.1 en IPv4) ni les adresses IP alphanumériques plus récentes et plus complexes (par exemple, 2400:cb00:2048:1::c629:d7a2 en IPv6).


## Comment fonctionne le DNS ?

Le processus de résolution DNS implique la conversion d'un nom d'hôte (par exemple, www.example.com) en adresse IP utilisable par un ordinateur (par exemple, 192.168.1.1). Chaque appareil connecté à Internet reçoit une adresse IP, qui est nécessaire pour trouver l'appareil approprié sur Internet, de la même manière qu'une adresse postale permet de trouver un domicile. Lorsqu'un utilisateur souhaite charger une page web, l'adresse que saisit l'utilisateur dans son navigateur (example.com) doit être traduite en adresse utilisable par un ordinateur, indispensable pour localiser la page web correspondante.

Afin de comprendre le processus à l'œuvre derrière la résolution DNS, il est important de connaître les différents composants matériels par lesquels doit passer une requête DNS. Du point de vue du navigateur, la recherche DNS se déroule « en arrière-plan » et ne nécessite aucune interaction de l'ordinateur de l'utilisateur, à l'exception de la requête initiale.

| https://www.cloudflare.com/fr-fr/learning/dns/what-is-dns/
## DHCP (Dynamic Host Configuration Protocol) Basics

Dynamic Host Configuration Protocol (DHCP) is a standard protocol that allows a server to dynamically distribute IP addressing and configuration information to clients. Normally the DHCP server provides the client with at least this basic information:

- IP Address
    
- Subnet Mask
    
- Default Gateway
    

Other information can be provided as well, such as Domain Name Service (DNS) server addresses and Windows Internet Name Service (WINS) server addresses. The system administrator configures the DHCP server with the options that are parsed out to the client.

| https://learn.microsoft.com/en-us/windows-server/troubleshoot/dynamic-host-configuration-protocol-basics