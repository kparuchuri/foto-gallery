import 'dart:async';

import 'package:foto_gallery/blocs/base_bloc.dart';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_base_helper.dart';
import 'package:foto_gallery/network/api_response.dart';
import 'package:foto_gallery/repositories/photos_repository.dart';
import 'package:foto_gallery/utils/utility.dart';

class GalleryBloc extends BaseBloc {
  final PhotosRepository _repo = PhotosRepository();
  final StreamController<ApiResponse<List<Photo>>> _scPhotosList =
      StreamController<ApiResponse<List<Photo>>>();

  StreamSink<ApiResponse<List<Photo>>> get photosListSink => _scPhotosList.sink;
  Stream<ApiResponse<List<Photo>>> get photosListStream => _scPhotosList.stream;

  final List<Photo> _photoList = [];

  List<Photo> get photoList => _photoList;

  String galleryFolderPath = '';
  bool isSearchScreen = false;
  String searchStr = '', searchType = '';

  GalleryBloc(this.galleryFolderPath, this.isSearchScreen, this.searchStr,
      this.searchType);

  Future<void> getInitialPhotosList() async {
    photosListSink.add(ApiResponse.loading());
    await _getPhotoList(photosListSink);
  }

  Future<void> refreshPhotosList() async {
    photosListSink.add(ApiResponse.refreshing());
    await _getPhotoList(photosListSink);
  }

  Future<List<Map<String, String>>> autocompletePhotos(String searchStr) async {
    List<Map<String, String>> results =
        await _repo.autocompletePhotos(searchStr);
    return results;
  }

  Future<void> _getPhotoList(StreamSink<ApiResponse<List<Photo>>> sink) async {
    debugLog('----------getting photo list');
    try {
      final PhotoResponse<List<Photo>> response =
          isSearchScreen && galleryFolderPath == ''
              ? await _repo.searchPhotos(searchType, searchStr)
              : await _repo.getPhotosList(galleryFolderPath);
      _photoList.clear();
      _photoList.addAll(response.body);
      sink.add(ApiResponse.completed(null));
    } catch (e) {
      sink.add(ApiResponse.error(e.toString()));
    }
  }

  Future<List<Photo>> searchPhotos(String text, String type) async {
    debugLog('----------searching photo ');
    List<Photo> photos = [];
    try {
      final PhotoResponse<List<Photo>> response =
          await _repo.searchPhotos(type, text);
      photos = response.body;
    } catch (e) {
      debugLog(e.toString());
    }
    return photos;
  }

  @override
  void dispose() {
    _scPhotosList.close();
  }
}
