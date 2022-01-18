
---
pagetitle: "DNS LOC | Ryan Gibb"
---

# DNS LOC

The Domain Name System (DNS) has a little known 'LOC' resouce record (RR) defined in 1996 for encoding location information purportedly for hosts, networks, and subnets[0].

It encodes:

- Latitude
- Longitude
- Altidude
- Size of the referenced sphere
- Horizontal and vertical precision

A number of suggested uses are proposed in the RFC:

- USENET - a distributed discussion system now ecplised by the World Wide Web - geographic flow maps.
- A 'visual traceroute' application showing geographical flow of IP packet, presumably relying on router responding to both IP TTL timeouts and DNS LOC requests.
- Network management based using LOC RRs to map hosts and routers.

RFC-1876 also describes algorithms for resolving locations for domain names or IP addresses with decreasing accuracy.
It still refers to classful addressing, despite being published 3 years after CIDR[1], probably because the algorithm it was adapted from was published in 1989.

An aside; `find.me.uk` can be used to get the location of any UK postcode. E.g.:

	dig loc cb30fd.find.me.uk

There are a few notable issues with the DNS LOC RR, distinct from other DNS RRs:

- There's no verification of LOC's, see:
```
dig loc ryan.gibb.xyz
```
- The privacy and security implications.

> High-precision LOC RR information could be used to plan a penetration of physical security, leading to potential denial-of-machine attacks. To avoid any appearance of suggesting this method to potential attackers, we declined the opportunity to name this RR "ICBM"[0].

- They have extremely limitted real-world usage for pratical purposes. trying to implement a visual traceroute would just not be possible, as no routers or networks have LOC records.

> CloudFlare handles millions of DNS records; of those just 743 are LOCs[2].

[0] - [RFC-1876 A Means for Expressing Location Information in the Domain Name System](https://datatracker.ietf.org/doc/html/rfc1876)\
[1] - [RFC-1518-An Architecture for IP Address Allocation with CIDR](https://datatracker.ietf.org/doc/html/rfc1518)\
[2] - [The weird and wonderful world of DNS LOC records](https://blog.cloudflare.com/the-weird-and-wonderful-world-of-dns-loc-records/)\

