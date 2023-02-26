import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foto_gallery/blocs/photo_preview_bloc.dart';
import 'package:foto_gallery/models/photos_list_response.dart';
import 'package:foto_gallery/network/api_response.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/widgets/loader_dialog.dart';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';

class PhotoPreviewScreen extends StatefulWidget {
  static const String routeName = '/photo-preview-screen';

  final PhotoPreviewScreenArgs args;

  const PhotoPreviewScreen({Key? key, required this.args}) : super(key: key);

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  late List<Photo> photoList;
  late int initialIndex;
  Timer? autoPlayTimer;
  bool showAutoPlayButton = false;
  final PhotoPreviewBloc _bloc = PhotoPreviewBloc();
  bool showNavButton = false;
  bool showPlayButton = true;
  late final int totalPages;
  final MyCarouselControllerImpl _controller = MyCarouselControllerImpl();
  final transformationController = TransformationController();

  bool get userHasZoomedIn =>
      (Matrix4.identity() - transformationController.value).infinityNorm() >
      0.000001;

  _PhotoPreviewScreenState();
  @override
  void initState() {
    super.initState();
    initialIndex = widget.args.index;
    photoList = widget.args.photoList;
    _controller.setCurrentPage(initialIndex);
    totalPages = photoList.length;
    _bloc.loaderStream.listen((event) {
      if (event.status == Status.loading) {
        DialogBuilder(context).showLoader();
      } else if (event.status == Status.completed) {
        DialogBuilder(context).hideLoader();
        showSnackBar(context, event.data);
      } else if (event.status == Status.error) {
        DialogBuilder(context).hideLoader();
        showSnackBar(context, event.message, true);
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showPlayButton = false; // <-- Code run after delay
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugLog('----------dependencies changed');
    precacheNextImage(initialIndex + 1);
  }

  void precacheNextImage(int photoIndex) {
    if (photoIndex < totalPages) {
      precacheImage(
              CachedNetworkImageProvider(photoList[photoIndex].type == 'image'
                  ? photoList[photoIndex].downloadUrl ?? ''
                  : photoList[photoIndex].url ?? ''),
              context)
          .then((value) =>
              debugLog('cached next image  ${photoList[photoIndex].id!}'));
    }
  }

  void gotoNextPage() {
    int currPage = _controller.getCurrentPage();
    debugLog("current page is $currPage");
    if (currPage == totalPages - 1) {
      debugLog('reached end of list');
      setState(() {
        showAutoPlayButton = false; // <-- Code run after delay
      });
    } else {
      _controller.nextPage();
    }
  }

  void gotoPrevPage() {
    int currPage = _controller.getCurrentPage();
    debugLog("current page is $currPage");
    if (currPage == 0) {
      debugLog('reached beginning of list');
    } else {
      _controller.previousPage();
    }
  }

  @override
  void dispose() {
    autoPlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 10,
          child: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop()),
      body: photoView(),
    );
  }

  Widget photoView() {
    final double pageHeight = MediaQuery.of(context).size.height;
    debugLog('painting photoView widet');
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          Object key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowRight) {
            debugLog('*********** key right pressed ');
            setState(() {
              showPlayButton = true;
            });
            gotoNextPage();
          } else if (key == LogicalKeyboardKey.arrowLeft) {
            debugLog('*********** key left pressed ');
            setState(() {
              showPlayButton = true;
            });
            gotoPrevPage();
          } else if (key == LogicalKeyboardKey.escape) {
            debugLog('*********** escape  pressed  on title');
            Navigator.of(context).maybePop();
          }
        }
      },
      child: MouseRegion(
          onEnter: (_) => setState(() {
                showPlayButton = true;
                showNavButton = true;
              }),
          onExit: (_) => setState(() {
                showNavButton = false;
                showPlayButton = false;
                debugLog('hiding play button');
              }),
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(
              onTap: () {
                debugLog('someone tapped on photo');
                setState(() {
                  showPlayButton = true;
                });
                Future.delayed(const Duration(seconds: 3), () {
                  setState(() {
                    showPlayButton = false;
                  });
                });
              },
              child: userHasZoomedIn
                  ? getInteractiveViewer(_controller.getCurrentPage())
                  : CarouselSlider.builder(
                      disableGesture: true,
                      carouselController: _controller,
                      itemCount: photoList.length,
                      options: CarouselOptions(
                        scrollPhysics: const BouncingScrollPhysics(),
                        disableCenter: true,
                        enlargeStrategy: CenterPageEnlargeStrategy.height,
                        onPageChanged: (index, reason) {
                          debugLog('page changed $index');
                          _controller.setCurrentPage(index);
                          setState(() {
                            if (index == totalPages - 1) {
                              showAutoPlayButton = false;
                            } else {
                              precacheNextImage(index + 1);
                            }
                          });
                        },
                        height: pageHeight,
                        enableInfiniteScroll: false,
                        viewportFraction: 1,
                        enlargeCenterPage: true,
                        initialPage: _controller.getCurrentPage(),
                      ),
                      itemBuilder: (ctx, index, realIdx) {
                        return Dismissible(
                            key: UniqueKey(),
                            direction: DismissDirection.down,
                            onDismissed: (direction) {
                              Navigator.of(context).pop();
                            },
                            resizeDuration: const Duration(milliseconds: 1),
                            child: getInteractiveViewer(index));
                      },
                    ),
            ),
            Visibility(
              visible: showNavButton &&
                  !userHasZoomedIn &&
                  _controller.getCurrentPage() != 0,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: IconButton(
                  color: Colors.white,
                  iconSize: 40,
                  icon: const Icon(
                    Icons.keyboard_arrow_left_rounded,
                  ),
                  onPressed: () {
                    gotoPrevPage();
                  },
                ),
              ),
            ),
            Visibility(
              visible: showPlayButton && !userHasZoomedIn,
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: IconButton(
                        iconSize: 40,
                        icon: showAutoPlayButton
                            ? const Icon(
                                Icons.pause_circle_filled_outlined,
                                color: Colors.white,
                              )
                            : const Icon(
                                Icons.play_circle_filled_outlined,
                                color: Colors.white,
                              ),
                        onPressed: () {
                          debugLog('play payuse button pressed');
                          if (!showAutoPlayButton) {
                            setState(() {
                              showAutoPlayButton = true;
                            });
                            autoPlayTimer = Timer.periodic(
                                const Duration(seconds: 3), (Timer t) {
                              debugLog('running autoplay');
                              if (showAutoPlayButton && mounted) {
                                gotoNextPage();
                              } else {
                                t.cancel();
                                debugLog('stopped autoplay');
                              }
                            });
                          } else {
                            autoPlayTimer?.cancel();
                            setState(() {
                              showAutoPlayButton = false;
                            });
                            debugLog('stopped autoplay');
                          }
                        }),
                  )),
            ),
            Visibility(
                visible: showNavButton &&
                    !userHasZoomedIn &&
                    _controller.getCurrentPage() != totalPages - 1,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    color: Colors.white,
                    iconSize: 40,
                    icon: const Icon(
                      Icons.keyboard_arrow_right_rounded,
                    ),
                    onPressed: () {
                      gotoNextPage();
                    },
                  ),
                ))
          ])),
    );
  }

  Widget getInteractiveViewer(int index) {
    return InteractiveViewer(
      panEnabled: !showAutoPlayButton,
      scaleEnabled: !showAutoPlayButton,
      minScale: 0.5,
      maxScale: 5,
      transformationController: transformationController,
      onInteractionEnd: (details) => setState(() {}),
      child: CachedNetworkImage(
          placeholderFadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => const Center(
                child: FotoProgressIndicator(),
              ),
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: const Duration(milliseconds: 100),
          memCacheWidth: 2048,
          fit: BoxFit.contain,
          imageUrl: photoList[index].type == 'image'
              ? photoList[index].downloadUrl ?? ''
              : photoList[index].url ?? ''),
    );
  }
}

class FotoProgressIndicator extends StatelessWidget {
  const FotoProgressIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 1000)),
        builder: (c, s) => s.connectionState == ConnectionState.done
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : const SizedBox());
  }
}

class PhotoPreviewScreenArgs {
  List<Photo> photoList;
  int index;

  PhotoPreviewScreenArgs({required this.photoList, required this.index});
}

class MyCarouselControllerImpl extends CarouselControllerImpl {
  int currentPage = 0;
  void setCurrentPage(int currPage) {
    currentPage = currPage;
  }

  int getCurrentPage() {
    return currentPage;
  }
}
