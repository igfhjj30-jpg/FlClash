# Android complete tunnel

This fork adds an opt-in Android mode that passes the original packets from
`VpnService` to WireGuard. A concrete UDP-capable proxy carries only the encrypted
WireGuard datagrams to the configured peer. The peer must route and NAT these
packets to the internet. Website TCP connections originate in the Android kernel;
the carrier proxy does not recreate them.

```text
Android apps → Android TCP/IP → VPN file descriptor → WireGuard encryption
            → selected proxy's UDP transport → WireGuard peer → routing/NAT
```

The carrier can be VLESS, Shadowsocks, or another concrete UDP-capable node already
in the current profile. Groups and DIRECT are rejected. A reverse tunnel between
servers is optional infrastructure: the actual carrier destination is the
configured `endpoint`, so configuring this mode does not by itself route that
destination through an existing server-to-server WireGuard link.

## Configure

1. Import the regular subscription containing the carrier node.
2. Open **Tools → Advanced configuration → Network**.
3. Choose **Read tunnel from current profile**, or import a WireGuard `.conf` file.
4. Select the concrete transport node and enable **Use complete tunnel**.
5. Start the VPN and accept Android's permission request. The network settings
   report whether WireGuard has completed a recent handshake.
6. Open **System network protection** and enable Android's **Always-on VPN** and
   **Block connections without VPN** for this app.

Profiles may carry the following extension. Replace the placeholders with a
distinct client's credentials; keep them out of public repositories and logs.
Importing the extension is explicit. After changing its credentials in a
subscription, update the subscription and read its tunnel configuration again.

```yaml
x-flclash-packet-tunnel:
  privateKey: <client private key, base64>
  publicKey: <server public key, base64>
  preSharedKey: <optional preshared key, base64>
  endpoint: 192.0.2.10:51820
  addresses: [10.204.32.2/32]
  dns: [1.1.1.1, 9.9.9.9]
  mtu: 1280
  persistentKeepalive: 25
  transportProxy: My transport node
```

The `.conf` importer accepts one interface and one peer, IPv4 interface/DNS
addresses, a numeric IPv4 endpoint, and `AllowedIPs = 0.0.0.0/0, ::/0`. It rejects
scripts, extra peers, partial routes, and unsupported settings. Each device needs
its own peer key and tunnel address.

## Routing and outage behavior

- All applications use this tunnel. Ordinary rule/global/direct selections,
  application exclusions, bypass routes, and the VPN HTTP proxy do not determine
  website routing in this mode. Mihomo's data listeners remain closed.
- IPv4, UDP, and DNS travel as original packets. Android Private DNS and browser
  secure DNS remain subject to the VPN's routes; the configured DNS addresses do
  not override those applications' own resolver choices.
- IPv6 routes are captured and IPv6 packets are discarded in both directions.
  IPv6 internet access is intentionally unavailable in this initial version.
- A transport or peer outage keeps the VPN interface and routes installed while
  WireGuard retries. There is no automatic direct or alternate-proxy fallback.
- Process death, explicit VPN stop, and permission revocation require Android's
  system lockdown setting to prevent traffic from leaving outside the VPN. The
  app cannot enable that privileged setting automatically.
- Private-network aliases and ordinary proxy routing rules must be implemented
  at the WireGuard gateway if they are needed in this mode.

The feature changes packet transport. It does not promise any particular result
from IP reputation, fraud-scoring, or proxy-classification services.

## Verification

`core/packet_tunnel_test.go` checks packet preservation, outage lifetime, carrier
restrictions, and closure of ordinary proxy listeners. Linux tests also check
IPv6 discard and support an opt-in isolated network-namespace integration test:

```sh
cd core
CGO_ENABLED=0 go test .
CGO_ENABLED=0 go vet .
CGO_ENABLED=0 go test -c -tags with_gvisor -o /tmp/packet-tunnel-test
sudo env FLCLASH_PACKET_TUNNEL_FIXTURE=/private/fixture.json \
  /tmp/packet-tunnel-test -test.run '^TestPacketTunnelKernelIntegration$' -test.v
```

The private integration fixture is JSON with `tunnel` matching the extension and
`proxy` containing the carrier's Mihomo node object. The test creates and removes
its own namespace, makes requests through the real peer, and can record the
original TCP SYN for comparison with a capture at the peer. It requires Linux,
root, `ip`, `curl`, and a configured test peer. Never reuse a production client's
key for a concurrently running test.

Android acceptance should additionally cover permission UI, actual browser IP,
WebRTC and DNS requests, peer outages and recovery, Always-on startup, process
death with lockdown, and system VPN revoke. A desktop namespace test alone cannot
prove those Android behaviors.
