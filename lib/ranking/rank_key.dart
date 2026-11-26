/// Sortable position keys ("fractional indexing").
///
/// Every ranked item stores a string key. Sorting items by key (plain string
/// comparison) gives the list order. To put an item between two neighbours we
/// make a new key that sorts between their keys, so only that one item changes.
/// This keeps inserts cheap and avoids conflicts when devices sync later.
library;

const _digits = '0123456789abcdefghijklmnopqrstuvwxyz';

/// Returns a key that sorts strictly between [before] and [after].
///
/// Pass `null` for [before] when inserting at the top, and `null` for [after]
/// when inserting at the bottom. Keys produced here never end in '0', which
/// guarantees there is always room for another key between any two.
String keyBetween(String? before, String? after) {
  final a = before ?? '';
  if (after != null && a.compareTo(after) >= 0) {
    throw ArgumentError('before ($before) must sort before after ($after)');
  }
  return _midpoint(a, after);
}

String _midpoint(String a, String? b) {
  if (b != null) {
    // Copy the shared prefix, then find a midpoint of what remains.
    var n = 0;
    while (n < b.length && (n < a.length ? a[n] : '0') == b[n]) {
      n++;
    }
    if (n > 0) {
      return b.substring(0, n) +
          _midpoint(a.length > n ? a.substring(n) : '', b.substring(n));
    }
  }
  final digitA = a.isNotEmpty ? _digits.indexOf(a[0]) : 0;
  final digitB = b != null ? _digits.indexOf(b[0]) : _digits.length;
  if (digitB - digitA > 1) {
    return _digits[((digitA + digitB) / 2).round()];
  }
  if (b != null && b.length > 1) {
    return b.substring(0, 1);
  }
  return _digits[digitA] + _midpoint(a.length > 1 ? a.substring(1) : '', null);
}

/// Returns evenly spread keys for [count] items, in order.
/// Used when importing or rebuilding a whole list at once.
List<String> spreadKeys(int count) {
  final keys = <String>[];
  String? previous;
  for (var i = 0; i < count; i++) {
    previous = keyBetween(previous, null);
    keys.add(previous);
  }
  return keys;
}
