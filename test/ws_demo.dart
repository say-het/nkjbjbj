import 'dart:convert';
import 'dart:io';

import 'package:appia/blocs/p2p/connection_bloc.dart';
import 'package:appia/models/models.dart';
import 'package:appia/p2p/transports/transports.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  // use this async iife to set up a dumb echo server on the local machine
  // for testing
  () async {
    try {
      var transport = new WsTransport();
      var listener = await transport.listen(
        WsListeningAddress(
          InternetAddress.tryParse("127.0.0.1")!,
          8088, // note the different port
        ),
      );
      listener.incomingConnections
          .map((conn) => new EventedConnection(
                conn,
                onMessage: (_, msg) {
                  print("server got message ${msg.toJson()}");
                },
              ))
          .forEach((conn) {
        print("server got connection from ${conn.connection.peerAddress}");
        conn.setListener(
          "echo",
          (connection, data) =>
              connection.emitEvent(EventMessage("echo", data)),
        );
      });
    } catch (err) {
      print("err seting up dumb server: $err");
    }
  }();
  runApp(MyApp());
}

enum DemoConnectionState { Connected, Connecting, NotConnected }
enum DemoListeningState { Listening, NotListening }

/// Cubit for controlling the demo connection
class DemoConnectionCubit extends Cubit<DemoConnectionState> {
  ConnectionBloc? connBloc;
  final DemoMessagesCubit msgsCubit;
  late final AbstractListener listener;
  final AbstractTransport tport;

  DemoConnectionCubit(this.msgsCubit)
      : tport = WsTransport(),
        super(DemoConnectionState.NotConnected);

  void setConnection(AbstractConnection conn) {
    if (this.state == DemoConnectionState.Connected) {
      this.msgsCubit.addMessage(
          "Incoming connection from ${conn.peerAddress.toString()} rejected.");
      return;
    }
    this.connBloc =
        ConnectionBloc(conn, User("testUser", "aid:tUser"), reconnect: true);
    this.connBloc!.eventedConnection.stream.listen((msg) {
      msgsCubit.addMessage("incoming " + jsonEncode(msg.toJson()));
    }, onError: (e) {
      msgsCubit.addMessage("error from evented connection: $e");
    }, onDone: () {
      msgsCubit.addMessage("connection finished: ${conn.closeReason}");
      emit(DemoConnectionState.NotConnected);
    });
    msgsCubit
        .addMessage("connected to peer at: ${conn.peerAddress.toString()}");
    emit(DemoConnectionState.Connected);
  }

  void connect(WsPeerAddress addr) {
    if (this.connBloc != null) this.msgsCubit.addMessage("Already connected");
    this.tport.dial(addr).then(
      this.setConnection,
      onError: (error, stackTrace) {
        msgsCubit.addMessage(
            "err dialing to address (${addr.toString()}): $error\n$stackTrace");
        emit(DemoConnectionState.NotConnected);
      },
    );
  }

  void sendMessage(EventMessage<dynamic> msg) {
    if (this.connBloc == null) throw "Not connected";
    this.connBloc!.eventedConnection.emitEvent(msg).then(
      (v) => msgsCubit.addMessage("outgoing: " + jsonEncode(msg.toJson())),
      onError: (e) {
        msgsCubit.addMessage("error sending message $e");
      },
    );
  }

  void disconnect() {
    this.connBloc!.close().then((v) {
      msgsCubit.addMessage("disconnected");
      this.connBloc = null;
      emit(DemoConnectionState.NotConnected);
    });
  }
}

/// Cubit for controlling the demo listening
class DemoListeningCubit extends Cubit<DemoListeningState> {
  final AbstractTransport tport;
  final DemoMessagesCubit msgsCubit;
  final DemoConnectionCubit connCubit;
  AbstractListener? listener;
  DemoListeningCubit(this.msgsCubit, this.connCubit)
      : tport = WsTransport(),
        super(DemoListeningState.NotListening);

