---
pagetitle: "ILNP Interface | gibbr.org"
date: "2021-10-16 00:00:00"
---

# ILNP Interface

2021-10-16

My [dissertation](../network_layer_mobility) involved implementing an [Identifier-Locator Network Protocol](../network_layer_mobility#ilnp) (ILNP) [overlay network](../network_layer_mobility#overlay-network) in Python which can be found at [github.com/RyanGibb/ilnp-overlay-network](https://github.com/RyanGibb/ilnp-overlay-network).

As part of this, I wanted to add an application layer interface to the overlay to support existing applications.
(To those who still want to know why I posit, why not?)
That is, applications other than those written in python specifically for the overlay.
This would also allow multiple applications to run over one overlay network stack.
However, this wasn't a priority for my dissertation as it wasn't necessary to obtain experimental results.

Since graduating I've found a few weekends to work on this and a solution will be explored in this blog post.

## Datagrams

First up, how can we send a datagram over this overlay network?

We already provide a Python socket interface with the skinny transport protocol (STP), which wraps an ILNP packet in a port for demultiplexing, very similar to UDP.
But this requires importing `transport.py` and instantiating a whole overlay stack.
We could support applications other than Python with some sort of inter-process communication (like Unix domain sockets), but this would only solve one of our problems.
It would allow applications written in other languages to use our overlay, but it will still require writing applications specifically to use our overlay.

Instead, to provide an interface that existing applications can use, we can use a local UDP port as a proxy into our overlay.
This will require a program to instantiate the overlay stack and proxy data from the UDP port to the overlay.
We'll call this program `proxy.py`.

However, this local proxy will require adding some connection state to a stateless communication protocol.
When `proxy.py` receives a packet how will it know what virtual hostname (which are different to the underlay hostnames), and STP port, to send it to?
We'll call this combination of hostname and port the 'remote'.

We could have a default remote hard coded, but this would only allow one communication channel.
So instead we will have a mapping from local ports to remotes, where the local port is the port of the UDP socket connecting to our listening UDP socket.
To allow these mappings to be dynamic we'll use out-of-band communication and have `proxy.py` listening on a unix domain socket `./sock` for new mappings.
As we don't have any restrictions on the STP ports we're using in our overlay, we might as well use a 1-to-1 mapping of UDP ports to STP ports to simplify things.

An ILNP overlay aware application could create a mapping itself, but to support existing programs we can manually create one with:

	$ python proxy_create.py LOCAL_PORT REMOTE_HOSTNAME REMOTE_PORT

Now receiving is very simple.
We just spawn a thread for every ILNP STP socket and when we receive a packet on this socket we forward with UDP to the corresponding port locally.
Note that a socket doesn't necessarily have to send packets to our overlay to receive packets from it, but a mapping does have to exist for its port.

So our local UDP proxy operating with 3 mappings would loop like:

![](proxy.svg){width=75%}

Where a, b, and c can be any free port.

We could have a separate listening port for every connection, which would allow any source port, but this would require double the number of ports and threads in use, as well as requiring keeping track of additional mappings between these listening ports and client ports.
Having only one listening UDP socket greatly simplifies the design of the proxy.

See [github.com/RyanGibb/ilnp-overlay-network/blob/master/src](https://github.com/RyanGibb/ilnp-overlay-network/blob/master/src) for the implementation of `proxy.sh` and `proxy_create.py`.

## Does it work?

This is all great in theory, but does it work in practice?

Unfortunately, I don't have access to the Raspberry Pi testbed that I used for my dissertation's [experiments](../network_layer_mobility/#experiments) anymore.
Luckily at the time of experimenting with this (but not at the time of writeup), I had access to my current laptop `ryan-laptop`, an old tower PC `ryan-pc`, and an old HP laptop `hp-laptop` being used as a server, all connected to the same network (important for multicast) using IEEE 801.11.
I have `ryan-laptop` and `ryan-pc` running Arch Linux, and `hp-laptop` running Ubuntu Server 21.04.

The only modifications required were a configuration change to the `mcast_interface`, and a one character [fix](https://github.com/RyanGibb/ilnp-overlay-network/commit/43eba661585d0fbd159c0e7e8777f095deb2d592) (arguably more of a hack) to get the machines IP address on the `mcast_interface`.

We'll leave the overlay network topology as it was in the experiments:

![](../network_layer_mobility/images/diagrams/experiment.svg){width=75%}

With `ryan-laptop` as the mobile node (MN), `ryan-pc` as the corresponding node (CN), and `hp-laptop` as the router.
This topology and mobility is transparent to the programs proxied through our overlay, as well as the proxy itself.

First, we'll create the two proxy sockets on port 10000 redirecting to our overlay at both endpoints, `ryan-laptop` and `ryan-pc`:

	ryan-laptop $ python proxy.py ../config/config.ini 10000

	ryan-pc $ python proxy.py ../config/config.ini 10000

Then create the mappings:

	ryan-laptop $ python proxy_create.py 10000 ryan-pc 10001

	ryan-pc $ python proxy_create.py 10000 ryan-laptop 10001

We will also require running the proxy without any mappings on `hp-laptop` to instantiate the ILNP stack so it can forward packets:

	hp-laptop $ python proxy.py

Now on both endpoints we can run netcat to listen for UDP packets from 10000 on port 10001, and they can communicate!

	ryan-laptop $ nc -u 127.0.0.1 10000 -p 10001
	hello,
	world

	ryan-pc $ nc -u 127.0.0.1 10000 -p 10001
	hello,
	world

We could replace netcat with any other application interfacing with a UDP socket as long as we know its source port.
If we don't have a predictable source port, we could just proxy it through netcat to provide one.

Through this, we can have bidirectional datagram communication over our overlay network using a local UDP proxy.

## Streams

Datagrams are great and all, but can we have a reliable ordered bytestream over our overlay?

We could follow a similar approach to what we did with datagrams.
That is, proxy TCP connections over our overlay.
But this would not provide reliability; or rather this would only provide reliable delivery locally to our TCP proxy.
Despite emphasising the lack of loss in our overlay, this was a lack of loss due to mobility.
It doesn't prevent loss due to congestion, link layer failures, or cosmic rays...

In a similar way to how our skinny transport protocol emulates UDP, we could add a transport layer protocol emulating TCP that provides a reliable, ordered, bytestream to our overlay.
But this is a lot of work.

UDP is essentially a port wrapped around an IP packet for demultiplexing.
What if we could treat our unreliable datagram as an IP packet, and run a transport layer protocol providing a reliable ordered bytestream on top of it?
That would solve both problems - provide reliable delivery and not require reinventing the wheel.

QUIC, implemented in 2012, and defined in [RFC9000](https://datatracker.ietf.org/doc/html/rfc9000), is the first that springs to mind.
This is a transport layer protocol intended to provide performant and secure HTTP connections.
To get around various protocol ossification problems, including NAT traversal, QUIC runs over UDP.
This works to our benefit as if we could proxy QUIC to send UDP packets over our overlay this would be perfect for our use case.

However, QUIC only exists as a [number of userspace implementations](https://github.com/quicwg/base-drafts/wiki/Implementations).
This has great benefits for development, but means we would be back to a raw userspace socket interface that we couldn't use existing programs with.
We could write another proxy from applications to a QUIC userspace process, but let's see if we can do better.

A slightly older protocol Stream Control Transmission Protocol (SCTP), defined in [RFC4960](https://datatracker.ietf.org/doc/html/rfc4960), is a better solution.
SCTP is a stream based transport layer protocol with some benefits over TCP, like multistreaming.
It's worth noting that there are a lot of parallels between what SCTP and ILNP provide, like mobility and multihoming, just implemented at different layers of the network stack.

But what we really care about is defined in [RFC6951](https://datatracker.ietf.org/doc/html/rfc6951).
This extension to SCTP provides an option to encapsulate SCTP packets in UDP packets instead of IP packets.
The main purpose of this extension is to allow SCTP packets to traverse 'legacy' NAT - the same reason QUIC uses UDP - but it also means we can proxy SCTP encapsulated in UDP over our overlay!

There is a [userspace implementation of SCTP](https://github.com/sctplab/usrsctp), but it only provides a userspace socket interface in C++.
Fortunately the Linux kernel has <a href="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/diff/net/sctp/?id=v5.11&id2=v5.10">implemented</a> RFC6951 in [version 5.11](https://cdn.kernel.org/pub/linux/kernel/v5.x/ChangeLog-5.11), released February 2021, and the nmap suite have included support for SCTP in their ncat utility (a spiritual successor to netcat).

Note that only the end hosts require SCTP support, so the fact that `hp-laptop` is running Ubuntu using an older kernel is not an issue.

SCTP UDP encapulsation uses a `udp_port` and `encap_port`.
From the [sysctl kernel documentation](https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html):

	udp_port - INTEGER

	The listening port for the local UDP tunnelling sock. Normally it’s using the IANA-assigned UDP port number 9899 (sctp-tunneling).

	This UDP sock is used for processing the incoming UDP-encapsulated SCTP packets (from RFC6951), and shared by all applications in the same net namespace.

	This UDP sock will be closed when the value is set to 0.

	The value will also be used to set the src port of the UDP header for the outgoing UDP-encapsulated SCTP packets. For the dest port, please refer to ‘encap_port’ below.
	
encap_port - INTEGER
	
	The default remote UDP encapsulation port.

	This value is used to set the dest port of the UDP header for the outgoing UDP-encapsulated SCTP packets by default. Users can also change the value for each sock/asoc/transport by using setsockopt. For further information, please refer to RFC6951.

	Note that when connecting to a remote server, the client should set this to the port that the UDP tunneling sock on the peer server is listening to and the local UDP tunneling sock on the client also must be started. On the server, it would get the encap_port from the incoming packet’s source port.

As we want to intercept the SCTP UDP packets for proxying over our overlay, we won't use the IANA-assigned 9899 port for these variables.
Instead, we'll use ncat to intercept outgoing SCTP UDP packets (sent to `udp_port`) proxying them over our overlay, and to forward received SCTP UDP packets to `encap_port`, where the kernel SCTP implementation will be listening. It's worth noting that this will likely break any other applications using SCTP.

## Putting it all together

On both `ryan-laptop` and `ryan-pc` we configure the kernel SCTP implementation's listening port and outgoing destination port:

	# UDP listening port
	$ sudo sysctl -w net.sctp.encap_port=10002
	# UDP dest port
	$ sudo sysctl -w net.sctp.udp_port=10003

To redirect outgoing SCTP UDP packets over the overlay we'll redirect packets destined for port 10002 to the overlay with source port 10002:

	$ ncat -u -l 10002 -c "ncat -u 127.0.0.1 10001 -p 10002" --keep-open

Proxy mappings redirecting packets from local port `encap_port` to remote port `udp_port`:

	ryan-pc: % python proxy_create.py 10002 alice 10003
	ryan-laptop: % python proxy_create.py 10002 bob 10003

And as control messages will be exchanged between the two SCTP instances we'll also require redirecting packets from local port `encap_port` to remote port `encap_port`.

	ryan-pc: % python proxy_create.py 10003 alice 10003
	ryan-laptop: % python proxy_create.py 10003 bob 10003

Now we can run ncat with SCTP :-)

	ryan-laptop $ ncat --sctp -l 9999
	hello,
	world

	ryan-pc $ ncat --sctp 127.0.0.1 9999
	hello,
	world

But this _still_ doesn't allow us to use existing applications using a standard TCP socket over our overlay.
For this, we turn to `ssh`.

On both end points we can run:

	$ ncat --sctp -l 9999 -c "ncat 127.0.0.1 22" --keep-open

Which will use ncat to send sctp data to port 22, used for ssh.

With an openssh server configured on the machine we can then use:

	$ ssh -o "ProxyCommand ncat --sctp 127.0.0.1 9999" -N -D 8080 localhost

To connect via ssh over our overlay.

And if we have ssh... we have anything!

That is, we can create a SOCKS proxy to send anything over our overlay.
For example, we can create a proxy:

	$ ssh -o "ProxyCommand ncat --sctp 127.0.0.1 9999" -N -D 8080 localhost

And then configure your web browser of choice to use this proxy.

Alternatively, one could also proxy a raw TCP connection on port `PORT` over SCTP and our overlay with:

	$ ncat -l PORT -c "ncat --sctp 127.0.0.1 9999" --keep-open

## Taking a step back

Putting all the pieces together, the network stack looks something like:

![](bin.jpg){width=75%}

Just kidding.
But not really.
All these proxies and overlays obviously have performance implications.

As David Wheeler said, "All problems in computer science can be solved by another level of indirection, except for the problem of too many layers of indirection."

But hey, it works!

Here's the actual network stack a SOCKS proxy over our overlay:

![](network_stack.svg){width=40%}

The various proxying and mappings are not depicted.

## Further Reading

Some interesting reads that are related and tangentially related, respectively, to this project.

- On QUIC and SCTP: [https://lwn.net/Articles/745590/](https://lwn.net/Articles/745590/) </li>
- On NAT traversal: [https://tailscale.com/blog/how-nat-traversal-works/](https://tailscale.com/blog/how-nat-traversal-works/)
