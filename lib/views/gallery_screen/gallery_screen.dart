import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:foto_gallery/blocs/gallery_bloc.dart';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_response.dart';
import 'package:foto_gallery/utils/app_constant.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/views/gallery_screen/widgets/gallery_image_box.dart';
import 'package:foto_gallery/views/photo_preview_screen/photo_preview_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/video_screen.dart';
import 'package:foto_gallery/widgets/error.dart';

// ignore: must_be_immutable
class GalleryScreen extends StatefulWidget {
  static const String routeName = 'gallery-screen';
  String path;
  GalleryScreen({super.key, this.path = ''});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  GalleryBloc _bloc = GalleryBloc('/');
  Map hover = {};
  double screenWidth = 0;
  @override
  void initState() {
    super.initState();
    _bloc = GalleryBloc(widget.path);
    _bloc.requestNextPageStream.listen((event) {
      if (event.status == Status.loading) {
      } else if (event.status == Status.completed) {
        setState(() {});
      } else if (event.status == Status.error) {
        showSnackBar(context, event.message, true);
      }
    });
    _bloc.getInitialPhotosList();
  }

  @override
  void dispose() {
    super.dispose();
    _bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: appBar(),
      body: rootWidget(),
      bottomNavigationBar: const SizedBox(height: 20),
    );
  }

  Widget rootWidget() {
    return StreamBuilder<ApiResponse<List<Photo>>>(
      stream: _bloc.photosListStream,
      builder: (context, snapshot) {
        if (snapshot.data?.status == Status.loading) {
          return Center(
            child: showLoader(context),
          );
        } else if (snapshot.data?.status == Status.completed) {
          return photosGridView();
        } else if (snapshot.data?.status == Status.error) {
          return Error(
              errorMessage: snapshot.data?.message,
              onRetryPressed: () => _bloc.getInitialPhotosList());
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget photosGridView() {
    //debugLog('photoliust is ${_bloc.photoList}');
    return _bloc.photoList.isEmpty
        ? const Center(
            child: Text(
            "No photos yet in this folder.",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ))
        : RefreshIndicator(
            onRefresh: () async {
              _bloc.getInitialPhotosList();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _bloc.scrollController,
              itemBuilder: (context, index) {
                return _bloc.photoList[index].type == 'folder'
                    ? FolderCard(photo: _bloc.photoList[index])
                    : _bloc.photoList[index].type == 'video'
                        ? PhotoVideoCard(
                            onTapFn: () {
                              Navigator.pushNamed(
                                context,
                                VideoScreen.routeName,
                                arguments: {
                                  'title': _bloc.photoList[index].id,
                                  'filePath': _bloc.photoList[index].downloadUrl
                                },
                              );
                            },
                            childWidget: GridTile(
                              footer: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.withOpacity(.5),
                                child: Center(
                                  child: Text(
                                    trimExtension(_bloc.photoList[index].id!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              child: Stack(fit: StackFit.expand, children: [
                                GalleryImageBox(photo: _bloc.photoList[index]),
                                const Icon(Icons.play_circle_outline_sharp,
                                    color: Colors.white, size: 40),
                              ]),
                            ))
                        : PhotoVideoCard(
                            onTapFn: () {
                              Navigator.pushNamed(
                                context,
                                PhotoPreviewScreen.routeName,
                                arguments: PhotoPreviewScreenArgs(
                                  photoList: _bloc.photoList,
                                  index: index,
                                ),
                              );
                            },
                            childWidget:
                                GalleryImageBox(photo: _bloc.photoList[index]));
              },
              itemCount: _bloc.photoList.length,
              gridDelegate: getGridDelegate(_bloc.photoList),
              scrollDirection: Axis.vertical,
            ),
          );
  }

  String trimExtension(String fileName) {
    return fileName.substring(0, fileName.lastIndexOf('.'));
  }

  SliverGridDelegate getGridDelegate(List<Photo> photoList) {
    List<QuiltedGridTile> smallScreen = const [
      QuiltedGridTile(2, 2),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1)
    ];
    List<QuiltedGridTile> largeScreen = const [
      QuiltedGridTile(2, 2),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(2, 2),
      QuiltedGridTile(2, 1),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1),
    ];

    bool isLargeScreen = screenWidth > 1200 ? true : false;
    return hasOnlyPhotos(_bloc.photoList)
        ? SliverQuiltedGridDelegate(
            crossAxisCount: isLargeScreen ? 10 : 6,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            repeatPattern: QuiltedGridRepeatPattern.inverted,
            pattern: isLargeScreen ? largeScreen : smallScreen,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width /
                    AppConstant.galleryThumbnailSize)
                .round(),
            crossAxisSpacing: AppConstant.galleryCrossAxisSpacing,
            mainAxisSpacing: AppConstant.galleryMainAxisSpacing,
          );
  }

  AppBar appBar() {
    return AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: RawKeyboardListener(
          autofocus: true,
          focusNode: FocusNode(),
          onKey: (event) {
            if (event is RawKeyDownEvent) {
              Object key = event.logicalKey;
              if (key == LogicalKeyboardKey.escape) {
                debugLog('*********** escape  pressed  on title');
                Navigator.of(context).maybePop();
              }
            }
          },
          child: widget.path == ''
              ? const Text(
                  'Foto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Bellania',
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                )
              : Text(
                  cleanupString(widget.path),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
        ));
  }

  String cleanupString(String path) {
    String cleanedupPath = path.replaceFirst('./', '');
    if (path.length > 2225) {
      cleanedupPath =
          '...${cleanedupPath.substring(widget.path.length - 25, widget.path.length)}';
    }
    return cleanedupPath;
  }

  filterImages(List<Photo> photoList) {
    List outputList =
        photoList.where((photo) => photo.type == 'image').toList();
    return outputList.reversed.toList();
  }

  hasOnlyPhotos(List<Photo> photoList) {
    bool hasOnlyPhotos = true;
    for (int i = 0; i < photoList.length; ++i) {
      if (photoList[i].type != 'image') {
        hasOnlyPhotos = false;
        break;
      }
    }
    return hasOnlyPhotos;
  }
}

class FolderCard extends StatefulWidget {
  const FolderCard({
    super.key,
    required this.photo,
  });

  final Photo photo;

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
        onHover: (value) {
          setState(() {
            isHover = value;
          });
        },
        onTap: () {
          Navigator.pushNamed(
            context,
            GalleryScreen.routeName,
            arguments: widget.photo.path,
          );
        },
        child: GridTile(
            footer: Container(
              decoration: BoxDecoration(
                color: isHover
                    ? Colors.grey.withOpacity(.9)
                    : Colors.grey.withOpacity(.5),
              ),
              padding: const EdgeInsets.all(8),
              //color: Colors.grey.withOpacity(.5),
              child: Center(
                child: Text(
                  widget.photo.id!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            child: GalleryImageBox(
              photo: widget.photo,
              isHover: isHover,
            )));
  }
}

class PhotoVideoCard extends StatelessWidget {
  const PhotoVideoCard({
    super.key,
    required this.childWidget,
    required this.onTapFn,
  });

  final Widget childWidget;
  final Function() onTapFn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapFn,
      child: childWidget,
    );
  }
}
