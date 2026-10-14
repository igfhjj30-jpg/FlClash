package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/netip"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	C "github.com/metacubex/mihomo/constant"
	wgtun "github.com/metacubex/wireguard-go/tun"
	"golang.org/x/sys/unix"
)

type recordingPacketTun struct {
	wgtun.Device
	syn chan string
}

func (r *recordingPacketTun) Read(buffers [][]byte, sizes []int, offset int) (int, error) {
	n, err := r.Device.Read(buffers, sizes, offset)
	for i := 0; i < n; i++ {
		packet := buffers[i][offset : offset+sizes[i]]
		if len(packet) < 40 || packet[0]>>4 != 4 || packet[9] != 6 || packet[16] != 1 || packet[17] != 0 || packet[18] != 0 || packet[19] != 1 {
			continue
		}
		header := int(packet[0]&15) * 4
		if len(packet) >= header+20 && packet[header+2] == 1 && packet[header+3] == 187 && packet[header+13]&2 != 0 {
			select {
			case r.syn <- hex.EncodeToString(packet):
			default:
			}
		}
	}
	return n, err
}

func packetIntegrationFD(namespace string) (fd int, err error) {
	runtime.LockOSThread()
	defer runtime.UnlockOSThread()
	original, err := os.Open("/proc/thread-self/ns/net")
	if err != nil {
		return -1, err
	}
	defer original.Close()
	target, err := os.Open(filepath.Join("/run/netns", namespace))
	if err != nil {
		return -1, err
	}
	defer target.Close()
	if err = unix.Setns(int(target.Fd()), unix.CLONE_NEWNET); err != nil {
		return -1, err
	}
	defer func() {
		if restore := unix.Setns(int(original.Fd()), unix.CLONE_NEWNET); restore != nil {
			panic("could not restore the integration test namespace")
		}
	}()
	fd, err = unix.Open("/dev/net/tun", unix.O_RDWR|unix.O_CLOEXEC|unix.O_NONBLOCK, 0)
	if err != nil {
		return -1, err
	}
	request, err := unix.NewIfreq("wgphone0")
	if err == nil {
		request.SetUint16(unix.IFF_TUN | unix.IFF_NO_PI)
		err = unix.IoctlIfreq(fd, unix.TUNSETIFF, request)
	}
	if err != nil {
		_ = unix.Close(fd)
		return -1, err
	}
	return fd, nil
}

