import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://databridge-app.onrender.com';

  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> extractFromImageBytes(
      Uint8List imageBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extract/image'));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: filename));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'extracted_text': ''};
    }
  }

  static Future<Map<String, dynamic>> extractFromAudioBytes(
      Uint8List audioBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extract/voice'));
      request.files.add(http.MultipartFile.fromBytes('file', audioBytes, filename: filename));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'extracted_text': ''};
    }
  }

  static Future<Map<String, dynamic>> extractFromDocumentBytes(
      Uint8List bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extract/document'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'extracted_text': ''};
    }
  }

  static Future<Map<String, dynamic>> extractFromSpreadsheetBytes(
      Uint8List bytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extract/spreadsheet'));
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'extracted_text': ''};
    }
  }

  static Future<Map<String, dynamic>> generateSchema(String text) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/schema/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveData(Map<String, dynamic> schema) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/data/save'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'schema': schema}));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTables() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/database/tables'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTableRows(String tableName) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/database/table/$tableName'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> nlToSql(String question) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/query/nl'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'question': question}));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  // ── Get analytics summary ──────────────────
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/analytics/summary'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Get analytics logs ─────────────────────
  static Future<Map<String, dynamic>> getAnalyticsLogs() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/analytics/logs'));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  // ── Multimodal Fusion ──────────────────────
  static Future<Map<String, dynamic>> fuseSchemas(
    Map<String, dynamic> schema1,
    Map<String, dynamic> schema2) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/fusion/merge'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'schema1': schema1, 'schema2': schema2}),
    );
    return jsonDecode(res.body);
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
  }
}