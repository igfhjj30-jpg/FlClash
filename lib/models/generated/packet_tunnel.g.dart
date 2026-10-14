// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../packet_tunnel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PacketTunnelConfig _$PacketTunnelConfigFromJson(Map<String, dynamic> json) =>
    _PacketTunnelConfig(
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
      preSharedKey: json['preSharedKey'] as String? ?? '',
      endpoint: json['endpoint'] as String,
      addresses: (json['addresses'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dns: (json['dns'] as List<dynamic>).map((e) => e as String).toList(),
      mtu: (json['mtu'] as num?)?.toInt() ?? 1280,
      persistentKeepalive: (json['persistentKeepalive'] as num?)?.toInt() ?? 25,
      transportProxy: json['transportProxy'] as String? ?? '',
    );

Map<String, dynamic> _$PacketTunnelConfigToJson(_PacketTunnelConfig instance) =>
    <String, dynamic>{
      'privateKey': instance.privateKey,
      'publicKey': instance.publicKey,
      'preSharedKey': instance.preSharedKey,
      'endpoint': instance.endpoint,
      'addresses': instance.addresses,
      'dns': instance.dns,
      'mtu': instance.mtu,
      'persistentKeepalive': instance.persistentKeepalive,
      'transportProxy': instance.transportProxy,
    };
