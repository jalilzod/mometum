import 'package:flutter/foundation.dart';

import '../data/json_store.dart';
import '../models/settings.dart';

class SettingsStore extends ChangeNotifier {
  SettingsStore(this._db);

  final JsonStore _db;
  static const _key = 'settings';

  AppSettings _value = const AppSettings();
  AppSettings get value => _value;

  Future<void> load() async {
    final raw = await _db.read(_key);
    if (raw is Map) _value = AppSettings.fromJson(Map<String, dynamic>.from(raw));
    notifyListeners();
  }

  Future<void> reset() async {
    _value = const AppSettings();
    notifyListeners();
    await _db.write(_key, _value.toJson());
  }

  Future<void> update(AppSettings Function(AppSettings s) change) async {
    _value = change(_value);
    notifyListeners();
    await _db.write(_key, _value.toJson());
  }
}
