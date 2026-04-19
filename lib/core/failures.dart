/// Domain-level failures. Keep these typed so callers can branch on them.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ConfigFailure extends Failure {
  const ConfigFailure(super.message);
}

class SaveMigrationFailure extends Failure {
  const SaveMigrationFailure(super.message);
}

class GameStateFailure extends Failure {
  const GameStateFailure(super.message);
}

class AdFailure extends Failure {
  const AdFailure(super.message);
}
