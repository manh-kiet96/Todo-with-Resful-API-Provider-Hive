import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo_with_resfulapi/models/task.dart';

class ApiService {
  // FastAPI backend endpoint (default local)
  static const String _fastApiBase = 'http://127.0.0.1:8000/api/tasks/';

  // RapidAPI endpoint (used when apiKey is provided)
  static const String _rapidApiBase = 'https://task-manager-api3.p.rapidapi.com/';

  // RapidAPI host header value
  static const String _rapidApiHost = 'task-manager-api3.p.rapidapi.com';

  // Optional RapidAPI key (nullable). Default set previously; can be cleared via setApiKey(...)
  static String? _apiKey = '5cccf55fbfmsha4f89acf4595db2p13853ajsn8add119d960e';

  /// Set the RapidAPI key at runtime (nullable) — allow clearing with null/empty.
  static void setApiKey(String? apiKey) {
    _apiKey = (apiKey == null || apiKey.trim().isEmpty) ? null : apiKey.trim();
    debugPrint('ApiService: RapidAPI key ${_apiKey == null ? 'cleared' : 'set'}');
  }

  /// Effective base URL depending on whether a RapidAPI key is configured.
  static String get _baseUrl => (_apiKey != null && _apiKey!.isNotEmpty) ? _rapidApiBase : _fastApiBase;

  /// Use mock mode for development
  static bool useMock = false;

  /// In-memory mock server store (simple simulation of remote tasks)
  static final List<Map<String, dynamic>> _mockServerTasks = <Map<String, dynamic>>[];

