import 'package:appia/blocs/p2p/p2p.dart';
import 'package:appia/blocs/screens/userDetail.dart';
import 'package:appia/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:namester/namester.dart';

import 'room.dart';

class UserDetailScreen extends StatefulWidget {
  static const String routeName = "connect";
  final UserEntry entry;

  const UserDetailScreen({Key? key, required this.entry}) : super(key: key);
  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Text(widget.entry.username),
          Text(widget.entry.id),
          Text(widget.entry.address.toJson()),
          BlocBuilder<P2PBloc, P2PBlocState>(
            builder: (context, connectionsState) => connectionsState.connections
                    .containsKey(widget.entry.id)
                ? Row(
                    children: <Widget>[
                      const Text("Connected"),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.popAndPushNamed(
                              context,
                              RoomScreen.routeName,
                              arguments: Room(
                                  widget.entry.id, RoomType.personalChat, [
                                User(widget.entry.username, widget.entry.id),
                                context.read<P2PBloc>().node.self
                              ]),
                            );
                          },
                          child: const Text("Chat"))
                    ],
                  )
                : BlocBuilder<UserDetailScreenBloc, UserDetailScreenState>(
                    builder: (context, screenState) => Column(
                      children: <Widget>[
                        screenState is Connecting
                            ? CircularProgressIndicator()
                            : TextButton(
                                onPressed: () {
                                  context
                                      .read<UserDetailScreenBloc>()
                                      .add(ConnectToId(widget.entry.id));
                                },
                                child: const Text("Connect"),
                              ),
                        screenState is ConnectingError
                            ? Text(
                                "Connection error: ${screenState.error.toString()}")
                            : Text(''),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
