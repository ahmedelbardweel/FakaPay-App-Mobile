import 'package:dio/dio.dart';

void main(List<String> args) async {
  const token = '32|vu3iqNKUyKHXFqdr0Qn9IyBIvpkBvu0BFpmertTJ282d588f';
  final dio = Dio(BaseOptions(
    baseUrl: 'https://faka-pay.onrender.com/',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  ));

  print('--- Wallet API Deep Diagnostic ---');
  print('Target: api/wallet/data');
  print('Token suffix: ...${token.substring(token.length - 5)}');

  try {
    print('\nSending request...');
    final response = await dio.get('api/wallet/data');
    print('\n[SUCCESS] HTTP Status: ${response.statusCode}');
    print('Raw response body:');
    print(response.data);

    if (response.data['success'] == true) {
      final balance = response.data['data']['balance'];
      print('\nDetected Balance: $balance');
      if (balance == 0 || balance == 0.0) {
        print(
            'WARNING: Balance is exactly zero. Check if this is correct for this account.');
      }
    } else {
      print('\n[API ERROR] success=false');
      print('Message: ${response.data['message']}');
    }
  } on DioException catch (e) {
    print('\n[NETWORK ERROR]');
    print('Status: ${e.response?.statusCode}');
    print('Error type: ${e.type}');
    print('Response headers: ${e.response?.headers}');
    print('Response body: ${e.response?.data}');
  } catch (e) {
    print('\n[UNEXPECTED ERROR]: $e');
  }
}
