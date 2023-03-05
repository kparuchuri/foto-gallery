import 'dart:async';

import 'package:flutter/material.dart';
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
  final StreamController<ApiResponse<List<Photo>>> _scRequestNextPage =
      StreamController<ApiResponse<List<Photo>>>();

  StreamSink<ApiResponse<List<Photo>>> get photosListSink => _scPhotosList.sink;
  Stream<ApiResponse<List<Photo>>> get photosListStream => _scPhotosList.stream;

  StreamSink<ApiResponse<List<Photo>>> get requestNextPageSink =>
      _scRequestNextPage.sink;
  Stream<ApiResponse<List<Photo>>> get requestNextPageStream =>
      _scRequestNextPage.stream;

  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;

  final List<Photo> _photoList = [];

  List<Photo> get photoList => _photoList;

  int pageNumber = 1;
  bool hasNextPage = true;
  String galleryFolderPath = '';
  bool isSearchScreen = false;
  String searchStr = '', searchType = '';

  GalleryBloc(this.galleryFolderPath, this.isSearchScreen, this.searchStr,
      this.searchType) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !_scrollController.position.outOfRange &&
          hasNextPage) {
        requestNextPage();
      }
    });
  }

  Future<void> getPhotoList(StreamSink<ApiResponse<List<Photo>>> sink,
      [bool checkDB = false]) async {
    debugLog('----------getting photo list');
    try {
      final Response<List<Photo>> response = isSearchScreen
          ? await _repo.searchPhotos(searchType, searchStr)
          : await _repo.getPhotosList(galleryFolderPath, pageNumber);

      if (response.headers['link'].toString().contains('rel="next"')) {
        hasNextPage = true;
        pageNumber++;
      } else {
        hasNextPage = false;
      }
      _photoList.clear();
      _photoList.addAll(response.body);
      sink.add(ApiResponse.completed(null));
    } catch (e) {
      sink.add(ApiResponse.error(e.toString()));
    }
  }

  Future<List<Photo>> getSearchPhotos(String text, String type) async {
    debugLog('----------getting photo ');
    List<Photo> photos = [];
    try {
      final Response<List<Photo>> response =
          await _repo.searchPhotos(type, text);
      photos = response.body;
    } catch (e) {
      debugLog(e.toString());
    }
    return photos;
  }

  void getInitialPhotosList() async {
    photosListSink.add(ApiResponse.loading());
    await getPhotoList(photosListSink);
  }

  void refreshPhotosList() async {
    photosListSink.add(ApiResponse.refreshing());
    await getPhotoList(photosListSink);
  }

  Future<List<Map<String, String>>> autocompletePhotos(String searchStr) async {
    List<Map<String, String>> results =
        await _repo.autocompletePhotos(searchStr);
    return results;
  }

  void requestNextPage() async {
    requestNextPageSink.add(ApiResponse.loading());
    await getPhotoList(requestNextPageSink);
  }

  @override
  void dispose() {
    _scPhotosList.close();
    _scRequestNextPage.close();
    _scrollController.dispose();
  }
}
