package main

import (
	"context"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/metacubex/mihomo/component/proxydialer"
	"github.com/metacubex/mihomo/component/slowdown"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"
	"github.com/metacubex/mihomo/tunnel"
	wireguard "github.com/metacubex/sing-wireguard"
	"github.com/metacubex/wireguard-go/device"
	wgtun "github.com/metacubex/wireguard-go/tun"
)

type packetTunnelConfig struct {
	PrivateKey          string   `json:"privateKey"`
	PublicKey           string   `json:"publicKey"`
	PreSharedKey        string   `json:"preSharedKey"`
	Endpoint            string   `json:"endpoint"`
	Addresses           []string `json:"addresses"`
	DNS                 []string `json:"dns"`
	MTU                 int      `json:"mtu"`
	PersistentKeepalive int      `json:"persistentKeepalive"`
	TransportProxy      string   `json:"transportProxy"`
}

func packetTunnelKey(value string) (string, error) {
	key, err := base64.StdEncoding.DecodeString(value)
	if err != nil || len(key) != 32 || strings.Trim(string(key), "\x00") == "" {
		return "", errors.New("invalid WireGuard key")
	}
	return hex.EncodeToString(key), nil
}

func (c packetTunnelConfig) validate() error {
	if _, err := packetTunnelKey(c.PrivateKey); err != nil {
		return err
	}
	if _, err := packetTunnelKey(c.PublicKey); err != nil {
		return err
	}
	if c.PreSharedKey != "" {
		if _, err := packetTunnelKey(c.PreSharedKey); err != nil {
			return err
		}
	}
	endpoint, err := netip.ParseAddrPort(c.Endpoint)
	if err != nil || endpoint.Port() == 0 || endpoint.Addr().IsUnspecified() || endpoint.Addr().IsMulticast() {
		return errors.New("WireGuard endpoint must be an IP address and port")
	}
	if c.MTU < 1280 || c.MTU > 1420 || c.PersistentKeepalive < 0 || c.PersistentKeepalive > 65535 {
		return errors.New("invalid full tunnel MTU or keepalive")
	}
	if strings.TrimSpace(c.TransportProxy) == "" {
		return errors.New("a concrete UDP proxy is required for the full tunnel")
	}
	return nil
}

func (c packetTunnelConfig) ipc() (string, error) {
	if err := c.validate(); err != nil {
		return "", err
	}
	privateKey, _ := packetTunnelKey(c.PrivateKey)
	publicKey, _ := packetTunnelKey(c.PublicKey)
	value := "private_key=" + privateKey + "\nreplace_peers=true\npublic_key=" + publicKey + "\n"
	if c.PreSharedKey != "" {
		key, _ := packetTunnelKey(c.PreSharedKey)
		value += "preshared_key=" + key + "\n"
	}
	value += "endpoint=" + c.Endpoint + "\nreplace_allowed_ips=true\nallowed_ip=0.0.0.0/0\nallowed_ip=::/0\n"
	value += "persistent_keepalive_interval=" + strconv.Itoa(c.PersistentKeepalive) + "\n"
	return value, nil
}

type packetTunnelDialer struct {
	proxyName string
	endpoint  netip.AddrPort
	lookup    func(string) C.Proxy
}

func packetTunnelProxy(name string) C.Proxy {
	return tunnel.AllProxies()[name]
}

func (d packetTunnelDialer) proxy() (C.Dialer, error) {
	proxy := d.lookup(d.proxyName)
	if proxy == nil || !proxy.SupportUDP() {
		return nil, errors.New("full tunnel transport is unavailable")
	}
	switch proxy.Type() {
	case C.Direct, C.Reject, C.RejectDrop, C.Compatible, C.Pass, C.PassRule, C.Rematch, C.Dns,
		C.Relay, C.Selector, C.Fallback, C.URLTest, C.LoadBalance:
		return nil, errors.New("full tunnel transport must be a concrete proxy, without automatic fallback")
	}
	return proxydialer.New(proxy, true), nil
}

func (d packetTunnelDialer) DialContext(ctx context.Context, network, address string) (net.Conn, error) {
	if network != "udp" || address != d.endpoint.String() {
		return nil, errors.New("full tunnel transport only carries its WireGuard peer datagrams")
	}
	proxy, err := d.proxy()
	if err != nil {
		return nil, err
	}
	return proxy.DialContext(ctx, network, address)
}

func (d packetTunnelDialer) ListenPacket(context.Context, string, string, netip.AddrPort) (net.PacketConn, error) {
	return nil, errors.New("unbound full tunnel transport is not permitted")
}

type packetTunnelStatus struct {
	Active        bool   `json:"active"`
	Handshaken    bool   `json:"handshaken"`
	LastHandshake int64  `json:"lastHandshake"`
	Received      uint64 `json:"received"`
	Sent          uint64 `json:"sent"`
	IPv6Blocked   bool   `json:"ipv6Blocked"`
}

type packetTunnel struct {
	device  *device.Device
	ctx     context.Context
	dns     []string
	dnsNext atomic.Uint32
	cancel  context.CancelFunc
	closed  atomic.Bool
	failing atomic.Bool
}

