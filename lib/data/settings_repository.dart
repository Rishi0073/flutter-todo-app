import 'package:shared_preferences/shared_preferences.dart';

// Small settings store, kept separate from task storage so
// each concern has exactly one owner.
abstract class SettingsRepository {
  Future<bool> loadDarkMode();
  Future<void> saveDarkMode(bool enabled);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const String _darkModeKey = 'dark_mode';

  @override
  Future<bool> loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  @override
  Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}
