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
      // print(response.body.toString());
      //  print('******************* done calling phoeo' +
      //    photoListFromJson(response.body['items']).toString());
      debugLog('done calling');
      // print(jsonDecode(response.body).toString());
      // debugLog('done calling with photos ' +
      // jsonDecode(utf8.decoder.convert(response.body))['result']);
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
    //return photos;
  }

  List<Photo> decodeResponse(Map<String, dynamic> jsonData, String url) {
    List<Photo> photos = [];
    List<dynamic> directories = jsonData["directory"]["directories"];
    List<dynamic> media = jsonData["directory"]["media"];
    debugLog('got dir ');

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
}
