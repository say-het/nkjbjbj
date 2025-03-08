import 'dart:collection';

import 'package:appia/models/models.dart';

// FIXME: the interface sucs
class RoomRepository {
  Map<String, RoomLog> _roomsLogs = new HashMap();

  Future<RoomLog?> getRoomLog(String roomId) async {
    return _roomsLogs[roomId];
  }

  Future<void> setRoomLog(String roomId, RoomLog entries) async {
    _roomsLogs[roomId] = entries;
  }
}
