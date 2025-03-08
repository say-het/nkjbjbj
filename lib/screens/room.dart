import 'package:appia/blocs/session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:appia/blocs/p2p/connection_bloc.dart' as conn_bloc;
import 'package:appia/blocs/screens/room/room.dart';

import 'package:appia/models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namester/namester.dart';

import 'userDetail.dart';

class RoomScreen extends StatefulWidget {
  static const String routeName = "room";
  final Room room;

  const RoomScreen({Key? key, required this.room}) : super(key: key);

  @override
  _RoomConnectionState createState() => _RoomConnectionState();
}

class _RoomConnectionState extends State<RoomScreen> {
  final _msgformKey = GlobalKey<FormState>();
  final myController = TextEditingController();

  // String _event = "echo";
  String _message = "hello appia";

  String _debugBoardMsg = "";

  @override
  Widget build(BuildContext context) {
    final roomConnBloc = context.read<RoomConnectionBloc>();
    final roomScrBloc = context.read<RoomScreenBloc>();
    final currentUser =
        (context.read<SessionBloc>().state as ActiveSession).user;
    final otherUser = widget.room.users.where((u) => u.id != currentUser).first;

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<int>(
              onSelected: (item) {
                switch (item) {
                  case 0:
                    /* Navigator.of(context).pushNamed(
                      UserDetailScreen.routeName,
                      arguments: UserEntry(otherUser.username, otherUser.id room),
                    ); */
                    break;
                  default:
                    throw Exception("unrecognized popup item");
                }
              },
              itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Text('User Info'),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Text('Disconnect'),
                    ),
                  ]),
        ],
        title: BlocConsumer<RoomConnectionBloc, RoomConnectionState>(
          listener: (context, roomConnBlocState) {
            if (roomConnBlocState is HasConnection) {
              roomConnBlocState.conn.stream.listen((connBlocState) {
                if (connBlocState == conn_bloc.ConnectionState.Connected) {}
                setState(() {
                  switch (connBlocState) {
                    case conn_bloc.ConnectionState.Connected:
                      _debugBoardMsg =
                          "connected to peer at: ${roomConnBlocState.conn.eventedConnection.peerAddress.toString()}";
                      break;
                    case conn_bloc.ConnectionState.Closed:
                      _debugBoardMsg =
                          "connection finished: ${roomConnBlocState.conn.eventedConnection.closeReason}";
                      break;
                    default:
                  }
                });
              });
            }
          },
          builder: (context, state) => state is HasConnection
              ? BlocBuilder<conn_bloc.ConnectionBloc,
                  conn_bloc.ConnectionState>(
                  bloc: state.conn,
                  builder: (context, state) =>
                      state == conn_bloc.ConnectionState.Connected
                          ? Text("Connected")
                          : state == conn_bloc.ConnectionState.Connected
                              ? const Text("Connecting")
                              : const Text("Closed"),
                )
              : Row(
                  children: <Widget>[
                    const Text("Not Connected"),
                    ElevatedButton(
                        onPressed: () {
                          roomConnBloc.add(CheckForConnection());
                        },
                        child: const Text("Check")),
                  ],
                ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Messages:',
          ),
          Text(
            _debugBoardMsg,
          ),
          Expanded(
            child: BlocBuilder<RoomScreenBloc, RoomScreenState>(
              builder: (context, state) => state is Loaded
                  ? ListView.builder(
                      itemCount: state.log.entries.length,
                      itemBuilder: (context, index) {
                        final msg = state.log.entries[index] as TextMessage;
                        return MessageUi(
                          message: msg,
                          alignment: msg.authorId == currentUser.id
                              ? MessageAlignment.Right
                              : MessageAlignment.Left,
                        );
                      },
                    )
                  : const Center(child: const CircularProgressIndicator()),
            ),
          ),
          Form(
            key: this._msgformKey,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      /* TextFormField(
                        initialValue: this._event,
                        onSaved: (value) {
                          if (value != null)
                            setState(() {
                              this._event = value;
                            });
                        },
                        validator: (msg) {
                          if (msg == null || msg.isEmpty) {
                            return "Event field is empty.";
                          }
                          return null;
                        },
                      ), */
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        initialValue: this._message,
                        onSaved: (value) {
                          if (value != null)
                            setState(() {
                              this._message = value;
                            });
                        },
                        validator: (msg) {
                          if (msg == null || msg.isEmpty) {
                            return "Message field is empty.";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                BlocBuilder<RoomConnectionBloc, RoomConnectionState>(
                  builder: (context, roomState) => roomState is HasConnection
                      ? BlocBuilder<conn_bloc.ConnectionBloc,
                          conn_bloc.ConnectionState>(
                          bloc: roomState.conn,
                          builder: (context, state) => ElevatedButton(
                            onPressed: state ==
                                    conn_bloc.ConnectionState.Connected
                                ? () {
                                    final form = this._msgformKey.currentState;
                                    if (form != null && form.validate()) {
                                      form.save();
                                      roomConnBloc.add(SendMessage(TextMessage(
                                        _message,
                                        id: -1,
                                        authorId: currentUser.id,
                                        authorUsername: currentUser.username,
                                        timestamp: DateTime.now(),
                                      )));
                                    }
                                  }
                                : null,
                            child: const Text("Send"),
                          ),
                        )
                      : const Text("Not Connected"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

enum MessageAlignment { Left, Right }

class MessageUi extends StatefulWidget {
  final TextMessage message;
  final MessageAlignment alignment;

  const MessageUi(
      {Key? key, required this.message, this.alignment = MessageAlignment.Left})
      : super(key: key);

  @override
  _MessageUiState createState() => _MessageUiState();
}

class _MessageUiState extends State<MessageUi> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: widget.alignment == MessageAlignment.Left
          ? Alignment.centerLeft
          : Alignment.centerRight,
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: widget.alignment == MessageAlignment.Left
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          // Text(message.senderUsername),
          Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width * 0.45,
              maxWidth: MediaQuery.of(context).size.width * 0.67,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.all(
                Radius.circular(MediaQuery.of(context).size.width * 0.05),
              ),
              color: Colors.blue.shade100,
            ),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: widget.alignment == MessageAlignment.Left
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      Flexible(child: Text(widget.message.text)),
                    ]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      widget.message.timestamp.toString(),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
