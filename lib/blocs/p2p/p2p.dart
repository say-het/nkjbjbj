import 'dart:collection';

import 'package:appia/p2p/p2p.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connection_bloc.dart';
export 'connection_bloc.dart';

// -- EVENTS

abstract class P2PBlocEvent {
  const P2PBlocEvent();
}

class AddConnection extends P2PBlocEvent {
  final AppiaConnection conn;
  const AddConnection(this.conn);
}

class PeerDisconncted extends P2PBlocEvent {
  final String id;
  const PeerDisconncted(this.id);
}

class IncomingPeerConnection extends P2PBlocEvent {
  final AppiaConnection connection;
  const IncomingPeerConnection(this.connection);
}

// -- STATE

class P2PBlocState {
  final Map<String, ConnectionBloc> connections;
  P2PBlocState(this.connections);
}

// -- BLOC

class P2PBloc extends Bloc<P2PBlocEvent, P2PBlocState> {
  final P2PNode node;

  P2PBloc(
    this.node,
  ) : super(P2PBlocState(new HashMap())) {
    this.node.incomingConnections.forEach((conn) {
      add(IncomingPeerConnection(conn));
    });
  }

  @override
  Stream<P2PBlocState> mapEventToState(P2PBlocEvent event) async* {
    if (event is AddConnection) {
      yield* _addConnectionToState(state, event.conn, true);
    } else if (event is IncomingPeerConnection) {
      yield* _addConnectionToState(state, event.connection, false);
    } else if (event is PeerDisconncted) {
      final connections = state.connections;
      connections.remove(event.id);
      yield P2PBlocState(connections);
    }
  }

  Stream<P2PBlocState> _addConnectionToState(
      P2PBlocState state, AppiaConnection connection, bool reconnect) async* {
    final bloc = ConnectionBloc(connection.connection, connection.user,
        reconnect: reconnect);
    // listen for disconenction
    bloc.stream.listen((event) {
      if (event == ConnectionState.Closed) {
        add(PeerDisconncted(connection.user.id));
      }
    });
    final connections = state.connections;
    connections[connection.user.id] = bloc;
    yield P2PBlocState(connections);
  }

  @override
  Future<void> close() async {
    await super.close();
    await this.node.close();
  }
}
