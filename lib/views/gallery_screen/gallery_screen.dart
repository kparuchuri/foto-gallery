import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:foto_gallery/blocs/gallery_bloc.dart';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_response.dart';
import 'package:foto_gallery/utils/app_constant.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/views/gallery_screen/photo_searchdelegate.dart';
import 'package:foto_gallery/views/gallery_screen/widgets/gallery_image_box.dart';
import 'package:foto_gallery/views/photo_preview_screen/photo_preview_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/video_screen.dart';
import 'package:foto_gallery/widgets/error.dart';

class GalleryScreen extends StatefulWidget {
  static const String routeName = 'gallery-screen';
  final String path;
  final bool isSearchScreen;
  final String searchStr, searchType;
  const GalleryScreen(
      {super.key,
      this.path = '',
      this.isSearchScreen = false,
      this.searchStr = '',
      this.searchType = ''});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late GalleryBloc _bloc;
  Map hover = {};
  double screenWidth = 0;
  double galleryThumbnailSize = AppConstant.galleryThumbnailSize;
  late ScrollController _scrollController;
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _bloc = GalleryBloc(widget.path, widget.isSearchScreen, widget.searchStr,
        widget.searchType);
    _bloc.getInitialPhotosList();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          if (_scrollController.offset >= 400) {
            _showBackToTopButton = true; // show the back-to-top button
          } else {
            _showBackToTopButton = false; // hide the back-to-top button
          }
        });
      });
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
        floatingActionButton: AnimatedOpacity(
            // If the widget is visible, animate to 0.0 (invisible).
            // If the widget is hidden, animate to 1.0 (fully visible).
            opacity: _showBackToTopButton ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            child: _showBackToTopButton
                ? Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.pinkAccent,
                            width: 4,
                            style: BorderStyle.solid)),
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 25),
                    width: 60,
                    height: 60,
                    child: FloatingActionButton(
                      onPressed: () {
                        _scrollController.animateTo(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.linear);
                      },
                      backgroundColor: const Color.fromRGBO(255, 64, 129, 0.3),
                      foregroundColor: Colors.pinkAccent,
                      child: const Icon(Icons.arrow_drop_up_outlined, size: 40),
                    ))
                : const SizedBox.shrink()),
        body: RefreshIndicator(
          color: Colors.white,
          backgroundColor: Colors.transparent,
          edgeOffset: AppBar().preferredSize.height,
          onRefresh: () async {
            await Future.wait([
              Future.delayed(const Duration(seconds: 1)),
              _bloc.refreshPhotosList()
            ]);
            return;
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                iconTheme: const IconThemeData(
                  color: Colors.grey,
                ),
                pinned: false,
                snap: true,
                floating: true,
                flexibleSpace: appBar(),
              ),
              StreamBuilder<ApiResponse<List<Photo>>>(
                stream: _bloc.photosListStream,
                builder: (context, snapshot) {
                  if (snapshot.data?.status == Status.loading) {
                    return SliverFillRemaining(
                      child: Center(
                        child: showLoader(context),
                      ),
                    );
                  } else if (snapshot.data?.status == Status.completed ||
                      snapshot.data?.status == Status.refreshing) {
                    return _bloc.photoList.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                "No photos yet in this folder.",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          )
                        : photosGridView();
                  } else if (snapshot.data?.status == Status.error) {
                    return SliverFillRemaining(
                        child: Error(
                            errorMessage: snapshot.data?.message,
                            onRetryPressed: () =>
                                _bloc.getInitialPhotosList()));
                  } else {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20))
            ],
          ),
        ));
  }

  Widget photosGridView() {
    return SliverGrid.builder(
      itemCount: _bloc.photoList.length,
      gridDelegate: getGridDelegate(_bloc.photoList),
      itemBuilder: (context, index) {
        return _bloc.photoList[index].type == 'folder'
            ? FolderCard(
                photo: _bloc.photoList[index],
                isSearchScreen: widget.isSearchScreen,
                onTapFn: () {
                  Navigator.pushNamed(
                    context,
                    GalleryScreen.routeName,
                    arguments: {
                      'path': _bloc.photoList[index].path,
                      'isSearchScreen': widget.isSearchScreen,
                      'searchString': '',
                      'searchType': ''
                    },
                  ).then((value) {
                    setState(() {
                      galleryThumbnailSize = AppConstant.galleryThumbnailSize;
                    });
                  });
                },
              )
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
    List<QuiltedGridTile> smallScreenZoomed = const [
      QuiltedGridTile(2, 2),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(1, 1),
      QuiltedGridTile(1, 1),
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
    List<QuiltedGridTile> largeScreenZoomed = const [
      QuiltedGridTile(2, 2),
      QuiltedGridTile(1, 2),
      QuiltedGridTile(2, 2),
      QuiltedGridTile(1, 2),
    ];
    bool isLargeScreen = screenWidth > 1200 ? true : false;
    bool isZoomed = AppConstant.galleryThumbnailSize ==
        AppConstant.galleryThumbnailSizeZoomed;
    return hasOnlyPhotos(_bloc.photoList)
        ? SliverQuiltedGridDelegate(
            crossAxisCount: isLargeScreen
                ? isZoomed
                    ? 6
                    : 10
                : isZoomed
                    ? 4
                    : 6,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            repeatPattern: QuiltedGridRepeatPattern.inverted,
            pattern: isLargeScreen
                ? isZoomed
                    ? largeScreenZoomed
                    : largeScreen
                : isZoomed
                    ? smallScreenZoomed
                    : smallScreen,
          )
        : SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                (MediaQuery.of(context).size.width / galleryThumbnailSize)
                    .round(),
            crossAxisSpacing: AppConstant.galleryCrossAxisSpacing,
            mainAxisSpacing: AppConstant.galleryMainAxisSpacing,
          );
  }

  AppBar appBar() {
    return AppBar(
        iconTheme: const IconThemeData(
          color: Colors.grey,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.grey,
        centerTitle: true,
        actions: [
          Visibility(
            visible:
                galleryThumbnailSize == AppConstant.galleryThumbnailSizeZoomed,
            child: IconButton(
              icon: const Icon(
                Icons.apps_sharp,
                color: Colors.grey,
              ),
              onPressed: () async {
                setState(() {
                  galleryThumbnailSize =
                      AppConstant.galleryThumbnailSizeUnZoomed;
                  AppConstant.galleryThumbnailSize = galleryThumbnailSize;
                });
              },
            ),
          ),
          Visibility(
            visible: galleryThumbnailSize ==
                AppConstant.galleryThumbnailSizeUnZoomed,
            child: IconButton(
              icon: const Icon(
                Icons.grid_view_sharp,
                color: Colors.grey,
              ),
              onPressed: () async {
                setState(() {
                  galleryThumbnailSize = AppConstant.galleryThumbnailSizeZoomed;
                  AppConstant.galleryThumbnailSize = galleryThumbnailSize;
                });
              },
            ),
          ),
          Visibility(
            visible: !widget.isSearchScreen,
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: Colors.grey,
              ),
              onPressed: () async {
                await showSearch<Map<String, String>>(
                  context: context,
                  query: null,
                  delegate: PhotoSearchDelegate(
                    parentBloc: _bloc,
                  ),
                );
                setState(() {
                  galleryThumbnailSize = AppConstant.galleryThumbnailSize;
                });
              },
            ),
          ),
        ],
        title: RawKeyboardListener(
          autofocus: true,
          focusNode: FocusNode(),
          onKey: (event) {
            if (event is RawKeyDownEvent) {
              Object key = event.logicalKey;
              if (key == LogicalKeyboardKey.escape) {
                Navigator.of(context).maybePop();
              }
            }
          },
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: widget.isSearchScreen && widget.path == ''
                ? Text(
                    widget.searchStr,
                    style: const TextStyle(
                      color: Colors.pinkAccent,
                      fontSize: 16.0,
                    ),
                  )
                : widget.path == ''
                    ? const Text(
                        'Foto',
                        style: TextStyle(
                          fontFamily: 'Bellania',
                          color: Colors.pinkAccent,
                          fontSize: 18.0,
                        ),
                      )
                    : Text(
                        cleanupString(widget.path),
                        style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontSize: 16.0,
                        ),
                      ),
          ),
        ));
  }

  Future<List<Map<String, String>>> getSuggestions(String query) async {
    List<Map<String, String>> photos = await _bloc.autocompletePhotos(query);
    debugLog('got photos from search $photos');
    return photos;
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
    required this.isSearchScreen,
    required this.onTapFn,
  });

  final Photo photo;
  final bool isSearchScreen;
  final Function() onTapFn;
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
        onTap: widget.onTapFn,
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
