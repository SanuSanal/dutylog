import 'package:flutter/material.dart';

class ErrorLoadingDataPage extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onReload;

  const ErrorLoadingDataPage(
      {super.key, required this.errorMessage, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
