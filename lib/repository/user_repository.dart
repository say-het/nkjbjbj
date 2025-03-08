import 'package:appia/data_provider/data_provider.dart';
import 'package:appia/models/models.dart';

class UserRepository {
  final UserDataProvider userDataProvider;
  UserRepository({required this.userDataProvider})
      // ignore: unnecessary_null_comparison
      : assert(userDataProvider != null);

  Future<User> searchUser(String username) async {
    return await userDataProvider.searchUser(username);
  }
}
