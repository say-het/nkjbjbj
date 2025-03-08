import 'package:json_annotation/json_annotation.dart';

import 'message.dart';

part 'text_message.g.dart';

@JsonSerializable()
class TextMessage extends Message {
  static const String EVENT_NAME = "appia.textMessage";

  final String text;

  const TextMessage(this.text,
      {required int id,
      required authorId,
      required authorUsername,
      required timestamp,
      String? forwadedFromId,
      String? forwardedFromUsername})
      : super(
          id: id,
          authorId: authorId,
          authorUsername: authorUsername,
          timestamp: timestamp,
          forwadedFromId: forwadedFromId,
          forwardedFromUsername: forwardedFromUsername,
        );

  @override
  Map<String, dynamic> toJson() {
    return _$TextMessageToJson(this);
  }

  factory TextMessage.fromJson(Map<String, dynamic> json) {
    return _$TextMessageFromJson(json);
  }
}
