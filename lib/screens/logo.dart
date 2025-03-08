import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:appia/blocs/session.dart';

import 'setup.dart';
import 'home.dart';

class LogoScreen extends StatefulWidget {
  static const String routeName = "logo";
  @override
  _LogoScreenState createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is ActiveSession)
              Navigator.of(context).pushNamedAndRemoveUntil(
                HomeScreen.routeName,
                (route) => false,
              );
            else if (state is NoSession)
              Navigator.of(context).pushNamedAndRemoveUntil(
                SetupScreen.routeName,
                (route) => false,
              );
          },
          child: const Text("Appia Logo something"),
        ),
      ),
    );
  }
}
