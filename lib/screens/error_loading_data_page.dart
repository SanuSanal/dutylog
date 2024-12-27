import 'package:flutter/material.dart';

class ErrorLoadingDataPage extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onReload;

  const ErrorLoadingDataPage(
      {super.key, required this.errorMessage, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: onReload,
                borderRadius: BorderRadius.circular(50),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.red,
                  size: 50.0,
                ),
              ),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_left,
                  color: Colors.grey,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.circle,
                    size: 10.0,
                    color: Colors.grey,
                  ),
                ),
                Icon(
                  Icons.arrow_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
