import 'package:anjus_duties/screens/data_loading_page.dart';
import 'package:anjus_duties/screens/duty_page.dart';
import 'package:anjus_duties/screens/error_loading_data_page.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late GoogleSheetApi googleSheetApi;
  late Future<DutyData> _dutyData;

  @override
  void initState() {
    super.initState();
    googleSheetApi = GoogleSheetApi();
    _dutyData = googleSheetApi.fetchSheetData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DutyData>(
      future: _dutyData,
      builder: (BuildContext context, AsyncSnapshot<DutyData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DataLoadingPage(
            message: 'Loading data, please wait...',
          );
        } else if (snapshot.hasError) {
          return ErrorLoadingDataPage(
            errorMessage: 'Failed to load data. Tap reload.',
            onReload: _reloadData,
          );
        } else if (snapshot.hasData) {
          DutyData dutyData = snapshot.data!;
          return DutyPage(
              todaysDutyType: dutyData.todaysDutyType,
              nextDuty: dutyData.nextDuty,
              nextDutyType: dutyData.nextDutyType);
        } else {
          return ErrorLoadingDataPage(
            errorMessage:
                'Failed to load data. Click reload. \n Contact developer.',
            onReload: _reloadData,
          );
        }
      },
    );
  }

  void _reloadData() {
    setState(() {
      _dutyData = googleSheetApi.fetchSheetData();
    });
  }
}
