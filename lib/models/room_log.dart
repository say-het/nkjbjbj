import 'package:json_annotation/json_annotation.dart';

import 'room.dart';
import 'room_entry.dart';

@JsonSerializable()
class RoomLog {
  final Room room;
  final List<RoomEntry> entries;
  const RoomLog(
    this.room,
    this.entries,
  );

  /*  Map<String, dynamic> toJson() {
    return _$RoomToJson(this);
  }

  static Room fromJson(Map<String, dynamic> json) {
    return _$RoomFromJson(json);
  } */
}
