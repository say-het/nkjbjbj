abstract class UserEvent {
  const UserEvent();
}

class GetAllUsers extends UserEvent {}

class SearchUserRequested extends UserEvent {
  final String username;

  SearchUserRequested(this.username);
}
