import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logger.dart';
import '../data/repositories/progression_repository.dart';
import '../data/repositories/save_repository.dart';
import '../data/sources/config_loader.dart';
import '../data/sources/local_storage.dart';
import '../di/providers.dart';
import 'app.dart';

/// Single async entry point. Runs all "must succeed" initialization
/// before we attach the UI, then overrides the DI providers with the
/// real instances. Any failure here surfaces as a visible error screen
/// rather than a silent blank app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final log = AppLogger('Bootstrap');

  try {
    final storage = await SharedPrefsStorage.open();
    final balanceResult = await const ConfigLoader().loadBalance();

    await balanceResult.fold(
      (balance) async {
        final saveRepo = SaveRepository(storage);
        final profileResult = await saveRepo.load();
        final profile = profileResult.valueOrNull;
        if (profile == null) {
          throw StateError('Profile load returned null');
        }

        runApp(
          ProviderScope(
            overrides: [
              keyValueStorageProvider.overrideWithValue(storage),
              balanceDataProvider.overrideWithValue(balance),
              playerProfileProvider.overrideWith(
                (ref) => PlayerProfileNotifier(
                  ProgressionRepository(saveRepo),
                  profile,
                ),
              ),
            ],
            child: const DeadDispatchApp(),
          ),
        );
      },
      (failure) async {
        log.e('Bootstrap failed: $failure');
        runApp(_BootstrapErrorApp(message: failure.toString()));
      },
    );
  } catch (e, st) {
    log.e('Unexpected bootstrap error', e, st);
    runApp(_BootstrapErrorApp(message: '$e'));
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Boot error: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }
}
