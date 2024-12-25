import 'package:anjus_duties/screens/data_loading_page.dart';
import 'package:anjus_duties/screens/duty_page.dart';
import 'package:anjus_duties/screens/error_loading_data_page.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:app_autoupdate/app_autoupdate.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String _appVersion = "Loading...";
  late GoogleSheetApi googleSheetApi;
  late Future<DutyData> _dutyData;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    googleSheetApi = GoogleSheetApi();
    _dutyData = googleSheetApi.fetchSheetData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: "Anju's Duties ",
            style: const TextStyle(
              fontSize: 24,
              fontFamily: 'Acme',
              color: Colors.black,
            ),
            children: [
              if (_appVersion.isNotEmpty)
                TextSpan(
                  text: 'v$_appVersion',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFeatures: [FontFeature.subscripts()]),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<DutyData>(
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
          ),
          const AppUpdateWidget(
            owner: 'SanuSanal',
            repo: 'anjus-duties',
          ),
        ],
      ),
    );
  }

  void _reloadData() {
    setState(() {
      _dutyData = googleSheetApi.fetchSheetData();
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }
}
