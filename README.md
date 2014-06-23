Multiple OpenVPN connections served through proxy
=================================================
I have multiple VPN connections, allowing 1 simultaneous login per user. I want to share these connections to my LAN so people who want specific browser sessions to use a different IP, they just choose from the local proxies:

- `proxyaddress:3128` for the first proxy (i.e. HU address)
- `proxyaddress:3129` for the second proxy (i.e. USA address), etc.

This way they don't need to set up an OpenVPN client on their machine, especially when they want to use the proxy for a single browser session and keep the rest of the network traffic routed through the default gateway, not everything through the VPN.

Because of the multiple simultaneous VPN connections running on the proxy machine, we need advanced Linux routing rules. *You can find the detailed howto in the respected README files.*


Files
-----

  * Server-side OpenVPN config

   * Default install, use `easy-rsa` to key generation (see OpenVPN manual)

   * You can have multiple servers set up on different machines.

* Client-side OpenVPN config
   * Squid proxy config, running on the VPN client machine

   Please note, it's required to use Squid v3 (squid3 package in Debian). The default squid package is v2.7 which is buggy.

   * config generator for the proxy
   * also you can find the required advanced routing rules (commands)

OpenVPN special config
----------------------
Use `--route-nopull` so it won't override your default gateway. This causes that nothing will be sent through the tunnel by default. You have to specify later what to send through VPN.


Routing
-------
**Server side**: nothing special. Follow OpenVPN manual. (NAT with tunneling.)

**Client side**: iproute2 routing tables with packet *MARK*ing

We don't allow OpenVPN the override the default gateway on the machine, so after connecting, by default nothing goes through the VPN tunnel. We can specifically add the routing rules later.

Squid uses different outgoing interfaces, based on which port we connect to it. In my example, if the user connects to `proxy:3128`, it will use `192.168.0.6` as outgoing IP. Iptables marks each packet coming from this address, so it will know it has to use my specific routing table for this destination tunnel.


I have two OpenVPN instance running, creating therefore `tun0` and `tun1` interfaces:

	root@inst02:~# ip addr show dev tun0
	3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 100
		link/none
		inet 192.168.0.6 peer 192.168.0.5/32 scope global tun0

	root@inst02:~# ip addr show dev tun1
	4: tun1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN qlen 100
		link/none
		inet 192.168.1.6 peer 192.168.1.5/32 scope global tun1


By default, nothing goes to the tunnel, my default GW is unmodified:

	root@inst02:~# ip route
	default via 10.248.70.1 dev eth0
	10.248.70.0/24 dev eth0  proto kernel  scope link  src 10.248.70.171
	192.168.0.5 dev tun0  proto kernel  scope link  src 192.168.0.6
	192.168.1.5 dev tun1  proto kernel  scope link  src 192.168.1.6


The packets are marked with iptables, so iproute2 will know where to redirect all the incoming proxy traffic:

	root@inst02:~# ip rule show
	0:      from all lookup local
	32762:  from all fwmark 0xc39 lookup VPN3129
	32763:  from all fwmark 0xc38 lookup VPN3128
	32764:  from 192.168.1.0/24 lookup VPN3129
	32765:  from 192.168.0.0/24 lookup VPN3128
	32766:  from all lookup main
	32767:  from all lookup default



I have the simplest routing rules for the tunnels: redirect everything to the tunnel (but I could specify to route only special subnets and drop everything else):

    root@inst02:~# ip route show table VPN3128
    default via 192.168.0.5 dev tun0

    root@inst02:~# ip route show table VPN3129
    default via 192.168.1.5 dev tun1
