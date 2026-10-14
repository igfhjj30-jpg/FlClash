import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/packet_tunnel.freezed.dart';
part 'generated/packet_tunnel.g.dart';

@Freezed(toStringOverride: false)
abstract class PacketTunnelConfig with _$PacketTunnelConfig {
  const PacketTunnelConfig._();

  const factory PacketTunnelConfig({
    required String privateKey,
    required String publicKey,
    @Default('') String preSharedKey,
    required String endpoint,
    required List<String> addresses,
    required List<String> dns,
    @Default(1280) int mtu,
    @Default(25) int persistentKeepalive,
    @Default('') String transportProxy,
  }) = _PacketTunnelConfig;

  factory PacketTunnelConfig.fromJson(Map<String, Object?> json) =>
      _$PacketTunnelConfigFromJson(json);

  factory PacketTunnelConfig.fromWgQuick(
    String source, {
    String transportProxy = '',
  }) {
    final interface = <String, String>{};
    final peer = <String, String>{};
    Map<String, String>? section;
    var peers = 0;
    for (final raw in const LineSplitter().convert(source)) {
      final line = raw.split(RegExp('[#;]')).first.trim();
      if (line.isEmpty) continue;
      if (line == '[Interface]') {
        if (section != null) _invalid();
        section = interface;
        continue;
      }
      if (line == '[Peer]') {
        if (++peers != 1 || section != interface) _invalid();
        section = peer;
        continue;
      }
      final separator = line.indexOf('=');
      if (section == null || separator <= 0) _invalid();
      final name = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      final allowed = section == interface
          ? const {'PrivateKey', 'Address', 'DNS', 'MTU'}
          : const {
              'PublicKey',
              'PresharedKey',
              'Endpoint',
              'AllowedIPs',
              'PersistentKeepalive',
            };
      if (!allowed.contains(name) || value.isEmpty) _invalid();
      if (section.containsKey(name)) {
        if (!const {'Address', 'DNS', 'AllowedIPs'}.contains(name)) _invalid();
        section[name] = '${section[name]},$value';
      } else {
        section[name] = value;
      }
    }
    final allowed = _list(peer['AllowedIPs']).toSet();
    if (peers != 1 ||
        allowed.length != 2 ||
        !allowed.contains('0.0.0.0/0') ||
        !allowed.contains('::/0')) {
      _invalid();
    }
    final config = PacketTunnelConfig(
      privateKey: _key(interface['PrivateKey'] ?? ''),
      publicKey: _key(peer['PublicKey'] ?? ''),
      preSharedKey: peer['PresharedKey'] == null
          ? ''
          : _key(peer['PresharedKey']!),
      endpoint: peer['Endpoint'] ?? '',
      addresses: _list(interface['Address']),
      dns: _list(interface['DNS']),
      mtu: interface['MTU'] == null
          ? 1280
          : int.tryParse(interface['MTU']!) ?? 0,
      persistentKeepalive: peer['PersistentKeepalive'] == null
          ? 25
          : int.tryParse(peer['PersistentKeepalive']!) ?? -1,
      transportProxy: transportProxy,
    );
    config.validate(requireTransport: false);
    return config;
  }

  void validate({bool requireTransport = true}) {
    _key(privateKey);
    _key(publicKey);
    if (preSharedKey.isNotEmpty) _key(preSharedKey);
    final parts = endpoint.split(':');
    if (parts.length != 2 ||
        !_ipv4(parts[0]) ||
        (int.tryParse(parts[1]) ?? 0) < 1 ||
        (int.tryParse(parts[1]) ?? 0) > 65535 ||
        mtu < 1280 ||
        mtu > 1420 ||
        persistentKeepalive < 0 ||
        persistentKeepalive > 65535 ||
        addresses.isEmpty ||
        dns.isEmpty ||
        !dns.every(_ipv4) ||
        (requireTransport && transportProxy.trim().isEmpty)) {
      _invalid();
    }
    for (final address in addresses) {
      final parts = address.split('/');
      if (parts.length != 2 ||
          !_ipv4(parts[0]) ||
          (int.tryParse(parts[1]) ?? -1) < 1 ||
          (int.tryParse(parts[1]) ?? -1) > 32) {
        _invalid();
      }
    }
  }

  @override
  String toString() =>
      'PacketTunnelConfig(endpoint: $endpoint, transportProxy: $transportProxy)';

  static List<String> _list(String? value) =>
      value?.split(',').map((part) => part.trim()).toList() ?? const [];

  static bool _ipv4(String value) =>
      InternetAddress.tryParse(value)?.type == InternetAddressType.IPv4;

  static String _key(String value) {
    try {
      final decoded = base64.decode(value);
      if (decoded.length != 32 || decoded.every((byte) => byte == 0)) {
        _invalid();
      }
      return base64.encode(decoded);
    } on FormatException {
      _invalid();
    }
  }

  static Never _invalid() =>
      throw const FormatException('Invalid complete tunnel configuration');
}
