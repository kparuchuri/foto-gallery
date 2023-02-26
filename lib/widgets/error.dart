import 'package:flutter/material.dart';

class Error extends StatelessWidget {
  final String? errorMessage;
  final Function onRetryPressed;
  const Error({Key? key, this.errorMessage, required this.onRetryPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            style: ButtonStyle(
              side: MaterialStateProperty.all(
                BorderSide(color: Theme.of(context).colorScheme.secondary, width: 1.0, style: BorderStyle.solid),
              ),
              foregroundColor: MaterialStateProperty.all<Color?>(Theme.of(context).colorScheme.secondary),
            ),
            onPressed: () {
              onRetryPressed();
            },
            child: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }
}
