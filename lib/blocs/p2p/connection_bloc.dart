import 'package:appia/models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appia/p2p/transports/transports.dart';

// -- EVENTS

abstract class ConnectionEvent {
  const ConnectionEvent();
}

class Reconnect extends ConnectionEvent {
  const Reconnect._modulePrivate();
}

// class Connect extends ConnectionEvent {}

class StopConnection extends ConnectionEvent {
  final CloseReason reason;
  const StopConnection(this.reason);
}

class Disconnected extends ConnectionEvent {
  final CloseReason reason;
  const Disconnected(this.reason);
}

class ConnectionError extends ConnectionEvent {
  final Object error;
  const ConnectionError(this.error);
}

// -- STATE

enum ConnectionState { Connected, Connecting, Closed }

// -- BLOC

/// This guy's responsible for reconnection when connection goes down.
///
/// TODO: find a way to make this get this started without needing a pre-existing
/// connection.
class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  // TODO(Yohe): figure out where to start using EventedConnection
  // right now it's here but I can't say if it's the right place

  late final EventedConnection eventedConnection;
  bool reconnect;
  Duration reconnectionDuration;
  User user;

  /// The dialer is responsible for reconnection.
  /// You can still add a Reconnect event from elsewhere to
  /// override this and enable auto reconnection.
  ConnectionBloc(
    AbstractConnection connection,
    this.user, {
    this.reconnect = false,
    this.reconnectionDuration = const Duration(seconds: 1),
  }) : super(ConnectionState.Connected) {
    // TODO: figure out a sensible hierarchy of connections
    this.eventedConnection = new EventedConnection(
      connection,
      onError: this._onErrorHandler,
      onFinish: this._onFinishHandler,
      onMessage: this._onMessageHandler,
    );
  }
  // factory ConnectionBloc.connect() => ConnectionBloc()..add(Connect());

  void _onMessageHandler(EventedConnection socket, EventMessage<dynamic> msg) {
    //
  }

  void _onErrorHandler(EventedConnection socket, Object err) {
    this.add(ConnectionError(err));
  }

  void _onFinishHandler(EventedConnection socket, CloseReason reason) {
    this.add(Disconnected(reason));
  }

  @override
  Stream<ConnectionState> mapEventToState(ConnectionEvent event) async* {
    if (event is ConnectionError) {
      if (this.reconnect) {
        // reconnect if allowed
        yield ConnectionState.Connecting;
        await Future.delayed(reconnectionDuration);
        this.add(Reconnect._modulePrivate());
      } else {
        // close bloc
        yield ConnectionState.Closed;
        await this.close();
      }
    } else if (event is Disconnected) {
      // close bloc
      yield ConnectionState.Closed;
      await this.close();
    } else if (event is StopConnection) {
      // close bloc
      this.reconnect = false;
      yield ConnectionState.Closed;
      await this.close(event.reason);
    } else if (event is Reconnect) {
      // start reconnection
      this.reconnect = true;
      yield ConnectionState.Connecting;
      await this.eventedConnection.reconnect();
      yield ConnectionState.Connected;
    }
  }

  @override
  Future<void> close([
    CloseReason reason = const CloseReason(
        code: CloseCode.GoingAway, message: "discarding connection bloc"),
  ]) async {
    await super.close();
    if (this.eventedConnection.isConnected)
      this.eventedConnection.close(reason);
  }
}
