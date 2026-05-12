import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../core/failures.dart';
import '../../core/result.dart';
import '../../domain/balance/balance_data.dart';
import '../../domain/balance/balance_provider.dart';

/// Loads JSON balance data from `assets/config/`. Hot-swappable via
/// remote config in the future — that adapter would implement the same
/// `loadBalance()` shape and feed the [BalanceProvider].
class ConfigLoader {
  const ConfigLoader({
    BalanceProvider provider = const BalanceProvider(),
  }) : _provider = provider;

  final BalanceProvider _provider;

  Future<Result<BalanceData>> loadBalance() async {
    try {
      final balance = await _readJsonObject('assets/config/balance.json');
      final packages = await _readJsonArray('assets/config/packages.json');
      final hazards = await _readJsonArray('assets/config/hazards.json');
      final upgrades = await _readJsonArray('assets/config/upgrades.json');
      final departments = await _readJsonArray('assets/config/departments.json');

      return Ok(_provider.assemble(
        balanceJson: balance,
        blocksJson: packages,
        hazardsJson: hazards,
        upgradesJson: upgrades,
        departmentsJson: departments,
      ));
    } catch (e, st) {
      return Err(ConfigFailure('Failed to load balance config: $e\n$st'));
    }
  }

  Future<Map<String, Object?>> _readJsonObject(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Expected object at $path, got ${decoded.runtimeType}');
    }
    return decoded;
  }

  Future<List<Map<String, Object?>>> _readJsonArray(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException('Expected list at $path, got ${decoded.runtimeType}');
    }
    return decoded.cast<Map<String, Object?>>();
  }
}
