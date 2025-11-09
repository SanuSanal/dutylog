import 'dart:async';
import 'dart:io';

import 'package:anjus_duties/screens/add_user_page.dart';
import 'package:anjus_duties/screens/data_loading_page.dart';
import 'package:anjus_duties/screens/duty_page.dart';
import 'package:anjus_duties/screens/error_loading_data_page.dart';
import 'package:anjus_duties/screens/user_not_added.dart';
import 'package:anjus_duties/service/google_sheet_api.dart';
import 'package:anjus_duties/models/duty_data.dart';
import 'package:anjus_duties/service/local_storage_service.dart';
import 'package:app_autoupdate/app_autoupdate.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  String _appVersion = '';
  late GoogleSheetApi googleSheetApi = GoogleSheetApi();
  Future<DutyData>? _dutyData;
  List<Map<String, dynamic>> _users = [];
  int _selectedUser = 0;

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _loadAppVersion();
    _loadUsers();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      final queryParams = uri.queryParameters;
      if (uri.pathSegments.contains("save") &&
          queryParams.containsKey('name') &&
          queryParams['name']!.isNotEmpty &&
          queryParams.containsKey('apiKey') &&
          queryParams['apiKey']!.isNotEmpty) {
        final name = queryParams['name']!;
        final apiKey = queryParams['apiKey']!;

        _saveUserFromApplink({'name': name, 'apiKey': apiKey, 'isHome': false});
      }
    });
  }

  void _saveUserFromApplink(Map<String, dynamic> jsonMap) async {
    List<Map<String, dynamic>> users = await storeUserFromApplink(jsonMap);
    if (_users.length < users.length) {
      setState(() {
        _users = users;
        _selectedUser = users.length - 1;
        _reloadData();
      });
    }
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

  Future<void> _captureAndShare() async {
    try {
      final image = await _screenshotController.capture(
          delay: const Duration(milliseconds: 100));

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/screenshot.png');
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles([XFile(imagePath.path)],
            text: 'Here’s my duty for today.');
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
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
            message: 'Share duty',
            child: IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _captureAndShare,
            ),
          ),
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
        child: Screenshot(
          controller: _screenshotController,
          child: Stack(
            children: [
              _users.isEmpty
                  ? const UserNotAdded()
                  : FutureBuilder<DutyData>(
                      future: _dutyData,
                      builder: (BuildContext context,
                          AsyncSnapshot<DutyData> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
