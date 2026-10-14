// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../packet_tunnel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PacketTunnelConfig {

 String get privateKey; String get publicKey; String get preSharedKey; String get endpoint; List<String> get addresses; List<String> get dns; int get mtu; int get persistentKeepalive; String get transportProxy;
/// Create a copy of PacketTunnelConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PacketTunnelConfigCopyWith<PacketTunnelConfig> get copyWith => _$PacketTunnelConfigCopyWithImpl<PacketTunnelConfig>(this as PacketTunnelConfig, _$identity);

  /// Serializes this PacketTunnelConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PacketTunnelConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PacketTunnelConfig&&(identical(other.privateKey, _this.privateKey) || other.privateKey == _this.privateKey)&&(identical(other.publicKey, _this.publicKey) || other.publicKey == _this.publicKey)&&(identical(other.preSharedKey, _this.preSharedKey) || other.preSharedKey == _this.preSharedKey)&&(identical(other.endpoint, _this.endpoint) || other.endpoint == _this.endpoint)&&const DeepCollectionEquality().equals(other.addresses, _this.addresses)&&const DeepCollectionEquality().equals(other.dns, _this.dns)&&(identical(other.mtu, _this.mtu) || other.mtu == _this.mtu)&&(identical(other.persistentKeepalive, _this.persistentKeepalive) || other.persistentKeepalive == _this.persistentKeepalive)&&(identical(other.transportProxy, _this.transportProxy) || other.transportProxy == _this.transportProxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PacketTunnelConfig;
  return Object.hash(runtimeType,_this.privateKey,_this.publicKey,_this.preSharedKey,_this.endpoint,const DeepCollectionEquality().hash(_this.addresses),const DeepCollectionEquality().hash(_this.dns),_this.mtu,_this.persistentKeepalive,_this.transportProxy);
}



}

/// @nodoc
abstract mixin class $PacketTunnelConfigCopyWith<$Res>  {
  factory $PacketTunnelConfigCopyWith(PacketTunnelConfig value, $Res Function(PacketTunnelConfig) _then) = _$PacketTunnelConfigCopyWithImpl;
@useResult
$Res call({
 String privateKey, String publicKey, String preSharedKey, String endpoint, List<String> addresses, List<String> dns, int mtu, int persistentKeepalive, String transportProxy
});




}
/// @nodoc
class _$PacketTunnelConfigCopyWithImpl<$Res>
    implements $PacketTunnelConfigCopyWith<$Res> {
  _$PacketTunnelConfigCopyWithImpl(this._self, this._then);

  final PacketTunnelConfig _self;
  final $Res Function(PacketTunnelConfig) _then;

/// Create a copy of PacketTunnelConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? privateKey = null,Object? publicKey = null,Object? preSharedKey = null,Object? endpoint = null,Object? addresses = null,Object? dns = null,Object? mtu = null,Object? persistentKeepalive = null,Object? transportProxy = null,}) {
  return _then(PacketTunnelConfig(
privateKey: null == privateKey ? _self.privateKey : privateKey // ignore: cast_nullable_to_non_nullable
as String,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,preSharedKey: null == preSharedKey ? _self.preSharedKey : preSharedKey // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,addresses: null == addresses ? _self.addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<String>,dns: null == dns ? _self.dns : dns // ignore: cast_nullable_to_non_nullable
as List<String>,mtu: null == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int,persistentKeepalive: null == persistentKeepalive ? _self.persistentKeepalive : persistentKeepalive // ignore: cast_nullable_to_non_nullable
as int,transportProxy: null == transportProxy ? _self.transportProxy : transportProxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PacketTunnelConfig].
extension PacketTunnelConfigPatterns on PacketTunnelConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PacketTunnelConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PacketTunnelConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PacketTunnelConfig value)  $default,){
final _that = this;
switch (_that) {
case _PacketTunnelConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PacketTunnelConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PacketTunnelConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String privateKey,  String publicKey,  String preSharedKey,  String endpoint,  List<String> addresses,  List<String> dns,  int mtu,  int persistentKeepalive,  String transportProxy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PacketTunnelConfig() when $default != null:
return $default(_that.privateKey,_that.publicKey,_that.preSharedKey,_that.endpoint,_that.addresses,_that.dns,_that.mtu,_that.persistentKeepalive,_that.transportProxy);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String privateKey,  String publicKey,  String preSharedKey,  String endpoint,  List<String> addresses,  List<String> dns,  int mtu,  int persistentKeepalive,  String transportProxy)  $default,) {final _that = this;
switch (_that) {
case _PacketTunnelConfig():
return $default(_that.privateKey,_that.publicKey,_that.preSharedKey,_that.endpoint,_that.addresses,_that.dns,_that.mtu,_that.persistentKeepalive,_that.transportProxy);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String privateKey,  String publicKey,  String preSharedKey,  String endpoint,  List<String> addresses,  List<String> dns,  int mtu,  int persistentKeepalive,  String transportProxy)?  $default,) {final _that = this;
switch (_that) {
case _PacketTunnelConfig() when $default != null:
return $default(_that.privateKey,_that.publicKey,_that.preSharedKey,_that.endpoint,_that.addresses,_that.dns,_that.mtu,_that.persistentKeepalive,_that.transportProxy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PacketTunnelConfig extends PacketTunnelConfig {
  const _PacketTunnelConfig({required this.privateKey, required this.publicKey, this.preSharedKey = '', required this.endpoint, required  List<String> addresses, required  List<String> dns, this.mtu = 1280, this.persistentKeepalive = 25, this.transportProxy = ''}): _addresses = addresses,_dns = dns,super._();
  factory _PacketTunnelConfig.fromJson(Map<String, dynamic> json) => _$PacketTunnelConfigFromJson(json);

@override final  String privateKey;
@override final  String publicKey;
@override@JsonKey() final  String preSharedKey;
@override final  String endpoint;
 final  List<String> _addresses;
@override List<String> get addresses {
  if (_addresses is EqualUnmodifiableListView) return _addresses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addresses);
}

 final  List<String> _dns;
@override List<String> get dns {
  if (_dns is EqualUnmodifiableListView) return _dns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dns);
}

@override@JsonKey() final  int mtu;
@override@JsonKey() final  int persistentKeepalive;
@override@JsonKey() final  String transportProxy;

/// Create a copy of PacketTunnelConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PacketTunnelConfigCopyWith<_PacketTunnelConfig> get copyWith => __$PacketTunnelConfigCopyWithImpl<_PacketTunnelConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PacketTunnelConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PacketTunnelConfig&&(identical(other.privateKey, privateKey) || other.privateKey == privateKey)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.preSharedKey, preSharedKey) || other.preSharedKey == preSharedKey)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&const DeepCollectionEquality().equals(other.addresses, _addresses)&&const DeepCollectionEquality().equals(other.dns, _dns)&&(identical(other.mtu, mtu) || other.mtu == mtu)&&(identical(other.persistentKeepalive, persistentKeepalive) || other.persistentKeepalive == persistentKeepalive)&&(identical(other.transportProxy, transportProxy) || other.transportProxy == transportProxy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,privateKey,publicKey,preSharedKey,endpoint,const DeepCollectionEquality().hash(_addresses),const DeepCollectionEquality().hash(_dns),mtu,persistentKeepalive,transportProxy);
}



}

