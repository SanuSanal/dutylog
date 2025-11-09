import 'dart:io';
import 'dart:ui' as ui;
import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/util/utils.dart';
import 'package:anjus_duties/widget/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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

  final ScrollController _scrollController = ScrollController();
  final _captureKey = GlobalKey();

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
    final originalOffset = _scrollController.offset;

    _scrollController.jumpTo(0);
    await Future.delayed(const Duration(milliseconds: 50));

    RenderRepaintBoundary boundary =
        _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = File('${directory.path}/screenshot.png');
    await imagePath.writeAsBytes(byteData.buffer.asUint8List());

    final monthAndYear = getMonthAndYearFromDate(_focusDate);

    await Share.shareXFiles([XFile(imagePath.path)],
        text: 'Here’s my duty for the month $monthAndYear.');

    _scrollController.jumpTo(originalOffset);
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
              icon: const Icon(Icons.ios_share),
              onPressed: _captureAndShare,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
              child: RepaintBoundary(
                key: _captureKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 16.0),
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
