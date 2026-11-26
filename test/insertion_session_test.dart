import 'package:flutter_test/flutter_test.dart';
import 'package:ordo/ranking/insertion_session.dart';

/// Ranks [value] into [ranked] (best = smallest number first) by answering
/// every question truthfully. Returns the insert index and question count.
(int, int) runSession(List<int> ranked, int value) {
  final s = InsertionSession<int>(ranked);
  var asked = 0;
  while (!s.isDone) {
    asked++;
    s.answer(value < s.opponent ? Preference.newItem : Preference.existingItem);
  }
  return (s.insertIndex, asked);
}

void main() {
  test('an empty list places the item at once', () {
    final s = InsertionSession<int>([]);
    expect(s.isDone, isTrue);
    expect(s.insertIndex, 0);
    expect(s.maxQuestions, 0);
  });

  test('finds the right slot for every position', () {
    for (var n = 0; n <= 40; n++) {
      final ranked = [for (var i = 0; i < n; i++) i * 10];
      for (var slot = 0; slot <= n; slot++) {
        final value = slot * 10 - 5; // sits just above ranked[slot]
        final (index, asked) = runSession(ranked, value);
        expect(index, slot, reason: 'n=$n slot=$slot');
        expect(asked, lessThanOrEqualTo(InsertionSession.maxQuestionsFor(n)));
      }
    }
  });

  test('question counts match the spec', () {
    expect(InsertionSession.maxQuestionsFor(10), 4);
    expect(InsertionSession.maxQuestionsFor(100), 7);
    expect(InsertionSession.maxQuestionsFor(1000), 10);
  });

  test('undo returns to the previous question', () {
    final s = InsertionSession<int>([10, 20, 30, 40, 50, 60, 70]);
    final first = s.compareIndex;
    s.answer(Preference.newItem);
    expect(s.compareIndex, isNot(first));
    s.undo();
    expect(s.compareIndex, first);
    expect(s.answered, 0);
    expect(s.canUndo, isFalse);
  });

  test('too close places the item right below the compared item', () {
    final s = InsertionSession<int>([10, 20, 30, 40, 50]);
    final mid = s.compareIndex;
    s.tooClose();
    expect(s.isDone, isTrue);
    expect(s.insertIndex, mid + 1);
    s.undo();
    expect(s.isDone, isFalse);
    expect(s.compareIndex, mid);
  });

  test('remaining questions never exceed the promise', () {
    final ranked = [for (var i = 0; i < 100; i++) i];
    final s = InsertionSession<int>(ranked);
    final promised = s.remainingAtMost;
    expect(promised, 7);
    var asked = 0;
    while (!s.isDone) {
      asked++;
      s.answer(Preference.existingItem);
      expect(asked + s.remainingAtMost, lessThanOrEqualTo(promised));
    }
  });
}
