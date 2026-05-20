import 'waydir_core_loader.dart';

abstract class TrashService {
  Future<List<WaydirTrashFailure>> trashAll(List<String> paths);

  static final TrashService instance = _NativeTrashService();
}

class _NativeTrashService implements TrashService {
  @override
  Future<List<WaydirTrashFailure>> trashAll(List<String> paths) async {
    return WaydirCoreLoader.trash(paths);
  }
}
