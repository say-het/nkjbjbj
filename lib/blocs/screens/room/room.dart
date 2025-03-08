import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appia/blocs/rooms.dart';
import 'package:appia/models/models.dart';

export 'connection.dart';

// -- EVENTS

abstract class RoomScreenEvent {
  const RoomScreenEvent();
}

class ReloadRoom extends RoomScreenEvent {
  const ReloadRoom._modulePrivate();
}

// -- STATE

abstract class RoomScreenState {
  const RoomScreenState();
}

class Loading extends RoomScreenState {}

class Loaded extends RoomScreenState {
  final RoomLog log;
  const Loaded(this.log);
}

// -- BLOC

class RoomScreenBloc extends Bloc<RoomScreenEvent, RoomScreenState> {
  RoomsBloc roomsBloc;
  Room room;
  RoomScreenBloc(
    this.room,
    this.roomsBloc,
  ) : super(Loading()) {
    add(ReloadRoom._modulePrivate());
    roomsBloc.stream.listen((event) {
      if (event is RoomsLoadSuccess) {
        add(ReloadRoom._modulePrivate());
      }
    });
  }

  @override
  Stream<RoomScreenState> mapEventToState(RoomScreenEvent event) async* {
    if (event is ReloadRoom) {
      yield Loading();
      final log = await roomsBloc.repo.getRoomLog(room.id);
      yield Loaded(log!);
    }
  }
}
