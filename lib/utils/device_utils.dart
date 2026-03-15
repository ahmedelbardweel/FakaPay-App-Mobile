import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:math';

class DeviceUtils {
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('unique_device_id');

    if (deviceId == null) {
      // Create a persistent random ID for this device
      deviceId =
          'device_${Platform.operatingSystem}_${Random().nextInt(10000000)}';
      await prefs.setString('unique_device_id', deviceId);
    }

    return deviceId;
  }
}
