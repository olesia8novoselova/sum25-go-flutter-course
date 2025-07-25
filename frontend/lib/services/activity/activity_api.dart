import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sum25_flutter_frontend/config.dart';
import 'package:sum25_flutter_frontend/models/activity.dart';

class ActivityApi {
  final String baseUrl = '$activityBase';

  final http.Client _client;
  ActivityApi({http.Client? client}) : _client = client ?? http.Client();

  Future<void> addActivity({
    required String type,
    required String name,
    required int duration,
    required String intensity,
    required int calories,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final resp = await _client.post(
      Uri.parse('$baseUrl'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': type,
        'name': name,
        'duration': duration,
        'intensity': intensity,
        'calories': calories,
        'location': location,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to add activity');
    }
  }

  Future<List<Activity>> fetchActivities({String? type}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = type == null
        ? '$baseUrl'
        : '$baseUrl?type=$type';
    final resp = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded == null) return [];
      if (decoded is List) {
        return decoded.map((e) => Activity.fromJson(e)).toList();
      } else {
        return [];
      }  
    } else {
      throw Exception('Failed to fetch activities');
    }
  }
  Future<void> postWorkoutReminder(String path, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null) throw Exception('Not authenticated');

    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to post workout reminder: ${response.body}');
    }
  }
}
