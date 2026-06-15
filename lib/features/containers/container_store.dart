import 'dart:async';

import 'package:signals/signals.dart';

import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import 'container_service.dart';
import 'wsl_distribution.dart';

class ContainerStore {
  final distributions = signal<List<WslDistribution>>([]);
  final ContainerService _service = ContainerService();
  Timer? _timer;

  ContainerStore() {
    if (PlatformPaths.isWindows) _init();
  }

  void _init() {
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      distributions.value = await _service.list();
    } catch (e, st) {
      log.warn('containers', 'container refresh failed', error: e, stack: st);
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

final containerStore = ContainerStore();
