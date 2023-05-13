import 'dart:convert';
import 'dart:io';
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:foto_gallery/network/endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:foto_gallery/utils/utility.dart';
import 'app_exception.dart';

class ApiBaseHelper {
  static bool isLoggedIn = false;
  String csrfToken = '';

  Future<void> login() async {
    if (isLoggedIn ||
        (Endpoints.pigallery2User == null &&
            Endpoints.pigallery2Password == null)) return;
    String url = Endpoints.getLoginUrl();
    var dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onError: (error, handler) {
      debugLog(error.message!);
      debugLog(error.stackTrace.toString());
      return handler.next(error);
    }, onRequest: (request, handler) {
      debugLog(
          "${request.headers} ${request.method} ${request.uri} ${request.queryParameters} ${request.data.toString()}");
      return handler.next(request);
    }, onResponse: (response, handler) {
      //print(response);
      return handler.next(response);
    }));

    BrowserHttpClientAdapter adapter = BrowserHttpClientAdapter();
    adapter.withCredentials = true;
    dio.httpClientAdapter = adapter;
    try {
      debugLog('calling login for path: $url');
      Map loginCreds = {
        'loginCredential': {
          'username': Endpoints.pigallery2User,
          'password': Endpoints.pigallery2Password,
          'rememberMe': 'true'
        }
      };

      final response = await dio.post(Endpoints.getLoginUrl(),
          options: Options(headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.accessControlAllowOriginHeader: "*,",
            HttpHeaders.accessControlAllowCredentialsHeader: "true",
            //  HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
          }),
          data: json.encode(loginCreds));
/* CORRECT RESPONSE {error: null, result: {id: 1, name: admin, csrfToken: U23EuXKt-4RpnoPIXugprp9nSP1BlwVwLmXU, role: 4, permissions: null}}
 ALREADY AUTHED {error: {code: 2, request: {method: , url: }, detailsStr: ALREADY_AUTHENTICATED}, result: null}
 WRONG CREDENTIALS {error: {code: 5, message: credentials not found during login, request: {method: , url: }}, result: null}
NOT AUTHED {"error":{"code":1,"message":"Not authenticated","request":{"method":"","url":""},"detailsStr":"NOT_AUTHENTICATED"},"result":null}
 */
      int errorCode = -1;

      if (response.data['error'] != null) {
        errorCode = response.data['error']!['code'];
        debugLog('error code is $errorCode');
        debugLog('error code type is ${errorCode.runtimeType}');
        if (errorCode == 1) isLoggedIn = false;
        if (errorCode != -1 && errorCode != 2) {
          throw Exception("Cannot login to PiGallery2: ${response.data}");
        }
      }
      debugLog('got response');
      debugLog(response.data.toString());
      // Map responseJson = response.data;
      //csrfToken = responseJson['result']['csrfToken'];
      //debugLog('csrf is ' + csrfToken);
      //debugLog('headers is ' + response.headers!.toString());
      // debugLog('headers cooke is is ' + response.headers.map['set-cookie']!);
      isLoggedIn = true;
    } on DioError catch (e) {
      debugLog(e.toString());
      if (e.type == DioErrorType.connectionTimeout) {
        throw Exception(
            'Unable to connect to backend server. Please try again');
      }
      if (e.type == DioErrorType.receiveTimeout) {
        throw Exception(
            'Receive timeout from backend server. Please try again');
      }
      rethrow;
    }
  }

  Future<dynamic> get(String url) async {
    PhotoResponse returnResponse;
    try {
      // await refreshToken();
      if (!isLoggedIn) await login();
      debugLog('calling getphotos for path: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'CSRF-Token': csrfToken,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw FetchDataException('Request timeout');
        },
      );
      debugLog('got response');
      returnResponse = PhotoResponse(
          _returnResponse(response), response.statusCode, response.headers);
    } on SocketException {
      throw FetchDataException('No Internet connection');
    }

    return returnResponse;
  }

  dynamic _returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
        return '';
      case 204: // No Content
      case 302: // Found
        return '';
      case 400:
      case 401:
      case 403:
      case 404:
      case 500:
        isLoggedIn = false;
        throw BadRequestException(response.body);
      default:
        throw FetchDataException(
            'Network error. StatusCode : ${response.statusCode}');
    }
  }
}

class PhotoResponse<T> {
  T body;
  int statusCode;
  Map<String, dynamic> headers;

  PhotoResponse(this.body, this.statusCode, this.headers);
}
