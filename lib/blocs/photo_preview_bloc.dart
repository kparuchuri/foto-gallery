import 'dart:async';

import 'package:foto_gallery/blocs/base_bloc.dart';
import 'package:foto_gallery/network/api_response.dart';

class PhotoPreviewBloc extends BaseBloc {
  final StreamController<ApiResponse<dynamic>> _scLoader =
      StreamController<ApiResponse<dynamic>>();

  StreamSink<ApiResponse<dynamic>> get loaderSink => _scLoader.sink;
  Stream<ApiResponse<dynamic>> get loaderStream => _scLoader.stream;

  @override
  void dispose() {
    _scLoader.close();
  }
}
