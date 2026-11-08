import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/core/format.dart';

void main() {
  test('compact durations', () {
    expect(Fmt.compact(const Duration(minutes: 90)), '1h 30m');
    expect(Fmt.compact(const Duration(seconds: 42)), '42s');
    expect(Fmt.clock(const Duration(hours: 1, minutes: 2, seconds: 3)), '01:02:03');
  });

  test('reminder labels', () {
    expect(Fmt.reminder(null), 'No early reminder');
    expect(Fmt.reminder(15), '15 min before');
    expect(Fmt.reminder(1440), '1 day before');
  });
}
