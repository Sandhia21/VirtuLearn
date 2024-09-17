import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:learn_smart/models/profile.dart';
import 'dart:convert';

import 'models/course.dart';
import 'models/datastore.dart';
import 'models/enrollment.dart';
import 'models/module.dart';
import 'models/note.dart';
import 'models/quiz.dart';

class ApiService {
  final String baseUrl;
  String? _token;

  ApiService({required this.baseUrl});

  void updateToken(String token) {
    _token = token;
  }

  // General Request Handler
  Future<dynamic> _performHttpRequest({
    required String url,
    required String requestType,
    Map<String, dynamic>? body,
  }) async {
    if (_token == null) {
      throw Exception('Token is null, authentication failed.');
    }

    final headers = {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };

    try {
      switch (requestType) {
        case 'GET':
          return await http.get(Uri.parse(url), headers: headers);
        case 'POST':
          return await http.post(Uri.parse(url),
              headers: headers, body: json.encode(body));
        case 'PUT':
          return await http.put(Uri.parse(url),
              headers: headers, body: json.encode(body));
        case 'PATCH':
          return await http.patch(Uri.parse(url),
              headers: headers, body: json.encode(body));
        case 'DELETE':
          return await http.delete(Uri.parse(url), headers: headers);
        default:
          throw Exception('Invalid request type');
      }
    } catch (error) {
      debugPrint('HTTP Request failed: $error');
      rethrow;
    }
  }

  // Courses CRUD
  Future<List<Course>> fetchCourses() async {
    List<Course> courses = [];
    try {
      final response = await _performHttpRequest(
        url: baseUrl + 'courses/',
        requestType: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> coursesJson = json.decode(response.body);
        courses = coursesJson.map((json) => Course.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch courses');
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
    }
    return courses;
  }

  Future<void> getCourseDetail(int courseId) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'courses/$courseId/',
      requestType: 'GET',
    );

    if (response.statusCode == 200) {
      // Parse the response body and update the DataStore with the course details
      Course course = Course.fromJson(json.decode(response.body));
      DataStore.addCourse(course); // Store course details in DataStore
      debugPrint('Course details fetched and stored');
    } else {
      throw Exception('Failed to load course details');
    }
  }

  // Modules CRUD
  Future<void> fetchModules(int courseId) async {
    try {
      final response = await _performHttpRequest(
          url: baseUrl + 'modules/?course_id=$courseId', requestType: 'GET');
      if (response.statusCode == 200) {
        List<dynamic> modulesJson = json.decode(response.body);
        List<Module> modules =
            modulesJson.map((m) => Module.fromJson(m)).toList();
        DataStore.setModules(courseId, modules);
      } else {
        throw Exception('Failed to fetch modules');
      }
    } catch (e) {
      debugPrint('Error fetching modules: $e');
    }
  }

  // Notes CRUD
  Future<void> fetchNotes(int moduleId) async {
    try {
      final response = await _performHttpRequest(
          url: baseUrl + 'modules/$moduleId/notes/', requestType: 'GET');
      if (response.statusCode == 200) {
        List<dynamic> notesJson = json.decode(response.body);
        List<Note> notes = notesJson.map((n) => Note.fromJson(n)).toList();
        DataStore.setNotes(moduleId, notes);
      } else {
        throw Exception('Failed to fetch notes');
      }
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }
  }

  // Quizzes CRUD
  Future<void> fetchQuizzes(int moduleId) async {
    try {
      final response = await _performHttpRequest(
        url: baseUrl + 'modules/$moduleId/quizzes/',
        requestType: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> quizzesJson = json.decode(response.body);
        List<Quiz> quizzes = quizzesJson.map((q) => Quiz.fromJson(q)).toList();
        DataStore.setQuizzes(moduleId, quizzes);
      } else {
        throw Exception('Failed to fetch quizzes');
      }
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
    }
  }

  // Enrollment Methods
  Future<void> enrollInCourse(int courseId, String courseCode) async {
    try {
      final response = await _performHttpRequest(
        url: baseUrl + 'enrollments/create/',
        requestType: 'POST',
        body: {
          'course_id': courseId, // Ensure course_id is passed
          'course_code': courseCode, // Ensure course_code is passed
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Successfully enrolled in the course.');
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['detail'] != null) {
          throw Exception(responseBody['detail']);
        } else {
          throw Exception(
              'Failed to enroll in the course. Please check the course code or ID.');
        }
      } else {
        throw Exception('Unexpected error. Please try again.');
      }
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
    }
  }

