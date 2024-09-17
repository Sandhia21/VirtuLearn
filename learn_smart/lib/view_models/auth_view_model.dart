import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user.dart';

class AuthViewModel extends ChangeNotifier {
  User _user = User(
    username: 'username',
    id: 1,
    imageUrl: 'imageUrl',
    token: 'token',
    role: 'role',
    email: 'email',
  );

  User get user => _user;

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/users/login/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _user = User.fromJson(data);
      _user.display(); // Display user details
      notifyListeners();
      Get.toNamed('/dashboard');
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> register(
    String username,
    String email,
    String password,
    String firstName,
    String lastName,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/users/register/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      Get.toNamed('/login');
    } else {
      throw Exception('Failed to register');
    }
  }

  void logout() {
    _user = User(
      username: 'username',
      id: 1,
      imageUrl: 'imageUrl',
      token: null,
      role: 'role',
      email: 'email',
    );
    notifyListeners();
  }
}
