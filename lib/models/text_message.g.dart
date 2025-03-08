// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextMessage _$TextMessageFromJson(Map<String, dynamic> json) {
  return $checkedNew('TextMessage', json, () {
    final val = TextMessage(
      $checkedConvert(json, 'text', (v) => v as String),
      id: $checkedConvert(json, 'id', (v) => v as int),
      authorId: $checkedConvert(json, 'authorId', (v) => v),
      authorUsername: $checkedConvert(json, 'authorUsername', (v) => v),
      timestamp:
          $checkedConvert(json, 'timestamp', (v) => DateTime.tryParse(v)),
      forwadedFromId:
          $checkedConvert(json, 'forwadedFromId', (v) => v as String?),
      forwardedFromUsername:
          $checkedConvert(json, 'forwardedFromUsername', (v) => v as String?),
    );
    return val;
  });
}

Map<String, dynamic> _$TextMessageToJson(TextMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'authorId': instance.authorId,
      'authorUsername': instance.authorUsername,
      'forwadedFromId': instance.forwadedFromId,
      'forwardedFromUsername': instance.forwardedFromUsername,
      'text': instance.text,
    };
