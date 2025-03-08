import 'package:appia/models/message.dart';
import 'package:appia/models/room_entry.dart';
import 'package:json_annotation/json_annotation.dart';

import 'user.dart';

part 'room.g.dart';

enum RoomType { personalChat }

@JsonSerializable()
// This is more of a description.
class Room {
  final String id;
  final List<User> users;
  final RoomType type;
  // final DateTime creationDate;

  const Room(
    this.id,
    this.type,
    this.users,
  );

  Map<String, dynamic> toJson() {
    return _$RoomToJson(this);
  }

  static Room fromJson(Map<String, dynamic> json) {
    return _$RoomFromJson(json);
  }
}
