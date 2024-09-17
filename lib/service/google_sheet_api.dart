import 'dart:convert';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/util/utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetApi {
  static final _spreadsheetId = dotenv.env['SHEET_ID']!;
  static final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
    json.decode(utf8.decode(base64.decode(dotenv.env['ENCODED_JSON_KEY']!))),
  );

  static final _scopes = [sheets.SheetsApi.spreadsheetsScope];

  Future<DutyData> fetchSheetData() async {
    DateTime now = DateTime.now();
    String sheetName = getSheetNameFromDate(now);
    List<SheetDutyData> dutyCalendar = await loadSheetData(sheetName);
    if (dutyCalendar.isNotEmpty) {
      dutyCalendar.removeWhere((value) => value.dutyType.toUpperCase() == 'O');

      Map<DateTime, String> dutyMap = {
        for (var duty in dutyCalendar) duty.dutyDate: duty.dutyType
      };

      List<MapEntry<DateTime, String>> entries = dutyMap.entries.toList();
      entries.sort((a, b) => a.key.compareTo(b.key));

      Map<DateTime, String> sortedDutyCalendar = Map.fromEntries(entries);
      return _createDutyData(sortedDutyCalendar, now.day);
    } else {
      throw Exception('Failed to load sheet data');
    }
  }

  static Future<List<SheetDutyData>> loadSheetData(String sheetName) async {
    List<SheetDutyData> sheetData = [];

    final client =
        await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    final sheetsApi = sheets.SheetsApi(client);
    var range = sheetName;
    try {
      final response =
          await sheetsApi.spreadsheets.values.get(_spreadsheetId, range);

      if (response.values != null) {
        for (var i = 1; i < response.values!.length; i++) {
          var row = response.values?[i];
          var dateString = '${row![0]}_$sheetName';
          DateFormat format = DateFormat("d_MMM_yyyy");
          DateTime dateTime = format.parse(dateString);
          DateTime date =
              DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
          String type = row[1] as String;
          String comment = '';
          if (row.length >= 3) {
            comment = row[2] as String;
          }
          sheetData.add(SheetDutyData(date, type, comment));
        }
      }
    } finally {
      client.close();
    }
    return sheetData;
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

  static Future<bool> updateSheetRange(
      DateTime editingDate, List<Object> sheetRowData) async {
    String sheetName = getSheetNameFromDate(editingDate);

    String range = '$sheetName!A${editingDate.day + 1}:C${editingDate.day + 1}';

    final List<List<Object>> values = [sheetRowData];

    final httpClient =
        await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    final sheetsApi = sheets.SheetsApi(httpClient);

    final valueRange = sheets.ValueRange.fromJson({
      'range': range,
      'values': values,
    });

    final sheets.UpdateValuesResponse response =
        await sheetsApi.spreadsheets.values.update(
      valueRange,
      _spreadsheetId,
      range,
      valueInputOption: 'RAW',
    );

    httpClient.close();

    if (response.updatedRows != null) {
      return true;
    } else {
      return false;
    }
  }
}
