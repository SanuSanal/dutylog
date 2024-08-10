import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DutyCalendarPage extends StatefulWidget {
  const DutyCalendarPage({super.key});

  @override
  DutyCalendarPageState createState() => DutyCalendarPageState();
}

class DutyCalendarPageState extends State<DutyCalendarPage> {
  bool _isLoading = true;
  GoogleSheetApi sheetApi = GoogleSheetApi();
  late Map<DateTime, String> _dayMarkers;

  final DateTime _now = DateTime.now();
  DateTime _focusDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({DateTime? focusDay}) async {
    focusDay ??= DateTime.now();

    setState(() {
      _isLoading = true;
    });

    DateFormat formatter = DateFormat('MMM_yyyy');
    Map<DateTime, String> dayMarkers =
        await sheetApi.fetchSheetDataApiCall(formatter.format(focusDay));

    setState(() {
      _focusDate = focusDay!;
      _dayMarkers = dayMarkers;
      _isLoading = false;
      if (_dayMarkers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duty not added.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textAndBorderColor = Colors.grey[900]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty calendar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend('Day duty', Colors.green),
                _buildLegend('Night duty', Colors.grey),
                _buildLegend('Off day', Colors.yellow),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TableCalendar(
                    firstDay: DateTime.utc(2024, 7, 1),
                    lastDay: DateTime.utc(2034, 7, 1),
                    focusedDay: _focusDate,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {CalendarFormat.month: ''},
                    calendarStyle:
                        const CalendarStyle(isTodayHighlighted: false),
                    onPageChanged: (focusedDay) {
                      _fetchData(focusDay: focusedDay);
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        String marker = _dayMarkers[date] ?? '';
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
                            border: isSameDate(date)
                                ? Border.all(
                                    color: textAndBorderColor, width: 3)
                                : Border.all(color: Colors.transparent),
                          ),
                          margin: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSameDate(date)
                                  ? textAndBorderColor
                                  : Colors.black,
                              fontWeight: isSameDate(date)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime date) {
    return (date.year == _now.year) &&
        (date.month == _now.month) &&
        (date.day == _now.day);
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
