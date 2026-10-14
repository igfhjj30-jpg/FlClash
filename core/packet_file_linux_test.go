package main

import (
	"bytes"
	"errors"
	"os"
	"testing"
	"time"

	"golang.org/x/sys/unix"
)

func TestPacketFileTunDropsIPv6InBothDirections(t *testing.T) {
	fds, err := unix.Socketpair(unix.AF_UNIX, unix.SOCK_DGRAM|unix.SOCK_NONBLOCK, 0)
	if err != nil {
		t.Fatal(err)
	}
	tun, err := newPacketFileTun(fds[0], 1280)
	if err != nil {
		t.Fatal(err)
	}
	defer tun.Close()
	peer := os.NewFile(uintptr(fds[1]), "packet-test-peer")
	defer peer.Close()
	ipv4 := []byte{0x45, 0, 0, 4}
	ipv6 := []byte{0x60, 0, 0, 4}
	for _, packet := range [][]byte{ipv6, ipv4} {
		if _, err = peer.Write(packet); err != nil {
			t.Fatal(err)
		}
	}
	buffer, sizes := make([]byte, 1280), make([]int, 1)
	if n, err := tun.Read([][]byte{buffer}, sizes, 16); err != nil || n != 1 || !bytes.Equal(buffer[16:16+sizes[0]], ipv4) {
		t.Fatalf("IPv6 reached encryption or IPv4 changed: n=%d err=%v", n, err)
	}
	if _, err = tun.Write([][]byte{ipv6, ipv4}, 0); err != nil {
		t.Fatal(err)
	}
	if err = peer.SetReadDeadline(time.Now().Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	if n, err := peer.Read(buffer); err != nil || !bytes.Equal(buffer[:n], ipv4) {
		t.Fatalf("IPv6 reached the OS or IPv4 changed: n=%d err=%v", n, err)
	}
	if _, err = peer.Read(buffer); !errors.Is(err, os.ErrDeadlineExceeded) {
		t.Fatalf("unexpected second delivered packet: %v", err)
	}
}
