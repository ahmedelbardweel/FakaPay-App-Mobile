import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/api/api_service.dart';
import '../data/models/auth_models.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String deviceId,
    required String idNumber,
    required String idPhotoPath,
    required String personalPhotoPath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': confirmPassword,
        'device_id': deviceId,
        'id_number': idNumber,
        'id_photo':
            await MultipartFile.fromFile(idPhotoPath, filename: 'id_photo.jpg'),
        'personal_photo': await MultipartFile.fromFile(personalPhotoPath,
            filename: 'personal_photo.jpg'),
      });

      final response = await _apiService.register(formData);
      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        _token = authResponse.data!.token;
        _user = authResponse.data!.user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = authResponse.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage =
            'Server is taking too long to respond. Please try again.';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        _errorMessage = e.response?.data['message'];
      } else {
        _errorMessage = 'Network Error: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password, String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password, deviceId);
      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success && authResponse.data != null) {
        _token = authResponse.data!.token;
        _user = authResponse.data!.user;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
        await prefs.setString('auth_email', email);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = authResponse.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _errorMessage = e.response?.data['message'] ??
            'Your account is pending admin approval.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _errorMessage =
            'Server is taking too long to respond. Please try again.';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        _errorMessage = e.response?.data['message'];
      } else {
        _errorMessage = 'Network Error: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Unexpected Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUser(User newUser) async {
    _user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<bool> refreshCurrentUser() async {
    try {
      final response = await _apiService.getUser();
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        // Case 1: Wrapped in success/data
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          User? newUser;
          if (data is Map<String, dynamic>) {
            if (data.containsKey('user')) {
              newUser = User.fromJson(data['user']);
            } else {
              newUser = User.fromJson(data);
            }
          }
          if (newUser != null) {
            // Keep old IBAN if new one is missing and old one exists
            if ((newUser.iban == null || newUser.iban!.isEmpty) &&
                _user?.iban != null &&
                _user!.iban!.isNotEmpty) {
              newUser = newUser.copyWith(iban: _user!.iban);
            }
            await updateUser(newUser);
            return true;
          }
        }
        // Case 2: Direct user object or direct data with id
        else if (responseData.containsKey('id')) {
          var newUser = User.fromJson(responseData);
          if ((newUser.iban == null || newUser.iban!.isEmpty) &&
              _user?.iban != null &&
              _user!.iban!.isNotEmpty) {
            newUser = newUser.copyWith(iban: _user!.iban);
          }
          await updateUser(newUser);
          return true;
        } else if (responseData.containsKey('user')) {
          var newUser = User.fromJson(responseData['user']);
          if ((newUser.iban == null || newUser.iban!.isEmpty) &&
              _user?.iban != null &&
              _user!.iban!.isNotEmpty) {
            newUser = newUser.copyWith(iban: _user!.iban);
          }
          await updateUser(newUser);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {}

    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