/// @nodoc
abstract mixin class _$PacketTunnelConfigCopyWith<$Res> implements $PacketTunnelConfigCopyWith<$Res> {
  factory _$PacketTunnelConfigCopyWith(_PacketTunnelConfig value, $Res Function(_PacketTunnelConfig) _then) = __$PacketTunnelConfigCopyWithImpl;
@override @useResult
$Res call({
 String privateKey, String publicKey, String preSharedKey, String endpoint, List<String> addresses, List<String> dns, int mtu, int persistentKeepalive, String transportProxy
});




}
/// @nodoc
class __$PacketTunnelConfigCopyWithImpl<$Res>
    implements _$PacketTunnelConfigCopyWith<$Res> {
  __$PacketTunnelConfigCopyWithImpl(this._self, this._then);

  final _PacketTunnelConfig _self;
  final $Res Function(_PacketTunnelConfig) _then;

/// Create a copy of PacketTunnelConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? privateKey = null,Object? publicKey = null,Object? preSharedKey = null,Object? endpoint = null,Object? addresses = null,Object? dns = null,Object? mtu = null,Object? persistentKeepalive = null,Object? transportProxy = null,}) {
  return _then(_PacketTunnelConfig(
privateKey: null == privateKey ? _self.privateKey : privateKey // ignore: cast_nullable_to_non_nullable
as String,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,preSharedKey: null == preSharedKey ? _self.preSharedKey : preSharedKey // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,addresses: null == addresses ? _self._addresses : addresses // ignore: cast_nullable_to_non_nullable
as List<String>,dns: null == dns ? _self._dns : dns // ignore: cast_nullable_to_non_nullable
as List<String>,mtu: null == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int,persistentKeepalive: null == persistentKeepalive ? _self.persistentKeepalive : persistentKeepalive // ignore: cast_nullable_to_non_nullable
as int,transportProxy: null == transportProxy ? _self.transportProxy : transportProxy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
