import 'dart:convert';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/util/utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

class GoogleSheetApi {
  static final _scopes = [sheets.SheetsApi.spreadsheetsScope];

  static final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
    json.decode(utf8.decode(base64.decode(dotenv.env['ENCODED_JSON_KEY']!))),
  );

  Future<DutyData> fetchSheetData(String spreadsheetId) async {
    DateTime now = DateTime.now();
    String sheetName = getSheetNameFromDate(now);
    List<SheetDutyData> dutyCalendar =
        await loadSheetData(sheetName, spreadsheetId);
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

  static Future<List<SheetDutyData>> loadSheetData(
      String sheetName, String spreadsheetId) async {
    List<SheetDutyData> sheetData = [];
    final client =
        await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    final sheetsApi = sheets.SheetsApi(client);
    var range = sheetName;
    try {
      final response =
          await sheetsApi.spreadsheets.values.get(spreadsheetId, range);

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
    } catch (e) {
      // DetailedApiRequestError: Sheet not available. nothing to do
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

  static Future<bool> updateSheetRange(DateTime editingDate,
      List<Object> sheetRowData, String spreadsheetId) async {
    String sheetName = getSheetNameFromDate(editingDate);
    String range = '$sheetName!A${editingDate.day + 1}:C${editingDate.day + 1}';
    final valueRange = sheets.ValueRange.fromJson({
      'range': range,
      'values': [sheetRowData],
    });

    final httpClient =
        await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    final sheetsApi = sheets.SheetsApi(httpClient);

    try {
      final sheets.UpdateValuesResponse response =
          await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: 'RAW',
      );

      if (response.updatedRows != null) {
        return true;
      } else {
        return false;
      }
    } on sheets.DetailedApiRequestError catch (_) {
      bool sheetExists =
          await doesSheetExistByName(sheetsApi, sheetName, spreadsheetId);
      if (!sheetExists) {
        int numberOfDays = getDaysInMonth(editingDate);
        bool result = await createSheetAndFillData(
            sheetsApi, sheetName, numberOfDays, spreadsheetId);

        if (result) {
          bool updateResult =
              await updateSheetRange(editingDate, sheetRowData, spreadsheetId);
          return updateResult;
        } else {
          return result;
        }
      } else {
        return false;
      }
    } finally {
      httpClient.close();
    }
  }

  static Future<bool> doesSheetExistByName(sheets.SheetsApi sheetsApi,
      String sheetName, String spreadsheetId) async {
    try {
      var spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);

      for (var sheet in spreadsheet.sheets!) {
        if (sheet.properties!.title == sheetName) {
          return true;
        }
      }
      return false;
    } on sheets.DetailedApiRequestError catch (_) {
      return true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> createSheetAndFillData(sheets.SheetsApi sheetsApi,
      String sheetName, int days, String spreadsheetId) async {
    var range = "$sheetName!A1:C${days + 1}";
    var values = [
      ["Date", "Duty Type (D/N)", "Comment"],
    ];

    for (var i = 1; i <= days; i++) {
      values.add(['$i', 'O', '']);
    }

    var valueRange = sheets.ValueRange.fromJson({
      "range": range,
      "values": values,
    });

    try {
      // created sheet with $sheetName
      var addSheetRequest = sheets.AddSheetRequest(
        properties: sheets.SheetProperties(
          title: sheetName,
        ),
      );
      var batchUpdateRequest = sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            addSheet: addSheetRequest,
          ),
        ],
      );

      await sheetsApi.spreadsheets
          .batchUpdate(batchUpdateRequest, spreadsheetId);

      // update sheet
      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        range,
        valueInputOption: "RAW",
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  static int getDaysInMonth(DateTime date) {
    int year = date.year;
    int month = date.month;
    DateTime firstDayNextMonth;

    if (month == 12) {
      firstDayNextMonth = DateTime(year + 1, 1, 1);
    } else {
      firstDayNextMonth = DateTime(year, month + 1, 1);
    }

    DateTime lastDayCurrentMonth =
        firstDayNextMonth.subtract(const Duration(days: 1));

    return lastDayCurrentMonth.day;
  }
}
