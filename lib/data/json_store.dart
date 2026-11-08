import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny durable key-file store. Each key is one JSON file in the app's
/// documents directory. Writes are serialised and atomic (temp file + rename)
/// so a crash mid-write can never corrupt saved data.
class JsonStore {
  JsonStore._(this._dir);

  final Directory _dir;
  Future<void> _queue = Future.value();

  static Future<JsonStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/momentum');
    if (!await dir.exists()) await dir.create(recursive: true);
    return JsonStore._(dir);
  }

  File _file(String key) => File('${_dir.path}/$key.json');

  Future<Object?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    try {
      return jsonDecode(await file.readAsString());
    } on FormatException {
      // Keep the broken file for manual recovery instead of silently losing it.
      await file.copy('${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
      return null;
    }
  }

  Future<void> write(String key, Object? value) {
    final encoded = jsonEncode(value);
    _queue = _queue.then((_) async {
      final target = _file(key);
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsString(encoded, flush: true);
      await tmp.rename(target.path);
    }).catchError((_) {});
    return _queue;
  }
}
