import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncNotifierProvider,
        AsyncValue,
        AsyncValueX,
        AutoDisposeAsyncNotifier,
        AutoDisposeNotifier,
        NotifierProvider;
import 'package:logger/logger.dart' show Logger;
import 'package:uuid/v1.dart';

class DiscoverySessionState {
  final bool inProgress;
  final String sessionId;

  DiscoverySessionState({
    this.inProgress = false,
    this.sessionId = '',
  });

  DiscoverySessionState copyWith({
    bool? inProgress,
    String? sessionId,
  }) {
    return DiscoverySessionState(
      inProgress: inProgress ?? this.inProgress,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class DiscoverySession extends AutoDisposeNotifier<DiscoverySessionState> {
  final logger = Logger();
  Timer? _discoveryTimer;

  static const Duration defaultTimeout = Duration(seconds: 15);

  @override
  DiscoverySessionState build() {
    ref.onDispose(() {
      _stop();
    });
    return _startNewSession(defaultTimeout);
  }

  DiscoverySessionState _startNewSession(final Duration timeout) {
    final sessionId = UuidV1().generate();
    _discoveryTimer = Timer(timeout, () {
      logger.i('Discovery session timed out: $sessionId');
      _stop();
    });
    logger.i('Starting discovery session: $sessionId');

    return DiscoverySessionState(inProgress: true, sessionId: sessionId);
  }

  void _stop() {
    logger.i('Stopping discovery session: ${state.sessionId}');
    _discoveryTimer?.cancel();
    state = state.copyWith(inProgress: false);
  }

  void restart() {
    _stop();
    state = _startNewSession(defaultTimeout);
  }
}

class DiscoveredServiceList {
  final List<BonsoirService> unresolvedServices;

  DiscoveredServiceList({
    required this.unresolvedServices,
  });

  DiscoveredServiceList copyWith({
    List<BonsoirService>? unresolvedServices,
  }) {
    return DiscoveredServiceList(
      unresolvedServices: unresolvedServices ?? this.unresolvedServices,
    );
  }
}

class ResolvedServiceList {
  final List<ResolvedBonsoirService> services;

  ResolvedServiceList({
    required this.services,
  });

  ResolvedServiceList copyWith({
    List<ResolvedBonsoirService>? services,
  }) {
    return ResolvedServiceList(
      services: services ?? this.services,
    );
  }
}

class ResolvedServiceListNotifier
    extends AutoDisposeNotifier<ResolvedServiceList> {
  @override
  ResolvedServiceList build() {
    ref.watch(discoverySession.select((value) => value.sessionId));

    return ResolvedServiceList(
      services: [],
    );
  }

  void addResolvedService(ResolvedBonsoirService service) {
    state = state.copyWith(services: [...state.services, service]);
  }

  void removeService(BonsoirService service) {
    state = state.copyWith(
        services: state.services
            .where((s) => s.name != service.name || s.type != service.type)
            .toList());
  }
}

class ServiceDiscovery extends AutoDisposeAsyncNotifier<DiscoveredServiceList> {
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  static const String type = '_kalinkaplayer._tcp';
  final logger = Logger();

  @override
  Future<DiscoveredServiceList> build() async {
    final session = ref.watch(discoverySession);
    if (session.inProgress) {
      final discovery = BonsoirDiscovery(type: ServiceDiscovery.type);
      await discovery.ready;

      _discoverySubscription = discovery.eventStream?.listen((event) {
        if (event.service == null) return;
        final s = state.valueOrNull;

        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service!.resolve(discovery.serviceResolver);
          if (s == null) {
            state = AsyncValue.data(DiscoveredServiceList(
              unresolvedServices: [event.service!],
            ));
          } else {
            state = AsyncValue.data(s.copyWith(
              unresolvedServices: List.from(s.unresolvedServices)
                ..add(event.service!),
            ));
          }
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceResolved) {
          if (s == null) return;

          final index = s.unresolvedServices.indexWhere((element) =>
              element.name == event.service!.name &&
              element.type == event.service!.type);
          if (index != -1) {
            state = AsyncValue.data(s.copyWith(
              unresolvedServices: List.from(s.unresolvedServices)
                ..removeAt(index),
            ));
            ref
                .read(resolvedServicesListProvider.notifier)
                .addResolvedService(event.service! as ResolvedBonsoirService);
          }
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceLost) {
          state = AsyncValue.data(s!.copyWith(
            unresolvedServices: List.from(s.unresolvedServices)
              ..remove(event.service!),
          ));
          ref
              .read(resolvedServicesListProvider.notifier)
              .removeService(event.service!);
        }
      });

      ref.onDispose(() async {
        await discovery.stop();
        _discoverySubscription?.cancel();
      });

      await discovery.start();
    }

    return DiscoveredServiceList(
      unresolvedServices: [],
    );
  }
}

final discoverySession =
    NotifierProvider.autoDispose<DiscoverySession, DiscoverySessionState>(
        DiscoverySession.new);

final discoveredServiceListProvider =
    AsyncNotifierProvider.autoDispose<ServiceDiscovery, DiscoveredServiceList>(
        ServiceDiscovery.new);

final resolvedServicesListProvider = NotifierProvider.autoDispose<
    ResolvedServiceListNotifier,
    ResolvedServiceList>(ResolvedServiceListNotifier.new);
