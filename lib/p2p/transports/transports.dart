import 'package:namester/namester.dart';

export 'evented_connection.dart';
export 'websocket.dart';
export 'package:namester/namester.dart'
    show PeerAddress, WsPeerAddress, TransportType;

abstract class ListeningAddress {
  final TransportType transportType;
  const ListeningAddress(this.transportType);
}

/// This guy's equivalent to an HttpClient (you can dial) but
/// one that also allows you to generate HttpServers (you can get listeners)
/// That is, it doesn't listen/serve itself, it's more of a factory for listeners/servers.
abstract class AbstractTransport<L extends AbstractListener<C>,
    C extends AbstractConnection> {
  TransportType get type;

  /// the peer address must be valid for the transport type
  Future<C> dial(PeerAddress address);

  /// the listening address, if it requires one, must be valid for the transport type
  Future<L> listen(ListeningAddress? listeningAddress);
}

abstract class AbstractListener<C extends AbstractConnection> {
  TransportType get type;
  ListeningAddress get listeningAddress;
  Stream<C> get incomingConnections;
  void close();
}

/// FIXME: Should we hoist the reconnection features upwards?
abstract class AbstractConnection {
  TransportType get type;

  bool get isConnected;

  PeerAddress get peerAddress;

  /// Get a refernce of the incoming stream.
  /// A broadcast stream, doesn't buffer messages.
  ///
  /// This will keep working even after a reconnection.
  Stream<dynamic> get stream;

  /// Get a reference to the outgiong sink.
  /// This will keep working even after a reconnection.
  // Sink<dynamic> get sink;

  /// I don't get sinks so use this to send messages.
  Future<void> emit(dynamic message);

  Future<void> close(CloseReason reason);

  /// Use this to reconnect when connection fails.
  ///
  /// This closes the connection if not closed with a [CloseCode.NormalClosure]
  Future<void> reconnect();

  /// This will be null if it's not closed
  CloseReason? get closeReason;
}

class NotConnectedException implements Exception {}

/// Copied from web_socket_channel status codes.
enum CloseCode {
  /// The purpose for which the connection was established has been fulfilled.
  NormalClosure,

  /// An endpoint is "going away", such as a server going down or a browser having
  /// navigated away from a page.
  GoingAway,

  /// An endpoint is terminating the connection due to a protocol error.
  ProtocolError,

  /// An endpoint is terminating the connection because it has received a type of
  /// data it cannot accept.
  ///
  /// For example, an endpoint that understands only text data MAY send this if it
  /// receives a binary message).
  UnsupportedData,

  /// No status code was present.
  ///
  /// This **must not** be set explicitly by an endpoint.
  NoStatusReceived,

  /// The connection was closed abnormally.
  ///
  /// For example, this is used if the connection was closed without sending or
  /// receiving a Close control frame.
  ///
  /// This **must not** be set explicitly by an endpoint.
  AbnormalClosure,

  /// An endpoint is terminating the connection because it has received data
  /// within a message that was not consistent with the type of the message.
  ///
  /// For example, the endpoint may have receieved non-UTF-8 data within a text
  /// message.
  InvalidFramePayloadData,

  /// An endpoint is terminating the connection because it has received a message
  /// that violates its policy.
  ///
  /// This is a generic status code that can be returned when there is no other
  /// more suitable status code (such as [unsupportedData] or [messageTooBig]), or
  /// if there is a need to hide specific details about the policy.
  PolicyViolation,

  /// An endpoint is terminating the connection because it has received a message
  /// that is too big for it to process.
  MessageTooBig,

  /// The client is terminating the connection because it expected the server to
  /// negotiate one or more extensions, but the server didn't return them in the
  /// response message of the WebSocket handshake.
  ///
  /// The list of extensions that are needed should appear in the close reason.
  /// Note that this status code is not used by the server, because it can fail
  /// the WebSocket handshake instead.
  MissingMandatoryExtension,

  /// The server is terminating the connection because it encountered an
  /// unexpected condition that prevented it from fulfilling the request.
  InternalServerError,

  /// The connection was closed due to a failure to perform a TLS handshake.
  ///
  /// For example, the server certificate may not have been verified.
  ///
  /// This **must not** be set explicitly by an endpoint.
  TlsHandshakeFailed,
}

class CloseReason {
  final CloseCode? code;
  final String? message;
  const CloseReason({this.code, this.message});
  @override
  String toString() => '{ "code": $code, "message": $message }';
}
