import 'dart:io';

import 'package:namester/namester.dart';
import 'package:http/http.dart' as http;

void main() async {
  final server = NamesterServer();
  final entry = UserEntry(
    'admin',
    'aid:fuckshit',
    WsPeerAddress(
      Uri.parse('ws://http://192168blowme'),
    ),
  );
  server.addUserEntry(entry);
  await server.serve(host: '127.0.0.1', port: 3000);
  try {
    await Future.delayed(Duration(seconds: 1));
    // get-peer-address username
    {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:3000/get-peer-address'),
        body: '{ "username":"${entry.username}" }',
      );
      assert(entry.toJson() == response.body);
    }
    // get-peer-address id
    {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:3000/get-peer-address'),
        body: '{ "id":"${entry.id}" }',
      );
      assert(response.statusCode == HttpStatus.ok);
      assert(entry.toJson() == response.body);
    }
    // put-peer-address
    {
      final testEntry = UserEntry(
        'supaedge',
        'aid:abcdef1234567890',
        WsPeerAddress(Uri.parse('ws://localdunce')),
      );
      {
        final response = await http.put(
          Uri.parse('http://127.0.0.1:3000/put-peer-address'),
          body: testEntry.toJson(),
        );

        assert(response.statusCode == HttpStatus.created);
        assert(testEntry.toJson() == response.body);
      }
      {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:3000/get-peer-address'),
          body: '{ "id":"${testEntry.id}" }',
        );
        assert(response.statusCode == HttpStatus.ok);
        assert(testEntry.toJson() == response.body);
      }
    }
  } catch (e) {
    print('err: $e');
  } finally {
    await server.close();
  }
}
