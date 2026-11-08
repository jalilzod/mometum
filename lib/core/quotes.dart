import 'dart:math';

import '../l10n/strings.dart';

class Quote {
  const Quote(this._en, this._ru, this._author, [this._authorRu]);
  final String _en;
  final String _ru;
  final String _author;
  final String? _authorRu;

  String get text => S.current.ru ? _ru : _en;
  String get author => S.current.ru ? (_authorRu ?? _author) : _author;

  @override
  String toString() => '“$text” — $author';
}

/// Curated quote banks (English + Russian) used by notifications and
/// celebration cards.
abstract final class Quotes {
  static final _rng = Random();

  static Quote _pick(List<Quote> list) => list[_rng.nextInt(list.length)];

  /// Pushed when a task is still undone after its due time.
  static Quote delay() => _pick(_delay);

  /// Shown after finishing a task on (or before) time.
  static Quote onTime() => _pick(_onTime);

  /// Shown after finishing a task late — encouraging, never guilt-tripping.
  static Quote late() => _pick(_late);

  /// Shown when starting a focus session.
  static Quote start() => _pick(_start);

  /// Stable for the whole day.
  static Quote ofTheDay() {
    final now = DateTime.now();
    final all = [..._start, ..._onTime, ..._delay];
    return all[(now.year * 372 + now.month * 31 + now.day) % all.length];
  }

  static const _delay = [
    Quote('The secret of getting ahead is getting started.',
        'Секрет движения вперёд — начать.', 'Mark Twain', 'Марк Твен'),
    Quote('You don’t have to see the whole staircase, just take the first step.',
        'Не нужно видеть всю лестницу — просто сделай первый шаг.', 'Martin Luther King Jr.',
        'Мартин Лютер Кинг'),
    Quote('Do the hard jobs first. The easy jobs will take care of themselves.',
        'Сначала делай трудное. Лёгкое сделается само.', 'Dale Carnegie', 'Дейл Карнеги'),
    Quote('Procrastination is the thief of time.', 'Промедление — вор времени.', 'Edward Young',
        'Эдвард Юнг'),
    Quote('Action is the foundational key to all success.', 'Действие — основа любого успеха.',
        'Pablo Picasso', 'Пабло Пикассо'),
    Quote('A year from now you may wish you had started today.',
        'Через год ты пожалеешь, что не начал сегодня.', 'Karen Lamb', 'Карен Лэмб'),
    Quote('Don’t wait. The time will never be just right.',
        'Не жди. Идеального момента не будет.', 'Napoleon Hill', 'Наполеон Хилл'),
    Quote('Small deeds done are better than great deeds planned.',
        'Малое сделанное лучше великого задуманного.', 'Peter Marshall', 'Питер Маршалл'),
    Quote('Start where you are. Use what you have. Do what you can.',
        'Начни там, где ты есть. Используй то, что имеешь. Делай, что можешь.', 'Arthur Ashe',
        'Артур Эш'),
    Quote('Well begun is half done.', 'Хорошее начало — половина дела.', 'Aristotle', 'Аристотель'),
    Quote('It always seems impossible until it’s done.',
        'Всё кажется невозможным, пока не сделано.', 'Nelson Mandela', 'Нельсон Мандела'),
    Quote('Five focused minutes beat an hour of worrying. Start now.',
        'Пять минут дела лучше часа переживаний. Начни сейчас.', 'Momentum'),
  ];

  static const _onTime = [
    Quote('Punctuality is the soul of business.', 'Пунктуальность — душа дела.',
        'Thomas Chandler Haliburton', 'Томас Халибертон'),
    Quote('We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
        'Мы — то, что мы делаем постоянно. Совершенство — не поступок, а привычка.', 'Will Durant',
        'Уилл Дюрант'),
    Quote('Success is the sum of small efforts, repeated day in and day out.',
        'Успех — это сумма небольших усилий, повторяемых изо дня в день.', 'Robert Collier',
        'Роберт Кольер'),
    Quote('Lost time is never found again.', 'Потерянное время не вернуть.', 'Benjamin Franklin',
        'Бенджамин Франклин'),
    Quote('Well done is better than well said.', 'Хорошо сделанное лучше хорошо сказанного.',
        'Benjamin Franklin', 'Бенджамин Франклин'),
    Quote('On time, every time. That’s how momentum is built.',
        'Вовремя — каждый раз. Так и набирается темп.', 'Momentum'),
    Quote('Discipline is the bridge between goals and accomplishment.',
        'Дисциплина — мост между целями и достижениями.', 'Jim Rohn', 'Джим Рон'),
  ];

  static const _late = [
    Quote('Better late than never — and better done than perfect.',
        'Лучше поздно, чем никогда — и лучше сделано, чем идеально.', 'Momentum'),
    Quote('It does not matter how slowly you go as long as you do not stop.',
        'Неважно, как медленно ты идёшь, главное — не останавливаться.', 'Confucius', 'Конфуций'),
    Quote('Done is better than perfect.', 'Сделанное лучше идеального.', 'Sheryl Sandberg',
        'Шерил Сэндберг'),
    Quote('Fall seven times, stand up eight.', 'Упади семь раз, поднимись восемь.',
        'Japanese proverb', 'Японская пословица'),
    Quote('Every finish line is the beginning of a new race.',
        'Каждый финиш — начало нового забега.', 'Momentum'),
  ];

  static const _start = [
    Quote('Concentrate all your thoughts upon the work at hand.',
        'Сосредоточь все мысли на деле, которым занят.', 'Alexander Graham Bell',
        'Александр Белл'),
    Quote('The way to get started is to quit talking and begin doing.',
        'Чтобы начать, перестань говорить и начни делать.', 'Walt Disney', 'Уолт Дисней'),
    Quote('Focus on being productive instead of busy.',
        'Будь продуктивным, а не просто занятым.', 'Tim Ferriss', 'Тим Феррис'),
    Quote('Energy flows where attention goes.', 'Энергия идёт туда, куда направлено внимание.',
        'Proverb', 'Пословица'),
    Quote('One thing at a time. Most important thing first.',
        'Одно дело за раз. Самое важное — первым.', 'Momentum'),
  ];
}
