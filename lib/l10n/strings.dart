import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// All user-facing text in English and Russian.
///
/// `S.current` is switched by the app whenever the locale changes, so it can
/// be used from widgets *and* from services (notifications, insights).
class S {
  const S._(this.ru);

  final bool ru;

  static const en = S._(false);
  static const russian = S._(true);
  static S current = en;

  static const supportedLocales = [Locale('en'), Locale('ru')];

  static void load(Locale locale) {
    current = locale.languageCode == 'ru' ? russian : en;
    Intl.defaultLocale = current.code;
  }

  String get code => ru ? 'ru' : 'en';

  String _t(String en, String ru) => this.ru ? ru : en;

  /// Russian plural forms: 1 задача, 2 задачи, 5 задач.
  String _pl(int n, String one, String few, String many) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return one;
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
    return many;
  }

  String tasksCount(int n) =>
      ru ? '$n ${_pl(n, 'задача', 'задачи', 'задач')}' : '$n task${n == 1 ? '' : 's'}';

  // ── Enums ───────────────────────────────────────────────────────────────
  String get prLow => _t('Low', 'Низкий');
  String get prMedium => _t('Medium', 'Средний');
  String get prHigh => _t('High', 'Высокий');
  String get prUrgent => _t('Urgent', 'Срочный');

  String get catPersonal => _t('Personal', 'Личное');
  String get catWork => _t('Work', 'Работа');
  String get catStudy => _t('Study', 'Учёба');
  String get catHealth => _t('Health', 'Здоровье');
  String get catShopping => _t('Shopping', 'Покупки');
  String get catHome => _t('Home', 'Дом');
  String get catOther => _t('Other', 'Другое');

  String get repNever => _t('Never', 'Нет');
  String get repDaily => _t('Daily', 'Ежедневно');
  String get repWeekly => _t('Weekly', 'Еженедельно');
  String get repMonthly => _t('Monthly', 'Ежемесячно');

  String get qDoFirst => _t('Do first', 'Сделать сейчас');
  String get qDoFirstSub => _t('Urgent & important', 'Срочно и важно');
  String get qSchedule => _t('Schedule', 'Запланировать');
  String get qScheduleSub => _t('Important, not urgent', 'Важно, не срочно');
  String get qQuick => _t('Quick hits', 'Быстрые дела');
  String get qQuickSub => _t('Urgent, less important', 'Срочно, менее важно');
  String get qLater => _t('Later', 'Потом');
  String get qLaterSub => _t('Neither — park it', 'Ни то, ни другое');

  // ── Time formatting ─────────────────────────────────────────────────────
  String get today => _t('Today', 'Сегодня');
  String get tomorrow => _t('Tomorrow', 'Завтра');
  String get yesterday => _t('Yesterday', 'Вчера');
  String inTime(String t) => _t('in $t', 'через $t');
  String overdueBy(String t) => _t('$t overdue', 'просрочено на $t');
  String get unitD => _t('d', 'д');
  String get unitH => _t('h', 'ч');
  String get unitM => _t('m', 'мин');
  String get unitS => _t('s', 'с');

  String get reminderNone => _t('No early reminder', 'Без напоминания');
  String get reminderAtTime => _t('At due time', 'В срок');
  String reminderMin(int m) => _t('$m min before', 'За $m мин');
  String reminderHours(int h) =>
      ru ? 'За $h ${_pl(h, 'час', 'часа', 'часов')}' : (h == 1 ? '1 hour before' : '$h hours before');
  String reminderDays(int d) =>
      ru ? 'За $d ${_pl(d, 'день', 'дня', 'дней')}' : (d == 1 ? '1 day before' : '$d days before');

  String get greetLate => _t('Working late', 'Доброй ночи');
  String get greetMorning => _t('Good morning', 'Доброе утро');
  String get greetAfternoon => _t('Good afternoon', 'Добрый день');
  String get greetEvening => _t('Good evening', 'Добрый вечер');

  // ── Navigation ──────────────────────────────────────────────────────────
  String get navTasks => _t('Tasks', 'Задачи');
  String get navDashboard => _t('Dashboard', 'Статистика');
  String get navGuide => _t('Guide', 'Гид');
  String get navSettings => _t('Settings', 'Настройки');

  // ── Tasks screen ────────────────────────────────────────────────────────
  String get fAll => _t('All', 'Все');
  String get fToday => _t('Today', 'Сегодня');
  String get fUpcoming => _t('Upcoming', 'Предстоящие');
  String get fOverdue => _t('Overdue', 'Просрочено');
  String get fDone => _t('Done', 'Готово');
  String get secOverdue => _t('Overdue', 'Просрочено');
  String get secToday => _t('Today', 'Сегодня');
  String get secUpcoming => _t('Upcoming', 'Предстоящие');
  String get secAnytime => _t('Anytime', 'Без срока');
  String get secCompleted => _t('Completed', 'Выполнено');
  String get searchHint => _t('Search tasks', 'Поиск задач');
  String get filterPriority => _t('Filter by priority', 'Фильтр по приоритету');
  String get allPriorities => _t('All priorities', 'Все приоритеты');
  String get nothingPressing => _t('Nothing pressing today ✨', 'Сегодня ничего срочного ✨');
  String needYouToday(int n) => ru
      ? 'Сегодня ${_pl(n, 'ждёт', 'ждут', 'ждут')} ${tasksCount(n)}'
      : '${tasksCount(n)} need${n == 1 ? 's' : ''} you today';
  String ofGoal(int g) => _t('of $g', 'из $g');
  String overdueBanner(int n) =>
      _t('$n overdue — let’s fix that', 'Просрочено: $n — давай исправим');
  String get emptyNoMatchTitle => _t('No matches', 'Ничего не найдено');
  String get emptyNoMatchBody =>
      _t('Try a different search or clear the priority filter.', 'Измени запрос или сбрось фильтр.');
  String get emptyDoneTitle => _t('Nothing completed yet', 'Пока ничего не выполнено');
  String get emptyDoneBody =>
      _t('Finish a task and it will show up here.', 'Выполненные задачи появятся здесь.');
  String get emptyOverdueTitle => _t('Nothing overdue', 'Нет просроченных');
  String get emptyOverdueBody => _t('You’re fully on track. Beautiful.', 'Ты всё успеваешь. Отлично!');
  String get emptyStartTitle => _t('A fresh start', 'С чистого листа');
  String get emptyStartBody => _t(
      'Tap + to add your first task. Set a due date and Momentum will remind you.',
      'Нажми +, чтобы добавить первую задачу. Укажи срок — Momentum напомнит.');

  // ── Tile / actions ──────────────────────────────────────────────────────
  String get swipeComplete => _t('Complete', 'Готово');
  String get swipeReopen => _t('Reopen', 'Вернуть');
  String get swipeDelete => _t('Delete', 'Удалить');
  String completed(String t) => _t('Completed “$t”', 'Выполнено: «$t»');
  String deleted(String t) => _t('Deleted “$t”', 'Удалено: «$t»');
  String get undo => _t('UNDO', 'ОТМЕНИТЬ');
  String focusStarted(String q) => _t('Focus started · $q', 'Фокус начат · $q');

  // ── Editor ──────────────────────────────────────────────────────────────
  String get newTask => _t('New task', 'Новая задача');
  String get editTask => _t('Edit task', 'Изменить задачу');
  String get titleHint => _t('What needs to be done?', 'Что нужно сделать?');
  String get notesHint => _t('Notes (optional)', 'Заметки (необязательно)');
  String get lblPriority => _t('Priority', 'Приоритет');
  String get lblCategory => _t('Category', 'Категория');
  String get lblDue => _t('Due', 'Срок');
  String get lblReminder => _t('Reminder', 'Напоминание');
  String get lblRepeat => _t('Repeat', 'Повтор');
  String get lblEstimate => _t('Estimated time', 'Оценка времени');
  String get lblChecklist => _t('Checklist', 'Чек-лист');
  String get nextWeek => _t('Next week', 'След. неделя');
  String get pickDate => _t('Pick date', 'Выбрать дату');
  String get none => _t('None', 'Нет');
  String get onTime => _t('On time', 'В срок');
  String minutesShort(int m) => _t('$m min', '$m мин');
  String get oneHour => _t('1 hour', '1 час');
  String get oneDay => _t('1 day', '1 день');
  String get addStep => _t('Add a step', 'Добавить шаг');
  String get addTask => _t('Add task', 'Добавить');
  String get saveChanges => _t('Save changes', 'Сохранить');

  // ── Detail ──────────────────────────────────────────────────────────────
  String get edit => _t('Edit', 'Изменить');
  String get delete => _t('Delete', 'Удалить');
  String get cancel => _t('Cancel', 'Отмена');
  String get save => _t('Save', 'Сохранить');
  String get completedTag => _t('Completed', 'Выполнено');
  String get focusSessions => _t('Focus sessions', 'Сессии фокуса');
  String get markNotDone => _t('Mark as not done', 'Вернуть в работу');
  String get completeTask => _t('Complete task', 'Выполнить задачу');
  String get deleteTaskQ => _t('Delete task?', 'Удалить задачу?');
  String deleteTaskBody(String t) =>
      _t('“$t” will be removed. You can undo right after.', '«$t» будет удалена. Можно сразу отменить.');
  String get focusing => _t('FOCUSING', 'В ФОКУСЕ');
  String get timeSpent => _t('TIME SPENT', 'ПОТРАЧЕНО');
  String estimateOf(String e, int pct) => _t('Estimate $e · $pct%', 'Оценка $e · $pct%');
  String get stop => _t('Stop', 'Стоп');
  String get start => _t('Start', 'Старт');
  String get resume => _t('Resume', 'Продолжить');
  String get infoDue => _t('Due', 'Срок');
  String get infoReminder => _t('Reminder', 'Напоминание');
  String get infoEstimate => _t('Estimate', 'Оценка');
  String get infoCompleted => _t('Completed', 'Выполнено');
  String get infoCreated => _t('Created', 'Создано');
  String get noDate => _t('No date', 'Без даты');

  // ── Celebration ─────────────────────────────────────────────────────────
  String get celebOnTime => _t('Right on time!', 'Точно в срок!');
  String get celebLate => _t('Done — and that counts', 'Готово — и это главное');
  String get celebDone => _t('Task complete!', 'Задача выполнена!');
  String get celebOnTimeSub =>
      _t('You beat the deadline. That’s how momentum is built.', 'Ты уложился в срок. Так и набирается темп.');
  String get celebLateSub =>
      _t('A little late, but finished. Next one on time.', 'Чуть позже, но сделано. Следующую — вовремя.');
  String get celebDoneSub => _t('One less thing on your mind.', 'Одной заботой меньше.');
  String get keepMomentum => _t('Keep the momentum', 'Продолжаем!');
  String get close => _t('Close', 'Закрыть');

  // ── Dashboard ───────────────────────────────────────────────────────────
  String get dashTitle => _t('DASHBOARD', 'СТАТИСТИКА');
  String get yourProgress => _t('Your progress', 'Твой прогресс');
  String get dailyGoalShort => _t('daily goal', 'цель дня');
  String get goalCrushed => _t('Goal crushed 🎉', 'Цель выполнена 🎉');
  String doneOf(int d, int g) => _t('$d of $g tasks done', 'Выполнено $d из $g');
  String focused(String h) => _t('$h focused', 'В фокусе: $h');
  String stillDueToday(int n) => _t('$n still due today', 'Осталось на сегодня: $n');
  String get doneThisWeek => _t('Done this week', 'За неделю');
  String get onTimeRate => _t('On-time rate', 'Вовремя');
  String get focusThisWeek => _t('Focus this week', 'Фокус за неделю');
  String get dayStreak => _t('Day streak', 'Серия дней');
  String get hoursSuffix => _t('h', 'ч');
  String get last7 => _t('Last 7 days', 'Последние 7 дней');
  String get tabTasks => _t('Tasks', 'Задачи');
  String get tabFocus => _t('Focus', 'Фокус');
  String get openByPriority => _t('Open by priority', 'Открытые по приоритету');
  String get openByCategory => _t('Open by category', 'Открытые по категориям');
  String get noOpen => _t('No open tasks 🎉', 'Нет открытых задач 🎉');

  // ── Guide ───────────────────────────────────────────────────────────────
  String get guideTitle => _t('SMART GUIDE', 'УМНЫЙ ГИД');
  String get whatNext => _t('What to do next', 'Что делать дальше');
  String get allCaughtUp => _t('All caught up', 'Всё сделано');
  String get allCaughtUpBody =>
      _t('No open tasks. Enjoy the calm — or plan tomorrow.', 'Открытых задач нет. Отдохни — или спланируй завтра.');
  String get then => _t('Then', 'Затем');
  String get quickWins => _t('Quick wins', 'Быстрые победы');
  String get priorityMatrix => _t('Priority matrix', 'Матрица приоритетов');
  String get insights => _t('Insights', 'Подсказки');
  String get quoteOfDay => _t('Quote of the day', 'Цитата дня');
  String get doThisNext => _t('DO THIS NEXT', 'СДЕЛАЙ ЭТО');
  String get pause => _t('Pause', 'Пауза');
  String get startNow => _t('Start now', 'Начать');
  String approxMin(int m) => _t('~$m min', '~$m мин');

  String get rRunning =>
      _t('You’re already in flow — keep the timer going and finish it.', 'Ты уже в потоке — не останавливай таймер и доведи до конца.');
  String rOverdue(String t) => _t('Overdue by $t. Clearing it removes the biggest weight on your list.',
      'Просрочено на $t. Закрой её — и станет намного легче.');
  String rDueSoon(String rel, String pr) =>
      _t('Due $rel and marked $pr priority.', 'Срок $rel, приоритет: $pr.');
  String get rStarted => _t('You’ve already started this one — finishing beats starting something new.',
      'Ты уже начал(а) — закончить лучше, чем браться за новое.');
  String rQuick(int m) =>
      _t('A quick win (~$m min). Small wins build momentum.', 'Быстрая победа (~$m мин). Маленькие победы дают темп.');
  String get rHigh => _t('High impact. Tackle it while your energy is fresh.', 'Важная задача. Сделай её, пока есть силы.');
  String get rDefault => _t('Best next step based on priority and timing.', 'Лучший следующий шаг по приоритету и срокам.');

  String tipOverdueT(int n) => _t('$n overdue', 'Просрочено: $n');
  String get tipOverdueB => _t('Pick the smallest overdue task and finish it first — clearing backlog lowers stress fast.',
      'Начни с самой маленькой просроченной задачи — разбор завалов быстро снижает стресс.');
  String get tipUrgentT => _t('Too many “urgent” tasks', 'Слишком много «срочных»');
  String tipUrgentB(int n) => _t('You have $n urgent tasks. If everything is urgent, nothing is — downgrade a few.',
      'У тебя $n срочных задач. Когда срочно всё — не срочно ничего. Понизь часть.');
  String tipPeakT(String h) => _t('Your peak hour: $h', 'Твой продуктивный час: $h');
  String get tipPeakB => _t('You finish most tasks around this time. Schedule deep work here.',
      'В это время ты закрываешь больше всего задач. Планируй важное на него.');
  String tipSlowT(int pct) => _t('Tasks take $pct% longer', 'Задачи занимают на $pct% дольше');
  String get tipSlowB => _t('Your real time beats your estimates. Pad new estimates or split big tasks into subtasks.',
      'Реальное время больше оценки. Закладывай запас или дели крупные задачи на шаги.');
  String get tipFastT => _t('You’re faster than you think', 'Ты быстрее, чем думаешь');
  String get tipFastB => _t('You usually finish under estimate. You can fit more into your day.',
      'Обычно ты укладываешься быстрее оценки. В день можно вместить больше.');
  String tipReliableT(int pct) => _t('$pct% on time', '$pct% вовремя');
  String get tipReliableB =>
      _t('Excellent reliability. Keep setting realistic due dates.', 'Отличная надёжность. Продолжай ставить реальные сроки.');
  String get tipSlipT => _t('Deadlines are slipping', 'Сроки срываются');
  String get tipSlipB => _t('Try early reminders (30–60 min before) and start with a 10-minute focus session.',
      'Включи ранние напоминания (за 30–60 мин) и начинай с 10 минут фокуса.');
  String tipNoDueT(int n) => _t('$n tasks without a date', 'Задач без срока: $n');
  String get tipNoDueB =>
      _t('Undated tasks tend to drift. Give your top few a due date.', 'Задачи без срока откладываются. Назначь срок главным.');
  String tipStreakT(int n) => _t('$n-day streak', 'Серия: $n ${_pl(n, 'день', 'дня', 'дней')}');
  String get tipStreakB =>
      _t('You’ve completed something every day. Don’t break the chain!', 'Ты выполняешь задачи каждый день. Не прерывай серию!');
  String get tipNoFocusT => _t('No focus time yet today', 'Сегодня ещё нет фокуса');
  String get tipNoFocusB =>
      _t('Press Start on your top task. Even 15 minutes counts.', 'Нажми «Старт» на главной задаче. Даже 15 минут — это уже результат.');
  String get tipClearT => _t('All clear', 'Всё чисто');
  String get tipClearB => _t('Add a few tasks with due dates and estimates — the guide gets smarter as you use it.',
      'Добавь задачи со сроками и оценками — гид становится умнее со временем.');

  // ── Settings ────────────────────────────────────────────────────────────
  String get settingsTitle => _t('SETTINGS', 'НАСТРОЙКИ');
  String get makeItYours => _t('Make it yours', 'Под себя');
  String get secProfile => _t('Profile', 'Профиль');
  String get yourName => _t('Your name', 'Твоё имя');
  String get nameHint => _t('Used in your greeting', 'Для приветствия');
  String get nameExample => _t('e.g. Alex', 'например, Алекс');
  String get dailyGoal => _t('Daily goal', 'Цель на день');
  String tasksPerDay(int n) => _t('$n tasks per day', '${tasksCount(n)} в день');
  String get secAppearance => _t('Appearance', 'Оформление');
  String get themeSystem => _t('System', 'Системная');
  String get themeLight => _t('Light', 'Светлая');
  String get themeDark => _t('Dark', 'Тёмная');
  String get language => _t('Language', 'Язык');
  String get langSystem => _t('System', 'Системный');
  String get celebrations => _t('Celebrations', 'Поздравления');
  String get celebrationsSub => _t('Quote card when you finish a task', 'Цитата после выполнения задачи');
  String get secNotifications => _t('Notifications', 'Уведомления');
  String get dueAlerts => _t('Due date alerts', 'Напоминания о сроках');
  String get dueAlertsSub => _t('Notify when a task is due', 'Уведомлять, когда подходит срок');
  String get nudges => _t('Motivation nudges', 'Мотивация');
  String get nudgesSub => _t('Quotes if a task stays undone after it’s due', 'Цитаты, если задача просрочена');
  String get defaultReminder => _t('Default reminder', 'Напоминание по умолчанию');
  String get testNotif => _t('Send test notification', 'Тестовое уведомление');
  String get testNotifSub => _t('Check that alerts reach you', 'Проверить, что уведомления приходят');
  String get testNotifTitle => _t('Momentum is ready ✅', 'Momentum готов ✅');
  String get testNotifBody =>
      _t('Notifications are working. Go get things done!', 'Уведомления работают. Вперёд к делам!');
  String get secData => _t('Data', 'Данные');
  String get exportTitle => _t('Export backup (JSON)', 'Экспорт копии (JSON)');
  String get exportSub =>
      _t('Save or send all tasks to move to another phone', 'Сохрани или отправь задачи для переноса на другой телефон');
  String get importTitle => _t('Import backup', 'Импорт копии');
  String get importSub => _t('Restore tasks from a Momentum JSON file', 'Восстановить задачи из файла Momentum');
  String get clearDone => _t('Clear completed tasks', 'Очистить выполненные');
  String get clearDoneSub => _t('Free up your list (this cannot be undone)', 'Освободить список (нельзя отменить)');
  String get deleteAll => _t('Delete all data', 'Удалить все данные');
  String get deleteAllSub =>
      _t('Erase all tasks, history and settings from this device', 'Стереть все задачи, историю и настройки с устройства');
  String get deleteAllQ => _t('Delete all data?', 'Удалить все данные?');
  String get deleteAllBody => _t(
      'All tasks, focus history, scheduled reminders and settings will be permanently erased from this device. '
          'Momentum stores nothing online, so this cannot be undone.\n\nTip: export a backup first.',
      'Все задачи, история фокуса, напоминания и настройки будут безвозвратно удалены с устройства. '
          'Momentum ничего не хранит в интернете, поэтому отменить это нельзя.\n\nСовет: сначала сделай экспорт.');
  String get typeDelete => _t('Type DELETE to confirm', 'Введите УДАЛИТЬ для подтверждения');
  String get deleteWord => _t('DELETE', 'УДАЛИТЬ');
  String get deleteForever => _t('Delete forever', 'Удалить навсегда');
  String get allDeleted => _t('All data deleted', 'Все данные удалены');
  String exportFailed(Object e) => _t('Export failed: $e', 'Ошибка экспорта: $e');
  String openFailed(Object e) => _t('Could not open file: $e', 'Не удалось открыть файл: $e');
  String get backupEmpty => _t('That backup has no tasks.', 'В этой копии нет задач.');
  String importQ(int n) => _t('Import $n tasks?', 'Импортировать ${tasksCount(n)}?');
  String get importBody => _t('Merge keeps your current tasks and adds the imported ones. Replace wipes this device first.',
      '«Объединить» сохранит текущие задачи и добавит новые. «Заменить» сначала очистит устройство.');
  String get merge => _t('Merge', 'Объединить');
  String get replace => _t('Replace', 'Заменить');
  String imported(int n) => _t('Imported $n tasks ✅', 'Импортировано: $n ✅');
  String get clearDoneQ => _t('Clear completed tasks?', 'Очистить выполненные?');
  String get clearDoneBody => _t('Completed tasks and their history will be permanently removed. Tip: export a backup first.',
      'Выполненные задачи и их история будут удалены навсегда. Совет: сначала сделай экспорт.');
  String get clear => _t('Clear', 'Очистить');
  String removed(int n) => _t('Removed $n tasks', 'Удалено: $n');
  String get secAbout => _t('About', 'О приложении');
  String get privacyPolicy => _t('Privacy policy', 'Политика конфиденциальности');
  String get privacySub => _t('No data collected · everything stays on device', 'Данные не собираются · всё на устройстве');
  String get linkFailed => _t('Could not open the link', 'Не удалось открыть ссылку');
  String get aboutLine =>
      _t('v1.0 · 100% offline · your data stays on this device', 'v1.0 · полностью офлайн · данные только на устройстве');

  // ── Backup errors ───────────────────────────────────────────────────────
  String get errNotJson => _t('This file is not valid JSON.', 'Файл не является корректным JSON.');
  String get errNoTasks => _t('No tasks found in this file.', 'В файле не найдены задачи.');
  String get errNotMomentum => _t('This JSON was not exported from Momentum.', 'Этот JSON не из Momentum.');
  String get errRead => _t('Could not read the selected file.', 'Не удалось прочитать файл.');
  String get backupSubject => _t('Momentum backup', 'Резервная копия Momentum');

  // ── Notifications ───────────────────────────────────────────────────────
  String get nComingUp => _t('⏰ Coming up', '⏰ Скоро');
  String nComingUpBody(String t, String due) =>
      _t('“$t” is due $due. Ready to start?', '«$t» — срок: $due. Готов начать?');
  String get nDueTitle => _t('🎯 Time to start', '🎯 Пора начинать');
  String nDueBody(String t) => _t('“$t” is due now. Tap to start the timer.', 'Срок «$t» наступил. Нажми, чтобы запустить таймер.');
  String get nNudgeTitle => _t('💪 Don’t let it slip', '💪 Не откладывай');
  String nNudgeBody(String t) => _t('“$t” is still waiting.', '«$t» всё ещё ждёт.');
  String get chReminders => _t('Task reminders', 'Напоминания');
  String get chDue => _t('Due now', 'Срок наступил');
  String get chMotivation => _t('Motivation', 'Мотивация');
  String get chGeneral => _t('General', 'Общие');
}
