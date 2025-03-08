import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// for the `read` method on BuildContext
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appia/blocs/session.dart';
import 'package:appia/models/models.dart';
import 'package:appia/p2p/namester_client.dart';
import 'package:appia/p2p/p2p.dart';
import 'package:appia/p2p/transports/transports.dart';

import 'home.dart';

class SetupScreen extends StatefulWidget {
  static const String routeName = "setup";
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // String _username = "auser_69420";
  String _username = "v";
  String _id = "gnirtsmodnaramai";
  // todo: replace by current ip address
  // InternetAddress _listeningHost = InternetAddress("192.168.8.102");
  InternetAddress _listeningHost = InternetAddress("192.168.12.77");
  int _listeningPort = 8080;
  // Uri _namesterAddress = Uri.parse("http://192.168.73.145:3000");
  Uri _namesterAddress = Uri.parse("http://192.168.12.1:3000");
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: <Widget>[
              const Text("Appia"),
              const Text("Setup:"),
              TextFormField(
                initialValue: this._username,
                decoration: const InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Username",
                  helperText: "Username",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Username's empty";
                  final trimmedValue = value.trim();
                  // if (trimmedValue.length < 5)
                  // return "Username length shorter than five";
                  // if (trimmedValue.contains(RegExp(r'^[A-Za-z0-9_]')))
                  // return "Only [A-Za-z0-9_] classes allowed in Username";
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    setState(() {
                      this._username = value;
                    });
                  }
                },
              ),
              TextFormField(
                initialValue: this._id,
                decoration: const InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "AppiaId",
                  helperText: "AppiaId",
                  prefix: const Text("aid:"),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Id's empty";
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    setState(() {
                      this._id = value;
                    });
                  }
                },
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: "Listening host",
                        helperText: "Listening host",
                        prefix: const Text("http://"),
                      ),
                      initialValue: this._listeningHost.address,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Listening host's empty";
                        if (InternetAddress.tryParse(value) == null)
                          return "Lisetning host is not valid.";
                        return null;
                      },
                      onSaved: (value) {
                        if (value != null) {
                          setState(() {
                            this._listeningHost = InternetAddress(value);
                          });
                        }
                      },
                    ),
                  ),
                  Container(
                    width: 75,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: "Listening port",
                        helperText: "Listening port",
                      ),
                      initialValue: this._listeningPort.toString(),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Listening port's empty";
                        if (int.tryParse(value) == null) {
                          return "Listening port field is invalid.";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        if (value != null) {
                          setState(() {
                            this._listeningPort = int.parse(value);
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "Namester address",
                  helperText: "Namester address",
                ),
                initialValue: this._namesterAddress.toString(),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Namester addres's empty";
                  if (Uri.tryParse(value) == null)
                    return "Namester addres's not valid";
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    setState(() {
                      this._namesterAddress = Uri.parse(value);
                    });
                  }
                },
              ),
              ElevatedButton(
                  onPressed: _isLoading ? null : _doSetup,
                  child: _isLoading
                      ? const Text("Loading...")
                      : const Text("Log in"))
            ],
          ),
        ),
      ),
    );
  }

  void _doSetup() {
    final form = this._formKey.currentState;
    if (form != null && form.validate()) {
      form.save();

      // FIXME: replace with bloc
      setState(() {
        _isLoading = true;
      });

      // TODO: loading screen shit

      final actualId = "aid:${this._id}";
      // iife
      () async {
        final p2pNode = context.read<P2PNode>();
        // check if namester address is true
        try {
          final namesterClient = HttpNamesterProxy(_namesterAddress);
          // TODO: replace this with a scheme that doesn't
          // rely on update
          await namesterClient.updateMyAddress(
            actualId,
            this._username,
            WsPeerAddress(
              Uri(
                  scheme: "ws",
                  host: this._listeningHost.address,
                  port: this._listeningPort),
            ),
          );
          p2pNode.namester = namesterClient;
        } catch (e) {
          throw Exception("unable to contact name server: $e");
        }

        // start a listener
        try {
          final listener =
              await p2pNode.transports[TransportType.WebSockets]!.listen(
            WsListeningAddress(
              this._listeningHost,
              this._listeningPort,
            ),
          );
          p2pNode.addListener(listener);
        } catch (e) {
          throw Exception("unable to listen at address: $e");
        }
        final me = User(this._username, actualId);
        p2pNode.self = me;
        return me;
      }()
          .then(
        (user) {
          context.read<SessionBloc>().add(Initiate(user));
          Navigator.of(context).pushNamedAndRemoveUntil(
            HomeScreen.routeName,
            (route) => false,
          );
        },
        onError: (error, stackTrace) {
          print(error);
          print(stackTrace);
        },
      ).whenComplete(
        () {
          setState(() {
            _isLoading = false;
          });
        },
      );
    }
  }
}
