import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final int day;
  final String weekday;
  final String comment;

  const CommentCard(
      {super.key,
      required this.day,
      required this.weekday,
      required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Aligns children at the start of the row
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns column children at the start
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                weekday,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12.0), // Space between date/weekday and comment
          Expanded(
            child: Text(
              comment,
              style: const TextStyle(
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis, // Handle long comments
            ),
          ),
        ],
      ),
    );
  }
}