  Future<List<EnrollmentRequest>> fetchTeacherEnrollmentRequests() async {
    try {
      final response = await _performHttpRequest(
        url: baseUrl + 'enrollments/teacher-requests/',
        requestType: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((json) => EnrollmentRequest.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load enrollment requests');
      }
    } catch (e) {
      debugPrint('Error fetching enrollment requests: $e');
      return [];
    }
  }

  Future<List<StudentEnrollmentRequest>>
      fetchStudentEnrollmentRequests() async {
    final response = await http.get(
      Uri.parse(baseUrl + 'enrollments/student-requests/'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => StudentEnrollmentRequest.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load student enrollment requests');
    }
  }

  // Fetch upcoming notes for enrolled courses
  Future<List<dynamic>> fetchUpcomingNotes() async {
    try {
      final response = await _performHttpRequest(
        url: baseUrl + ' notes/upcoming/',
        requestType: 'GET',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch upcoming notes');
      }
    } catch (e) {
      debugPrint('Error fetching upcoming notes: $e');
      return [];
    }
  }

  Future<void> deleteModule(int moduleId, int courseId) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'modules/$moduleId/',
      requestType: 'DELETE',
    );

    if (response.statusCode == 204) {
      DataStore.removeModule(courseId, moduleId);
      debugPrint('Module deleted successfully');
    } else {
      throw Exception('Failed to delete module');
    }
  }

  Future<void> createModule(
      int courseId, String title, String description) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'modules/',
      requestType: 'POST',
      body: {
        'course': courseId,
        'title': title,
        'description': description,
      },
    );

    if (response.statusCode == 201) {
      await fetchModules(courseId); // Refresh modules after creation
      debugPrint('Module created successfully');
    } else {
      throw Exception('Failed to create module');
    }
  }

  Future<void> updateModule(
      int moduleId, int courseId, String title, String description) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'modules/$moduleId/',
      requestType: 'PUT',
      body: {
        'title': title,
        'description': description,
      },
    );

    if (response.statusCode == 200) {
      await fetchModules(courseId); // Refresh modules after update
      debugPrint('Module updated successfully');
    } else {
      throw Exception('Failed to update module');
    }
  }

  Future<void> createCourse(String name, String description) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'courses/',
      requestType: 'POST',
      body: {
        'name': name,
        'description': description,
      },
    );

    if (response.statusCode == 201) {
      await fetchCourses(); // Refresh courses after creation
      debugPrint('Course created successfully');
    } else {
      throw Exception('Failed to create course');
    }
  }

  Future<void> createNote(
    int moduleId,
    String title,
    String content,
  ) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'modules/$moduleId/notes/',
      requestType: 'POST',
      body: {'title': title, 'content': content},
    );

    if (response.statusCode == 201) {
      await fetchNotes(moduleId); // Refresh notes after creation
    } else {
      throw Exception('Failed to create note');
    }
  }

  Future<void> createQuiz(
    int moduleId,
    String title,
    String description,
    String quizType,
    String category,
    List<Map<String, dynamic>> questions,
  ) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'modules/$moduleId/quizzes/',
      requestType: 'POST',
      body: {
        'title': title,
        'description': description,
        'quiz_type': quizType,
        'category': category,
        'questions': questions,
      },
    );

    if (response.statusCode == 201) {
      await fetchQuizzes(moduleId); // Refresh quizzes after creation
    } else {
      throw Exception('Failed to create quiz');
    }
  }

  // Fetch quiz results
  Future<List<dynamic>> fetchQuizResults(int quizId) async {
    final response = await _performHttpRequest(
      url: baseUrl + 'quizzes/$quizId/results/',
      requestType: 'GET',
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch quiz results');
    }
  }

  Future<Profile> fetchUserProfile() async {
    try {
      final response = await _performHttpRequest(
        url: baseUrl + 'users/profile/',
        requestType: 'GET',
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('User profile JSON response: $jsonResponse');

        final profile = Profile.fromJson(jsonResponse);
        print('Parsed Profile: ${profile.username}, Role: ${profile.role}');
        return profile;
      } else {
        print('Error fetching profile: ${response.statusCode}');
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      print('Error in fetchUserProfile: $e');
      throw Exception('Failed to fetch user profile');
    }
  }
}
