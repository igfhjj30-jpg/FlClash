import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/common/picker.dart';
import 'package:fl_clash/plugins/service.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/packet_tunnel.g.dart';

@Riverpod(keepAlive: true)
Service? packetTunnelService(Ref ref) =>
    ref.watch(safeModeProvider) ? null : service;

@Riverpod(keepAlive: true)
Future<String?> Function() packetTunnelFileReader(Ref ref) => () async {
  final file = await picker.pickerFile();
  if (file == null) return null;
  final bytes = await file.readBytes();
  if (bytes.length > 1024 * 1024) throw const FormatException();
  return utf8.decode(bytes);
};

@riverpod
Future<Map<String, Object?>> packetTunnelStatus(Ref ref) async {
  if (ref.watch(safeModeProvider)) return const {'active': false};
  final service = ref.watch(packetTunnelServiceProvider);
  if (service == null) return const {'active': false};
  try {
    return await service.packetTunnelStatus();
  } finally {
    if (ref.mounted) {
      final timer = Timer(const Duration(seconds: 2), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
    }
  }
}
