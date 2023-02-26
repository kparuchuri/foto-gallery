import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/utils/app_constant.dart';

class GalleryImageBox extends StatelessWidget {
  const GalleryImageBox({
    Key? key,
    required this.photo,
    this.isHover = false,
  }) : super(key: key);

  final Photo photo;
  final bool isHover;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      color: Colors.white,
      colorBlendMode: isHover ? BlendMode.softLight : BlendMode.darken,
      errorWidget: (context, url, error) => Image.asset(
        'assets/images/placeholder_folder.png',
        fit: BoxFit.cover,
      ),
      placeholder: (context, url) => Image.asset(
        'assets/images/placeholder_folder.png',
        fit: BoxFit.contain,
      ),
      imageUrl: photo.url!,
      fit: BoxFit.cover,
      height: AppConstant.galleryThumbnailSize,
      width: AppConstant.galleryThumbnailSize,
    );
  }
}
