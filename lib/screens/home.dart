import 'package:appia/blocs/session.dart';
import 'package:appia/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appia/blocs/rooms.dart';
import 'package:appia/blocs/p2p/p2p.dart';
import 'package:appia/blocs/p2p/connection_bloc.dart' as c_bloc;

import 'room.dart';
import 'search.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "home";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // FIXME: ??
  @override
  Widget build(BuildContext context) {
    final currentUser =
        (context.read<SessionBloc>().state as ActiveSession).user;
    return Scaffold(
        appBar: AppBar(
          title: Text("Appia"),
          // TODO: display for listener status
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(SearchScreen.routeName);
              },
              icon: Icon(Icons.search),
            ),
            PopupMenuButton<int>(
                onSelected: (item) => (context, item) {},
                itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Text('Settings'),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Text('Blocked List'),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Text('Log out'),
                      ),
                    ]),
          ],
        ),
        body: Column(
          children: <Widget>[
            BlocBuilder<RoomsBloc, RoomState>(
              builder: (context, state) {
                if (state is RoomsLoadSuccess) {
                  final rooms = state.rooms;
                  final roomKeys = state.rooms.keys;
                  return Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.all(20),
                      child: rooms.isNotEmpty
                          ? ListView.builder(
                              itemCount: rooms.length,
                              itemBuilder: (context, index) {
                                final otherUser =
                                    rooms[roomKeys.elementAt(index)]!
                                        .users
                                        .where((u) => u.id != currentUser.id)
                                        .first;
                                return ListTile(
                                  title: Text(otherUser.username),
                                  subtitle: Text(otherUser.id),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RoomScreen.routeName,
                                      arguments: Room(
                                        otherUser.id,
                                        RoomType.personalChat,
                                        [
                                          otherUser,
                                          currentUser,
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : Center(
                              child: const Text("No Rooms"),
                            ));
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            BlocBuilder<P2PBloc, P2PBlocState>(
              builder: (context, state) => state.connections.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.connections.length,
                      itemBuilder: (context, index) {
                        final item = state.connections[
                            state.connections.keys.elementAt(index)]!;
                        return ListTile(
                          title: Text(item.user.username),
                          subtitle: Text(item.user.id),
                          trailing: item.state ==
                                  c_bloc.ConnectionState.Connected
                              ? const Text("Connected")
                              : item.state == c_bloc.ConnectionState.Connecting
                                  ? const Text("Connecting")
                                  : const Text("Closed"),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoomScreen.routeName,
                              arguments: Room(
                                  item.user.id, RoomType.personalChat, [
                                item.user,
                                context.read<P2PBloc>().node.self
                              ]),
                            );
                          },
                        );
                      },
                    )
                  : Center(child: const Text("No Peers")),
            ),
          ],
        ));
  }
}
/* 
class UnseenText extends StatelessWidget {
  final Room room;
  UnseenText({required this.room});

  @override
  Widget build(BuildContext context) {
    var text = room.entries[0];
    //how do you cast in golang
    TextMessage lastMessage = text as TextMessage;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(ChatRoom.routeName, arguments: room);
      },
      child: Container(
        height: MediaQuery.of(context).size.width * 0.2,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                constraints: BoxConstraints(
                    maxHeight: 50.0,
                    maxWidth: 50.0,
                    minWidth: 50.0,
                    minHeight: 50.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text("${lastMessage.authorUsername.toUpperCase()}")),
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                margin: EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                    border: Border(
                  bottom: BorderSide(color: Colors.blueAccent),
                )),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${lastMessage.authorUsername}"),
                          Text("${lastMessage.text}"),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(5),
                            child: Text("68"),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(15),
                                right: Radius.circular(15),
                              ),
                            ),
                          ),
                          Text("${lastMessage.timestamp.toString()}",
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .apply(fontSizeFactor: 0.9)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
 */