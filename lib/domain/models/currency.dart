/// Soft currency. Hard currency / premium can be added later as another type
/// here without touching call sites.
enum Currency {
  coins,
  spectralDust;

  String get key => name;
}

class Wallet {
  Wallet({Map<Currency, int>? balances})
      : _balances = {
          for (final c in Currency.values) c: balances?[c] ?? 0,
        };

  final Map<Currency, int> _balances;

  int get(Currency c) => _balances[c] ?? 0;

  bool canSpend(Currency c, int amount) => get(c) >= amount;

  void add(Currency c, int amount) {
    if (amount <= 0) return;
    _balances[c] = (_balances[c] ?? 0) + amount;
  }

  bool spend(Currency c, int amount) {
    if (!canSpend(c, amount)) return false;
    _balances[c] = (_balances[c] ?? 0) - amount;
    return true;
  }

  Map<String, int> toJson() => {
        for (final entry in _balances.entries) entry.key.key: entry.value,
      };

  static Wallet fromJson(Map<String, Object?> json) => Wallet(
        balances: {
          for (final c in Currency.values)
            c: (json[c.key] as num?)?.toInt() ?? 0,
        },
      );
}
