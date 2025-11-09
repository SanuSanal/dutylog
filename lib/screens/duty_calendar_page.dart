import 'dart:io';

import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/util/utils.dart';
import 'package:anjus_duties/widget/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class DutyCalendarPage extends StatefulWidget {
  final String spreadsheetId;
  const DutyCalendarPage({super.key, required this.spreadsheetId});

  @override
  DutyCalendarPageState createState() => DutyCalendarPageState();
}

class DutyCalendarPageState extends State<DutyCalendarPage> {
  bool _isLoading = true;
  GoogleSheetApi sheetApi = GoogleSheetApi();
  late Map<DateTime, String> _dayMarkers;
  late List<SheetDutyData> _commentList;
  final ScreenshotController _screenshotController = ScreenshotController();

  DateTime _focusDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({DateTime? focusDay}) async {
    setState(() {
      _isLoading = true;
    });

    focusDay ??= DateTime.now();
    List<SheetDutyData> sheetDutyData = await GoogleSheetApi.loadSheetData(
        getSheetNameFromDate(focusDay), widget.spreadsheetId);
    Map<DateTime, String> dayMarkers = {
      for (var duty in sheetDutyData) duty.dutyDate: duty.dutyType
    };
    sheetDutyData.removeWhere((data) => data.comment == '');
    sheetDutyData.sort((a, b) => a.dutyDate.compareTo(b.dutyDate));

    setState(() {
      _focusDate = focusDay!;
      _dayMarkers = dayMarkers;
      _commentList = sheetDutyData;
      _isLoading = false;
      if (_dayMarkers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duty not added.')),
        );
      }
    });
  }

  Future<void> _captureAndShare() async {
    try {
      final image = await _screenshotController.capture(
          delay: const Duration(milliseconds: 100));

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/screenshot.png');
        await imagePath.writeAsBytes(image);

        final monthAndYear = getMonthAndYearFromDate(_focusDate);

        await Share.shareXFiles([XFile(imagePath.path)],
            text: 'Here’s my duty for the month $monthAndYear.');
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty calendar'),
        actions: [
          Tooltip(
            message: 'Share duty calendar',
            child: IconButton(
              icon: const Icon(Icons.share),
              onPressed: _captureAndShare,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Screenshot(
              controller: _screenshotController,
              child: SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _initializeLegend(),
                      CalendarWidget(
                        dayMarkers: _dayMarkers,
                        focusDate: _focusDate,
                        fetchData: _fetchData,
                        commentList: _commentList,
                        spreadsheetId: widget.spreadsheetId,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Wrap(
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

  _initializeLegend() {
    Set<String> dutyTypes =
        _dayMarkers.isNotEmpty ? _dayMarkers.values.toSet() : {'O'};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 5.0,
        direction: Axis.horizontal,
        alignment: WrapAlignment.center,
        children: [
          if (dutyTypes.contains('M'))
            _buildLegend('Morning duty', const Color(0xFF50C878)),
          if (dutyTypes.contains('E'))
            _buildLegend('Evening duty', const Color(0xFF808000)),
          if (dutyTypes.contains('D')) _buildLegend('Day duty', Colors.green),
          if (dutyTypes.contains('N')) _buildLegend('Night duty', Colors.grey),
          if (dutyTypes.contains('O')) _buildLegend('Off day', Colors.yellow),
        ],
      ),
    );
  }
}
