// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StateChangedEvent {

@PlayerStateConverter() PlayerState get state;
/// Create a copy of StateChangedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateChangedEventCopyWith<StateChangedEvent> get copyWith => _$StateChangedEventCopyWithImpl<StateChangedEvent>(this as StateChangedEvent, _$identity);

  /// Serializes this StateChangedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateChangedEvent&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state);

@override
String toString() {
  return 'StateChangedEvent(state: $state)';
}


}

/// @nodoc
abstract mixin class $StateChangedEventCopyWith<$Res>  {
  factory $StateChangedEventCopyWith(StateChangedEvent value, $Res Function(StateChangedEvent) _then) = _$StateChangedEventCopyWithImpl;
@useResult
$Res call({
@PlayerStateConverter() PlayerState state
});




}
/// @nodoc
class _$StateChangedEventCopyWithImpl<$Res>
    implements $StateChangedEventCopyWith<$Res> {
  _$StateChangedEventCopyWithImpl(this._self, this._then);

  final StateChangedEvent _self;
  final $Res Function(StateChangedEvent) _then;

/// Create a copy of StateChangedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PlayerState,
  ));
}

}


/// Adds pattern-matching-related methods to [StateChangedEvent].
extension StateChangedEventPatterns on StateChangedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateChangedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateChangedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateChangedEvent value)  $default,){
final _that = this;
switch (_that) {
case _StateChangedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateChangedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _StateChangedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PlayerStateConverter()  PlayerState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateChangedEvent() when $default != null:
return $default(_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PlayerStateConverter()  PlayerState state)  $default,) {final _that = this;
switch (_that) {
case _StateChangedEvent():
return $default(_that.state);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PlayerStateConverter()  PlayerState state)?  $default,) {final _that = this;
switch (_that) {
case _StateChangedEvent() when $default != null:
return $default(_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateChangedEvent implements StateChangedEvent {
  const _StateChangedEvent({@PlayerStateConverter() required this.state});
  factory _StateChangedEvent.fromJson(Map<String, dynamic> json) => _$StateChangedEventFromJson(json);

@override@PlayerStateConverter() final  PlayerState state;

/// Create a copy of StateChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateChangedEventCopyWith<_StateChangedEvent> get copyWith => __$StateChangedEventCopyWithImpl<_StateChangedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateChangedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateChangedEvent&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state);

@override
String toString() {
  return 'StateChangedEvent(state: $state)';
}


}

/// @nodoc
abstract mixin class _$StateChangedEventCopyWith<$Res> implements $StateChangedEventCopyWith<$Res> {
  factory _$StateChangedEventCopyWith(_StateChangedEvent value, $Res Function(_StateChangedEvent) _then) = __$StateChangedEventCopyWithImpl;
@override @useResult
$Res call({
@PlayerStateConverter() PlayerState state
});




}
/// @nodoc
class __$StateChangedEventCopyWithImpl<$Res>
    implements _$StateChangedEventCopyWith<$Res> {
  __$StateChangedEventCopyWithImpl(this._self, this._then);

  final _StateChangedEvent _self;
  final $Res Function(_StateChangedEvent) _then;

/// Create a copy of StateChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,}) {
  return _then(_StateChangedEvent(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PlayerState,
  ));
}


}


/// @nodoc
mixin _$RequestMoreTracksEvent {



  /// Serializes this RequestMoreTracksEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestMoreTracksEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RequestMoreTracksEvent()';
}


}

/// @nodoc
class $RequestMoreTracksEventCopyWith<$Res>  {
$RequestMoreTracksEventCopyWith(RequestMoreTracksEvent _, $Res Function(RequestMoreTracksEvent) __);
}


/// Adds pattern-matching-related methods to [RequestMoreTracksEvent].
extension RequestMoreTracksEventPatterns on RequestMoreTracksEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestMoreTracksEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestMoreTracksEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestMoreTracksEvent value)  $default,){
final _that = this;
switch (_that) {
case _RequestMoreTracksEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestMoreTracksEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RequestMoreTracksEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function()?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestMoreTracksEvent() when $default != null:
return $default();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function()  $default,) {final _that = this;
switch (_that) {
case _RequestMoreTracksEvent():
return $default();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function()?  $default,) {final _that = this;
switch (_that) {
case _RequestMoreTracksEvent() when $default != null:
return $default();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RequestMoreTracksEvent implements RequestMoreTracksEvent {
  const _RequestMoreTracksEvent();
  factory _RequestMoreTracksEvent.fromJson(Map<String, dynamic> json) => _$RequestMoreTracksEventFromJson(json);




@override
Map<String, dynamic> toJson() {
  return _$RequestMoreTracksEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestMoreTracksEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RequestMoreTracksEvent()';
}


}





/// @nodoc
mixin _$TracksAddedEvent {

 List<Track> get tracks;
/// Create a copy of TracksAddedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TracksAddedEventCopyWith<TracksAddedEvent> get copyWith => _$TracksAddedEventCopyWithImpl<TracksAddedEvent>(this as TracksAddedEvent, _$identity);

  /// Serializes this TracksAddedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TracksAddedEvent&&const DeepCollectionEquality().equals(other.tracks, tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tracks));

@override
String toString() {
  return 'TracksAddedEvent(tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class $TracksAddedEventCopyWith<$Res>  {
  factory $TracksAddedEventCopyWith(TracksAddedEvent value, $Res Function(TracksAddedEvent) _then) = _$TracksAddedEventCopyWithImpl;
@useResult
$Res call({
 List<Track> tracks
});




}
/// @nodoc
class _$TracksAddedEventCopyWithImpl<$Res>
    implements $TracksAddedEventCopyWith<$Res> {
  _$TracksAddedEventCopyWithImpl(this._self, this._then);

  final TracksAddedEvent _self;
  final $Res Function(TracksAddedEvent) _then;

/// Create a copy of TracksAddedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tracks = null,}) {
  return _then(_self.copyWith(
tracks: null == tracks ? _self.tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}

}


/// Adds pattern-matching-related methods to [TracksAddedEvent].
extension TracksAddedEventPatterns on TracksAddedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TracksAddedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TracksAddedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TracksAddedEvent value)  $default,){
final _that = this;
switch (_that) {
case _TracksAddedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TracksAddedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _TracksAddedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Track> tracks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TracksAddedEvent() when $default != null:
return $default(_that.tracks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Track> tracks)  $default,) {final _that = this;
switch (_that) {
case _TracksAddedEvent():
return $default(_that.tracks);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Track> tracks)?  $default,) {final _that = this;
switch (_that) {
case _TracksAddedEvent() when $default != null:
return $default(_that.tracks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TracksAddedEvent implements TracksAddedEvent {
  const _TracksAddedEvent({required final  List<Track> tracks}): _tracks = tracks;
  factory _TracksAddedEvent.fromJson(Map<String, dynamic> json) => _$TracksAddedEventFromJson(json);

 final  List<Track> _tracks;
@override List<Track> get tracks {
  if (_tracks is EqualUnmodifiableListView) return _tracks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tracks);
}


/// Create a copy of TracksAddedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TracksAddedEventCopyWith<_TracksAddedEvent> get copyWith => __$TracksAddedEventCopyWithImpl<_TracksAddedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TracksAddedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TracksAddedEvent&&const DeepCollectionEquality().equals(other._tracks, _tracks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tracks));

@override
String toString() {
  return 'TracksAddedEvent(tracks: $tracks)';
}


}

/// @nodoc
abstract mixin class _$TracksAddedEventCopyWith<$Res> implements $TracksAddedEventCopyWith<$Res> {
  factory _$TracksAddedEventCopyWith(_TracksAddedEvent value, $Res Function(_TracksAddedEvent) _then) = __$TracksAddedEventCopyWithImpl;
@override @useResult
$Res call({
 List<Track> tracks
});




}
/// @nodoc
class __$TracksAddedEventCopyWithImpl<$Res>
    implements _$TracksAddedEventCopyWith<$Res> {
  __$TracksAddedEventCopyWithImpl(this._self, this._then);

  final _TracksAddedEvent _self;
  final $Res Function(_TracksAddedEvent) _then;

/// Create a copy of TracksAddedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tracks = null,}) {
  return _then(_TracksAddedEvent(
tracks: null == tracks ? _self._tracks : tracks // ignore: cast_nullable_to_non_nullable
as List<Track>,
  ));
}


}


/// @nodoc
mixin _$TracksRemovedEvent {

 List<int> get indices;
/// Create a copy of TracksRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TracksRemovedEventCopyWith<TracksRemovedEvent> get copyWith => _$TracksRemovedEventCopyWithImpl<TracksRemovedEvent>(this as TracksRemovedEvent, _$identity);

  /// Serializes this TracksRemovedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TracksRemovedEvent&&const DeepCollectionEquality().equals(other.indices, indices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(indices));

@override
String toString() {
  return 'TracksRemovedEvent(indices: $indices)';
}


}

/// @nodoc
abstract mixin class $TracksRemovedEventCopyWith<$Res>  {
  factory $TracksRemovedEventCopyWith(TracksRemovedEvent value, $Res Function(TracksRemovedEvent) _then) = _$TracksRemovedEventCopyWithImpl;
@useResult
$Res call({
 List<int> indices
});




}
/// @nodoc
class _$TracksRemovedEventCopyWithImpl<$Res>
    implements $TracksRemovedEventCopyWith<$Res> {
  _$TracksRemovedEventCopyWithImpl(this._self, this._then);

  final TracksRemovedEvent _self;
  final $Res Function(TracksRemovedEvent) _then;

/// Create a copy of TracksRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? indices = null,}) {
  return _then(_self.copyWith(
indices: null == indices ? _self.indices : indices // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [TracksRemovedEvent].
extension TracksRemovedEventPatterns on TracksRemovedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TracksRemovedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TracksRemovedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TracksRemovedEvent value)  $default,){
final _that = this;
switch (_that) {
case _TracksRemovedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TracksRemovedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _TracksRemovedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> indices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TracksRemovedEvent() when $default != null:
return $default(_that.indices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> indices)  $default,) {final _that = this;
switch (_that) {
case _TracksRemovedEvent():
return $default(_that.indices);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> indices)?  $default,) {final _that = this;
switch (_that) {
case _TracksRemovedEvent() when $default != null:
return $default(_that.indices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TracksRemovedEvent implements TracksRemovedEvent {
  const _TracksRemovedEvent({required final  List<int> indices}): _indices = indices;
  factory _TracksRemovedEvent.fromJson(Map<String, dynamic> json) => _$TracksRemovedEventFromJson(json);

 final  List<int> _indices;
@override List<int> get indices {
  if (_indices is EqualUnmodifiableListView) return _indices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_indices);
}


/// Create a copy of TracksRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TracksRemovedEventCopyWith<_TracksRemovedEvent> get copyWith => __$TracksRemovedEventCopyWithImpl<_TracksRemovedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TracksRemovedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TracksRemovedEvent&&const DeepCollectionEquality().equals(other._indices, _indices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_indices));

@override
String toString() {
  return 'TracksRemovedEvent(indices: $indices)';
}


}

/// @nodoc
abstract mixin class _$TracksRemovedEventCopyWith<$Res> implements $TracksRemovedEventCopyWith<$Res> {
  factory _$TracksRemovedEventCopyWith(_TracksRemovedEvent value, $Res Function(_TracksRemovedEvent) _then) = __$TracksRemovedEventCopyWithImpl;
@override @useResult
$Res call({
 List<int> indices
});




}
/// @nodoc
class __$TracksRemovedEventCopyWithImpl<$Res>
    implements _$TracksRemovedEventCopyWith<$Res> {
  __$TracksRemovedEventCopyWithImpl(this._self, this._then);

  final _TracksRemovedEvent _self;
  final $Res Function(_TracksRemovedEvent) _then;

/// Create a copy of TracksRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? indices = null,}) {
  return _then(_TracksRemovedEvent(
indices: null == indices ? _self._indices : indices // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}


/// @nodoc
mixin _$NetworkErrorEvent {

 String get message;
/// Create a copy of NetworkErrorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkErrorEventCopyWith<NetworkErrorEvent> get copyWith => _$NetworkErrorEventCopyWithImpl<NetworkErrorEvent>(this as NetworkErrorEvent, _$identity);

  /// Serializes this NetworkErrorEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkErrorEvent&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NetworkErrorEvent(message: $message)';
}


}

/// @nodoc
abstract mixin class $NetworkErrorEventCopyWith<$Res>  {
  factory $NetworkErrorEventCopyWith(NetworkErrorEvent value, $Res Function(NetworkErrorEvent) _then) = _$NetworkErrorEventCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NetworkErrorEventCopyWithImpl<$Res>
    implements $NetworkErrorEventCopyWith<$Res> {
  _$NetworkErrorEventCopyWithImpl(this._self, this._then);

  final NetworkErrorEvent _self;
  final $Res Function(NetworkErrorEvent) _then;

/// Create a copy of NetworkErrorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NetworkErrorEvent].
extension NetworkErrorEventPatterns on NetworkErrorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetworkErrorEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetworkErrorEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetworkErrorEvent value)  $default,){
final _that = this;
switch (_that) {
case _NetworkErrorEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetworkErrorEvent value)?  $default,){
final _that = this;
switch (_that) {
case _NetworkErrorEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetworkErrorEvent() when $default != null:
return $default(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message)  $default,) {final _that = this;
switch (_that) {
case _NetworkErrorEvent():
return $default(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message)?  $default,) {final _that = this;
switch (_that) {
case _NetworkErrorEvent() when $default != null:
return $default(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetworkErrorEvent implements NetworkErrorEvent {
  const _NetworkErrorEvent({required this.message});
  factory _NetworkErrorEvent.fromJson(Map<String, dynamic> json) => _$NetworkErrorEventFromJson(json);

@override final  String message;

/// Create a copy of NetworkErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetworkErrorEventCopyWith<_NetworkErrorEvent> get copyWith => __$NetworkErrorEventCopyWithImpl<_NetworkErrorEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetworkErrorEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetworkErrorEvent&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'NetworkErrorEvent(message: $message)';
}


}

/// @nodoc
abstract mixin class _$NetworkErrorEventCopyWith<$Res> implements $NetworkErrorEventCopyWith<$Res> {
  factory _$NetworkErrorEventCopyWith(_NetworkErrorEvent value, $Res Function(_NetworkErrorEvent) _then) = __$NetworkErrorEventCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class __$NetworkErrorEventCopyWithImpl<$Res>
    implements _$NetworkErrorEventCopyWith<$Res> {
  __$NetworkErrorEventCopyWithImpl(this._self, this._then);

  final _NetworkErrorEvent _self;
  final $Res Function(_NetworkErrorEvent) _then;

/// Create a copy of NetworkErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_NetworkErrorEvent(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FavoriteAddedEvent {

@EntityIdConverter() EntityId get id;
/// Create a copy of FavoriteAddedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteAddedEventCopyWith<FavoriteAddedEvent> get copyWith => _$FavoriteAddedEventCopyWithImpl<FavoriteAddedEvent>(this as FavoriteAddedEvent, _$identity);

  /// Serializes this FavoriteAddedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteAddedEvent&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FavoriteAddedEvent(id: $id)';
}


}

/// @nodoc
abstract mixin class $FavoriteAddedEventCopyWith<$Res>  {
  factory $FavoriteAddedEventCopyWith(FavoriteAddedEvent value, $Res Function(FavoriteAddedEvent) _then) = _$FavoriteAddedEventCopyWithImpl;
@useResult
$Res call({
@EntityIdConverter() EntityId id
});




}
/// @nodoc
class _$FavoriteAddedEventCopyWithImpl<$Res>
    implements $FavoriteAddedEventCopyWith<$Res> {
  _$FavoriteAddedEventCopyWithImpl(this._self, this._then);

  final FavoriteAddedEvent _self;
  final $Res Function(FavoriteAddedEvent) _then;

/// Create a copy of FavoriteAddedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EntityId,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteAddedEvent].
extension FavoriteAddedEventPatterns on FavoriteAddedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteAddedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteAddedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteAddedEvent value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteAddedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteAddedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteAddedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@EntityIdConverter()  EntityId id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteAddedEvent() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@EntityIdConverter()  EntityId id)  $default,) {final _that = this;
switch (_that) {
case _FavoriteAddedEvent():
return $default(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@EntityIdConverter()  EntityId id)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteAddedEvent() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoriteAddedEvent implements FavoriteAddedEvent {
  const _FavoriteAddedEvent({@EntityIdConverter() required this.id});
  factory _FavoriteAddedEvent.fromJson(Map<String, dynamic> json) => _$FavoriteAddedEventFromJson(json);

@override@EntityIdConverter() final  EntityId id;

/// Create a copy of FavoriteAddedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteAddedEventCopyWith<_FavoriteAddedEvent> get copyWith => __$FavoriteAddedEventCopyWithImpl<_FavoriteAddedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoriteAddedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteAddedEvent&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FavoriteAddedEvent(id: $id)';
}


}

/// @nodoc
abstract mixin class _$FavoriteAddedEventCopyWith<$Res> implements $FavoriteAddedEventCopyWith<$Res> {
  factory _$FavoriteAddedEventCopyWith(_FavoriteAddedEvent value, $Res Function(_FavoriteAddedEvent) _then) = __$FavoriteAddedEventCopyWithImpl;
@override @useResult
$Res call({
@EntityIdConverter() EntityId id
});




}
/// @nodoc
class __$FavoriteAddedEventCopyWithImpl<$Res>
    implements _$FavoriteAddedEventCopyWith<$Res> {
  __$FavoriteAddedEventCopyWithImpl(this._self, this._then);

  final _FavoriteAddedEvent _self;
  final $Res Function(_FavoriteAddedEvent) _then;

/// Create a copy of FavoriteAddedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_FavoriteAddedEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EntityId,
  ));
}


}


/// @nodoc
mixin _$FavoriteRemovedEvent {

@EntityIdConverter() EntityId get id;
/// Create a copy of FavoriteRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteRemovedEventCopyWith<FavoriteRemovedEvent> get copyWith => _$FavoriteRemovedEventCopyWithImpl<FavoriteRemovedEvent>(this as FavoriteRemovedEvent, _$identity);

  /// Serializes this FavoriteRemovedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteRemovedEvent&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FavoriteRemovedEvent(id: $id)';
}


}

/// @nodoc
abstract mixin class $FavoriteRemovedEventCopyWith<$Res>  {
  factory $FavoriteRemovedEventCopyWith(FavoriteRemovedEvent value, $Res Function(FavoriteRemovedEvent) _then) = _$FavoriteRemovedEventCopyWithImpl;
@useResult
$Res call({
@EntityIdConverter() EntityId id
});




}
/// @nodoc
class _$FavoriteRemovedEventCopyWithImpl<$Res>
    implements $FavoriteRemovedEventCopyWith<$Res> {
  _$FavoriteRemovedEventCopyWithImpl(this._self, this._then);

  final FavoriteRemovedEvent _self;
  final $Res Function(FavoriteRemovedEvent) _then;

/// Create a copy of FavoriteRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EntityId,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteRemovedEvent].
extension FavoriteRemovedEventPatterns on FavoriteRemovedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteRemovedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteRemovedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteRemovedEvent value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteRemovedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteRemovedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteRemovedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@EntityIdConverter()  EntityId id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteRemovedEvent() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@EntityIdConverter()  EntityId id)  $default,) {final _that = this;
switch (_that) {
case _FavoriteRemovedEvent():
return $default(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@EntityIdConverter()  EntityId id)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteRemovedEvent() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoriteRemovedEvent implements FavoriteRemovedEvent {
  const _FavoriteRemovedEvent({@EntityIdConverter() required this.id});
  factory _FavoriteRemovedEvent.fromJson(Map<String, dynamic> json) => _$FavoriteRemovedEventFromJson(json);

@override@EntityIdConverter() final  EntityId id;

/// Create a copy of FavoriteRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteRemovedEventCopyWith<_FavoriteRemovedEvent> get copyWith => __$FavoriteRemovedEventCopyWithImpl<_FavoriteRemovedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoriteRemovedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteRemovedEvent&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FavoriteRemovedEvent(id: $id)';
}


}

/// @nodoc
abstract mixin class _$FavoriteRemovedEventCopyWith<$Res> implements $FavoriteRemovedEventCopyWith<$Res> {
  factory _$FavoriteRemovedEventCopyWith(_FavoriteRemovedEvent value, $Res Function(_FavoriteRemovedEvent) _then) = __$FavoriteRemovedEventCopyWithImpl;
@override @useResult
$Res call({
@EntityIdConverter() EntityId id
});




}
/// @nodoc
class __$FavoriteRemovedEventCopyWithImpl<$Res>
    implements _$FavoriteRemovedEventCopyWith<$Res> {
  __$FavoriteRemovedEventCopyWithImpl(this._self, this._then);

  final _FavoriteRemovedEvent _self;
  final $Res Function(_FavoriteRemovedEvent) _then;

/// Create a copy of FavoriteRemovedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_FavoriteRemovedEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as EntityId,
  ));
}


}


/// @nodoc
mixin _$VolumeChangedEvent {

 int get volume;
/// Create a copy of VolumeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VolumeChangedEventCopyWith<VolumeChangedEvent> get copyWith => _$VolumeChangedEventCopyWithImpl<VolumeChangedEvent>(this as VolumeChangedEvent, _$identity);

  /// Serializes this VolumeChangedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VolumeChangedEvent&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'VolumeChangedEvent(volume: $volume)';
}


}

/// @nodoc
abstract mixin class $VolumeChangedEventCopyWith<$Res>  {
  factory $VolumeChangedEventCopyWith(VolumeChangedEvent value, $Res Function(VolumeChangedEvent) _then) = _$VolumeChangedEventCopyWithImpl;
@useResult
$Res call({
 int volume
});




}
/// @nodoc
class _$VolumeChangedEventCopyWithImpl<$Res>
    implements $VolumeChangedEventCopyWith<$Res> {
  _$VolumeChangedEventCopyWithImpl(this._self, this._then);

  final VolumeChangedEvent _self;
  final $Res Function(VolumeChangedEvent) _then;

/// Create a copy of VolumeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volume = null,}) {
  return _then(_self.copyWith(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VolumeChangedEvent].
extension VolumeChangedEventPatterns on VolumeChangedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VolumeChangedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VolumeChangedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VolumeChangedEvent value)  $default,){
final _that = this;
switch (_that) {
case _VolumeChangedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VolumeChangedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _VolumeChangedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int volume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VolumeChangedEvent() when $default != null:
return $default(_that.volume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int volume)  $default,) {final _that = this;
switch (_that) {
case _VolumeChangedEvent():
return $default(_that.volume);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int volume)?  $default,) {final _that = this;
switch (_that) {
case _VolumeChangedEvent() when $default != null:
return $default(_that.volume);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VolumeChangedEvent implements VolumeChangedEvent {
  const _VolumeChangedEvent({required this.volume});
  factory _VolumeChangedEvent.fromJson(Map<String, dynamic> json) => _$VolumeChangedEventFromJson(json);

@override final  int volume;

/// Create a copy of VolumeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VolumeChangedEventCopyWith<_VolumeChangedEvent> get copyWith => __$VolumeChangedEventCopyWithImpl<_VolumeChangedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VolumeChangedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VolumeChangedEvent&&(identical(other.volume, volume) || other.volume == volume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,volume);

@override
String toString() {
  return 'VolumeChangedEvent(volume: $volume)';
}


}

/// @nodoc
abstract mixin class _$VolumeChangedEventCopyWith<$Res> implements $VolumeChangedEventCopyWith<$Res> {
  factory _$VolumeChangedEventCopyWith(_VolumeChangedEvent value, $Res Function(_VolumeChangedEvent) _then) = __$VolumeChangedEventCopyWithImpl;
@override @useResult
$Res call({
 int volume
});




}
/// @nodoc
class __$VolumeChangedEventCopyWithImpl<$Res>
    implements _$VolumeChangedEventCopyWith<$Res> {
  __$VolumeChangedEventCopyWithImpl(this._self, this._then);

  final _VolumeChangedEvent _self;
  final $Res Function(_VolumeChangedEvent) _then;

/// Create a copy of VolumeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volume = null,}) {
  return _then(_VolumeChangedEvent(
volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StateReplayEvent {

@PlayerStateConverter() PlayerState get state; TrackList get trackList; PlaybackMode get playbackMode;
/// Create a copy of StateReplayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateReplayEventCopyWith<StateReplayEvent> get copyWith => _$StateReplayEventCopyWithImpl<StateReplayEvent>(this as StateReplayEvent, _$identity);

  /// Serializes this StateReplayEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateReplayEvent&&(identical(other.state, state) || other.state == state)&&(identical(other.trackList, trackList) || other.trackList == trackList)&&(identical(other.playbackMode, playbackMode) || other.playbackMode == playbackMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,trackList,playbackMode);

@override
String toString() {
  return 'StateReplayEvent(state: $state, trackList: $trackList, playbackMode: $playbackMode)';
}


}

/// @nodoc
abstract mixin class $StateReplayEventCopyWith<$Res>  {
  factory $StateReplayEventCopyWith(StateReplayEvent value, $Res Function(StateReplayEvent) _then) = _$StateReplayEventCopyWithImpl;
@useResult
$Res call({
@PlayerStateConverter() PlayerState state, TrackList trackList, PlaybackMode playbackMode
});




}
/// @nodoc
class _$StateReplayEventCopyWithImpl<$Res>
    implements $StateReplayEventCopyWith<$Res> {
  _$StateReplayEventCopyWithImpl(this._self, this._then);

  final StateReplayEvent _self;
  final $Res Function(StateReplayEvent) _then;

/// Create a copy of StateReplayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? trackList = null,Object? playbackMode = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PlayerState,trackList: null == trackList ? _self.trackList : trackList // ignore: cast_nullable_to_non_nullable
as TrackList,playbackMode: null == playbackMode ? _self.playbackMode : playbackMode // ignore: cast_nullable_to_non_nullable
as PlaybackMode,
  ));
}

}


/// Adds pattern-matching-related methods to [StateReplayEvent].
extension StateReplayEventPatterns on StateReplayEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateReplayEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateReplayEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateReplayEvent value)  $default,){
final _that = this;
switch (_that) {
case _StateReplayEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateReplayEvent value)?  $default,){
final _that = this;
switch (_that) {
case _StateReplayEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@PlayerStateConverter()  PlayerState state,  TrackList trackList,  PlaybackMode playbackMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateReplayEvent() when $default != null:
return $default(_that.state,_that.trackList,_that.playbackMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@PlayerStateConverter()  PlayerState state,  TrackList trackList,  PlaybackMode playbackMode)  $default,) {final _that = this;
switch (_that) {
case _StateReplayEvent():
return $default(_that.state,_that.trackList,_that.playbackMode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@PlayerStateConverter()  PlayerState state,  TrackList trackList,  PlaybackMode playbackMode)?  $default,) {final _that = this;
switch (_that) {
case _StateReplayEvent() when $default != null:
return $default(_that.state,_that.trackList,_that.playbackMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateReplayEvent implements StateReplayEvent {
  const _StateReplayEvent({@PlayerStateConverter() required this.state, required this.trackList, required this.playbackMode});
  factory _StateReplayEvent.fromJson(Map<String, dynamic> json) => _$StateReplayEventFromJson(json);

@override@PlayerStateConverter() final  PlayerState state;
@override final  TrackList trackList;
@override final  PlaybackMode playbackMode;

/// Create a copy of StateReplayEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateReplayEventCopyWith<_StateReplayEvent> get copyWith => __$StateReplayEventCopyWithImpl<_StateReplayEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateReplayEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateReplayEvent&&(identical(other.state, state) || other.state == state)&&(identical(other.trackList, trackList) || other.trackList == trackList)&&(identical(other.playbackMode, playbackMode) || other.playbackMode == playbackMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,trackList,playbackMode);

@override
String toString() {
  return 'StateReplayEvent(state: $state, trackList: $trackList, playbackMode: $playbackMode)';
}


}

/// @nodoc
abstract mixin class _$StateReplayEventCopyWith<$Res> implements $StateReplayEventCopyWith<$Res> {
  factory _$StateReplayEventCopyWith(_StateReplayEvent value, $Res Function(_StateReplayEvent) _then) = __$StateReplayEventCopyWithImpl;
@override @useResult
$Res call({
@PlayerStateConverter() PlayerState state, TrackList trackList, PlaybackMode playbackMode
});




}
/// @nodoc
class __$StateReplayEventCopyWithImpl<$Res>
    implements _$StateReplayEventCopyWith<$Res> {
  __$StateReplayEventCopyWithImpl(this._self, this._then);

  final _StateReplayEvent _self;
  final $Res Function(_StateReplayEvent) _then;

/// Create a copy of StateReplayEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? trackList = null,Object? playbackMode = null,}) {
  return _then(_StateReplayEvent(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as PlayerState,trackList: null == trackList ? _self.trackList : trackList // ignore: cast_nullable_to_non_nullable
as TrackList,playbackMode: null == playbackMode ? _self.playbackMode : playbackMode // ignore: cast_nullable_to_non_nullable
as PlaybackMode,
  ));
}


}


/// @nodoc
mixin _$PlaybackModeChangedEvent {

 PlaybackMode get mode;
/// Create a copy of PlaybackModeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaybackModeChangedEventCopyWith<PlaybackModeChangedEvent> get copyWith => _$PlaybackModeChangedEventCopyWithImpl<PlaybackModeChangedEvent>(this as PlaybackModeChangedEvent, _$identity);

  /// Serializes this PlaybackModeChangedEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaybackModeChangedEvent&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'PlaybackModeChangedEvent(mode: $mode)';
}


}

/// @nodoc
abstract mixin class $PlaybackModeChangedEventCopyWith<$Res>  {
  factory $PlaybackModeChangedEventCopyWith(PlaybackModeChangedEvent value, $Res Function(PlaybackModeChangedEvent) _then) = _$PlaybackModeChangedEventCopyWithImpl;
@useResult
$Res call({
 PlaybackMode mode
});




}
/// @nodoc
class _$PlaybackModeChangedEventCopyWithImpl<$Res>
    implements $PlaybackModeChangedEventCopyWith<$Res> {
  _$PlaybackModeChangedEventCopyWithImpl(this._self, this._then);

  final PlaybackModeChangedEvent _self;
  final $Res Function(PlaybackModeChangedEvent) _then;

/// Create a copy of PlaybackModeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as PlaybackMode,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaybackModeChangedEvent].
extension PlaybackModeChangedEventPatterns on PlaybackModeChangedEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaybackModeChangedEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaybackModeChangedEvent value)  $default,){
final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaybackModeChangedEvent value)?  $default,){
final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlaybackMode mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent() when $default != null:
return $default(_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlaybackMode mode)  $default,) {final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent():
return $default(_that.mode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlaybackMode mode)?  $default,) {final _that = this;
switch (_that) {
case _PlaybackModeChangedEvent() when $default != null:
return $default(_that.mode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaybackModeChangedEvent implements PlaybackModeChangedEvent {
  const _PlaybackModeChangedEvent({required this.mode});
  factory _PlaybackModeChangedEvent.fromJson(Map<String, dynamic> json) => _$PlaybackModeChangedEventFromJson(json);

@override final  PlaybackMode mode;

/// Create a copy of PlaybackModeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaybackModeChangedEventCopyWith<_PlaybackModeChangedEvent> get copyWith => __$PlaybackModeChangedEventCopyWithImpl<_PlaybackModeChangedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaybackModeChangedEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaybackModeChangedEvent&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mode);

@override
String toString() {
  return 'PlaybackModeChangedEvent(mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$PlaybackModeChangedEventCopyWith<$Res> implements $PlaybackModeChangedEventCopyWith<$Res> {
  factory _$PlaybackModeChangedEventCopyWith(_PlaybackModeChangedEvent value, $Res Function(_PlaybackModeChangedEvent) _then) = __$PlaybackModeChangedEventCopyWithImpl;
@override @useResult
$Res call({
 PlaybackMode mode
});




}
/// @nodoc
class __$PlaybackModeChangedEventCopyWithImpl<$Res>
    implements _$PlaybackModeChangedEventCopyWith<$Res> {
  __$PlaybackModeChangedEventCopyWithImpl(this._self, this._then);

  final _PlaybackModeChangedEvent _self;
  final $Res Function(_PlaybackModeChangedEvent) _then;

/// Create a copy of PlaybackModeChangedEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,}) {
  return _then(_PlaybackModeChangedEvent(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as PlaybackMode,
  ));
}


}

/// @nodoc
mixin _$WireEvent {

 Object get payload;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEvent&&const DeepCollectionEquality().equals(other.payload, payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'WireEvent(payload: $payload)';
}


}

/// @nodoc
class $WireEventCopyWith<$Res>  {
$WireEventCopyWith(WireEvent _, $Res Function(WireEvent) __);
}


/// Adds pattern-matching-related methods to [WireEvent].
extension WireEventPatterns on WireEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WireEventStateChanged value)?  stateChanged,TResult Function( WireEventRequestMoreTracks value)?  requestMoreTracks,TResult Function( WireEventTracksAdded value)?  tracksAdded,TResult Function( WireEventTracksRemoved value)?  tracksRemoved,TResult Function( WireEventNetworkError value)?  networkError,TResult Function( WireEventFavoriteAdded value)?  favoriteAdded,TResult Function( WireEventFavoriteRemoved value)?  favoriteRemoved,TResult Function( WireEventVolumeChanged value)?  volumeChanged,TResult Function( WireEventStateReplay value)?  stateReplay,TResult Function( WireEventPlaybackModeChanged value)?  playbackModeChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WireEventStateChanged() when stateChanged != null:
return stateChanged(_that);case WireEventRequestMoreTracks() when requestMoreTracks != null:
return requestMoreTracks(_that);case WireEventTracksAdded() when tracksAdded != null:
return tracksAdded(_that);case WireEventTracksRemoved() when tracksRemoved != null:
return tracksRemoved(_that);case WireEventNetworkError() when networkError != null:
return networkError(_that);case WireEventFavoriteAdded() when favoriteAdded != null:
return favoriteAdded(_that);case WireEventFavoriteRemoved() when favoriteRemoved != null:
return favoriteRemoved(_that);case WireEventVolumeChanged() when volumeChanged != null:
return volumeChanged(_that);case WireEventStateReplay() when stateReplay != null:
return stateReplay(_that);case WireEventPlaybackModeChanged() when playbackModeChanged != null:
return playbackModeChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WireEventStateChanged value)  stateChanged,required TResult Function( WireEventRequestMoreTracks value)  requestMoreTracks,required TResult Function( WireEventTracksAdded value)  tracksAdded,required TResult Function( WireEventTracksRemoved value)  tracksRemoved,required TResult Function( WireEventNetworkError value)  networkError,required TResult Function( WireEventFavoriteAdded value)  favoriteAdded,required TResult Function( WireEventFavoriteRemoved value)  favoriteRemoved,required TResult Function( WireEventVolumeChanged value)  volumeChanged,required TResult Function( WireEventStateReplay value)  stateReplay,required TResult Function( WireEventPlaybackModeChanged value)  playbackModeChanged,}){
final _that = this;
switch (_that) {
case WireEventStateChanged():
return stateChanged(_that);case WireEventRequestMoreTracks():
return requestMoreTracks(_that);case WireEventTracksAdded():
return tracksAdded(_that);case WireEventTracksRemoved():
return tracksRemoved(_that);case WireEventNetworkError():
return networkError(_that);case WireEventFavoriteAdded():
return favoriteAdded(_that);case WireEventFavoriteRemoved():
return favoriteRemoved(_that);case WireEventVolumeChanged():
return volumeChanged(_that);case WireEventStateReplay():
return stateReplay(_that);case WireEventPlaybackModeChanged():
return playbackModeChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WireEventStateChanged value)?  stateChanged,TResult? Function( WireEventRequestMoreTracks value)?  requestMoreTracks,TResult? Function( WireEventTracksAdded value)?  tracksAdded,TResult? Function( WireEventTracksRemoved value)?  tracksRemoved,TResult? Function( WireEventNetworkError value)?  networkError,TResult? Function( WireEventFavoriteAdded value)?  favoriteAdded,TResult? Function( WireEventFavoriteRemoved value)?  favoriteRemoved,TResult? Function( WireEventVolumeChanged value)?  volumeChanged,TResult? Function( WireEventStateReplay value)?  stateReplay,TResult? Function( WireEventPlaybackModeChanged value)?  playbackModeChanged,}){
final _that = this;
switch (_that) {
case WireEventStateChanged() when stateChanged != null:
return stateChanged(_that);case WireEventRequestMoreTracks() when requestMoreTracks != null:
return requestMoreTracks(_that);case WireEventTracksAdded() when tracksAdded != null:
return tracksAdded(_that);case WireEventTracksRemoved() when tracksRemoved != null:
return tracksRemoved(_that);case WireEventNetworkError() when networkError != null:
return networkError(_that);case WireEventFavoriteAdded() when favoriteAdded != null:
return favoriteAdded(_that);case WireEventFavoriteRemoved() when favoriteRemoved != null:
return favoriteRemoved(_that);case WireEventVolumeChanged() when volumeChanged != null:
return volumeChanged(_that);case WireEventStateReplay() when stateReplay != null:
return stateReplay(_that);case WireEventPlaybackModeChanged() when playbackModeChanged != null:
return playbackModeChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( StateChangedEvent payload)?  stateChanged,TResult Function( RequestMoreTracksEvent payload)?  requestMoreTracks,TResult Function( TracksAddedEvent payload)?  tracksAdded,TResult Function( TracksRemovedEvent payload)?  tracksRemoved,TResult Function( NetworkErrorEvent payload)?  networkError,TResult Function( FavoriteAddedEvent payload)?  favoriteAdded,TResult Function( FavoriteRemovedEvent payload)?  favoriteRemoved,TResult Function( VolumeChangedEvent payload)?  volumeChanged,TResult Function( StateReplayEvent payload)?  stateReplay,TResult Function( PlaybackModeChangedEvent payload)?  playbackModeChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WireEventStateChanged() when stateChanged != null:
return stateChanged(_that.payload);case WireEventRequestMoreTracks() when requestMoreTracks != null:
return requestMoreTracks(_that.payload);case WireEventTracksAdded() when tracksAdded != null:
return tracksAdded(_that.payload);case WireEventTracksRemoved() when tracksRemoved != null:
return tracksRemoved(_that.payload);case WireEventNetworkError() when networkError != null:
return networkError(_that.payload);case WireEventFavoriteAdded() when favoriteAdded != null:
return favoriteAdded(_that.payload);case WireEventFavoriteRemoved() when favoriteRemoved != null:
return favoriteRemoved(_that.payload);case WireEventVolumeChanged() when volumeChanged != null:
return volumeChanged(_that.payload);case WireEventStateReplay() when stateReplay != null:
return stateReplay(_that.payload);case WireEventPlaybackModeChanged() when playbackModeChanged != null:
return playbackModeChanged(_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( StateChangedEvent payload)  stateChanged,required TResult Function( RequestMoreTracksEvent payload)  requestMoreTracks,required TResult Function( TracksAddedEvent payload)  tracksAdded,required TResult Function( TracksRemovedEvent payload)  tracksRemoved,required TResult Function( NetworkErrorEvent payload)  networkError,required TResult Function( FavoriteAddedEvent payload)  favoriteAdded,required TResult Function( FavoriteRemovedEvent payload)  favoriteRemoved,required TResult Function( VolumeChangedEvent payload)  volumeChanged,required TResult Function( StateReplayEvent payload)  stateReplay,required TResult Function( PlaybackModeChangedEvent payload)  playbackModeChanged,}) {final _that = this;
switch (_that) {
case WireEventStateChanged():
return stateChanged(_that.payload);case WireEventRequestMoreTracks():
return requestMoreTracks(_that.payload);case WireEventTracksAdded():
return tracksAdded(_that.payload);case WireEventTracksRemoved():
return tracksRemoved(_that.payload);case WireEventNetworkError():
return networkError(_that.payload);case WireEventFavoriteAdded():
return favoriteAdded(_that.payload);case WireEventFavoriteRemoved():
return favoriteRemoved(_that.payload);case WireEventVolumeChanged():
return volumeChanged(_that.payload);case WireEventStateReplay():
return stateReplay(_that.payload);case WireEventPlaybackModeChanged():
return playbackModeChanged(_that.payload);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( StateChangedEvent payload)?  stateChanged,TResult? Function( RequestMoreTracksEvent payload)?  requestMoreTracks,TResult? Function( TracksAddedEvent payload)?  tracksAdded,TResult? Function( TracksRemovedEvent payload)?  tracksRemoved,TResult? Function( NetworkErrorEvent payload)?  networkError,TResult? Function( FavoriteAddedEvent payload)?  favoriteAdded,TResult? Function( FavoriteRemovedEvent payload)?  favoriteRemoved,TResult? Function( VolumeChangedEvent payload)?  volumeChanged,TResult? Function( StateReplayEvent payload)?  stateReplay,TResult? Function( PlaybackModeChangedEvent payload)?  playbackModeChanged,}) {final _that = this;
switch (_that) {
case WireEventStateChanged() when stateChanged != null:
return stateChanged(_that.payload);case WireEventRequestMoreTracks() when requestMoreTracks != null:
return requestMoreTracks(_that.payload);case WireEventTracksAdded() when tracksAdded != null:
return tracksAdded(_that.payload);case WireEventTracksRemoved() when tracksRemoved != null:
return tracksRemoved(_that.payload);case WireEventNetworkError() when networkError != null:
return networkError(_that.payload);case WireEventFavoriteAdded() when favoriteAdded != null:
return favoriteAdded(_that.payload);case WireEventFavoriteRemoved() when favoriteRemoved != null:
return favoriteRemoved(_that.payload);case WireEventVolumeChanged() when volumeChanged != null:
return volumeChanged(_that.payload);case WireEventStateReplay() when stateReplay != null:
return stateReplay(_that.payload);case WireEventPlaybackModeChanged() when playbackModeChanged != null:
return playbackModeChanged(_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class WireEventStateChanged implements WireEvent {
  const WireEventStateChanged(this.payload);
  

@override final  StateChangedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventStateChangedCopyWith<WireEventStateChanged> get copyWith => _$WireEventStateChangedCopyWithImpl<WireEventStateChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventStateChanged&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.stateChanged(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventStateChangedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventStateChangedCopyWith(WireEventStateChanged value, $Res Function(WireEventStateChanged) _then) = _$WireEventStateChangedCopyWithImpl;
@useResult
$Res call({
 StateChangedEvent payload
});


$StateChangedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventStateChangedCopyWithImpl<$Res>
    implements $WireEventStateChangedCopyWith<$Res> {
  _$WireEventStateChangedCopyWithImpl(this._self, this._then);

  final WireEventStateChanged _self;
  final $Res Function(WireEventStateChanged) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventStateChanged(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as StateChangedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateChangedEventCopyWith<$Res> get payload {
  
  return $StateChangedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventRequestMoreTracks implements WireEvent {
  const WireEventRequestMoreTracks(this.payload);
  

@override final  RequestMoreTracksEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventRequestMoreTracksCopyWith<WireEventRequestMoreTracks> get copyWith => _$WireEventRequestMoreTracksCopyWithImpl<WireEventRequestMoreTracks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventRequestMoreTracks&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.requestMoreTracks(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventRequestMoreTracksCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventRequestMoreTracksCopyWith(WireEventRequestMoreTracks value, $Res Function(WireEventRequestMoreTracks) _then) = _$WireEventRequestMoreTracksCopyWithImpl;
@useResult
$Res call({
 RequestMoreTracksEvent payload
});


$RequestMoreTracksEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventRequestMoreTracksCopyWithImpl<$Res>
    implements $WireEventRequestMoreTracksCopyWith<$Res> {
  _$WireEventRequestMoreTracksCopyWithImpl(this._self, this._then);

  final WireEventRequestMoreTracks _self;
  final $Res Function(WireEventRequestMoreTracks) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventRequestMoreTracks(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as RequestMoreTracksEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RequestMoreTracksEventCopyWith<$Res> get payload {
  
  return $RequestMoreTracksEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventTracksAdded implements WireEvent {
  const WireEventTracksAdded(this.payload);
  

@override final  TracksAddedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventTracksAddedCopyWith<WireEventTracksAdded> get copyWith => _$WireEventTracksAddedCopyWithImpl<WireEventTracksAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventTracksAdded&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.tracksAdded(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventTracksAddedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventTracksAddedCopyWith(WireEventTracksAdded value, $Res Function(WireEventTracksAdded) _then) = _$WireEventTracksAddedCopyWithImpl;
@useResult
$Res call({
 TracksAddedEvent payload
});


$TracksAddedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventTracksAddedCopyWithImpl<$Res>
    implements $WireEventTracksAddedCopyWith<$Res> {
  _$WireEventTracksAddedCopyWithImpl(this._self, this._then);

  final WireEventTracksAdded _self;
  final $Res Function(WireEventTracksAdded) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventTracksAdded(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as TracksAddedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TracksAddedEventCopyWith<$Res> get payload {
  
  return $TracksAddedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventTracksRemoved implements WireEvent {
  const WireEventTracksRemoved(this.payload);
  

@override final  TracksRemovedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventTracksRemovedCopyWith<WireEventTracksRemoved> get copyWith => _$WireEventTracksRemovedCopyWithImpl<WireEventTracksRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventTracksRemoved&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.tracksRemoved(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventTracksRemovedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventTracksRemovedCopyWith(WireEventTracksRemoved value, $Res Function(WireEventTracksRemoved) _then) = _$WireEventTracksRemovedCopyWithImpl;
@useResult
$Res call({
 TracksRemovedEvent payload
});


$TracksRemovedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventTracksRemovedCopyWithImpl<$Res>
    implements $WireEventTracksRemovedCopyWith<$Res> {
  _$WireEventTracksRemovedCopyWithImpl(this._self, this._then);

  final WireEventTracksRemoved _self;
  final $Res Function(WireEventTracksRemoved) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventTracksRemoved(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as TracksRemovedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TracksRemovedEventCopyWith<$Res> get payload {
  
  return $TracksRemovedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventNetworkError implements WireEvent {
  const WireEventNetworkError(this.payload);
  

@override final  NetworkErrorEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventNetworkErrorCopyWith<WireEventNetworkError> get copyWith => _$WireEventNetworkErrorCopyWithImpl<WireEventNetworkError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventNetworkError&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.networkError(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventNetworkErrorCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventNetworkErrorCopyWith(WireEventNetworkError value, $Res Function(WireEventNetworkError) _then) = _$WireEventNetworkErrorCopyWithImpl;
@useResult
$Res call({
 NetworkErrorEvent payload
});


$NetworkErrorEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventNetworkErrorCopyWithImpl<$Res>
    implements $WireEventNetworkErrorCopyWith<$Res> {
  _$WireEventNetworkErrorCopyWithImpl(this._self, this._then);

  final WireEventNetworkError _self;
  final $Res Function(WireEventNetworkError) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventNetworkError(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as NetworkErrorEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NetworkErrorEventCopyWith<$Res> get payload {
  
  return $NetworkErrorEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventFavoriteAdded implements WireEvent {
  const WireEventFavoriteAdded(this.payload);
  

@override final  FavoriteAddedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventFavoriteAddedCopyWith<WireEventFavoriteAdded> get copyWith => _$WireEventFavoriteAddedCopyWithImpl<WireEventFavoriteAdded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventFavoriteAdded&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.favoriteAdded(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventFavoriteAddedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventFavoriteAddedCopyWith(WireEventFavoriteAdded value, $Res Function(WireEventFavoriteAdded) _then) = _$WireEventFavoriteAddedCopyWithImpl;
@useResult
$Res call({
 FavoriteAddedEvent payload
});


$FavoriteAddedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventFavoriteAddedCopyWithImpl<$Res>
    implements $WireEventFavoriteAddedCopyWith<$Res> {
  _$WireEventFavoriteAddedCopyWithImpl(this._self, this._then);

  final WireEventFavoriteAdded _self;
  final $Res Function(WireEventFavoriteAdded) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventFavoriteAdded(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as FavoriteAddedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavoriteAddedEventCopyWith<$Res> get payload {
  
  return $FavoriteAddedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventFavoriteRemoved implements WireEvent {
  const WireEventFavoriteRemoved(this.payload);
  

@override final  FavoriteRemovedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventFavoriteRemovedCopyWith<WireEventFavoriteRemoved> get copyWith => _$WireEventFavoriteRemovedCopyWithImpl<WireEventFavoriteRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventFavoriteRemoved&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.favoriteRemoved(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventFavoriteRemovedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventFavoriteRemovedCopyWith(WireEventFavoriteRemoved value, $Res Function(WireEventFavoriteRemoved) _then) = _$WireEventFavoriteRemovedCopyWithImpl;
@useResult
$Res call({
 FavoriteRemovedEvent payload
});


$FavoriteRemovedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventFavoriteRemovedCopyWithImpl<$Res>
    implements $WireEventFavoriteRemovedCopyWith<$Res> {
  _$WireEventFavoriteRemovedCopyWithImpl(this._self, this._then);

  final WireEventFavoriteRemoved _self;
  final $Res Function(WireEventFavoriteRemoved) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventFavoriteRemoved(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as FavoriteRemovedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FavoriteRemovedEventCopyWith<$Res> get payload {
  
  return $FavoriteRemovedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventVolumeChanged implements WireEvent {
  const WireEventVolumeChanged(this.payload);
  

@override final  VolumeChangedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventVolumeChangedCopyWith<WireEventVolumeChanged> get copyWith => _$WireEventVolumeChangedCopyWithImpl<WireEventVolumeChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventVolumeChanged&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.volumeChanged(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventVolumeChangedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventVolumeChangedCopyWith(WireEventVolumeChanged value, $Res Function(WireEventVolumeChanged) _then) = _$WireEventVolumeChangedCopyWithImpl;
@useResult
$Res call({
 VolumeChangedEvent payload
});


$VolumeChangedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventVolumeChangedCopyWithImpl<$Res>
    implements $WireEventVolumeChangedCopyWith<$Res> {
  _$WireEventVolumeChangedCopyWithImpl(this._self, this._then);

  final WireEventVolumeChanged _self;
  final $Res Function(WireEventVolumeChanged) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventVolumeChanged(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as VolumeChangedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VolumeChangedEventCopyWith<$Res> get payload {
  
  return $VolumeChangedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventStateReplay implements WireEvent {
  const WireEventStateReplay(this.payload);
  

@override final  StateReplayEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventStateReplayCopyWith<WireEventStateReplay> get copyWith => _$WireEventStateReplayCopyWithImpl<WireEventStateReplay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventStateReplay&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.stateReplay(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventStateReplayCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventStateReplayCopyWith(WireEventStateReplay value, $Res Function(WireEventStateReplay) _then) = _$WireEventStateReplayCopyWithImpl;
@useResult
$Res call({
 StateReplayEvent payload
});


$StateReplayEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventStateReplayCopyWithImpl<$Res>
    implements $WireEventStateReplayCopyWith<$Res> {
  _$WireEventStateReplayCopyWithImpl(this._self, this._then);

  final WireEventStateReplay _self;
  final $Res Function(WireEventStateReplay) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventStateReplay(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as StateReplayEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateReplayEventCopyWith<$Res> get payload {
  
  return $StateReplayEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc


class WireEventPlaybackModeChanged implements WireEvent {
  const WireEventPlaybackModeChanged(this.payload);
  

@override final  PlaybackModeChangedEvent payload;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WireEventPlaybackModeChangedCopyWith<WireEventPlaybackModeChanged> get copyWith => _$WireEventPlaybackModeChangedCopyWithImpl<WireEventPlaybackModeChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WireEventPlaybackModeChanged&&(identical(other.payload, payload) || other.payload == payload));
}


@override
int get hashCode => Object.hash(runtimeType,payload);

@override
String toString() {
  return 'WireEvent.playbackModeChanged(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $WireEventPlaybackModeChangedCopyWith<$Res> implements $WireEventCopyWith<$Res> {
  factory $WireEventPlaybackModeChangedCopyWith(WireEventPlaybackModeChanged value, $Res Function(WireEventPlaybackModeChanged) _then) = _$WireEventPlaybackModeChangedCopyWithImpl;
@useResult
$Res call({
 PlaybackModeChangedEvent payload
});


$PlaybackModeChangedEventCopyWith<$Res> get payload;

}
/// @nodoc
class _$WireEventPlaybackModeChangedCopyWithImpl<$Res>
    implements $WireEventPlaybackModeChangedCopyWith<$Res> {
  _$WireEventPlaybackModeChangedCopyWithImpl(this._self, this._then);

  final WireEventPlaybackModeChanged _self;
  final $Res Function(WireEventPlaybackModeChanged) _then;

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(WireEventPlaybackModeChanged(
null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as PlaybackModeChangedEvent,
  ));
}

/// Create a copy of WireEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaybackModeChangedEventCopyWith<$Res> get payload {
  
  return $PlaybackModeChangedEventCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

// dart format on