var activePacketTunnel atomic.Pointer[packetTunnel]
var packetTunnelMode atomic.Bool

func handlePacketTunnelMode(enabled bool) {
	configMu.Lock()
	defer configMu.Unlock()
	changed := packetTunnelMode.Swap(enabled) != enabled
	if changed && enabled {
		handleCloseConnections()
	}
	updateListeners(currentConfig)
	if changed {
		bumpRouteEpoch()
	}
}

func newPacketTunnel(tun wgtun.Device, config packetTunnelConfig, transport C.Dialer) (*packetTunnel, error) {
	ipc, err := config.ipc()
	if err != nil {
		_ = tun.Close()
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	packet := &packetTunnel{ctx: ctx, cancel: cancel, dns: append([]string(nil), config.DNS...)}
	endpoint, _ := netip.ParseAddrPort(config.Endpoint)
	slowDialer := proxydialer.NewSlowDownDialer(transport, slowdown.New())
	bind := wireguard.NewClientBind(ctx, packet, proxydialer.NewSingDialer(slowDialer), true, endpoint, [3]uint8{})
	logger := &device.Logger{Verbosef: func(string, ...any) {}, Errorf: func(string, ...any) {}}
	packet.device = device.NewDevice(tun, bind, logger, 2)
	if err = packet.device.IpcSet(ipc); err == nil {
		err = packet.device.Up()
	}
	if err != nil {
		packet.Close()
		return nil, errors.New("could not initialize the packet tunnel")
	}
	return packet, nil
}

func (p *packetTunnel) NewError(context.Context, error) {
	if !p.closed.Load() && p.failing.CompareAndSwap(false, true) {
		log.Warnln("[Full tunnel] transport unavailable; VPN routes remain in place")
	}
}

func (p *packetTunnel) Close() {
	if p.closed.Swap(true) {
		return
	}
	p.cancel()
	p.device.Close()
}

func (p *packetTunnel) dialProbe(ctx context.Context, address string) (net.Conn, error) {
	if len(p.dns) == 0 {
		return nil, errors.New("complete tunnel DNS is not configured")
	}
	resolver := &net.Resolver{PreferGo: true, Dial: func(ctx context.Context, network, _ string) (net.Conn, error) {
		nameserver := p.dns[(p.dnsNext.Add(1)-1)%uint32(len(p.dns))]
		if network == "tcp" {
			network = "tcp4"
		} else {
			network = "udp4"
		}
		return (&net.Dialer{}).DialContext(ctx, network, net.JoinHostPort(nameserver, "53"))
	}}
	return (&net.Dialer{Resolver: resolver}).DialContext(ctx, "tcp4", address)
}

func (p *packetTunnel) status() packetTunnelStatus {
	if p == nil || p.closed.Load() {
		return packetTunnelStatus{}
	}
	status := packetTunnelStatus{Active: true, IPv6Blocked: true}
	ipc, err := p.device.IpcGet()
	if err != nil {
		return status
	}
	for _, line := range strings.Split(ipc, "\n") {
		key, value, found := strings.Cut(line, "=")
		if !found {
			continue
		}
		switch key {
		case "last_handshake_time_sec":
			status.LastHandshake, _ = strconv.ParseInt(value, 10, 64)
		case "rx_bytes":
			status.Received, _ = strconv.ParseUint(value, 10, 64)
		case "tx_bytes":
			status.Sent, _ = strconv.ParseUint(value, 10, 64)
		}
	}
	status.Handshaken = status.LastHandshake > 0 && time.Now().Unix()-status.LastHandshake < 185
	return status
}

type packetFileTun struct {
	file   *os.File
	mtu    int
	events chan wgtun.Event
	once   sync.Once
}

func newPacketFileTun(fd int, mtu int) (*packetFileTun, error) {
	file := os.NewFile(uintptr(fd), "FlClashPacketTunnel")
	if file == nil {
		return nil, errors.New("invalid packet tunnel descriptor")
	}
	return &packetFileTun{file: file, mtu: mtu, events: make(chan wgtun.Event)}, nil
}

func (t *packetFileTun) File() *os.File             { return t.file }
func (t *packetFileTun) MTU() (int, error)          { return t.mtu, nil }
func (t *packetFileTun) Name() (string, error)      { return "FlClashWG", nil }
func (t *packetFileTun) Events() <-chan wgtun.Event { return t.events }
func (t *packetFileTun) BatchSize() int             { return 1 }

func (t *packetFileTun) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	for {
		n, err := t.file.Read(buffers[0][offset:])
		if err != nil {
			return 0, err
		}
		if n > 0 && buffers[0][offset]>>4 == 4 {
			sizes[0] = n
			return 1, nil
		}
	}
}

func (t *packetFileTun) Write(buffers [][]byte, offset int) (int, error) {
	for i, buffer := range buffers {
		if len(buffer) <= offset || buffer[offset]>>4 != 4 {
			continue
		}
		if _, err := t.file.Write(buffer[offset:]); err != nil {
			return i, fmt.Errorf("packet tunnel write: %w", err)
		}
	}
	return len(buffers), nil
}

func (t *packetFileTun) Close() error {
	var err error
	t.once.Do(func() {
		err = t.file.Close()
		close(t.events)
	})
	return err
}
