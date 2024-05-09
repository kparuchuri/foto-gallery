import 'dart:convert';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_base_helper.dart';
import 'package:foto_gallery/network/endpoints.dart';
import 'package:foto_gallery/utils/utility.dart';

class PhotosRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<PhotoResponse<List<Photo>>> getPhotosList(
      String galleryFolderPath) async {
    List<Photo> photos = [];
    PhotoResponse response;
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
    return PhotoResponse(photos, response.statusCode, response.headers);
  }

  Future<List<Map<String, String>>> autocompletePhotos(String searchStr) async {
    List<Map<String, String>> results = [];
    PhotoResponse response;
    Stopwatch stopwatch = Stopwatch()..start();
    try {
      String url;
      url = Endpoints.getAutocompleteUrl() + searchStr;
      debugLog('******************* calling autocompletePhotos for $url');
      Stopwatch stopwatch1 = Stopwatch()..start();
      response = await _helper.get(url);
      debugLog(
          'autocompletePhotos() rest call  executed in ${stopwatch1.elapsed}');
      debugLog(jsonDecode(utf8.decoder.convert(response.body)).toString());
      debugLog(
          'done calling with autocompletePhotos ${jsonDecode(utf8.decoder.convert(response.body))['result']}');
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
    debugLog('autocompletePhotos() executed in ${stopwatch.elapsed}');
    return results;
  }

  Future<PhotoResponse<List<Photo>>> searchPhotos(
      String photoType, String photoSearchStr) async {
    List<Photo> photos = [];
    PhotoResponse response;
    PhotoResponse<List<Photo>> pResponse;
    Stopwatch stopwatch = Stopwatch()..start();
    try {
      String url;
      url =
          '${Endpoints.getSearchUrl()}{"type":$photoType,"text":"$photoSearchStr","matchType":1}';
      debugLog('******************* calling searchPhotos 2 for $url');
      Stopwatch stopwatch1 = Stopwatch()..start();
      response = await _helper.get(url);
      debugLog('searchPhotos() rest call  executed in ${stopwatch1.elapsed}');

      if (jsonDecode(utf8.decoder.convert(response.body))['result'] != null) {
        Map<String, dynamic> jsonData =
            jsonDecode(utf8.decoder.convert(response.body))['result'];
        debugLog("searchphotos json data $jsonData");
        if (jsonData["searchResult"]["searchQuery"]["type"] == 102) {
          //Directory
          String path = jsonData["searchResult"]["searchQuery"]["text"];
          if (jsonData["map"]["directories"] != null) {
            path = jsonData["map"]["directories"][0]["path"] +
                jsonData["map"]["directories"][0]['name'];
          }
          pResponse = await getPhotosList(path);
        } else {
          //Photo or Video
          photos = decodeSearchResponse(jsonData, url);
          photos = photos
              .where((o) =>
                  o.type == 'image' || o.type == 'video' || o.type == 'folder')
              .toList();
          pResponse =
              PhotoResponse(photos, response.statusCode, response.headers);
        }
      } else {
        pResponse =
            PhotoResponse(photos, response.statusCode, response.headers);
      }
    } on Exception catch (e, stack) {
      debugLog(e.toString());
      debugLog(stack.toString());
      //When folder is empty, its throwing an exception. so just suppress it
      //rethrow;
      return PhotoResponse(photos, 0, {});
    }
    debugLog('searchPhotos() executed in ${stopwatch.elapsed}');
    debugLog('got searchPhotos $photos');
    return pResponse;
  }

  List<Photo> decodeResponse(Map<String, dynamic> jsonData, String url) {
    List<Photo> photos = [];
    List<dynamic> directories = jsonData["directory"]["directories"];
    List<dynamic> media = jsonData["directory"]["media"];
    int length = directories.length;
    for (var i = 0; i < length; i++) {
      Map directory = directories[i];
      Photo photo = Photo(
        id: directory['name'],
        type: 'folder',
        path: directory['path'] + directory['name'],
        downloadUrl: directory['path'] + directory['name'],
        url: directory['cover'] != null
            ? '${Endpoints.getContentUrl() + '/' + directory['cover']['directory']['path'] + '/' + directory['cover']['directory']['name']}/' +
                directory['cover']['name'] +
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
    }
    debugLog('done getting photos ');
    return photos;
  }

  List<Photo> decodeSearchResponse(Map<String, dynamic> jsonData, String url) {
    List<Photo> photos = [];
    debugLog('json data is $jsonData');
    int type = jsonData["searchResult"]["searchQuery"]["type"];
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
      debugLog(
          'decodeSearchResponse returning photo-=---------------- $photos');
    }
    return photos;
  }
}
