import 'package:shared_preferences/shared_preferences.dart';

class PinUtils {
  static const String _pinEnabledKey = 'is_pin_enabled';
  static const String _savedPinKey = 'saved_pin';

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
  }

  static Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPinKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  static Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString(_savedPinKey);
    return savedPin != null && savedPin == inputPin;
  }
}
