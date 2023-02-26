import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  static const String routeName = 'video-screen';
  const VideoScreen({Key? key, required this.title, required this.filePath})
      : super(key: key);

  final String title;
  final String filePath;

  @override
  State<StatefulWidget> createState() {
    return _VideoScreenState();
  }
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _videoPlayerController1;
  ChewieController? _chewieController;
  int? bufferDelay;
  bool canPlayVideo = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController1 =
        VideoPlayerController.network(Uri.encodeFull(widget.filePath));

    await Future.wait([
      _videoPlayerController1.initialize().catchError((Object e) {
        debugLog('-----------------Got error playing video$e');
        setState(() {
          canPlayVideo = false;
          errorMessage = e.toString();
        });
      }),
    ]);
    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController1,
      allowPlaybackSpeedChanging: false,
      autoPlay: true,
      looping: false,
      progressIndicatorDelay:
          bufferDelay != null ? Duration(milliseconds: bufferDelay!) : null,
      hideControlsTimer: const Duration(seconds: 1),
      errorBuilder: (context, errorMessage) {
        debugLog('Error playing video in chewy$errorMessage');
        return createErrorWidget();
      },
    );
  }

  int currPlayIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 10,
          child: const Icon(Icons.close_sharp),
          onPressed: () => Navigator.of(context).pop()),
      body: rootWidget(context),
    );
  }

  Widget rootWidget(BuildContext context) {
    debugLog("video widget filePath ${widget.filePath}");

    return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.down,
        onDismissed: (direction) {
          Navigator.of(context).pop();
        },
        resizeDuration: const Duration(milliseconds: 1),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: canPlayVideo
                    ? _chewieController != null &&
                            _chewieController!
                                .videoPlayerController.value.isInitialized
                        ? Chewie(
                            controller: _chewieController!,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 20),
                              Text('Loading'),
                            ],
                          )
                    : createErrorWidget(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ));
  }

  Widget createErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Cannot play video.',
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
          const Text(
            'Please check the supported video formats that your browser can play.',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 20),
          Text(
            'Error: $errorMessage',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          )
        ],
      ),
    );
  }
}
