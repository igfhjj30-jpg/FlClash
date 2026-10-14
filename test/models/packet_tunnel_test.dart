import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

String key(int value) => base64.encode(List.filled(32, value));

String configuration({String routes = '0.0.0.0/0, ::/0'}) =>
    '''
[Interface]
PrivateKey = ${key(1)}
Address = 10.204.32.2/32
DNS = 1.1.1.1, 9.9.9.9

[Peer]
PublicKey = ${key(2)}
PresharedKey = ${key(3)}
Endpoint = 192.0.2.1:51823
AllowedIPs = $routes
PersistentKeepalive = 25
''';

void main() {
  test(
    'imports a full route and preserves credentials through persistence',
    () {
      final config = PacketTunnelConfig.fromWgQuick(
        configuration(),
        transportProxy: 'test-carrier',
      );
      config.validate();
      expect(config.addresses, ['10.204.32.2/32']);
      expect(config.dns, ['1.1.1.1', '9.9.9.9']);
      expect(config.mtu, 1280);
      final state = VpnProps(fullTunnel: true, packetTunnel: config);
      expect(VpnProps.fromJson(jsonDecode(jsonEncode(state))), state);
      expect(state.toString(), isNot(contains(key(1))));
      expect(state.toString(), isNot(contains(key(3))));
    },
  );

  test('rejects partial routing, scripts, extra peers, and invalid keys', () {
    final invalid = [
      configuration(routes: '0.0.0.0/0'),
      configuration(routes: '0.0.0.0/0, ::/0, 10.0.0.0/8'),
      configuration().replaceFirst('DNS =', 'PostUp ='),
      '${configuration()}\n[Peer]\nPublicKey = ${key(4)}\n',
      configuration().replaceFirst(key(1), 'private-value-that-must-not-leak'),
      configuration().replaceFirst('192.0.2.1:51823', 'hostname.example:51823'),
      configuration().replaceFirst(
        'DNS = 1.1.1.1, 9.9.9.9',
        'DNS = 2606:4700:4700::1111',
      ),
    ];
    for (final source in invalid) {
      expect(
        () => PacketTunnelConfig.fromWgQuick(source),
        throwsA(
          isA<FormatException>().having(
            (error) => error.toString(),
            'redacted error',
            isNot(contains('private-value-that-must-not-leak')),
          ),
        ),
      );
    }
  });

  test('does not consider a profile ready before its carrier is selected', () {
    final config = PacketTunnelConfig.fromWgQuick(configuration());
    expect(config.validate, throwsFormatException);
    expect(
      config.copyWith(transportProxy: 'test-carrier').validate,
      returnsNormally,
    );
  });

  test('old VPN preferences keep the ordinary proxy mode', () {
    final props = VpnProps.fromJson({'enable': true});
    expect(props.fullTunnel, isFalse);
    expect(props.packetTunnel, isNull);
  });
}
