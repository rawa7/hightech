import 'dart:convert';
import 'package:http/http.dart' as http;

class PointsService {
  static const String baseUrl = 'https://dasroor.com/hightech';

  /// Get user points information with history and summary
  Future<Map<String, dynamic>> getUserPoints({
    int? userId,
    String? email,
    bool includeHistory = false,
    bool includeSummary = false,
  }) async {
    try {
      String url = '$baseUrl/points.php?';
      
      if (userId != null) {
        url += 'user_id=$userId';
      } else if (email != null) {
        url += 'email=$email';
      }
      
      if (includeHistory) {
        url += '&include_history=true';
      }
      
      if (includeSummary) {
        url += '&include_summary=true';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch points information');
      }
    } catch (e) {
      print('Error fetching points: $e');
      throw Exception('Failed to fetch points: $e');
    }
  }

  /// Get points history for a user
  Future<List<Map<String, dynamic>>> getPointsHistory({
    required int userId,
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      String url = '$baseUrl/points_history.php?user_id=$userId';
      
      if (type != null) {
        url += '&type=$type';
      }
      
      if (dateFrom != null) {
        url += '&date_from=$dateFrom';
      }
      
      if (dateTo != null) {
        url += '&date_to=$dateTo';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch points history');
      }
    } catch (e) {
      print('Error fetching points history: $e');
      throw Exception('Failed to fetch points history: $e');
    }
  }
}
