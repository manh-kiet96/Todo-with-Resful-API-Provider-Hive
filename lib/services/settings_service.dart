import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const _boxName = 'app_settings';
  static const _keyUseMock = 'useMock';
  static const _keyApiKey = 'apiKey';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  bool getUseMock() {
    return _box.get(_keyUseMock, defaultValue: false) as bool;
  }

  Future<void> setUseMock(bool value) async {
    await _box.put(_keyUseMock, value);
  }

  String? getApiKey() {
    return _box.get(_keyApiKey) as String?;
  }

  Future<void> setApiKey(String apiKey) async {
    await _box.put(_keyApiKey, apiKey);
  }
}
