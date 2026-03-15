import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://faka-pay.onrender.com/';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        // Handle global errors if needed
        return handler.next(e);
      },
    ));
  }

  Future<Response> login(String email, String password, String deviceId) async {
    return _dio.post('api/auth/login', data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
    });
  }

  Future<Response> register(dynamic data) async {
    return _dio.post('api/auth/register', data: data);
  }

  Future<Response> logout() async {
    return _dio.post('api/auth/logout');
  }

  Future<Response> getUser() async {
    return _dio.get('api/user');
  }

  Future<Response> getWalletData() async {
    return _dio.get('api/wallet/data');
  }

  Future<Response> createTransfer(double amount) async {
    return _dio.post('api/wallet/qr/create', data: {'amount': amount});
  }

  Future<Response> processTransfer(String token, double amount) async {
    return _dio.post('api/wallet/qr/process', data: {
      'token': token,
      'amount': amount,
    });
  }

  Future<Response> syncTransfers(List<Map<String, dynamic>> tokens) async {
    return _dio.post('api/wallet/qr/sync', data: {'tokens': tokens});
  }

  Future<Response> checkStatus(String token) async {
    return _dio.get('api/wallet/qr/$token/status');
  }

  Future<Response> topUp(double amount) async {
    return _dio.post('api/wallet/topup', data: {'amount': amount});
  }
}
