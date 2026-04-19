import '../../core/result.dart';
import '../../domain/models/player_profile.dart';
import 'save_repository.dart';

/// Façade that lets services treat profile mutations as transactional.
/// Today it just delegates to [SaveRepository], but it gives us a seam
/// for adding cloud-sync, conflict resolution, etc., without changing
/// service call sites.
class ProgressionRepository {
  ProgressionRepository(this._save);
  final SaveRepository _save;

  Future<Result<PlayerProfile>> load() => _save.load();
  Future<Result<void>> persist(PlayerProfile profile) => _save.save(profile);
  Future<Result<void>> wipe() => _save.wipe();
}
