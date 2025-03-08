import 'package:appia/models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// -- EVENTS

abstract class SessionEvent {
  const SessionEvent();
}

class Initiate extends SessionEvent {
  final User user;

  Initiate(this.user);
}

class Remove extends SessionEvent {}

// -- STATE

abstract class SessionState {
  const SessionState();
}

class Loading extends SessionState {}

class NoSession extends SessionState {}

class ActiveSession extends SessionState {
  final User user;

  ActiveSession(this.user);
}

// -- BLOC

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(Loading()) {
    // TODO: check for session from persistent store
    // Future.delayed(Duration(seconds: 2)).then((_) =>
    add(Remove());
    // );
  }

  @override
  Stream<SessionState> mapEventToState(SessionEvent event) async* {
    if (event is Initiate) {
      yield ActiveSession(event.user);
    } else if (event is Remove) {
      yield NoSession();
    }
  }
}
