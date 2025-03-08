import 'package:namester/namester.dart';

void main(List<String> arguments) async {
  final server = NamesterServer();
  await server.serve(hotReload: true);
}
