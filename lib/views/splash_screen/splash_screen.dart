import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foto_gallery/views/gallery_screen/gallery_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(164, 220, 87, 98),
                  Color.fromARGB(198, 205, 19, 96),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Foto',
                  style: TextStyle(
                    fontFamily: 'Bellania',
                    color: Colors.white,
                    fontSize: 24.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void initializeApp() {
    Navigator.pushReplacementNamed(
      context,
      GalleryScreen.routeName,
      arguments: {
        'path': '',
        'isSearchScreen': false,
        'searchString': '',
        'searchType': ''
      },
    );
  }
}
