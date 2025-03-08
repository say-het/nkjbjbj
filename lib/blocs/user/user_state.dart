import 'package:appia/models/models.dart';

class UserState {
  const UserState();
}

class UserLoading extends UserState {}

class UserLoadSuccess extends UserState {
  final User user;
  UserLoadSuccess({required this.user});
}

class UserLoadFailure extends UserState {}
