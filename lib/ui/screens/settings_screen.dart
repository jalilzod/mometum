import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../l10n/strings.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../state/settings_store.dart';
import '../../state/task_store.dart';
import '../navigation.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = context.watch<SettingsStore>();
    final s = settingsStore.value;
    final tasks = context.read<TaskStore>();
    final p = context.palette;
    final t = S.current;

    Future<void> setAndResync(bool notif, bool nudges) async {
      await settingsStore
          .update((x) => x.copyWith(notificationsEnabled: notif, motivationNudges: nudges));
      await tasks.rescheduleAll();
    }

    Future<void> setLanguage(String? code) async {
      await settingsStore.update((x) => x.copyWith(languageCode: () => code));
      // Re-schedule after the new locale is applied so notifications use it.
      WidgetsBinding.instance.addPostFrameCallback((_) => tasks.rescheduleAll());
    }

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 180),
      children: [
        Text(t.settingsTitle,
            style: TextStyle(
                color: p.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(t.makeItYours, style: context.text.headlineMedium?.copyWith(fontSize: 27)),
        SectionHeader(t.secProfile),
        _Group(children: [
          _Tile(
            icon: Icons.person_rounded,
            title: t.yourName,
            subtitle: s.userName.isEmpty ? t.nameHint : s.userName,
            onTap: () => _editName(context, s.userName),
          ),
          _Tile(
            icon: Icons.flag_rounded,
            title: t.dailyGoal,
            subtitle: t.tasksPerDay(s.dailyGoal),
            trailing: _Stepper(
              value: s.dailyGoal,
              onChanged: (v) => settingsStore.update((x) => x.copyWith(dailyGoal: v)),
            ),
          ),
        ]),
        SectionHeader(t.secAppearance),
        _Group(children: [
          _Segmented<ThemeMode>(
            value: s.themeMode,
            onChanged: (m) => settingsStore.update((x) => x.copyWith(themeMode: m)),
            options: [
              (ThemeMode.system, Icons.brightness_auto_rounded, t.themeSystem),
              (ThemeMode.light, Icons.light_mode_rounded, t.themeLight),
              (ThemeMode.dark, Icons.dark_mode_rounded, t.themeDark),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(children: [
              Icon(Icons.translate_rounded, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Text(t.language, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          _Segmented<String?>(
            value: s.languageCode,
            onChanged: setLanguage,
            options: [
              (null, Icons.phone_iphone_rounded, t.langSystem),
              ('en', Icons.language_rounded, 'English'),
              ('ru', Icons.language_rounded, 'Русский'),
            ],
          ),
          _Tile(
            icon: Icons.celebration_rounded,
            title: t.celebrations,
            subtitle: t.celebrationsSub,
            trailing: Switch(
              value: s.celebrations,
              onChanged: (v) => settingsStore.update((x) => x.copyWith(celebrations: v)),
            ),
          ),
        ]),
        SectionHeader(t.secNotifications),
        _Group(children: [
          _Tile(
            icon: Icons.notifications_active_rounded,
            title: t.dueAlerts,
            subtitle: t.dueAlertsSub,
            trailing: Switch(
              value: s.notificationsEnabled,
              onChanged: (v) async {
                if (v) await NotificationService.instance.requestPermissions(exactAlarms: true);
                await setAndResync(v, s.motivationNudges);
              },
            ),
          ),
          _Tile(
            icon: Icons.format_quote_rounded,
            title: t.nudges,
            subtitle: t.nudgesSub,
            trailing: Switch(
              value: s.motivationNudges,
              onChanged: s.notificationsEnabled ? (v) => setAndResync(true, v) : null,
            ),
          ),
          _Tile(
            icon: Icons.alarm_rounded,
            title: t.defaultReminder,
            subtitle: Fmt.reminder(s.defaultReminderMinutes),
            onTap: () => _pickReminder(context, s.defaultReminderMinutes),
          ),
          _Tile(
            icon: Icons.send_rounded,
            title: t.testNotif,
            subtitle: t.testNotifSub,
            onTap: () async {
              await NotificationService.instance.requestPermissions(exactAlarms: true);
              await NotificationService.instance.showNow(t.testNotifTitle, t.testNotifBody);
            },
          ),
        ]),
        SectionHeader(t.secData),
        _Group(children: [
          _Tile(
            icon: Icons.ios_share_rounded,
            title: t.exportTitle,
            subtitle: t.exportSub,
            onTap: () => _export(context),
          ),
          _Tile(
            icon: Icons.download_rounded,
            title: t.importTitle,
            subtitle: t.importSub,
            onTap: () => _import(context),
          ),
          _Tile(
            icon: Icons.cleaning_services_rounded,
            title: t.clearDone,
            subtitle: t.clearDoneSub,
            onTap: () => _clearCompleted(context),
          ),
          _Tile(
            icon: Icons.delete_forever_rounded,
            title: t.deleteAll,
            subtitle: t.deleteAllSub,
            danger: true,
            onTap: () => _deleteAll(context),
          ),
        ]),
        SectionHeader(t.secAbout),
        _Group(children: [
          _Tile(
            icon: Icons.privacy_tip_rounded,
            title: t.privacyPolicy,
            subtitle: t.privacySub,
            onTap: _openPrivacy,
          ),
        ]),
        const SizedBox(height: 28),
        Center(
          child: Column(children: [
            ShaderMask(
              shaderCallback: (r) => p.accentGradient.createShader(r),
              child: const Text('Momentum',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(height: 4),
            Text(t.aboutLine, style: TextStyle(color: p.textMuted, fontSize: 12)),
          ]),
        ),
      ],
    );
  }

  static void _snack(String msg) => appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  static Future<void> _openPrivacy() async {
    final uri = Uri.parse('${Links.privacyPolicy}?lang=${S.current.code}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _snack(S.current.linkFailed);
  }

  Future<void> _editName(BuildContext context, String current) async {
    final store = context.read<SettingsStore>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name != null) await store.update((x) => x.copyWith(userName: name.trim()));
  }

  Future<void> _pickReminder(BuildContext context, int? current) async {
    final store = context.read<SettingsStore>();
    const options = <int?>[null, 0, 5, 15, 30, 60, 1440];
    final picked = await showModalBottomSheet<(int?,)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final m in options)
            ListTile(
              title: Text(Fmt.reminder(m)),
              trailing: m == current ? Icon(Icons.check_rounded, color: ctx.palette.accent) : null,
              onTap: () => Navigator.pop(ctx, (m,)),
            ),
        ]),
      ),
    );
    if (picked != null) {
      await store.update((x) => x.copyWith(defaultReminderMinutes: () => picked.$1));
    }
  }

  Future<void> _export(BuildContext context) async {
    final tasks = context.read<TaskStore>().all;
    final settings = context.read<SettingsStore>().value;
    try {
      await BackupService.export(tasks, settings);
    } catch (e) {
      _snack(S.current.exportFailed(e));
    }
  }

  Future<void> _import(BuildContext context) async {
    final taskStore = context.read<TaskStore>();
    final settingsStore = context.read<SettingsStore>();
    final t = S.current;
    BackupData? picked;
    try {
      picked = await BackupService.pickAndRead();
    } on BackupException catch (e) {
      _snack(e.message);
      return;
    } catch (e) {
      _snack(t.openFailed(e));
      return;
    }
    if (picked == null || !context.mounted) return;
    final BackupData data = picked;
    if (data.tasks.isEmpty) {
      _snack(t.backupEmpty);
      return;
    }
    final count = data.tasks.length;

    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.importQ(count)),
        content: Text(t.importBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.merge)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.replace, style: TextStyle(color: ctx.palette.danger)),
          ),
        ],
      ),
    );
    if (replace == null) return;
    final n = await taskStore.importTasks(data.tasks, replace: replace);
    final importedSettings = data.settings;
    if (replace && importedSettings != null) {
      await settingsStore.update((_) => importedSettings);
    }
    _snack(t.imported(n));
  }

  Future<void> _clearCompleted(BuildContext context) async {
    final store = context.read<TaskStore>();
    final t = S.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearDoneQ),
        content: Text(t.clearDoneBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.clear, style: TextStyle(color: ctx.palette.danger)),
          ),
        ],
      ),
    );
    if (ok == true) _snack(t.removed(await store.clearCompleted()));
  }

  Future<void> _deleteAll(BuildContext context) async {
    final taskStore = context.read<TaskStore>();
    final settingsStore = context.read<SettingsStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAllDialog(),
    );
    if (ok != true) return;
    await taskStore.deleteAll();
    await settingsStore.reset();
    _snack(S.current.allDeleted);
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged, required this.options});
  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, IconData, String)> options;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        for (final (v, icon, label) in options)
          Expanded(
            child: Pressable(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: value == v ? p.accentGradient : null,
                  color: value == v ? null : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Icon(icon, color: value == v ? Colors.white : p.textMuted),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: value == v ? Colors.white : p.text,
                      )),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1 && children[i] is _Tile)
              Divider(height: 1, indent: 64, color: context.palette.border.o(0.6)),
          ],
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = danger ? p.danger : p.accent;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: c.o(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.w700, color: danger ? p.danger : p.text)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: p.textMuted, fontSize: 12.5)),
      trailing:
          trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: p.textMuted) : null),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget btn(IconData i, int v) => Pressable(
          scale: 0.85,
          onTap: v < 1 || v > 50 ? null : () => onChanged(v),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 18, color: p.text),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove_rounded, value - 1),
      SizedBox(
        width: 34,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$value',
                key: ValueKey(value),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ),
      btn(Icons.add_rounded, value + 1),
    ]);
  }
}

/// Owns its TextEditingController so it is disposed only after the dialog's
/// closing animation finishes.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.current;
    return AlertDialog(
      title: Text(t.yourName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: t.nameExample),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(t.save),
        ),
      ],
    );
  }
}

/// Requires typing a confirmation word before irreversible data deletion.
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.current;
    final p = context.palette;
    final confirmed = _controller.text.trim().toUpperCase() == t.deleteWord;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: p.danger, size: 36),
      title: Text(t.deleteAllQ),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t.deleteAllBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: t.typeDelete),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
        TextButton(
          onPressed: confirmed ? () => Navigator.pop(context, true) : null,
          child: Text(t.deleteForever,
              style: TextStyle(
                  color: confirmed ? p.danger : p.textMuted, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
