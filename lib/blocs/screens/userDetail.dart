import 'package:appia/blocs/p2p/p2p.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// -- EVENTS

abstract class UserDetailScreenEvent {
  const UserDetailScreenEvent();
}

class ConnectToId extends UserDetailScreenEvent {
  final String id;

  ConnectToId(this.id);
}

// -- STATE

abstract class UserDetailScreenState {
  const UserDetailScreenState();
}

class Initial extends UserDetailScreenState {}

class Connecting extends UserDetailScreenState {}

class ConnectingError extends UserDetailScreenState {
  Object? error;
  ConnectingError(this.error);
}

class ConnectionSucceded extends UserDetailScreenState {}

// -- BLOC

class UserDetailScreenBloc
    extends Bloc<UserDetailScreenEvent, UserDetailScreenState> {
  P2PBloc _p2pBloc;
  UserDetailScreenBloc(this._p2pBloc) : super(Initial());

  @override
  Stream<UserDetailScreenState> mapEventToState(
      UserDetailScreenEvent event) async* {
    if (event is ConnectToId) {
      yield Connecting();
      try {
        final connection = await _p2pBloc.node.connectTo(event.id);
        _p2pBloc.add(AddConnection(connection));
        yield ConnectionSucceded();
      } catch (e) {
        yield ConnectingError(e);
      }
    }
  }
}
