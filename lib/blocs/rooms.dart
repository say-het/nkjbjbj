import 'dart:async';
import 'dart:collection';

import 'package:appia/models/room_log.dart';
import 'package:bloc/bloc.dart';

import 'package:appia/models/models.dart';
import 'package:appia/repository/room_repository.dart';

// EVENTS

abstract class RoomEvent {
  const RoomEvent();
}

// TODO: Add it's own Bloc, ChatBloc
class LoadRooms extends RoomEvent {
  const LoadRooms();
}

class UpdateRoom extends RoomEvent {
  final RoomLog log;
  UpdateRoom(this.log);
}

// STATE

abstract class RoomState {
  const RoomState();
}

class RoomsLoading extends RoomState {}

class RoomsLoadSuccess extends RoomState {
  final Map<String, Room> rooms;

  RoomsLoadSuccess(this.rooms);
}

// BLOC

class RoomsBloc extends Bloc<RoomEvent, RoomState> {
  RoomRepository repo;
  RoomsBloc(this.repo) : super(RoomsLoading());

  @override
  Stream<RoomState> mapEventToState(
    RoomEvent event,
  ) async* {
    if (event is UpdateRoom) {
      repo.setRoomLog(event.log.room.id, event.log);
      final rooms = (state as RoomsLoadSuccess).rooms;
      rooms[event.log.room.id] = event.log.room;
      yield RoomsLoadSuccess(rooms);
    } else if (event is LoadRooms) {
      // TODO:  load from fs
      yield RoomsLoadSuccess(new HashMap());
    }
  }
}
