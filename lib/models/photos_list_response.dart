import 'package:foto_gallery/network/endpoints.dart';

class Photo {
  String? id;

  String? url;

  String? downloadUrl;

  String? type;

  String? path;

  Photo({this.id, this.url, this.downloadUrl, this.type, this.path});

  factory Photo.fromJson(Map<String, dynamic> json, String token) {
    return Photo(
        /*  id: json['id'] as String?,
      author: json['author'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      url: json['url'] as String?,
      downloadUrl: json['download_url'] as String?, */
        id: json['name'] as String?,
        url: Endpoints.getContentUrl() + Endpoints.thumbpath + json['path'],
        downloadUrl:
            Endpoints.getContentUrl() + Endpoints.rawImagePath + json['path'],
        type: json['isDir'] == true ? 'folder' : json['type'] as String?,
        path: json['path']);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'download_url': downloadUrl,
        'type': type,
        'path': path
      };

  @override
  String toString() {
    return 'id=${id!}, type=${type!}, path=${path!},  downloadUrl=${downloadUrl!}, url=${url!}';
  }

  Photo copyWith(
      {String? id,
      String? url,
      String? downloadUrl,
      String? type,
      String? path}) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      type: type ?? this.type,
      path: path ?? this.path,
    );
  }
}
