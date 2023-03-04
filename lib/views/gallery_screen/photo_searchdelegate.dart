import 'package:flutter/material.dart';
import 'package:foto_gallery/blocs/gallery_bloc.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/views/gallery_screen/gallery_screen.dart';
import 'package:substring_highlight/substring_highlight.dart';

class PhotoSearchDelegate extends SearchDelegate<Map<String, String>> {
  GalleryBloc parentBloc;

  PhotoSearchDelegate({
    required this.parentBloc,
  }) : super(searchFieldLabel: '  Search for photos..');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      hintColor: Colors.grey,
      primaryColor: Colors.white,
      textTheme: const TextTheme(
          headline6: TextStyle(
              // headline 6 affects the query text
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold)),
      appBarTheme: const AppBarTheme(
        color: Colors.black, // affects AppBar's background color
        //backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        //  hintColor: Colors.grey, // affects the initial 'Search' text
        //  toolbarTextStyle: TextStyle(color: Colors.white),
        // titleTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          debugLog('---------building....');
          return Container(
            color: Colors.black,
            child: ListView.builder(
              //  shrinkWrap: true,
              itemBuilder: (context, index) {
                debugLog(
                    '---------building 2....${snapshot.data![index]['text']!}');
                return ListTile(
                  textColor: Colors.white,
                  leading: snapshot.data![index]['type']! == '103'
                      ? const Icon(Icons.photo, color: Colors.white)
                      : const Icon(Icons.folder, color: Colors.white),
                  title: Text(snapshot.data![index]['text']!),
                  onTap: () {
                    // close(context, snapshot.data![index]);

                    Navigator.pushNamed(
                      context,
                      GalleryScreen.routeName,
                      arguments: {
                        'path': '',
                        'isSearchScreen': true,
                        'searchString': snapshot.data![index]['text']!,
                        'searchType': snapshot.data![index]['type']!
                      },
                    );
                  },
                );
              },
              itemCount: snapshot.data!.length,
            ),
          );
        } else {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    debugLog('buildSuggestions callled$query');

    return FutureBuilder<List<Map<String, String>>>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          debugLog('---------building....');
          return Container(
            // padding: EdgeInsets.only(left: 60),
            color: Colors.black,
            child: ListView.builder(
              //  shrinkWrap: true,
              itemBuilder: (context, index) {
                debugLog(
                    '---------building 2....${snapshot.data![index]['text']!}');
                return ListTile(
                  textColor: Colors.white,
                  leading: snapshot.data![index]['type']! == '103'
                      ? const Icon(
                          Icons.photo,
                          color: Colors.white,
                        )
                      : const Icon(Icons.folder, color: Colors.white),
                  //   title: Text(snapshot.data![index]['text']!),

                  title: SubstringHighlight(
                    text: snapshot.data![index]['text']!,
                    term: query,
                    textStyle: const TextStyle(color: Colors.white),
                    textStyleHighlight: const TextStyle(color: Colors.blue),
                    //   textStyleHighlight: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    // close(context, snapshot.data![index]);

                    Navigator.pushNamed(
                      context,
                      GalleryScreen.routeName,
                      arguments: {
                        'path': '',
                        'isSearchScreen': true,
                        'searchString': snapshot.data![index]['text']!,
                        'searchType': snapshot.data![index]['type']!
                      },
                    );
                  },
                );
              },
              itemCount: snapshot.data!.length,
            ),
          );
        } else {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  @override
  void showSuggestions(BuildContext context) {
    debugLog('show suggestions called..');
  }

  Future<List<Map<String, String>>> _search() async {
    debugLog('search callled');
    return getSuggestions(query);
    //return [];
    // return list.map((e) => ToDo.fromJson(e)).toList();
  }

  Future<List<Map<String, String>>> getSuggestions(String query) async {
    // await Future<void>.delayed(const Duration(seconds: 1));
    if (query.length < 3) {
      return [];
    } else {
      List<Map<String, String>> photos =
          await parentBloc.autocompletePhotos(query);
      debugLog('got photos from search $photos');
      return photos;
    }
  }
}
