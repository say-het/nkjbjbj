import 'dart:collection';
import 'dart:io';

import 'package:shelf_plus/shelf_plus.dart';

/// We mainly use these enum for runtime compatablity checks between
/// addresses and transports
enum TransportType { WebSockets }

/// i miss rust
abstract class PeerAddress {
  final TransportType transportType;
  const PeerAddress(this.transportType);

  String toJson();

  factory PeerAddress.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == null) {
      throw Exception('JSON not valid PeerAddress: missing type');
    }
    switch (type) {
      case 'ws':
        final uriString = json['uri'] as String?;
        if (uriString == null) {
          throw Exception('JSON not valid WsPeerAddress: missing uri string');
        }
        final uri = Uri.tryParse(uriString);
        if (uri == null) {
          throw Exception('JSON not valid WsPeerAddress: uri string not valid');
        }
        return WsPeerAddress(uri);
      default:
        throw Exception('unrecognized transport type ($type)');
    }
  }
}

class WsPeerAddress extends PeerAddress {
  final Uri uri;
  WsPeerAddress(this.uri) : super(TransportType.WebSockets);
  @override
  String toString() => 'WsPeerAddress(${uri.toString()})';

  @override
  String toJson() => '{ "type": "ws", "uri": "${uri.toString()}" }';
}

class UserEntry {
  final String username;
  final String id;
  final PeerAddress address;
  const UserEntry(this.username, this.id, this.address);

  factory UserEntry.fromJson(Map<String, dynamic> json) {
    final rawAddress = json['address'];
    // this might throw
    final address = PeerAddress.fromJson(rawAddress);

    final appiaId = json['id'];
    if (appiaId == null) throw Exception('JSON not valid: id field missing');

    final username = json['username'] as String?;
    if (username == null) {
      throw Exception('JSON not valid: rawUsername field missing');
    }
    return UserEntry(username, appiaId, address);
  }
  // TODO: change return type to Map<String, dynamic>
  String toJson() =>
      '{ "id": "$id", "username":"$username", "address": ${address.toJson()} }';
}

class NamesterServer {
  // TODO: make these thread safe
  final Map<String, UserEntry> _idToAddr = HashMap();
  final Map<String, UserEntry> _usernameToAddr = HashMap();

  // final RouterPlus app;
  ShelfRunContext? context;
  // final Map<String, HttpResponse Function(HttpRequest)> handlers;

  NamesterServer() {
    addUserEntry(UserEntry(
        'echo', 'aid:echo', WsPeerAddress(Uri.parse('ws://127.0.0.1:8088'))));
  }

  /// Can be configured with environment variables:
  ///
  /// -  SHELF_PORT: port to run (default 8080)
  /// - SHELF_ADDRESS: address to bind to (default 'localhost')
  /// - SHELF_HOTRELOAD: enable (true) or disable (false) hot reload (default true)
  Future<void> serve({
    String host = '127.0.0.1',
    int port = 3000,
    bool hotReload = false,
  }) async {
    context = await shelfRun(
      _init,
      defaultBindAddress: host.toString(),
      defaultBindPort: port,
      defaultEnableHotReload: hotReload,
    );
    print('server online');
  }

  Future<void> close() {
    if (context != null) {
      return context!.close();
    } else {
      throw Exception('server is not running');
    }
  }

  void addUserEntry(UserEntry entry) {
    _idToAddr[entry.id] = entry;
    _usernameToAddr[entry.username] = entry;
  }

  UserEntry? getFromUsername(String username) {
    return _usernameToAddr[username];
  }

  UserEntry? getFromIdString(String id) {
    return _usernameToAddr[id];
  }

  UserEntry? getFromAppiaId(String id) {
    return _usernameToAddr[id];
  }

  Handler _init() {
    final app = Router().plus;
    app.use(logRequests());

    // POST /get-peer-address
    //
    // provide { "id" : "<appia id>"} or { "username" : "username"}
    // we specify our request in body as opposed to a path or query
    // for privacy reasons.
    app.post('/get-peer-address', (Request request) async {
      // if(request.)
      try {
        final body = await request.body.asJson as Map<String, dynamic>?;
        if (body == null) {
          return Response(
            HttpStatus.badRequest,
          );
        }
        final id = body['id'];
        if (id != null) {
          final addr = _idToAddr[id];
          if (addr == null) {
            return Response.notFound(null);
          } else {
            return Response.ok(addr.toJson());
          }
        }
        final username = body['username'];
        if (username != null) {
          final addr = _usernameToAddr[username];
          if (addr == null) {
            return Response.notFound(null);
          } else {
            return Response.ok(addr.toJson());
          }
        }
        return Response(
          HttpStatus.badRequest,
        );
      } catch (e) {
        return Response(
          HttpStatus.badRequest,
          body: e.toString(),
        );
      }
    });

    // POST /peer-address
    //
    // provide body of format {
    //   "id" : "<appia id>",
    //   "username" : "username",
    //   "peerAddress": "peerAddres"
    // }
    app.put('/put-peer-address', (Request request) async {
      // if(request.)
      try {
        final body = await request.body.asJson;
        if (body == null) {
          return Response(
            HttpStatus.badRequest,
          );
        }

        final userEntry = UserEntry.fromJson(body);
        _idToAddr[userEntry.id] = userEntry;
        _usernameToAddr[userEntry.username] = userEntry;
        return Response(HttpStatus.created, body: userEntry.toJson());
      } catch (e) {
        return Response(
          HttpStatus.badRequest,
          body: e.toString(),
        );
      }
    });
    return app;
  }
}
