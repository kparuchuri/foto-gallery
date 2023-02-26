import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foto_gallery/network/endpoints.dart';
import 'package:foto_gallery/utils/styles.dart';
import 'package:foto_gallery/utils/utility.dart';
import 'package:foto_gallery/views/gallery_screen/gallery_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/photo_preview_screen.dart';
import 'package:foto_gallery/views/photo_preview_screen/video_screen.dart';
import 'package:foto_gallery/views/splash_screen/splash_screen.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.grey[900],
  ));
  String settingsFile = const String.fromEnvironment('FOTO_SETTINGS_FILE',
      defaultValue: 'foto_settings.json');
  debugLog('--settings file in environment variable is $settingsFile');

  //Load env variables
  final contents = await rootBundle
      .loadString(settingsFile, cache: false)
      .onError((error, stackTrace) {
    debugLog('Cannot find $settingsFile, assuming defaults.');
    return '';
  });
  try {
    if (contents != '') {
      final json = jsonDecode(contents);
      //The url will be redundent as CORS won't allow calling a remote URL. This can be used only while dev
      if (json['pigallery2_baseurl'] != null) {
        Endpoints.baseUrl = json['pigallery2_baseurl'];
        debugLog(
            'setting baseurl from  foto_settings.json, to ${Endpoints.baseUrl}');
      }
      if (json['pigallery2_user'] != null && json['pigallery2_user'] != '') {
        Endpoints.pigallery2User = json['pigallery2_user'];
        //  debugLog('setting pigallery2User from  foto_settings.json, to ' +
        //     Endpoints.pigallery2User!);
      }
      if (json['pigallery2_password'] != null &&
          json['pigallery2_password'] != '') {
        Endpoints.pigallery2Password = json['pigallery2_password'];
        //  debugLog('setting pigallery2Password from  foto_settings.json, to ' +
        //      Endpoints.pigallery2Password!);
      }
    }
  } catch (e) {
    debugLog(e.toString());
  }
  runApp(const PhotoGallery());
}

class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foto',
      theme: Styles.darkTheme(),
      routes: {
        '/': (context) => const SplashScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case PhotoPreviewScreen.routeName:
            {
              final args = settings.arguments as PhotoPreviewScreenArgs;
              return MaterialPageRoute(
                builder: (context) {
                  return PhotoPreviewScreen(args: args);
                },
              );
            }
          case GalleryScreen.routeName:
            {
              final path = settings.arguments == null
                  ? ''
                  : settings.arguments as String;
              return SwipeablePageRoute(
                builder: (context) {
                  return GalleryScreen(path: path);
                },
              );
            }
          case VideoScreen.routeName:
            {
              String title = '';
              String filePath = '';

              final Map arguments = settings.arguments as Map;

              title = arguments['title']!;
              filePath = arguments['filePath'];

              return SwipeablePageRoute(
                builder: (context) {
                  return VideoScreen(title: title, filePath: filePath);
                },
              );
            }
          default:
            {
              assert(false, 'Need to implement ${settings.name}');
              return null;
            }
        }
      },
    );
  }
}
