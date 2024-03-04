import 'package:flutter/foundation.dart';
import 'package:bonsoir/bonsoir.dart';

class ServiceDiscoveryDataProvider with ChangeNotifier {
  final String type = '_rpiplayer._tcp';

  late BonsoirDiscovery _discovery;

  final List<ResolvedBonsoirService> _services = [];
  List<ResolvedBonsoirService> get services => _services;

  Future<void> start() async {
    _discovery = BonsoirDiscovery(type: type);
    _services.clear();
    await _discovery.ready;
    notifyListeners();

    _discovery.eventStream!.listen((event) {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service!.resolve(_discovery.serviceResolver);
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceResolved) {
        _services.add(event.service! as ResolvedBonsoirService);
        notifyListeners();
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
        _services.remove(event.service! as ResolvedBonsoirService);
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
