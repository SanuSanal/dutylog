import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeJsonList(List<Map<String, dynamic>> jsonList) async {
  final prefs = await SharedPreferences.getInstance();

  String jsonString = jsonEncode(jsonList);
  await prefs.setString('users', jsonString);
}

Future<List<Map<String, dynamic>>> getStoredJsonList() async {
  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> jsonList = [];

  String? storedString = prefs.getString('users');
  if (storedString != null) {
    List<dynamic> decodedList = jsonDecode(storedString);
    jsonList = List<Map<String, dynamic>>.from(decodedList);
  }

  return jsonList;
}

Future<List<Map<String, dynamic>>> storeJsonMap(
    Map<String, dynamic> jsonMap) async {
  List<Map<String, dynamic>> jsonList = await getStoredJsonList();
  jsonList.add(jsonMap);
  await storeJsonList(jsonList);
  return jsonList;
}

Future<List<Map<String, dynamic>>> storeUserFromApplink(
    Map<String, dynamic> jsonMap) async {
  List<Map<String, dynamic>> jsonList = await getStoredJsonList();
  if (jsonList.isNotEmpty &&
      jsonList.any((element) => element['name'] == jsonMap['name'])) {
    return jsonList;
  }
  jsonList.add(jsonMap);
  await storeJsonList(jsonList);
  return jsonList;
}
