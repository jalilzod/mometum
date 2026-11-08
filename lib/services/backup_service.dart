import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/settings.dart';
import '../models/task.dart';

class BackupData {
  const BackupData(this.tasks, this.settings, this.exportedAt);
  final List<Task> tasks;
  final AppSettings? settings;
  final DateTime? exportedAt;
}

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Exports everything to a portable JSON file and imports it on another phone.
abstract final class BackupService {
  static const _format = 'momentum-backup';
  static const _version = 1;

  static String encode(List<Task> tasks, AppSettings settings) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': _format,
        'version': _version,
        'exportedAt': DateTime.now().toIso8601String(),
        'taskCount': tasks.length,
        'settings': settings.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      });

  static BackupData decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      throw BackupException(S.current.errNotJson);
    }
    // Accept both our wrapped format and a bare list of tasks.
    final List? list = raw is List ? raw : (raw is Map ? raw['tasks'] as List? : null);
    if (list == null) throw BackupException(S.current.errNoTasks);
    if (raw is Map && raw['format'] != null && raw['format'] != _format) {
      throw BackupException(S.current.errNotMomentum);
    }
    final tasks = list
        .whereType<Map>()
        .map((m) => Task.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final s = raw is Map && raw['settings'] is Map
        ? AppSettings.fromJson(Map<String, dynamic>.from(raw['settings'] as Map))
        : null;
    final at = raw is Map ? DateTime.tryParse('${raw['exportedAt']}') : null;
    return BackupData(tasks, s, at);
  }

  /// Writes the backup to a temp file and opens the system share sheet so the
  /// user can save it to Files / Drive / Telegram / AirDrop, etc.
  static Future<void> export(List<Task> tasks, AppSettings settings) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final file = File('${dir.path}/momentum-backup-$stamp.json');
    await file.writeAsString(encode(tasks, settings), flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: S.current.backupSubject,
      text: '${S.current.backupSubject} · ${S.current.tasksCount(tasks.length)}',
    );
  }

  /// Returns `null` if the user cancelled the picker.
  static Future<BackupData?> pickAndRead() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final String content;
    if (f.bytes != null) {
      content = utf8.decode(f.bytes!, allowMalformed: true);
    } else if (f.path != null) {
      content = await File(f.path!).readAsString();
    } else {
      throw BackupException(S.current.errRead);
    }
    return decode(content);
  }
}
