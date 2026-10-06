## What is a DNS PTR record?

The [Domain Name System, or DNS](https://www.cloudflare.com/learning/dns/what-is-dns/), correlates [domain names](https://www.cloudflare.com/learning/dns/glossary/what-is-a-domain-name/) with [IP addresses](https://www.cloudflare.com/learning/dns/glossary/what-is-my-ip-address/). A DNS pointer record (PTR for short) provides the domain name associated with an IP address. A DNS PTR record is exactly the opposite of the ['A' record](https://www.cloudflare.com/learning/dns/dns-records/dns-a-record/), which provides the IP address associated with a domain name.

DNS PTR records are used in [reverse DNS lookups](https://www.cloudflare.com/learning/dns/glossary/reverse-dns/). When a user attempts to reach a domain name in their browser, a DNS lookup occurs, matching the domain name to the IP address. A reverse DNS lookup is the opposite of this process: it is a query that starts with the IP address and looks up the domain name.

## How are DNS PTR records stored?

_In IPv4:_

While DNS A records are stored under the given domain name, DNS PTR records are stored under the IP address — reversed, and with ".in-addr.arpa" added. For example, the PTR record for the IP address 192.0.2.255 would be stored under "255.2.0.192.in-addr.arpa".

"in-addr.arpa" has to be added because PTR records are stored within the .arpa top-level domain in the DNS. .arpa is a domain used mostly for managing network infrastructure, and it was [the first](https://tools.ietf.org/html/rfc881) top-level domain name defined for the Internet. (The name "arpa" dates back to the earliest days of the Internet: it takes its name from the Advanced Research Projects Agency (ARPA), which created ARPANET, an important precursor to the Internet.)

in-addr.arpa is the namespace within .arpa for reverse DNS lookups in IPv4.

_In IPv6:_

IPv6 addresses are constructed differently from IPv4 addresses, and IPv6 PTR records exist in a different namespace within .arpa. IPv6 PTR records are stored under the IPv6 address, reversed and converted into four-bit sections (as opposed to 8-bit sections, as in IPv4), plus ".ip6.arpa".

Report

Secure your DNS infrastructure

[Get the report →](https://www.cloudflare.com/lp/dns-and-the-threat-of-ddos/)

## What are some of the main uses for PTR records?

PTR records are used in reverse DNS lookups; common uses for reverse DNS include:

**Anti-spam:** Some email anti-spam filters use reverse DNS to check the domain names of email addresses and see if the associated IP addresses are likely to be used by legitimate email servers.

**Troubleshooting email delivery issues:** Because anti-spam filters perform these checks, email delivery problems can result from a misconfigured or missing PTR record. If a domain has no PTR record, or if the PTR record contains the wrong domain, email services may block all emails from that domain.

**Logging:** System logs typically record only IP addresses; a reverse DNS lookup can convert these into domain names for logs that are more human-readable.