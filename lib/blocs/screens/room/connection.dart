import 'package:appia/blocs/p2p/p2p.dart';
import 'package:appia/blocs/rooms.dart';
import 'package:appia/models/models.dart';
import 'package:appia/p2p/transports/transports.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// -- EVENTS

abstract class RoomConnectionEvent {
  const RoomConnectionEvent();
}

class CheckForConnection extends RoomConnectionEvent {}

class SendMessage extends RoomConnectionEvent {
  final RoomEntry msg;
  const SendMessage(this.msg);
}

class IncomingMessage extends RoomConnectionEvent {
  final RoomEntry msg;
  const IncomingMessage(this.msg);
}

// class CancelSearch extends SearchScreenEvent {}

// -- STATE

abstract class RoomConnectionState {
  const RoomConnectionState();
}

class HasConnection extends RoomConnectionState {
  final ConnectionBloc conn;

  HasConnection(this.conn);
}

class NoConnection extends RoomConnectionState {}

// -- BLOC

class RoomConnectionBloc
    extends Bloc<RoomConnectionEvent, RoomConnectionState> {
  P2PBloc p2pBloc;
  RoomsBloc roomsBloc;
  Room room;
  late RoomLog log;
  RoomConnectionBloc(this.room, this.p2pBloc, this.roomsBloc)
      : super(NoConnection()) {
    () async {
      final log = await roomsBloc.repo.getRoomLog(this.room.id);
      if (log != null) {
        this.log = log;
      } else {
        this.log = RoomLog(room, []);
        roomsBloc.add(UpdateRoom(this.log));
      }
    }();
  }

  void _hookupConnection(ConnectionBloc bloc) {
    bloc.eventedConnection.stream.listen((event) {
      final eventName = event.event;
      // we only care of appia events
      if (!eventName.startsWith("appia.")) return;
      switch (eventName) {
        case TextMessage.EVENT_NAME:
          add(IncomingMessage(TextMessage.fromJson(event.data)));
          break;
        default:
          throw Exception("unrecognized appia message: $eventName");
      }
    });
  }

  @override
  Stream<RoomConnectionState> mapEventToState(
      RoomConnectionEvent event) async* {
    if (event is CheckForConnection) {
      final conn = p2pBloc.state.connections[room.id];
      if (conn != null) {
        _hookupConnection(conn);
        yield HasConnection(conn);
      } else {
        yield NoConnection();
      }
    } else if (event is IncomingMessage) {
      log.entries.add(event.msg);
      roomsBloc.add(UpdateRoom(log));
    } else if (event is SendMessage) {
      final currentState = state;
      if (currentState is HasConnection) {
        await currentState.conn.eventedConnection.emitEvent(
          EventMessage(TextMessage.EVENT_NAME, event.msg.toJson()),
        );
        log.entries.add(event.msg);
        roomsBloc.add(UpdateRoom(log));
      } else {
        throw Exception("Has no connection");
      }
    }
  }
}
