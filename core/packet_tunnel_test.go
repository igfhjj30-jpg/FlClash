package main

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/metacubex/mihomo/config"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/listener"
	wgtun "github.com/metacubex/wireguard-go/tun"
	"golang.org/x/crypto/curve25519"
)

type memoryPacketTun struct {
	read   chan []byte
	wrote  chan []byte
	done   chan struct{}
	events chan wgtun.Event
	once   sync.Once
	closed atomic.Bool
}

func newMemoryPacketTun() *memoryPacketTun {
	return &memoryPacketTun{read: make(chan []byte, 8), wrote: make(chan []byte, 8), done: make(chan struct{}), events: make(chan wgtun.Event)}
}
func (m *memoryPacketTun) File() *os.File             { return nil }
func (m *memoryPacketTun) MTU() (int, error)          { return 1280, nil }
func (m *memoryPacketTun) Name() (string, error)      { return "test", nil }
func (m *memoryPacketTun) Events() <-chan wgtun.Event { return m.events }
func (m *memoryPacketTun) BatchSize() int             { return 1 }
func (m *memoryPacketTun) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	select {
	case packet := <-m.read:
		sizes[0] = copy(buffers[0][offset:], packet)
		return 1, nil
	case <-m.done:
		return 0, net.ErrClosed
	}
}
func (m *memoryPacketTun) Write(buffers [][]byte, offset int) (int, error) {
	for i, buffer := range buffers {
		select {
		case m.wrote <- bytes.Clone(buffer[offset:]):
		case <-m.done:
			return i, net.ErrClosed
		}
	}
	return len(buffers), nil
}
func (m *memoryPacketTun) Close() error {
	m.once.Do(func() { m.closed.Store(true); close(m.done); close(m.events) })
	return nil
}

type packetTestConn struct {
	net.Conn
	local, remote net.Addr
}

func (c packetTestConn) LocalAddr() net.Addr  { return c.local }
func (c packetTestConn) RemoteAddr() net.Addr { return c.remote }

type packetTestDialer struct {
	conn    net.Conn
	attempt chan struct{}
	once    sync.Once
}

func (d *packetTestDialer) DialContext(_ context.Context, network, _ string) (net.Conn, error) {
	if network != "udp" {
		return nil, errors.New("attempted to create a website TCP connection")
	}
	if d.attempt != nil {
		d.once.Do(func() { close(d.attempt) })
	}
	if d.conn == nil {
		return nil, errors.New("transport offline")
	}
	return d.conn, nil
}
func (d *packetTestDialer) ListenPacket(context.Context, string, string, netip.AddrPort) (net.PacketConn, error) {
	return nil, errors.New("unexpected unbound transport")
}

func testPacketConfig(seed byte) packetTunnelConfig {
	private := bytes.Repeat([]byte{seed}, 32)
	public, _ := curve25519.X25519(private, curve25519.Basepoint)
	return packetTunnelConfig{PrivateKey: base64.StdEncoding.EncodeToString(private), PublicKey: base64.StdEncoding.EncodeToString(public), Endpoint: "192.0.2.1:51820", MTU: 1280, PersistentKeepalive: 0, TransportProxy: "test-proxy"}
}

