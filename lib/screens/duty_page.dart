import 'package:anjus_duties/screens/duty_calendar_page.dart';
import 'package:flutter/material.dart';

class DutyPage extends StatelessWidget {
  final String todaysDutyType;
  final String nextDuty;
  final String nextDutyType;
  final String spreadsheetId;

  const DutyPage({
    super.key,
    required this.todaysDutyType,
    required this.nextDuty,
    required this.nextDutyType,
    required this.spreadsheetId,
  });

  @override
  Widget build(BuildContext context) {
    String backgroundImage;
    if (todaysDutyType == 'D' ||
        todaysDutyType == 'M' ||
        todaysDutyType == 'E') {
      backgroundImage = 'assets/images/day_background.jpg';
    } else if (todaysDutyType == 'N') {
      backgroundImage = 'assets/images/night_background.jpg';
    } else {
      backgroundImage = 'assets/images/relaxing_background.jpg';
    }

    bool isLeftAligned = todaysDutyType == 'O' || todaysDutyType == 'N';
    Color fontColor = todaysDutyType == 'N' ? Colors.white : Colors.black;

    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
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
                  left: isLeftAligned ? 16.0 : null,
                  right: isLeftAligned ? null : 16.0,
                  child: Column(
                    crossAxisAlignment: isLeftAligned
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Today: ${_getDutyDescription(todaysDutyType)}',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: fontColor),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Next: ${_getFormattedNextDuty(nextDuty)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fontColor),
                      ),
                      Text(
                        nextDutyType.isNotEmpty
                            ? _getDutyDescription(nextDutyType)
                            : '',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: fontColor),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DutyCalendarPage(
                                  spreadsheetId: spreadsheetId,
                                )),
                      );
                    },
                    child: const Icon(Icons.calendar_month_rounded),
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
          },
        ));
  }

  String _getDutyDescription(String dutyType) {
    switch (dutyType) {
      case 'D':
        return 'Day Duty';
      case 'N':
        return 'Night Duty';
      case 'O':
        return 'Off Day';
      case 'M':
        return 'Morning Duty';
      case 'E':
        return 'Evening Duty';
      default:
        return 'Unknown Duty';
    }
  }

  _getFormattedNextDuty(String nextDuty) {
    List<String> parts = nextDuty.split(', ');
    if (parts.length > 2) {
      return '${parts[0]},\n${parts[1]}, ${parts[2]}';
    } else if (parts.length > 1) {
      return '${parts[0]},\n${parts[1]}';
    }
    return nextDuty;
  }
}
