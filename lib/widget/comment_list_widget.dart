import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/widget/comment_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentListWidget extends StatelessWidget {
  final List<SheetDutyData> commentList;

  const CommentListWidget({super.key, required this.commentList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16.0),
      itemCount: commentList.length,
      itemBuilder: (context, index) {
        final SheetDutyData commentData = commentList[index];
        int date = commentData.dutyDate.day;
        String weekdayString = DateFormat('EEEE').format(commentData.dutyDate);
        return Column(
          children: [
            CommentCard(
              day: date,
              weekday: weekdayString,
              comment: commentData.comment,
            ),
            const SizedBox(height: 16.0),
          ],
        );
      },
    );
  }
}
