import 'dart:convert';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GoogleSheetApi {
  Future<DutyData> fetchSheetData() async {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('MMM_yyyy');
    String sheetName = formatter.format(now);
    Map<DateTime, String> dutyCalendar = await fetchSheetDataApiCall(sheetName);
    if (dutyCalendar.isNotEmpty) {
      dutyCalendar.removeWhere((key, value) => value == 'O');

      List<MapEntry<DateTime, String>> entries = dutyCalendar.entries.toList();
      entries.sort((a, b) => a.key.compareTo(b.key));

      Map<DateTime, String> sortedDutyCalendar = Map.fromEntries(entries);
      return _createDutyData(sortedDutyCalendar, now.day);
    } else {
      throw Exception('Failed to load sheet data');
    }
  }

  Future<Map<DateTime, String>> fetchSheetDataApiCall(String sheetName) async {
    Map<DateTime, String> dutyCalendar = {};
    var sheetId = dotenv.env['SHEET_ID']!;
    var apiKey = dotenv.env['API_KEY']!;
    final url =
        'https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$sheetName?key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> values = data['values'];

      for (int i = 1; i < values.length; i++) {
        var item = values[i];
        var dateString = '${item[0]}_$sheetName';
        DateFormat format = DateFormat("d_MMM_yyyy");
        DateTime dateTime = format.parse(dateString);
        DateTime date =
            DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
        String type = item[1];
        dutyCalendar[date] = type;
      }
    }
    return dutyCalendar;
  }

  DutyData _createDutyData(Map<DateTime, String> data, int day) {
    String dutyType = 'O';
    DateTime nextWorkingDate = DateTime.now();
    String nextDutyType = '';

    for (var entry in data.entries) {
      int date = entry.key.day;
      String type = entry.value;

      if (date == day) {
        dutyType = type;
      }

      if (date > day) {
        nextWorkingDate = entry.key;
        nextDutyType = type;
        break;
      }
    }
    String nextWorkingDateStr;

    if (nextDutyType == '') {
      nextWorkingDateStr = 'No more duty this month.';
    } else {
      nextWorkingDateStr =
          DateFormat('EEEE, MMMM d, yyyy').format(nextWorkingDate);
    }

    return DutyData(dutyType, nextWorkingDateStr, nextDutyType);
  }
}
