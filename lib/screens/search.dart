import 'package:appia/blocs/screens/search.dart';
import 'package:appia/screens/userDetail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchScreen extends StatefulWidget {
  static const String routeName = "search";
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchString = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SearchScreenBloc, SearchScreenState>(
          builder: (context, state) => TextField(
            decoration: InputDecoration(hintText: 'Search'),
            onChanged: (value) {
              final str = value.trim();
              if (str.isNotEmpty) {
                setState(() {
                  _searchString = str;
                });
              }
              if (state is! Searching) {
                context
                    .read<SearchScreenBloc>()
                    .add(SearchString(this._searchString));
              }
            },
          ),
        ),
      ),
      body: Center(
        child: BlocBuilder<SearchScreenBloc, SearchScreenState>(
          builder: (context, state) => state is Results
              ? state.users.isNotEmpty
                  ? ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(state.users[index].username),
                          subtitle: Text(
                            "${state.users[index].id} | ${state.users[index].address.toJson()}",
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            UserDetailScreen.routeName,
                            arguments: state.users[index],
                          ),
                        );
                      })
                  : const Text("No results")
              : state is Searching
                  ? CircularProgressIndicator.adaptive()
                  : state is ErrorTalkingWithNs
                      ? Text(state.error.toString())
                      : const Text("Search using username"),
        ),
      ),
    );
  }
}
