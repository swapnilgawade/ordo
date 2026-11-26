/// The result of answering one comparison.
enum Preference { newItem, existingItem }

/// Finds where a new item belongs in an already ranked list by asking
/// "which do you prefer?" questions, using binary search.
///
/// The list is ordered best first (index 0 is rank #1). The search keeps a
/// window `[low, high]` of possible insert positions. Each answer halves it.
/// A list of n items needs at most ceil(log2(n + 1)) questions.
class InsertionSession<T> {
  InsertionSession(List<T> ranked)
    : ranked = List.unmodifiable(ranked),
      _low = 0,
      _high = ranked.length;

  /// The existing items, best first. Never changes during a session.
  final List<T> ranked;

  int _low;
  int _high;
  int? _forcedIndex;
  final List<_Window> _history = [];

  /// True once the insert position is known.
  bool get isDone => _forcedIndex != null || _low >= _high;

  /// The index in [ranked] the new item is compared with next.
  int get compareIndex {
    if (isDone) throw StateError('Session is finished');
    return (_low + _high) ~/ 2;
  }

  /// The existing item to show beside the new item.
  T get opponent => ranked[compareIndex];

  /// Where the new item goes: it will sit at this index once inserted.
  int get insertIndex {
    if (!isDone) throw StateError('Session is not finished');
    return _forcedIndex ?? _low;
  }

  /// How many questions have been answered so far.
  int get answered => _history.length;

  /// The most questions this session can take in total.
  int get maxQuestions => maxQuestionsFor(ranked.length);

  /// A safe upper bound on the questions still to come.
  int get remainingAtMost {
    if (isDone) return 0;
    // ceil(log2(size + 1)) equals the bit length of size.
    return (_high - _low).bitLength;
  }

  bool get canUndo => _history.isNotEmpty;

  /// Records which item the person prefers.
  void answer(Preference preference) {
    final mid = compareIndex;
    _history.add(_Window(_low, _high, null));
    if (preference == Preference.newItem) {
      _high = mid; // new item ranks above the compared item
    } else {
      _low = mid + 1; // new item ranks below it
    }
  }

  /// "Too close to call": place the new item right below the compared item
  /// and finish early.
  void tooClose() {
    final mid = compareIndex;
    _history.add(_Window(_low, _high, null));
    _forcedIndex = mid + 1;
  }

  /// Steps back to the previous question.
  void undo() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    _low = last.low;
    _high = last.high;
    _forcedIndex = last.forced;
  }

  /// The most questions needed to place an item into a list of [n] items.
  /// This is ceil(log2(n + 1)), which equals the bit length of n.
  static int maxQuestionsFor(int n) => n.bitLength;
}

class _Window {
  const _Window(this.low, this.high, this.forced);
  final int low;
  final int high;
  final int? forced;
}
