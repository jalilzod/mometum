import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/task.dart';
import '../../state/settings_store.dart';
import '../../state/task_store.dart';
import '../../l10n/strings.dart';
import '../widgets/common.dart';

Future<void> showTaskEditor(BuildContext context, {Task? task}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.o(0.4),
      builder: (_) => TaskEditor(task: task),
    );

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});
  final Task? task;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final _title = TextEditingController(text: widget.task?.title);
  late final _notes = TextEditingController(text: widget.task?.notes);
  final _subtaskInput = TextEditingController();

  late Priority _priority = widget.task?.priority ?? Priority.medium;
  late TaskCategory _category = widget.task?.category ?? TaskCategory.personal;
  late DateTime? _due = widget.task?.dueAt;
  late int? _reminder = widget.task != null
      ? widget.task!.reminderMinutes
      : context.read<SettingsStore>().value.defaultReminderMinutes;
  late int? _estimate = widget.task?.estimateMinutes;
  late Repeat _repeat = widget.task?.repeat ?? Repeat.none;
  late final List<Subtask> _subtasks = [...?widget.task?.subtasks];

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _subtaskInput.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final store = context.read<TaskStore>();
    final base = widget.task;
    final task = base == null
        ? Task.create(
            title: title,
            notes: _notes.text.trim(),
            priority: _priority,
            category: _category,
            dueAt: _due,
            reminderMinutes: _reminder,
            estimateMinutes: _estimate,
            repeat: _repeat,
            subtasks: _subtasks,
          )
        : base.copyWith(
            title: title,
            notes: _notes.text.trim(),
            priority: _priority,
            category: _category,
            dueAt: () => _due,
            reminderMinutes: () => _reminder,
            estimateMinutes: () => _estimate,
            repeat: _repeat,
            subtasks: _subtasks,
          );
    HapticFeedback.lightImpact();
    await store.upsert(task);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate([DateTime? preset]) async {
    final now = DateTime.now();
    final DateTime? date = preset ??
        await showDatePicker(
          context: context,
          initialDate: _due ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 10),
        );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _due != null
          ? TimeOfDay.fromDateTime(_due!)
          : TimeOfDay(hour: (now.hour + 1).clamp(0, 23), minute: 0),
    );
    if (time == null || !mounted) return;
    setState(() => _due = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addSubtask() {
    final t = _subtaskInput.text.trim();
    if (t.isEmpty) return;
    setState(() => _subtasks.add(Subtask(id: newId(), title: t)));
    _subtaskInput.clear();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
            child: Row(children: [
              Text(_isEdit ? S.current.editTask : S.current.newTask, style: context.text.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: p.textMuted),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
              children: [
                TextField(
                  controller: _title,
                  autofocus: !_isEdit,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(hintText: S.current.titleHint),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: S.current.notesHint),
                ),
                _label(S.current.lblPriority),
                Row(children: [
                  for (final pr in Priority.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: pr == Priority.urgent ? 0 : 8),
                        child: _PriorityOption(
                          priority: pr,
                          selected: _priority == pr,
                          onTap: () => setState(() => _priority = pr),
                        ),
                      ),
                    ),
                ]),
                _label(S.current.lblCategory),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in TaskCategory.values)
                    _ChoiceChip(
                      label: c.label,
                      icon: c.icon,
                      color: c.color,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                ]),
                _label(S.current.lblDue),
                _dueSection(context),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _due == null
                      ? const SizedBox(width: double.infinity)
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _label(S.current.lblReminder),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final m in const [null, 0, 5, 15, 30, 60, 1440])
                              _ChoiceChip(
                                label: m == null
                                    ? S.current.none
                                    : m == 0
                                        ? S.current.onTime
                                        : m < 60
                                            ? S.current.minutesShort(m)
                                            : m == 60
                                                ? S.current.oneHour
                                                : S.current.oneDay,
                                selected: _reminder == m,
                                onTap: () => setState(() => _reminder = m),
                              ),
                          ]),
                          _label(S.current.lblRepeat),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final r in Repeat.values)
                              _ChoiceChip(
                                label: r.label,
                                icon: r == Repeat.none ? null : Icons.repeat_rounded,
                                selected: _repeat == r,
                                onTap: () => setState(() => _repeat = r),
                              ),
                          ]),
                        ]),
                ),
                _label(S.current.lblEstimate),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in const [null, 5, 15, 30, 60, 120, 240])
                    _ChoiceChip(
                      label: m == null ? S.current.none : Fmt.hours(Duration(minutes: m)),
                      icon: m == null ? null : Icons.hourglass_bottom_rounded,
                      selected: _estimate == m,
                      onTap: () => setState(() => _estimate = m),
                    ),
                ]),
                _label(S.current.lblChecklist),
                ..._subtasks.map((s) => _subtaskRow(context, s)),
                TextField(
                  controller: _subtaskInput,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _addSubtask(),
                  decoration: InputDecoration(
                    hintText: S.current.addStep,
                    prefixIcon: Icon(Icons.add_rounded, color: p.accent),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.keyboard_return_rounded, color: p.textMuted),
                      onPressed: _addSubtask,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: _isEdit ? S.current.saveChanges : S.current.addTask,
                  icon: _isEdit ? Icons.check_rounded : Icons.add_task_rounded,
                  onTap: _title.text.trim().isEmpty ? null : _save,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _dueSection(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final presets = <String, DateTime>{
      S.current.today: today,
      S.current.tomorrow: today.add(const Duration(days: 1)),
      S.current.nextWeek: today.add(Duration(days: 8 - today.weekday)),
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in presets.entries)
          _ChoiceChip(
            label: e.key,
            selected: _due != null && Fmt.sameDay(_due!, e.value),
            onTap: () => _pickDate(e.value),
          ),
        _ChoiceChip(label: S.current.pickDate, icon: Icons.calendar_month_rounded, onTap: _pickDate),
      ]),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _due == null
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey(_due),
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [p.accent.o(0.14), p.accentAlt.o(0.10)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(Icons.event_rounded, color: p.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(Fmt.due(_due!),
                          style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_calendar_rounded, color: p.accent),
                      onPressed: _pickDate,
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: p.textMuted),
                      onPressed: () => setState(() => _due = null),
                    ),
                  ]),
                ),
              ),
      ),
    ]);
  }

  Widget _subtaskRow(BuildContext context, Subtask s) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          CheckCircle(
            checked: s.done,
            color: p.textMuted,
            size: 22,
            onTap: () => setState(() {
              final i = _subtasks.indexOf(s);
              _subtasks[i] = s.copyWith(done: !s.done);
            }),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(s.title)),
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded, color: p.textMuted, size: 20),
            onPressed: () => setState(() => _subtasks.remove(s)),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10, left: 2),
        child: Text(text.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: context.palette.textMuted,
            )),
      );
}

class _PriorityOption extends StatelessWidget {
  const _PriorityOption({required this.priority, required this.selected, required this.onTap});
  final Priority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = priority.color;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c : p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? c : p.border),
          boxShadow: selected
              ? [BoxShadow(color: c.o(0.35), blurRadius: 14, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(children: [
          Icon(priority.icon, color: selected ? Colors.white : c, size: 20),
          const SizedBox(height: 4),
          Text(priority.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : p.text,
              )),
        ]),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.color,
  });
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.accent;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.o(0.15) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? c : p.border, width: selected ? 1.6 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? c : p.textMuted),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: selected ? c : p.text,
              )),
        ]),
      ),
    );
  }
}
