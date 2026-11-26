import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordo/ranking/rank_key.dart';

void main() {
  test('keys sort between their neighbours', () {
    final first = keyBetween(null, null);
    final below = keyBetween(first, null);
    final above = keyBetween(null, first);
    final middle = keyBetween(first, below);
    expect(above.compareTo(first), lessThan(0));
    expect(first.compareTo(middle), lessThan(0));
    expect(middle.compareTo(below), lessThan(0));
  });

  test('thousands of random inserts keep a strict order', () {
    final rng = Random(42);
    final keys = <String>[];
    for (var i = 0; i < 3000; i++) {
      final at = rng.nextInt(keys.length + 1);
      final key = keyBetween(
        at > 0 ? keys[at - 1] : null,
        at < keys.length ? keys[at] : null,
      );
      keys.insert(at, key);
    }
    for (var i = 1; i < keys.length; i++) {
      expect(keys[i - 1].compareTo(keys[i]), lessThan(0));
    }
    expect(keys.every((k) => !k.endsWith('0')), isTrue);
  });

  test('repeated inserts at the top stay short enough', () {
    String? top;
    for (var i = 0; i < 500; i++) {
      top = keyBetween(null, top);
    }
    expect(top!.length, lessThan(120));
  });

  test('rejects neighbours in the wrong order', () {
    expect(() => keyBetween('b', 'a'), throwsArgumentError);
  });

  test('spreadKeys returns ordered keys', () {
    final keys = spreadKeys(50);
    expect([...keys]..sort(), keys);
    expect(keys.toSet().length, 50);
  });
}