func TestPacketTunnelKernelIntegration(t *testing.T) {
	fixture := os.Getenv("FLCLASH_PACKET_TUNNEL_FIXTURE")
	if fixture == "" {
		t.Skip("requires an explicitly supplied private fixture and isolated Linux network namespace")
	}
	if os.Geteuid() != 0 {
		t.Fatal("the isolated namespace test needs root")
	}
	raw, err := os.ReadFile(fixture)
	if err != nil {
		t.Fatal(err)
	}
	var cfg struct {
		Tunnel packetTunnelConfig `json:"tunnel"`
		Proxy  map[string]any     `json:"proxy"`
	}
	if json.Unmarshal(raw, &cfg) != nil || cfg.Tunnel.validate() != nil || len(cfg.Tunnel.Addresses) != 1 {
		t.Fatal("invalid private integration fixture")
	}
	proxy, err := adapter.ParseProxy(cfg.Proxy)
	if err != nil {
		t.Fatal("could not configure the integration transport")
	}
	t.Cleanup(func() { _ = proxy.Close() })
	namespace := fmt.Sprintf("flclash-packet-%d", os.Getpid())
	run := func(args ...string) string {
		t.Helper()
		output, err := exec.Command(args[0], args[1:]...).CombinedOutput()
		if err != nil {
			t.Fatalf("%s failed: %s", args[0], output)
		}
		return strings.TrimSpace(string(output))
	}
	run("ip", "netns", "add", namespace)
	t.Cleanup(func() { _ = exec.Command("ip", "netns", "del", namespace).Run() })
	dnsDir := filepath.Join("/etc/netns", namespace)
	if err = os.MkdirAll(filepath.Dir(dnsDir), 0755); err != nil {
		t.Fatal(err)
	}
	if err = os.Mkdir(dnsDir, 0755); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(dnsDir) })
	if err = os.WriteFile(filepath.Join(dnsDir, "resolv.conf"), []byte("nameserver "+cfg.Tunnel.DNS[0]+"\n"), 0600); err != nil {
		t.Fatal(err)
	}
	fd, err := packetIntegrationFD(namespace)
	if err != nil {
		t.Fatal(err)
	}
	tun, err := newPacketFileTun(fd, cfg.Tunnel.MTU)
	if err != nil {
		t.Fatal(err)
	}
	run("ip", "-n", namespace, "link", "set", "lo", "up")
	run("ip", "-n", namespace, "address", "add", cfg.Tunnel.Addresses[0], "dev", "wgphone0")
	run("ip", "-n", namespace, "-6", "address", "add", "fdfe:dcba:9876::1/128", "dev", "wgphone0")
	run("ip", "-n", namespace, "link", "set", "wgphone0", "up", "mtu", "1280")
	run("ip", "-n", namespace, "route", "add", "default", "dev", "wgphone0")
	run("ip", "-n", namespace, "-6", "route", "add", "default", "dev", "wgphone0")
	endpoint, _ := netip.ParseAddrPort(cfg.Tunnel.Endpoint)
	transport := packetTunnelDialer{proxyName: cfg.Tunnel.TransportProxy, endpoint: endpoint, lookup: func(string) C.Proxy { return proxy }}
	recorded := &recordingPacketTun{Device: tun, syn: make(chan string, 1)}
	packet, err := newPacketTunnel(recorded, cfg.Tunnel, transport)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(packet.Close)
	deadline := time.Now().Add(25 * time.Second)
	for !packet.status().Handshaken && time.Now().Before(deadline) {
		time.Sleep(100 * time.Millisecond)
	}
	if !packet.status().Handshaken {
		t.Fatal("the full packet tunnel did not handshake")
	}
	t.Logf("kernel tunnel namespace: %s", namespace)
	ip := run("ip", "netns", "exec", namespace, "curl", "-fsS", "--max-time", "25", "https://api.ipify.org")
	if _, err := netip.ParseAddr(ip); err != nil {
		t.Fatal("the kernel tunnel did not return an exit address")
	}
	t.Logf("full packet tunnel exit: %s", ip)
	trace := run("ip", "netns", "exec", namespace, "curl", "-fsS", "--max-time", "25", "--local-port", "55053", "--connect-to", "one.one.one.one:443:1.0.0.1:443", "https://one.one.one.one/cdn-cgi/trace")
	if !strings.Contains(trace, "ip="+ip) {
		t.Fatal("the second destination used a different exit")
	}
	if path := os.Getenv("FLCLASH_PACKET_TUNNEL_REPORT"); path != "" {
		var syn string
		select {
		case syn = <-recorded.syn:
		default:
			t.Fatal("the original kernel TCP SYN was not observed")
		}
		report, _ := json.Marshal(map[string]any{"namespace": namespace, "exit_ip": ip, "status": packet.status(), "kernel_tcp_client": true, "original_syn_hex": syn})
		if err = os.WriteFile(path, report, 0600); err != nil {
			t.Fatal(err)
		}
		if seconds, _ := strconv.Atoi(os.Getenv("FLCLASH_PACKET_TUNNEL_HOLD")); seconds > 0 && seconds <= 300 {
			until := time.Now().Add(time.Duration(seconds) * time.Second)
			for time.Now().Before(until) {
				if _, err := os.Stat(path + ".release"); err == nil {
					break
				}
				time.Sleep(200 * time.Millisecond)
			}
		}
	}
}
