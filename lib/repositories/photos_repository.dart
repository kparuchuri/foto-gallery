import 'dart:convert';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_base_helper.dart';
import 'package:foto_gallery/network/endpoints.dart';
import 'package:foto_gallery/utils/utility.dart';

class PhotosRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<Response<List<Photo>>> getPhotosList(
      String galleryFolderPath, int pageNumber) async {
    List<Photo> photos = [];
    Response response;
    Stopwatch stopwatch = Stopwatch()..start();
    try {
      String url;
      url = galleryFolderPath == ''
          ? Endpoints.getContentUrl()
          : Endpoints.getContentUrl() + galleryFolderPath;
      debugLog('******************* calling photo for $url');
      Stopwatch stopwatch1 = Stopwatch()..start();
      response = await _helper.get(url);
      debugLog('getPhotos() rest call  executed in ${stopwatch1.elapsed}');

      if (jsonDecode(utf8.decoder.convert(response.body))['result'] != null) {
        photos = decodeResponse(
            jsonDecode(utf8.decoder.convert(response.body))['result'], url);

        photos = photos
            .where((o) =>
                o.type == 'image' || o.type == 'video' || o.type == 'folder')
            .toList();
      }
    } on Exception catch (e, stack) {
      debugLog(e.toString());
      debugLog(stack.toString());

      rethrow;
    }
    debugLog('getPhotos() executed in ${stopwatch.elapsed}');
    return Response(photos, response.statusCode, response.headers);
  }

  Future<List<Map<String, String>>> autocompletePhotos(String searchStr) async {
    List<Map<String, String>> results = [];
    Response response;
    Stopwatch stopwatch = Stopwatch()..start();
    try {
      String url;
      url = Endpoints.getAutocompleteUrl() + searchStr;
      debugLog('******************* calling searchPhotos for $url');
      Stopwatch stopwatch1 = Stopwatch()..start();
      response = await _helper.get(url);
      debugLog('searchPhotos() rest call  executed in ${stopwatch1.elapsed}');
      debugLog(jsonDecode(utf8.decoder.convert(response.body)).toString());
      debugLog(
          'done calling with searchPhotos ${jsonDecode(utf8.decoder.convert(response.body))['result']}');
      if (jsonDecode(utf8.decoder.convert(response.body))['result'] != null) {
        List<dynamic> rawResults =
            jsonDecode(utf8.decoder.convert(response.body))['result'];
        for (var i = 0; i < rawResults.length; i++) {
          debugLog(rawResults[i]['text']);
          debugLog(rawResults[i]['type'].toString());
          if (rawResults[i]['type'] == 102 || rawResults[i]['type'] == 103) {
            results.add({
              'text': rawResults[i]['text'],
              'type': rawResults[i]['type'].toString()
            });
          }
        }
      }
    } on Exception catch (e, stack) {
      debugLog(e.toString());
      debugLog(stack.toString());

      rethrow;
    }
    debugLog('getPhotos() executed in ${stopwatch.elapsed}');
    return results;
  }

  Future<Response<List<Photo>>> searchPhotos(String type, String text) async {
    List<Photo> photos = [];

    Response response;
    Stopwatch stopwatch = Stopwatch()..start();

    try {
      String url;
      url =
          '${Endpoints.getSearchUrl()}{"type":$type,"text":"$text","matchType":1}';
      debugLog('******************* calling searchPhotos 2 for $url');
      Stopwatch stopwatch1 = Stopwatch()..start();
      response = await _helper.get(url);
      debugLog('getPhotos() rest call  executed in ${stopwatch1.elapsed}');

      if (jsonDecode(utf8.decoder.convert(response.body))['result'] != null) {
        Map<String, dynamic> jsonData =
            jsonDecode(utf8.decoder.convert(response.body))['result'];
        if (jsonData["searchResult"]["searchQuery"]["type"] == 102) {
          //Directory
          String path = jsonData["searchResult"]["searchQuery"]["text"];
          if (jsonData["map"]["directories"] != null) {
            path = jsonData["map"]["directories"][0]["path"] +
                jsonData["map"]["directories"][0]['name'];
          }
          return getPhotosList(path, 1);
        } else {
          photos = decodeSearchResponse(jsonData, url);

          photos = photos
              .where((o) =>
                  o.type == 'image' || o.type == 'video' || o.type == 'folder')
              .toList();
        }
      }
    } on Exception catch (e, stack) {
      debugLog(e.toString());
      debugLog(stack.toString());

      rethrow;
    }
    debugLog('searchPhotos() executed in ${stopwatch.elapsed}');
    debugLog('got searchPhotos $photos');
    return Response(photos, response.statusCode, response.headers);
  }

  List<Photo> decodeResponse(Map<String, dynamic> jsonData, String url) {
    List<dynamic> directories = jsonData["directory"]["directories"];
    List<dynamic> media = jsonData["directory"]["media"];
    debugLog('got dir ');
    return decodeResponseInternal(url, directories, media);
  }

  List<Photo> decodeResponseInternal(
      String url, List<dynamic> directories, List<dynamic> media) {
    List<Photo> photos = [];
    int length = directories.length;
    for (var i = 0; i < length; i++) {
      Map directory = directories[i];
      debugLog('got dir ');
      Photo photo = Photo(
        id: directory['name'],
        type: 'folder',
        path: directory['path'] + directory['name'],
        downloadUrl: directory['path'] + directory['name'],
        url: directory['preview'] != null
            ? '${Endpoints.getContentUrl() + '/' + directory['preview']['directory']['path'] + '/' + directory['preview']['directory']['name']}/' +
                directory['preview']['name'] +
                Endpoints.thumbpathPostfix
            : directory['path'] + directory['name'],
      );

      photos.add(photo);
    }
    debugLog('got media ');
    for (var mediaFile in media) {
      Photo photo = Photo(
        id: mediaFile['n'],
        type: 'image',
        path: mediaFile['n'],
        url: '${"$url/" + mediaFile['n']}${Endpoints.thumbpathPostfix400}',
        downloadUrl: '${"$url/" + mediaFile['n']}${Endpoints.bestFitPath}',
      );
      if (mediaFile['m']['bitRate'] != null) {
        photo.type = 'video';
      }
      photos.add(photo);
      //  print(photo);
    }
    debugLog('done getting photos ');
    return photos;
  }

  List<Photo> decodeSearchResponse(Map<String, dynamic> jsonData, String url) {
    List<Photo> photos = [];
    debugLog('json data is $jsonData');
    int type = jsonData["searchResult"]["searchQuery"]["type"];
    debugLog('type  is $type');

    if (type == 103) //media file
    {
      String fileName = jsonData["searchResult"]["media"][0]["n"];

      String path = jsonData["map"]["directories"][0]["path"] +
          jsonData["map"]["directories"][0]['name'];
      Photo photo = Photo(
        id: fileName,
        type: 'image',
        path: fileName,
        url:
            '${Endpoints.getContentUrl()}/$path/$fileName${Endpoints.bestFitPath}',
        downloadUrl:
            '${Endpoints.getContentUrl()}/$path/$fileName${Endpoints.bestFitPath}',
      );

      debugLog('type 2 is $type');
      if (jsonData["searchResult"]["media"][0]['m']['bitRate'] != null) {
        photo.type = 'video';
      }
      photos.add(photo);
      debugLog('returning photo-=---------------- $photos');
    }
    return photos;
  }
}
