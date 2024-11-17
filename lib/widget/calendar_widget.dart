import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/screens/edit_duty_page.dart';
import 'package:anjus_duties/widget/comment_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatelessWidget {
  final Map<DateTime, String> dayMarkers;
  final List<SheetDutyData> commentList;
  final DateTime focusDate;
  final Future<void> Function({DateTime? focusDay}) fetchData;

  final DateTime _now = DateTime.now();
  late final DateTime lastDayOfPreviousMonth;
  late final DateTime firstDayOfNextMonth;

  CalendarWidget(
      {super.key,
      required this.dayMarkers,
      required this.focusDate,
      required this.fetchData,
      required this.commentList}) {
    DateTime firstDayOfCurrentMonth =
        DateTime(focusDate.year, focusDate.month, 1);
    lastDayOfPreviousMonth =
        firstDayOfCurrentMonth.subtract(const Duration(days: 1));

    firstDayOfNextMonth = (focusDate.month < 12)
        ? DateTime(focusDate.year, focusDate.month + 1, 1)
        : DateTime(focusDate.year + 1, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final Color textAndBorderColor = Colors.grey[900]!;

    return Column(
      children: [
        TableCalendar(
          firstDay: lastDayOfPreviousMonth,
          lastDay: firstDayOfNextMonth,
          focusedDay: focusDate,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: ''},
          calendarStyle: const CalendarStyle(isTodayHighlighted: false),
          onPageChanged: (focusedDay) => fetchData(focusDay: focusedDay),
          onDaySelected: (day, focusDay) async {
            final bool result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditDutyPage(
                  editingDate: day,
                  dutyType: dayMarkers[day] ?? 'O',
                  comment: _getCommentForTheDay(day),
                ),
              ),
            );
            if (result && context.mounted) {
              fetchData(focusDay: focusDay);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duty updated.')),
              );
            }
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              String marker = dayMarkers[date] ?? '';
              bool sameDay = isSameDate(date);
              Color textColor = sameDay ? textAndBorderColor : Colors.black;
              Color borderColor =
                  sameDay ? textAndBorderColor : Colors.transparent;
              Color cellColor;
              switch (marker) {
                case 'D':
                  cellColor = Colors.green;
                  break;
                case 'N':
                  cellColor = Colors.grey;
                  break;
                default:
                  cellColor = Colors.yellow;
                  break;
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(6.0),
                  border: _createBoxBorder(date, borderColor),
                ),
                margin: const EdgeInsets.all(4.0),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: sameDay ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),
        CommentListWidget(commentList: commentList)
      ],
    );
  }

  bool isSameDate(DateTime date) {
    return (date.year == _now.year) &&
        (date.month == _now.month) &&
        (date.day == _now.day);
  }

  _getCommentForTheDay(DateTime day) {
    SheetDutyData foundData = commentList.firstWhere(
      (element) => element.dutyDate == day,
      orElse: () => SheetDutyData(DateTime.now(), 'NA', 'comment'),
    );

    if (foundData.dutyType != 'NA') {
      return foundData.comment;
    } else {
      return '';
    }
  }

  _createBoxBorder(DateTime day, Color borderColor) {
    Color bottomBorderColor =
        _getCommentForTheDay(day) != '' ? Colors.red : borderColor;

    return Border.all(color: bottomBorderColor, width: 3);
  }
}
