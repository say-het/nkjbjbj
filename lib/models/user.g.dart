// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return $checkedNew('User', json, () {
    final val = User(
      $checkedConvert(json, 'username', (v) => v as String),
      $checkedConvert(json, 'id', (v) => v as String),
    );
    return val;
  });
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'id': instance.id,
    };
