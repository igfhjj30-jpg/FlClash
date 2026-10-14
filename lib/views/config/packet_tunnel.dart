import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/packet_tunnel.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yaml/yaml.dart';

class PacketTunnelSection extends ConsumerStatefulWidget {
  const PacketTunnelSection({super.key});

  @override
  ConsumerState<PacketTunnelSection> createState() =>
      _PacketTunnelSectionState();
}

class _PacketTunnelSectionState extends ConsumerState<PacketTunnelSection> {
  var _importing = false;

  Future<void> _import({required bool fromProfile}) async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      String source;
      if (fromProfile) {
        final profile = ref.read(currentProfileProvider);
        if (profile == null) {
          throw const FormatException();
        }
        source = await (await profile.file).readAsString();
      } else {
        final imported = await ref.read(packetTunnelFileReaderProvider)();
        if (imported == null) return;
        source = imported;
      }
      if (!mounted) return;
      final current = ref.read(vpnSettingProvider);
      final PacketTunnelConfig config;
      if (RegExp(r'^\s*\[Interface\]', multiLine: true).hasMatch(source)) {
        config = PacketTunnelConfig.fromWgQuick(
          source,
          transportProxy: current.packetTunnel?.transportProxy ?? '',
        );
      } else {
        final document = loadYaml(source);
        if (document is! Map || document['x-flclash-packet-tunnel'] is! Map) {
          throw const FormatException();
        }
        config = PacketTunnelConfig.fromJson(
          Map<String, Object?>.from(document['x-flclash-packet-tunnel'] as Map),
        );
        config.validate(requireTransport: false);
      }
      ref
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(packetTunnel: config));
    } catch (_) {
      if (mounted) {
        context.showNotifier(
          context.appLocalizations.packetTunnelInvalid,
          level: MessageLevel.error,
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final config = ref.watch(
      vpnSettingProvider.select((state) => state.packetTunnel),
    );
    final groups = ref.watch(groupsProvider);
    const excluded = {
      'direct',
      'reject',
      'rejectdrop',
      'compatible',
      'selector',
      'fallback',
      'urltest',
      'loadbalance',
      'relay',
      'pass',
      'passrule',
      'rematch',
      'dns',
    };
    final names =
        groups
            .expand((group) => group.all)
            .where((proxy) => !excluded.contains(proxy.type.toLowerCase()))
            .map((proxy) => proxy.name)
            .toSet()
            .toList()
          ..sort();
    final selected = config?.transportProxy ?? '';
    if (selected.isNotEmpty && !names.contains(selected)) {
      names.insert(0, selected);
    }
    final status = ref.watch(packetTunnelStatusProvider);
    final state = status.when(
      data: (value) => value,
      error: (_, _) => null,
      loading: () => null,
    );
    final statusText = switch (state) {
      {'active': true, 'handshaken': true} => l.packetTunnelConnected,
      {'active': true} => l.packetTunnelWaiting,
      _ => l.packetTunnelStopped,
    };
    return generateSectionV3(
      title: l.packetTunnelTitle,
      items: [
        ConfigToggleItem(
          title: (l) => l.packetTunnelEnable,
          subtitle: (l) => l.packetTunnelDescription,
          selector: vpnSettingProvider.select((state) => state.fullTunnel),
          onChanged: (ref, value) {
            if (value) {
              try {
                if (config == null) throw const FormatException();
                config.validate();
              } catch (_) {
                context.showNotifier(
                  l.packetTunnelConfigureFirst,
                  level: MessageLevel.warning,
                );
                return;
              }
            }
            ref
                .read(vpnSettingProvider.notifier)
                .update((state) => state.copyWith(fullTunnel: value));
          },
        ),
        ListItem(
          title: Text(l.packetTunnelImportProfile),
          subtitle: Text(config?.endpoint ?? l.packetTunnelNotConfigured),
          onTap: _importing ? null : () => _import(fromProfile: true),
        ),
        ListItem(
          title: Text(l.packetTunnelImportFile),
          onTap: _importing ? null : () => _import(fromProfile: false),
          trailing: _importing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (config != null)
          ConfigOptionsItem<String>(
            title: (l) => l.packetTunnelTransport,
            subtitle: selected.isEmpty
                ? (l) => l.packetTunnelChooseTransport
                : null,
            options: names,
            textBuilder: (name) => name,
            selector: vpnSettingProvider.select(
              (state) => state.packetTunnel?.transportProxy ?? '',
            ),
            onChanged: (ref, value) => ref
                .read(vpnSettingProvider.notifier)
                .update(
                  (state) => state.copyWith(
                    packetTunnel: state.packetTunnel?.copyWith(
                      transportProxy: value,
                    ),
                  ),
                ),
          ),
        ListItem(
          title: Text(l.packetTunnelStatus),
          subtitle: Text(
            status.hasError ? l.packetTunnelStatusUnavailable : statusText,
          ),
        ),
        ListItem(
          title: Text(l.packetTunnelProtection),
          subtitle: Text(
            state?['alwaysOn'] == true && state?['lockdown'] == true
                ? l.packetTunnelProtectionEnabled
                : l.packetTunnelProtectionDescription,
          ),
          onTap: () async {
            try {
              await ref.read(packetTunnelServiceProvider)?.openVpnSettings();
            } catch (_) {
              if (context.mounted) {
                context.showNotifier(
                  l.packetTunnelStatusUnavailable,
                  level: MessageLevel.error,
                );
              }
            }
          },
        ),
        ListItem(
          title: Text(l.packetTunnelIpv6),
          subtitle: Text(l.packetTunnelIpv6Description),
        ),
      ],
    );
  }
}
