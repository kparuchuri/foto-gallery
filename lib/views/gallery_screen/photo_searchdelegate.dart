import 'package:flutter/material.dart';
import 'package:foto_gallery/blocs/gallery_bloc.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/views/gallery_screen/gallery_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/photo_preview_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/video_screen.dart';
import 'package:substring_highlight/substring_highlight.dart';

class PhotoSearchDelegate extends SearchDelegate<Map<String, String>> {
  GalleryBloc parentBloc;

  PhotoSearchDelegate({
    required this.parentBloc,
  }) : super(searchFieldLabel: '  Search for photos or folders..');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          backgroundColor: Colors.black,
          cardColor: Colors.black),
      hintColor: Colors.grey,
      primaryColor: Colors.white,
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.grey),
      textTheme: const TextTheme(
          titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold)),
      appBarTheme: const AppBarTheme(
        color: Colors.black, // affects AppBar's background color
        foregroundColor: Colors.white,
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
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    debugLog('buildSuggestions callled$query');

    return FutureBuilder<List<Map<String, String>>>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Container(
            // padding: EdgeInsets.only(left: 60),
            color: Colors.black,
            child: ListView.builder(
              //  shrinkWrap: true,
              itemBuilder: (context, index) {
                return ListTile(
                  textColor: Colors.white,
                  leading: snapshot.data![index]['type']! == '103'
                      ? const Icon(
                          Icons.photo,
                          color: Colors.white,
                        )
                      : const Icon(Icons.folder, color: Colors.white),
                  title: SubstringHighlight(
                    text: snapshot.data![index]['text']!,
                    term: query,
                    textStyle: const TextStyle(color: Colors.white),
                    textStyleHighlight: const TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    if (snapshot.data![index]['type']! == '103') {
                      //Photo
                      parentBloc
                          .getSearchPhotos(snapshot.data![index]['text']!,
                              snapshot.data![index]['type']!)
                          .then((photos) {
                        if (photos[0].type == 'video') {
                          Navigator.pushNamed(
                            context,
                            VideoScreen.routeName,
                            arguments: {
                              'title': photos[0].id,
                              'filePath': photos[0].downloadUrl
                            },
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            PhotoPreviewScreen.routeName,
                            arguments: PhotoPreviewScreenArgs(
                              photoList: photos,
                              index: 0,
                            ),
                          );
                        }
                      });
                    } else {
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
                    }
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

  Future<List<Map<String, String>>> _search() async {
    debugLog('search callled');
    return getSuggestions(query);
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
