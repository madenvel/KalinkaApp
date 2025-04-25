import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';
import 'package:logger/logger.dart' show Logger;

class ServiceDiscoveryDataProvider with ChangeNotifier {
  final String type = '_kalinkaplayer._tcp';
  final logger = Logger();

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  bool _isLoading = false;
  Timer? _discoveryTimer;
  bool _disposed = false;

  final List<ResolvedBonsoirService> _services = [];
  final List<BonsoirService> _unresolvedServices = [];

  List<ResolvedBonsoirService> get services => _services;
  bool get isLoading => _isLoading;

  Completer<void>? _startCompleter;

  Future<void> start({Duration timeout = const Duration(minutes: 2)}) async {
    if (_startCompleter != null) {
      await _startCompleter!.future;
      return;
    }
    logger.i(
        'Starting discovery for type: $type with ${timeout.inSeconds}s timeout');

    _startCompleter = Completer<void>();
    try {
      _discovery = BonsoirDiscovery(type: type);
      _services.clear();
      await _discovery!.ready;
      _isLoading = true;
      notifyListeners();

      _discoverySubscription = _discovery!.eventStream!.listen((event) {
        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service!.resolve(_discovery!.serviceResolver);
          _unresolvedServices.add(event.service!);
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceResolved) {
          var index = _unresolvedServices.indexWhere((element) =>
              element.name == event.service!.name &&
              element.type == event.service!.type);
          if (index != -1) {
            _unresolvedServices.removeAt(index);
            _services.add(event.service! as ResolvedBonsoirService);
            notifyListeners();
          }
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceLost) {
          _unresolvedServices.remove(event.service!);
          _services.removeWhere((element) =>
              element.name == event.service!.name &&
              element.type == event.service!.type);
          notifyListeners();
        }
      });

      await _discovery!.start();

      // Set up timer to automatically stop discovery after timeout
      _discoveryTimer?.cancel();
      _discoveryTimer = Timer(timeout, () {
        logger.i('Discovery timeout reached after ${timeout.inSeconds}s');
        stop();
      });

      _startCompleter!.complete();
    } catch (e) {
      _startCompleter!.completeError(e);
    } finally {
      _startCompleter = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _discoveryTimer?.cancel();
    stop();
    super.dispose();
  }

  Future<void> stop() async {
    if (_startCompleter != null) {
      await _startCompleter!.future;
    }

    _discoveryTimer?.cancel();
    _discoveryTimer = null;

    logger.i('Stopping discovery for type: $type');
    await _discovery?.stop();
    await _discoverySubscription?.cancel();
    _isLoading = false;
    _discoverySubscription = null;
    _discovery = null;
    _unresolvedServices.clear();
    if (!_disposed) {
      notifyListeners();
    }
  }
}
