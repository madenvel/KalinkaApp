import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';

class ServiceDiscoveryDataProvider with ChangeNotifier {
  final String type = '_kalinkaplayer._tcp';

  BonsoirDiscovery? _discovery;

  final List<ResolvedBonsoirService> _services = [];
  final List<BonsoirService> _unresolvedServices = [];
  List<ResolvedBonsoirService> get services => _services;

  Completer<void>? _startCompleter;

  Future<void> start() async {
    if (_startCompleter != null) {
      await _startCompleter!.future;
      return;
    }

    _startCompleter = Completer<void>();
    try {
      _discovery = BonsoirDiscovery(type: type);
      _services.clear();
      await _discovery!.ready;
      notifyListeners();

      _discovery!.eventStream!.listen((event) {
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
      _startCompleter!.complete();
    } catch (e) {
      _startCompleter!.completeError(e);
    } finally {
      _startCompleter = null;
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  Future<void> stop() async {
    if (_startCompleter != null) {
      await _startCompleter!.future;
    }
    await _discovery?.stop();
  }
}
