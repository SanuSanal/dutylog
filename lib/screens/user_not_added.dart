import 'package:flutter/material.dart';

class UserNotAdded extends StatelessWidget {
  const UserNotAdded({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/training.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double topPadding = constraints.maxHeight / 3;

          return Stack(
            children: [
              Positioned(
                top: topPadding,
                right: 16.0,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'User not added',
                      style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Please add a user to continue',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // child: const Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Text(
      //         'User not added',
      //         style: TextStyle(
      //           fontSize: 21,
      //           fontWeight: FontWeight.bold,
      //         ),
      //       ),
      //       SizedBox(height: 8.0),
      //       Text(
      //         'Please add a user to continue',
      //         style: TextStyle(
      //           fontSize: 16,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
