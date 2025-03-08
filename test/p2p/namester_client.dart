import 'package:appia/p2p/namester_client.dart';
import 'package:namester/namester.dart';

void main() async {
  final server = NamesterServer();
  final entry = UserEntry(
    'entropy',
    'aid:decadence',
    WsPeerAddress(
      Uri.parse('ws://dagagagagad'),
    ),
  );
  server.addUserEntry(entry);
  await server.serve(host: '127.0.0.1', port: 3000);
  // await Future.delayed(Duration(seconds: 4));

  final client = HttpNamesterProxy(Uri.parse('http://127.0.0.1:3000'));
  try {
    // get-peer-address username
    {
      final addr = await client.getEntryForUsername(entry.username);
      assert(addr != null);
      assert(addr!.toJson() == entry.address.toJson());
    }
    // get-peer-address id
    {
      final addr = await client.getEntryForId(entry.id);
      assert(addr != null);
      assert(addr!.toJson() == entry.address.toJson());
    }
    // put-peer-address
    {
      final testEntry = UserEntry(
        'supaedge',
        'aid:abcdef1234567890',
        WsPeerAddress(Uri.parse('ws://localdunce')),
      );
      {
        await client.updateMyAddress(
            testEntry.id, testEntry.username, testEntry.address);
      }
      {
        final addr = await client.getEntryForId(testEntry.id);
        assert(addr != null);
        assert(addr!.toJson() == testEntry.address.toJson());
      }
    }
  } catch (e) {
    print('err: $e');
  } finally {
    await server.close();
  }
}