func TestPacketTunnelPreservesOriginalTCPPacket(t *testing.T) {
	clientConfig, serverConfig := testPacketConfig(11), testPacketConfig(22)
	clientConfig.PublicKey, serverConfig.PublicKey = serverConfig.PublicKey, clientConfig.PublicKey
	serverConfig.Endpoint = "192.0.2.2:51820"
	left, right := net.Pipe()
	clientAddr, serverAddr := net.UDPAddrFromAddrPort(netip.MustParseAddrPort(serverConfig.Endpoint)), net.UDPAddrFromAddrPort(netip.MustParseAddrPort(clientConfig.Endpoint))
	clientTun, serverTun := newMemoryPacketTun(), newMemoryPacketTun()
	client, err := newPacketTunnel(clientTun, clientConfig, &packetTestDialer{conn: packetTestConn{left, clientAddr, serverAddr}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(client.Close)
	server, err := newPacketTunnel(serverTun, serverConfig, &packetTestDialer{conn: packetTestConn{right, serverAddr, clientAddr}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(server.Close)
	packet := make([]byte, 60)
	packet[0], packet[8], packet[9] = 0x45, 64, 6
	binary.BigEndian.PutUint16(packet[2:4], uint16(len(packet)))
	copy(packet[12:16], []byte{10, 204, 32, 2})
	copy(packet[16:20], []byte{1, 1, 1, 1})
	binary.BigEndian.PutUint16(packet[20:22], 49152)
	binary.BigEndian.PutUint16(packet[22:24], 443)
	binary.BigEndian.PutUint32(packet[24:28], 0x12345678)
	packet[32], packet[33] = 0xa0, 2
	copy(packet[40:], []byte{2, 4, 5, 180, 4, 2, 8, 10, 1, 2, 3, 4, 0, 0, 0, 0, 1, 3, 3, 7})
	clientTun.read <- packet
	select {
	case received := <-serverTun.wrote:
		if !bytes.Equal(received, packet) {
			t.Fatalf("TCP sequence, options or IP packet changed: got %x, want %x", received, packet)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("the original packet did not reach the WireGuard peer")
	}
	if !client.status().Handshaken {
		t.Fatal("successful packet transfer did not report a handshake")
	}
}

func TestPacketTunnelOutageKeepsTunOpen(t *testing.T) {
	tun := newMemoryPacketTun()
	dialer := &packetTestDialer{attempt: make(chan struct{})}
	packet, err := newPacketTunnel(tun, testPacketConfig(33), dialer)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(packet.Close)
	select {
	case <-dialer.attempt:
	case <-time.After(2 * time.Second):
		t.Fatal("the encrypted transport was not attempted")
	}
	if tun.closed.Load() || !packet.status().Active || packet.status().Handshaken {
		t.Fatal("an upstream outage must keep the VPN interface active without claiming a handshake")
	}
	finished := make(chan struct{})
	go func() { packet.Close(); close(finished) }()
	select {
	case <-finished:
	case <-time.After(2 * time.Second):
		t.Fatal("closing an unavailable transport did not cancel its reconnect loop")
	}
	if !tun.closed.Load() {
		t.Fatal("an explicit stop must release the owned TUN")
	}
}

type packetPolicyProxy struct {
	C.Proxy
	adapterType C.AdapterType
}

func (p packetPolicyProxy) Type() C.AdapterType { return p.adapterType }
func (p packetPolicyProxy) SupportUDP() bool    { return true }

func TestPacketTunnelNeverFallsBackToDirectOrAnotherDestination(t *testing.T) {
	for _, adapterType := range []C.AdapterType{C.Direct, C.Compatible, C.Fallback, C.Selector, C.URLTest, C.LoadBalance} {
		d := packetTunnelDialer{proxyName: "named", endpoint: netip.MustParseAddrPort("192.0.2.1:51820"), lookup: func(string) C.Proxy { return packetPolicyProxy{adapterType: adapterType} }}
		if _, err := d.proxy(); err == nil {
			t.Fatalf("transport accepted %v", adapterType)
		}
	}
	d := packetTunnelDialer{endpoint: netip.MustParseAddrPort("192.0.2.1:51820"), lookup: func(string) C.Proxy { t.Fatal("invalid traffic reached the proxy lookup"); return nil }}
	for _, request := range [][2]string{{"tcp", "1.1.1.1:443"}, {"udp", "192.0.2.2:51820"}} {
		if _, err := d.DialContext(context.Background(), request[0], request[1]); err == nil {
			t.Fatalf("accepted traffic outside the WireGuard peer: %v", request)
		}
	}
}

func TestPacketTunnelModeClosesAndWithholdsProxyListeners(t *testing.T) {
	reservation, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	port := reservation.Addr().(*net.TCPAddr).Port
	_ = reservation.Close()
	cfg, err := config.Parse([]byte(fmt.Sprintf("mixed-port: %d\nbind-address: 127.0.0.1\n", port)))
	if err != nil {
		t.Fatal(err)
	}
	withCurrentConfig(t, cfg)
	previousRunning, previousMode := isRunning.Swap(true), packetTunnelMode.Swap(false)
	t.Cleanup(func() {
		listener.StopListener()
		isRunning.Store(previousRunning)
		packetTunnelMode.Store(previousMode)
	})
	updateListeners(cfg)
	if listener.GetPorts().MixedPort != port {
		t.Fatal("ordinary mode did not open the configured mixed listener")
	}
	handlePacketTunnelMode(true)
	updateListeners(cfg)
	if listener.GetPorts().MixedPort != 0 {
		t.Fatal("a profile refresh re-enabled proxy traffic outside the full tunnel")
	}
	handlePacketTunnelMode(false)
	if listener.GetPorts().MixedPort != port {
		t.Fatal("returning to ordinary mode did not restore its listener")
	}
}
