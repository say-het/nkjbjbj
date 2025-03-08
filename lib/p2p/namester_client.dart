import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:namester/namester.dart';

import 'p2p.dart';

/// Interface for interacting with a name server
abstract class AbstractNamester {
  /// Returns null if id not recognized
  Future<UserEntry?> getEntryForId(String id);

  /// Returns null if username not recognized
  Future<UserEntry?> getEntryForUsername(String username);
  Future<void> updateMyAddress(String id, String username, PeerAddress address);
}

/// Returns null if id not recognized
/// Interface for nameserver that's on an REST API elsewhere
class HttpNamesterProxy extends AbstractNamester {
  final Client _client;

  Uri _nameserverAddress;

  HttpNamesterProxy(this._nameserverAddress) : _client = new Client();

  Future<UserEntry?> getEntryForId(String id) async {
    try {
      final response = await _client.post(
        _nameserverAddress.resolve("/get-peer-address"),
        body: '{ "id":"${id.toString()}" }',
      );
      switch (response.statusCode) {
        case HttpStatus.ok:
          final entry = UserEntry.fromJson(jsonDecode(response.body));
          return entry;
        case HttpStatus.notFound:
          return null;
        default:
          throw UnsupportedError(
            "nameserver response not recognized: ${response.toString()}",
          );
      }
    } catch (e) {
      throw NetworkException("error talking with nameserver: ${e.toString()}");
    }
  }

  @override
  Future<UserEntry?> getEntryForUsername(String username) async {
    try {
      final response = await _client.post(
        _nameserverAddress.resolve("/get-peer-address"),
        body: '{ "username":"$username" }',
      );
      switch (response.statusCode) {
        case HttpStatus.ok:
          final entry = UserEntry.fromJson(jsonDecode(response.body));
          return entry;
        case HttpStatus.notFound:
          return null;
        default:
          throw UnimplementedError(
              "nameserver response not recognized: ${response.toString()}");
      }
    } catch (e) {
      throw NetworkException("error talking with nameserver: ${e.toString()}");
    }
  }

  @override
  Future<void> updateMyAddress(
      String id, String username, PeerAddress address) async {
    try {
      final response = await _client.put(
        _nameserverAddress.resolve("/put-peer-address"),
        body: UserEntry(username, id.toString(), address).toJson(),
      );
      switch (response.statusCode) {
        case HttpStatus.created:
          return;
        default:
          throw UnimplementedError(
            "nameserver response not recognized: ${response.toString()}",
          );
      }
    } catch (e) {
      throw NetworkException("error talking with nameserver: ${e.toString()}");
    }
  }
}

/// Namester that always returns the same peerAddress
class DumbNamester extends AbstractNamester {
  final UserEntry universalAddress;

  DumbNamester(this.universalAddress);
  @override
  Future<UserEntry?> getEntryForId(String id) async {
    return this.universalAddress;
  }

  @override
  Future<void> updateMyAddress(
      String id, String username, PeerAddress address) async {
    throw UnimplementedError();
  }

  @override
  Future<UserEntry?> getEntryForUsername(String username) async {
    return this.universalAddress;
  }
}
