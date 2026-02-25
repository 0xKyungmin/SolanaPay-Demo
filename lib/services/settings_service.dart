import 'package:shared_preferences/shared_preferences.dart';

import '../models/brand.dart';

class SettingsService {
  static const _brandKey = 'selected_brand';
  static SettingsService? _instance;
  late SharedPreferences _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  /// Sync access (only after getInstance called)
  static SettingsService get instance => _instance!;

  Brand get selectedBrand {
    final index = _prefs.getInt(_brandKey) ?? 0;
    return Brand.values[index.clamp(0, Brand.values.length - 1)];
  }

  Future<void> setBrand(Brand brand) async {
    await _prefs.setInt(_brandKey, brand.index);
  }
}
