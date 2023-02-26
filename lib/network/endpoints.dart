import 'dart:html' as html;

class Endpoints {
  static String baseUrl =
      "http://${html.window.location.hostname!}:${html.window.location.port}/";
  static String getContentUrl() {
    return '$baseUrl/pgapi/gallery/content/';
  }

  static String getLoginUrl() {
    return '$baseUrl/pgapi/user/login';
  }

  static String? pigallery2User;
  static String? pigallery2Password;

  static const String thumbpath = "/api/preview/thumb/";

  static const String thumbpathPostfix = "/thumbnail/240";
  static const String thumbpathPostfix400 = "/thumbnail/400";
  static const String previewpath = "/api/preview/big/";
  static const String rawImagePath = "/api/raw/";
  static const String bestFitPath = "/bestfit";
}
