import 'package:anjus_duties/screens/add_user_page.dart';
import 'package:anjus_duties/screens/data_loading_page.dart';
import 'package:anjus_duties/screens/duty_page.dart';
import 'package:anjus_duties/screens/error_loading_data_page.dart';
import 'package:anjus_duties/screens/user_not_added.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:anjus_duties/service/local_storage_service.dart';
import 'package:app_autoupdate/app_autoupdate.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String _appVersion = '';
  late GoogleSheetApi googleSheetApi = GoogleSheetApi();
  Future<DutyData>? _dutyData;
  List<Map<String, dynamic>> _users = [];
  int _selectedUser = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadUsers();
  }

  void _loadUsers() async {
    _users = await getStoredJsonList();
    int homeIndex = _users.indexWhere((user) => user['isHome'] == true);
    _selectedUser = homeIndex == -1 ? 0 : homeIndex;

    setState(() {
      if (_users.isNotEmpty) {
        _dutyData =
            googleSheetApi.fetchSheetData(_users[_selectedUser]['apiKey']);
      }
    });
  }

  void _loadUsersAndCheckState() async {
    List<Map<String, dynamic>> users = await getStoredJsonList();

    setState(() {
      if (users.length <= _selectedUser) {
        _selectedUser = users.length - 1;
        if (_selectedUser < 0) {
          _selectedUser = 0;
          _dutyData = null;
        } else {
          _dutyData =
              googleSheetApi.fetchSheetData(users[_selectedUser]['apiKey']);
        }
      }
      if (_users.isEmpty && users.isNotEmpty) {
        _dutyData =
            googleSheetApi.fetchSheetData(users[_selectedUser]['apiKey']);
      }
      _users = users;
    });
  }

  void _toggleHomePage() async {
    if (_users.isNotEmpty) {
      for (int i = 0; i < _users.length; i++) {
        if (i == _selectedUser) {
          _users[i]['isHome'] = !_users[i]['isHome'];
        } else {
          _users[i]['isHome'] = false;
        }
      }

      await storeJsonList(_users);
      _loadUsersAndCheckState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            text: _users.isEmpty
                ? "Dutylog "
                : "${_users[_selectedUser]['name']}'s Duties ",
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
        actions: [
          Tooltip(
            message: 'Set as home',
            child: IconButton(
              icon:
                  _users.isNotEmpty && (_users[_selectedUser]['isHome'] as bool)
                      ? const Icon(Icons.star_rounded)
                      : const Icon(Icons.star_border_rounded),
              onPressed: _toggleHomePage,
            ),
          ),
          Tooltip(
            message: 'Add user',
            child: IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddUserPage()),
                ).then((value) {
                  _loadUsersAndCheckState();
                });
              },
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! > 0 && _users.length > 1) {
            setState(() {
              _selectedUser = (_selectedUser - 1) % _users.length;
              _dutyData = googleSheetApi
                  .fetchSheetData(_users[_selectedUser]['apiKey']);
            });
          } else if (details.primaryVelocity! < 0 && _users.length > 1) {
            setState(() {
              _selectedUser = (_selectedUser + 1) % _users.length;
              _dutyData = googleSheetApi
                  .fetchSheetData(_users[_selectedUser]['apiKey']);
            });
          }
        },
        child: Stack(
          children: [
            _users.isEmpty
                ? const UserNotAdded()
                : FutureBuilder<DutyData>(
                    future: _dutyData,
                    builder: (BuildContext context,
                        AsyncSnapshot<DutyData> snapshot) {
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
                            nextDutyType: dutyData.nextDutyType,
                            spreadsheetId: _users[_selectedUser]['apiKey']);
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
              repo: 'dutylog',
            ),
          ],
        ),
      ),
    );
  }

  void _reloadData() {
    setState(() {
      _dutyData =
          googleSheetApi.fetchSheetData(_users[_selectedUser]['apiKey']);
    });
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }
}
