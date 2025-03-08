import 'dart:io';

import 'package:appia/p2p/transports/transports.dart';
import 'package:appia/p2p/transports/evented_connection.dart';
import 'package:appia/p2p/transports/websocket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  // this doesn't work in a browser
  test("works", () {
    var transport = new WsTransport();
    Future.wait([
      // dial and sender
      () async {
        try {
          var listener = await transport.listen(WsListeningAddress(
            InternetAddress.tryParse("127.0.0.1")!,
            8080,
          ));
          var conn =
              new EventedConnection(await listener.incomingConnections.first);
          var msg = await conn.stream.first;
          print("msg: ${msg.toJson()}");
        } catch (err) {
          print("err $err");
        }
      }(), // closures are called right away
      // listen and recieve
      () async {
        var conn = new EventedConnection(await transport
            .dial(WsPeerAddress(Uri.parse("ws://127.0.0.1:8080"))));
        // FIXME: this seems emit even when no connection's established
        await conn.emit(EventMessage("echo", "hello"));
        await conn.close(new CloseReason(code: CloseCode.GoingAway));
      }(),
    ]).onError((error, stackTrace) {
      print("$error, $stackTrace");
      return new List.empty();
    }).whenComplete(() => print("done"));
  });
}
