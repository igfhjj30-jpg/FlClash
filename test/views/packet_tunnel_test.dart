import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/providers/packet_tunnel.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/packet_tunnel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  testWidgets(
    'failed import releases progress and cannot enable a missing tunnel',
    (tester) async {
      final read = Completer<String?>();
      final container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(TestProfiles.new),
          packetTunnelFileReaderProvider.overrideWithValue(() => read.future),
          packetTunnelStatusProvider.overrideWith(
            (_) async => const {'active': false},
          ),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(
            child: Scaffold(
              body: SingleChildScrollView(child: PacketTunnelSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(container.read(vpnSettingProvider).fullTunnel, isFalse);
      await tester.tap(find.text('Import WireGuard configuration file'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      read.completeError(const FormatException('private-content'));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('private-content'), findsNothing);
      expect(container.read(vpnSettingProvider).packetTunnel, isNull);
    },
  );

  testWidgets(
    'imports without displaying keys and enables the configured tunnel',
    (tester) async {
      final privateKey = base64.encode(List.filled(32, 1));
      final publicKey = base64.encode(List.filled(32, 2));
      final configuration = jsonEncode({
        'x-flclash-packet-tunnel': {
          'privateKey': privateKey,
          'publicKey': publicKey,
          'endpoint': '192.0.2.1:51823',
          'addresses': ['10.204.32.2/32'],
          'dns': ['1.1.1.1'],
          'transportProxy': 'test-carrier',
        },
      });
      final container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(TestProfiles.new),
          packetTunnelFileReaderProvider.overrideWithValue(
            () async => configuration,
          ),
          packetTunnelStatusProvider.overrideWith(
            (_) async => const {'active': true, 'handshaken': false},
          ),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(
            child: Scaffold(
              body: SingleChildScrollView(child: PacketTunnelSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('VPN active, waiting for the WireGuard peer'),
        findsOneWidget,
      );
      await tester.tap(find.text('Import WireGuard configuration file'));
      await tester.pumpAndSettle();
      expect(find.text('192.0.2.1:51823'), findsOneWidget);
      expect(find.textContaining(privateKey), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(container.read(vpnSettingProvider).fullTunnel, isTrue);
      expect(
        container.read(vpnSettingProvider).packetTunnel?.transportProxy,
        'test-carrier',
      );
    },
  );
}
