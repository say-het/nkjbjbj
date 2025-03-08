import 'package:appia/blocs/p2p/p2p.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:namester/namester.dart';

// -- EVENTS

abstract class SearchScreenEvent {
  const SearchScreenEvent();
}

class SearchString extends SearchScreenEvent {
  final String string;

  SearchString(this.string);
}

// class CancelSearch extends SearchScreenEvent {}

// -- STATE

abstract class SearchScreenState {
  const SearchScreenState();
}

class Initial extends SearchScreenState {}

class Searching extends SearchScreenState {}

class ErrorTalkingWithNs extends SearchScreenState {
  Object? error;
  ErrorTalkingWithNs(this.error);
}

class Results extends SearchScreenState {
  final List<UserEntry> users;

  Results(this.users);
}

// -- BLOC

class SearchScreenBloc extends Bloc<SearchScreenEvent, SearchScreenState> {
  P2PBloc _p2pBloc;
  SearchScreenBloc(this._p2pBloc) : super(Initial());
  static final UserEntry echoUser = UserEntry(
    "echo",
    "aid:echo",
    WsPeerAddress(
      Uri.parse("ws://127.0.0.1:8088"),
    ),
  );
  @override
  Stream<SearchScreenState> mapEventToState(SearchScreenEvent event) async* {
    if (event is SearchString) {
      yield Searching();
      try {
        final result =
            await _p2pBloc.node.namester.getEntryForUsername(event.string);
        yield result != null
            ? Results([result, echoUser])
            : Results([echoUser]);
      } catch (e) {
        yield ErrorTalkingWithNs(e);
      }
    }
  }
}
