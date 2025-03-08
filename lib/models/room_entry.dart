import 'message.dart';

enum EntryType { message }

abstract class RoomEntry {
  final int id;
  final EntryType entryType;
  final DateTime timestamp;

  const RoomEntry(this.id, this.entryType, this.timestamp);

  Map<String, dynamic> toJson();

  factory RoomEntry.fromJson(Map<String, dynamic> json) {
    final type = json['entryType'] as String?;
    switch (type) {
      case null:
        throw InvalidJSONException(
          json,
          'no entryType',
        );
      case "message":
        return Message.fromJson(json);
      default:
        throw InvalidJSONException(
          json,
          'unrecognized entryType ($type)',
        );
    }
  }
}
