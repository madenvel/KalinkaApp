import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';

class ServiceDiscoveryDataProvider with ChangeNotifier {
  final String type = '_kalinkaplayer._tcp';

  late BonsoirDiscovery _discovery;

  final List<ResolvedBonsoirService> _services = [];
  final List<BonsoirService> _unresolvedServices = [];
  List<ResolvedBonsoirService> get services => _services;

  Future<void> start() async {
    _discovery = BonsoirDiscovery(type: type);
    _services.clear();
    await _discovery.ready;
    notifyListeners();

    _discovery.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service!.resolve(_discovery.serviceResolver);
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
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        _unresolvedServices.remove(event.service!);
        _services.removeWhere((element) =>
            element.name == event.service!.name &&
            element.type == event.service!.type);
        notifyListeners();
      }
    });

    return _discovery.start();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  Future<void> stop() async {
    return _discovery.stop();
  }
}
