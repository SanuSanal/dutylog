import 'package:anjus_duties/models/sheet_duty_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final scheduleClient = Supabase.instance.client.from('duty_schedule');
  final userClient = Supabase.instance.client.from('users');

  Future<void> getData() async {
    final future = await scheduleClient.select();
    print("LOG: $future");
  }

  Future<int> createUser(String name) async {
    final List<Map<String, dynamic>> data =
        await userClient.insert({'name': name}).select();
    print("LOG: User created with ID: ${data[0]['id']}");
    return data[0]['id'];
  }

  Future<void> saveData(SheetDutyData data, int userId) async {
    PostgrestFilterBuilder response;
    if (data.dutyType == 'O' && data.comment.isEmpty) {
      response = await scheduleClient
          .delete()
          .eq('duty_date', data.dutyDate.toIso8601String())
          .eq('user_id', userId);
    } else {
      final jsonMap = {
        'duty_date': data.dutyDate.toIso8601String(),
        'duty_type': data.dutyType,
        'comment': data.comment,
        'user_id': userId,
      };
      response = await scheduleClient.upsert(jsonMap);
    }

    // if (response. != null) {
    //   print("Error saving data: ${response.error!.message}");
    // } else {
    //   print("Data saved successfully: ${response.data}");
    // }
  }
}
