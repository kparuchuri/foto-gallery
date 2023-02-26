import 'package:flutter/material.dart';

class DialogBuilder {
  DialogBuilder(this.context);

  final BuildContext context;
  static bool _isVisible = false;

  void showLoader() {
    if (_isVisible) {
      return;
    } else {
      _isVisible = true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const LoadingIndicator(),
        );
      },
    ).then((value) {
      _isVisible = false;
    });
  }

  void hideLoader() {
    if (_isVisible) Navigator.of(context).pop();
  }

  bool isVisible() => _isVisible;
}

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getLoadingIndicator(),
            _getHeader(),
          ],
        ),
      ),
    );
  }

  Widget _getLoadingIndicator() {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _getHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: Text(
        'Please wait',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