  /// Build headers dynamically depending on whether RapidAPI key is configured
  static Map<String, String> get headers {
    final base = <String, String>{'Content-Type': 'application/json'};
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      base['x-rapidapi-host'] = _rapidApiHost;
      base['x-rapidapi-key'] = _apiKey!;
    }
    return base;
  }

  // Retry configuration
  static const int _maxAttempts = 5;
  static const Duration _baseDelay = Duration(seconds: 1);

  /// Helper to perform HTTP requests with basic exponential backoff retry
  /// for 429 (Too Many Requests) responses. It honors the `Retry-After`
  /// header when present (seconds). Throws the last exception if attempts
  /// are exhausted.
  Future<http.Response> _withRetry(Future<http.Response> Function() attempt) async {
    final random = Random();
    dynamic lastError;

    for (var attemptCount = 1; attemptCount <= _maxAttempts; attemptCount++) {
      try {
        final response = await attempt();

        if (response.statusCode == 429) {
          // If server tells us how long to wait, prefer that
          final retryAfter = response.headers['retry-after'];
          Duration waitDuration = Duration.zero;
          if (retryAfter != null) {
            final seconds = int.tryParse(retryAfter);
            if (seconds != null) {
              waitDuration = Duration(seconds: seconds);
            }
          }

          if (waitDuration == Duration.zero) {
            // exponential backoff with jitter
            final backoffMillis = _baseDelay.inMilliseconds * pow(2, attemptCount - 1);
            final jitter = random.nextInt(500); // up to 500ms jitter
            waitDuration = Duration(milliseconds: backoffMillis.toInt() + jitter);
          }

          debugPrint('API rate limited (429). Attempt $attemptCount/$_maxAttempts - waiting ${waitDuration.inMilliseconds}ms before retry.');

          if (attemptCount == _maxAttempts) {
            // last attempt: return the response so callers can inspect it
            return response;
          }

          await Future.delayed(waitDuration);
          continue; // retry
        }

        // Not a 429, return immediately
        return response;
      } catch (e) {
        lastError = e;
        // for network errors, apply a short backoff and retry
        if (attemptCount == _maxAttempts) break;
        final backoffMillis = _baseDelay.inMilliseconds * pow(2, attemptCount - 1);
        final jitter = random.nextInt(300);
        final waitDuration = Duration(milliseconds: backoffMillis.toInt() + jitter);
        debugPrint('Request failed (attempt $attemptCount). Retrying after ${waitDuration.inMilliseconds}ms. Error: $e');
        await Future.delayed(waitDuration);
      }
    }

    // If we reached here, all retries failed due to exceptions
    throw lastError ?? Exception('HTTP request failed after $_maxAttempts attempts');
  }

  /// GET All Tasks
  Future<List<Task>> getAllTasks() async {
    try {
      // Mock mode: return in-memory server tasks
      if (useMock) {
        debugPrint('ApiService: returning mock server tasks (${_mockServerTasks.length})');
        return _mockServerTasks.map((m) => Task.fromJson(Map<String, dynamic>.from(m))).toList();
      }

      final response = await _withRetry(() => http.get(Uri.parse(ApiService._baseUrl), headers: headers));
      debugPrint('API response status code: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');

      if (response.statusCode == 200) {
        // If RapidAPI returns wrapped response, try to handle both list and wrapped formats
        final decoded = json.decode(response.body);
        if (decoded is List) {
          final List<dynamic> listOfTasks = decoded;
          return listOfTasks
              .map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
              .where((task) => task.id != null)
              .toList();
        } else if (decoded is Map && decoded.containsKey('data')) {
          final List<dynamic> listOfTasks = decoded['data'] as List<dynamic>;
          return listOfTasks
              .map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
              .where((task) => task.id != null)
              .toList();
        } else {
          throw Exception('Unexpected API response format');
        }
      } else if (response.statusCode == 403) {
        debugPrint('API Key unauthorized or expired');
        throw Exception('API Key unauthorized. Update RapidAPI key in Settings.');
      } else if (response.statusCode == 429) {
        debugPrint('API rate limit exceeded');
        throw Exception('API rate limit exceeded. Please try again later.');
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// POST - Create new task
  Future<void> createTask(String title, String description) async {
    try {
      final body = json.encode({
        'title': title,
        'description': description,
        "status": "pendiente",
      });

      // Mock create: simulate creating on server
      if (useMock) {
        final serverId = 'srv_${DateTime.now().microsecondsSinceEpoch}';
        final serverTask = {
          'id': serverId,
          'title': title,
          'description': description,
          'status': 'pendiente',
        };
        _mockServerTasks.add(serverTask);
        debugPrint('ApiService (mock): created task $serverId');
        return;
      }

      final response = await _withRetry(() => http.post(
            Uri.parse(ApiService._baseUrl),
            headers: headers,
            body: body,
          ));

      debugPrint('Create task response status: ${response.statusCode}');
      debugPrint('Create task response body: ${response.body}');

      if (response.statusCode == 403) {
        debugPrint('Create task unauthorized - API key problem');
        throw Exception('API Key unauthorized. Update RapidAPI key in Settings.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Create task error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      throw Exception('Failed to create task: $e');
    }
  }

  /// PUT - Update existing task
  Future<void> updateTask(Task task) async {
    try {
      final body = json.encode(task.toJson());

      // Mock update
      if (useMock) {
        final idx = _mockServerTasks.indexWhere((m) => m['id'] == task.id);
        if (idx != -1) {
          _mockServerTasks[idx] = task.toJson();
          debugPrint('ApiService (mock): updated task ${task.id}');
          return;
        } else {
          throw Exception('Mock server: task not found');
        }
      }

      final response = await _withRetry(() => http.put(
            Uri.parse('${ApiService._baseUrl}${task.id}'),
            headers: headers,
            body: body,
          ));

      debugPrint('Update task response status: ${response.statusCode}');
      debugPrint('Update task response body: ${response.body}');

      if (response.statusCode == 403) {
        debugPrint('Update task unauthorized - API key problem');
        throw Exception('API Key unauthorized. Update RapidAPI key in Settings.');
      }

      if (response.statusCode != 200) {
        debugPrint('Update task error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  /// DELETE - Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      // Mock delete
      if (useMock) {
        _mockServerTasks.removeWhere((m) => m['id'] == taskId);
        debugPrint('ApiService (mock): deleted task $taskId');
        return;
      }

      final response = await _withRetry(() => http.delete(
            Uri.parse('${ApiService._baseUrl}$taskId'),
            headers: headers,
          ));

      debugPrint('Delete task response status: ${response.statusCode}');
      debugPrint('Delete task response body: ${response.body}');

      if (response.statusCode == 403) {
        debugPrint('Delete task unauthorized - API key problem');
        throw Exception('API Key unauthorized. Update RapidAPI key in Settings.');
      }

      if (response.statusCode != 200 && response.statusCode != 204) {
        debugPrint('Delete task error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }
}
