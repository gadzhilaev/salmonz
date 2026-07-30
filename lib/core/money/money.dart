/// Safe money parsing / formatting for RUB amounts from API.
///
/// Prefer this over raw `double` formatting in UI to avoid float display bugs.
class Money {
  const Money._(this.minorUnits);

  static const zero = Money._(0);

  /// Value stored as integer kopecks (minor units).
  final int minorUnits;

  /// Parses API number or string into [Money].
  factory Money.parse(Object? value) {
    if (value == null) return const Money._(0);
    if (value is int) return Money._(value * 100);
    if (value is num) {
      return Money._((value * 100).round());
    }
    final s = value.toString().trim().replaceAll(',', '.');
    if (s.isEmpty) return const Money._(0);
    final parsed = double.tryParse(s);
    if (parsed == null) return const Money._(0);
    return Money._((parsed * 100).round());
  }

  factory Money.fromRubles(num rubles) => Money._((rubles * 100).round());

  double get asDouble => minorUnits / 100.0;

  /// Display string without currency symbol, e.g. `1 249` or `99,50`.
  String format({bool grouping = true}) {
    final negative = minorUnits < 0;
    final abs = minorUnits.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;

    final wholeStr = grouping ? _group(whole) : whole.toString();
    final sign = negative ? '-' : '';

    if (frac == 0) return '$sign$wholeStr';
    final fracStr = frac.toString().padLeft(2, '0');
    return '$sign$wholeStr,$fracStr';
  }

  /// e.g. `1 249 ₽`
  String formatRub({bool grouping = true}) => '${format(grouping: grouping)} ₽';

  static String _group(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Money operator +(Money other) => Money._(minorUnits + other.minorUnits);

  Money operator -(Money other) => Money._(minorUnits - other.minorUnits);

  Money operator *(int qty) => Money._(minorUnits * qty);

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => formatRub();
}