  void startListening(WsListeningAddress addr) {
    if (this.listener != null) this.msgsCubit.addMessage("Already listening");

    // initiate a listener
    final transport = new WsTransport();
    transport.listen(addr).then(
      (ls) {
        this.listener = ls;
        // listen for incoming connections
        ls.incomingConnections.listen(
          this.connCubit.setConnection,
          onError: (e) {
            this.msgsCubit.addMessage("listening error ${e.toString()}");
          },
        );
        emit(DemoListeningState.Listening);
        this.msgsCubit.addMessage("listening on ${ls.listeningAddress}.");
      },
      onError: (error, stackTrace) {
        this.msgsCubit.addMessage(
            "error establishing node listener: $error\n$stackTrace");
      },
    );
  }

  void stopListening() {
    if (this.listener != null) {
      this.listener!.close();
      this.listener = null;
      this.msgsCubit.addMessage("listener severed");
      emit(DemoListeningState.NotListening);
    }
  }
}

class Messages {
  final List<String> messages;

  Messages(this.messages);
}

class DemoMessagesCubit extends Cubit<Messages> {
  DemoMessagesCubit() : super(Messages([]));
  void addMessage(String s) {
    print("message added $s");
    final state = this.state;
    state.messages.add(s);
    emit(Messages(state.messages));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      // provide repositorys first
      /*MultiRepositoryProvider(
        providers: [
          
          RepositoryProvider(
            create: (context) {
              final transport = new WsTransport();
              final bloc = new P2PBloc(
                P2PNode(
                  DumbNamester(
                    WsPeerAddress(Uri.parse("ws://127.0.0.1:8080")),
                  ),
                  tports: [WsTransport()],
                ),
              );
              transport
                  .listen(WsListeningAddress(
                    InternetAddress.tryParse("127.0.0.1")!,
                    8080,
                  ))
                  .then((listener) => bloc.node.addListener(listener))
                  .onError(
                (error, stackTrace) {
                  print(
                      "error establishing node listener: $error\n$stackTrace");
                },
              );
              return bloc;
            },
          ),
        ],
        // then come the blocs
        child:*/
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => DemoMessagesCubit(),
          ),
          BlocProvider(
            create: (context) =>
                DemoConnectionCubit(context.read<DemoMessagesCubit>()),
          ),
          BlocProvider(
            create: (context) => DemoListeningCubit(
              context.read<DemoMessagesCubit>(),
              context.read<DemoConnectionCubit>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Appia Demo',
          theme: ThemeData(
            primarySwatch: Colors.pink,
          ),
          home: MyHomePage(title: 'Appia Demo'),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _connectFormKey = GlobalKey<FormState>();
  final _msgformKey = GlobalKey<FormState>();
  final _listenForm = GlobalKey<FormState>();

  String _event = "echo";
  String _message = "hello appia";

  // try connecting to port 8088 to access the local echo server
  // else, find the host of the other device
  String _peerHost = "127.0.0.1";
  int _peerPort = 8080;

  String _listenHost = "192.168.43.39";
  int _listenPort = 8080;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<DemoConnectionCubit, DemoConnectionState>(
          builder: (context, state) => state == DemoConnectionState.Connected
              ? Text("Connected")
              : state == DemoConnectionState.Connecting
                  ? Text("Connecting")
                  : Text("Not Connected"),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Form(
            key: this._listenForm,
            child: BlocBuilder<DemoListeningCubit, DemoListeningState>(
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: state == DemoListeningState.NotListening,
                      initialValue: this._listenHost,
                      onSaved: (value) {
                        if (value != null)
                          setState(() {
                            this._listenHost = value;
                          });
                      },
                      validator: (host) {
                        if (host == null || host.isEmpty) {
                          return "Listening host field is empty.";
                        }
                        if (InternetAddress.tryParse(host) == null)
                          return "Lisetning host is not valid.";
                        return null;
                      },
                    ),
                  ),
                  Container(
                    width: 75,
                    child: TextFormField(
                      enabled: state == DemoListeningState.NotListening,
                      initialValue: this._listenPort.toString(),
                      onSaved: (value) {
                        if (value != null)
                          setState(() {
                            this._listenPort = int.parse(value);
                          });
                      },
                      validator: (port) {
                        if (port == null || port.isEmpty) {
                          return "Listening port field is empty.";
                        }
                        if (int.tryParse(port) == null) {
                          return "Listening port field is invalid.";
                        }
                        return null;
                      },
                    ),
                  ),
                  state == DemoListeningState.NotListening
                      ? ElevatedButton(
                          onPressed: () {
                            final form = this._listenForm.currentState;
                            if (form != null && form.validate()) {
                              form.save();
                              context
                                  .read<DemoListeningCubit>()
                                  .startListening(WsListeningAddress(
                                    InternetAddress.tryParse(this._listenHost)!,
                                    this._listenPort,
                                  ));
                            }
                          },
                          child: const Text("Listen"),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            context.read<DemoListeningCubit>().stopListening();
                          },
                          child: const Text("Close"),
                        )
                ],
              ),
            ),
          ),
          Form(
            key: this._connectFormKey,
            child: BlocBuilder<DemoConnectionCubit, DemoConnectionState>(
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: state == DemoConnectionState.NotConnected,
                      initialValue: this._peerHost,
                      onSaved: (value) {
                        if (value != null)
                          setState(() {
                            this._peerHost = value;
                          });
                      },
                      validator: (host) {
                        if (host == null || host.isEmpty) {
                          return "Connection host field is empty.";
                        }
                        if (InternetAddress.tryParse(host) == null)
                          return "Lisetning host is not valid.";
                        return null;
                      },
                    ),
                  ),
                  Container(
                    width: 75,
                    child: TextFormField(
                      enabled: state == DemoConnectionState.NotConnected,
                      initialValue: this._peerPort.toString(),
                      onSaved: (value) {
                        if (value != null)
                          setState(() {
                            this._peerPort = int.parse(value);
                          });
                      },
                      validator: (port) {
                        if (port == null || port.isEmpty) {
                          return "Port field is empty.";
                        }
                        if (int.tryParse(port) == null) {
                          return "Port field is invalid.";
                        }
                        return null;
                      },
                    ),
                  ),
                  state == DemoConnectionState.NotConnected
                      ? ElevatedButton(
                          onPressed: () {
                            final form = this._connectFormKey.currentState;
                            if (form != null && form.validate()) {
                              form.save();
                              context.read<DemoConnectionCubit>().connect(
                                    WsPeerAddress(
                                      Uri(
                                          scheme: "ws",
                                          host: this._peerHost,
                                          port: this._peerPort),
                                    ),
                                  );
                            }
                          },
                          child: const Text("Connect"),
                        )
                      : state == DemoConnectionState.Connected
                          ? ElevatedButton(
                              onPressed: () {
                                context
                                    .read<DemoConnectionCubit>()
                                    .disconnect();
                              },
                              child: const Text("Disconnect"),
                            )
                          : ElevatedButton(
                              onPressed: null, child: const Text("Wait")),
                ],
              ),
            ),
          ),
          Text(
            'Messages:',
          ),
          Expanded(
            child: BlocBuilder<DemoMessagesCubit, Messages>(
              builder: (context, state) => ListView.builder(
                itemCount: state.messages.length,
                itemBuilder: (context, index) => Text(state.messages[index]),
              ),
            ),
          ),
          Form(
            key: this._msgformKey,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
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
                      ),
                      TextFormField(
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
                BlocBuilder<DemoConnectionCubit, DemoConnectionState>(
                  builder: (context, state) => ElevatedButton(
                    onPressed: state == DemoConnectionState.Connected
                        ? () {
                            final form = this._msgformKey.currentState;
                            if (form != null && form.validate()) {
                              form.save();
                              context.read<DemoConnectionCubit>().sendMessage(
                                    EventMessage(this._event, this._message),
                                  );
                            }
                          }
                        : null,
                    child: const Text("Send"),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
