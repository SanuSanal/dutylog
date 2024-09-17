import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/util/utils.dart';
import 'package:anjus_duties/widget/calendar_widget.dart';
import 'package:flutter/material.dart';

class DutyCalendarPage extends StatefulWidget {
  const DutyCalendarPage({super.key});

  @override
  DutyCalendarPageState createState() => DutyCalendarPageState();
}

class DutyCalendarPageState extends State<DutyCalendarPage> {
  bool _isLoading = true;
  GoogleSheetApi sheetApi = GoogleSheetApi();
  late Map<DateTime, String> _dayMarkers;
  late List<SheetDutyData> _commentList;

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
    List<SheetDutyData> sheetDutyData =
        await GoogleSheetApi.loadSheetData(getSheetNameFromDate(focusDay));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duty calendar'),
      ),
      body: SingleChildScrollView(
        child: Column(
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
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CalendarWidget(
                    dayMarkers: _dayMarkers,
                    focusDate: _focusDate,
                    fetchData: _fetchData,
                    commentList: _commentList),
          ],
        ),
      ),
    );
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
