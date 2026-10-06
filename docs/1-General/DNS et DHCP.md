---
tags:
  - definition
---
Recherches en autonomie :

- DNS (Rôle, Port, Fonctionnement)
- DHCP (Rôle, Port, Fonctionnement)

## DNS

## What is DNS?

The Domain Name System (DNS) is the phonebook of the Internet. Humans access information online through [domain names](https://www.cloudflare.com/learning/dns/glossary/what-is-a-domain-name/), like nytimes.com or espn.com. Web browsers interact through [Internet Protocol (IP)](https://www.cloudflare.com/learning/network-layer/internet-protocol/) addresses. DNS translates domain names to [IP addresses](https://www.cloudflare.com/learning/dns/glossary/what-is-my-ip-address/) so browsers can load Internet resources.

Each device connected to the Internet has a unique IP address which other machines use to find the device. DNS servers eliminate the need for humans to memorize IP addresses such as 192.168.1.1 (in IPv4), or more complex newer alphanumeric IP addresses such as 2400:cb00:2048:1::c629:d7a2 (in IPv6).

## How does DNS work?

The process of DNS resolution involves converting a hostname (such as www.example.com) into a computer-friendly IP address (such as 192.168.1.1). An IP address is given to each device on the Internet, and that address is necessary to find the appropriate Internet device - like a street address is used to find a particular home. When a user wants to load a webpage, a translation must occur between what a user types into their web browser (example.com) and the machine-friendly address necessary to locate the example.com webpage.

In order to understand the process behind the DNS resolution, it’s important to learn about the different hardware components a DNS query must pass between. For the web browser, the DNS lookup occurs "behind the scenes" and requires no interaction from the user’s computer apart from the initial request.

> https://www.cloudflare.com/learning/dns/what-is-dns/


### DNS ports

|Traffic Type|Source of Transmission|Source Port|Destination of Transmission|Destination Port|
|---|---|---|---|---|
|Queries from local DNS server|Local DNS server|A random port numbered 49152 or higher|Any remote DNS server|53|
|Responses to local DNS server|Any remote DNS server|53|Local DNS server|A random port numbered 49152 or higher|
|Queries from remote DNS server|Any remote DNS server|A random port numbered 49152 or higher|Local DNS server|53|
|Responses to remote DNS server|Local DNS server|53|Any remote DNS server|A random port numbered 49152 or higher|

>https://learn.microsoft.com/en-us/windows-server/networking/dns/network-ports
## DHCP (Dynamic Host Configuration Protocol) Basics

Dynamic Host Configuration Protocol (DHCP) is a standard protocol that allows a server to dynamically distribute IP addressing and configuration information to clients. Normally the DHCP server provides the client with at least this basic information:

- IP Address
    
- Subnet Mask
    
- Default Gateway
    

Other information can be provided as well, such as Domain Name Service (DNS) server addresses and Windows Internet Name Service (WINS) server addresses. The system administrator configures the DHCP server with the options that are parsed out to the client.

> https://learn.microsoft.com/en-us/windows-server/troubleshoot/dynamic-host-configuration-protocol-basics

### DHCP ports
A DHCP port is a designated network port that facilitates DHCP communication between the clients and servers in a network. DHCP uses the following UDP ports:

**DHCP port 67:** This port is used by the DHCP server to listen for client requests and handle DHCP discover packets as devices connect to the network.

**DHCP port 68:** Dedicated to the client side, this port receives DHCP responses, such as IP configuration details, from the server.

These ports are integral to the DHCP communication process, enabling IP address requests, server offers, client responses, and acknowledgments. By using distinct ports, DHCP optimizes both broadcast and direct client-server traffic, reducing network congestion and ensuring efficient, dynamic IP management.

>https://www.manageengine.com/products/eventlog/kb/server/dhcp-port.html