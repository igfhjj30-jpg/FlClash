// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../packet_tunnel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(packetTunnelService)
final packetTunnelServiceProvider = PacketTunnelServiceProvider._();

final class PacketTunnelServiceProvider
    extends $FunctionalProvider<Service?, Service?, Service?>
    with $Provider<Service?> {
  PacketTunnelServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packetTunnelServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packetTunnelServiceHash();

  @$internal
  @override
  $ProviderElement<Service?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Service? create(Ref ref) {
    return packetTunnelService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Service? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Service?>(value),
    );
  }
}

String _$packetTunnelServiceHash() =>
    r'0e6f8f792cc14b8065c373edae23620c04d4de3f';

@ProviderFor(packetTunnelFileReader)
final packetTunnelFileReaderProvider = PacketTunnelFileReaderProvider._();

final class PacketTunnelFileReaderProvider
    extends
        $FunctionalProvider<
          Future<String?> Function(),
          Future<String?> Function(),
          Future<String?> Function()
        >
    with $Provider<Future<String?> Function()> {
  PacketTunnelFileReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packetTunnelFileReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packetTunnelFileReaderHash();

  @$internal
  @override
  $ProviderElement<Future<String?> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<String?> Function() create(Ref ref) {
    return packetTunnelFileReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<String?> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<String?> Function()>(value),
    );
  }
}

String _$packetTunnelFileReaderHash() =>
    r'8ca7e87b9718bb37688ce62bcb7f074d4612607d';

@ProviderFor(packetTunnelStatus)
final packetTunnelStatusProvider = PacketTunnelStatusProvider._();

final class PacketTunnelStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Object?>>,
          Map<String, Object?>,
          FutureOr<Map<String, Object?>>
        >
    with
        $FutureModifier<Map<String, Object?>>,
        $FutureProvider<Map<String, Object?>> {
  PacketTunnelStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packetTunnelStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packetTunnelStatusHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Object?>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Object?>> create(Ref ref) {
    return packetTunnelStatus(ref);
  }
}

String _$packetTunnelStatusHash() =>
    r'a1049c9e8f9c605919d7d06ce03cbf9b60eac76c';
