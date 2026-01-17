import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model/ext_device_events.dart' show ExtDeviceEvent;
import 'package:kalinka/data_model/playqueue_events.dart' show PlayQueueEvent;
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

StreamProvider<TEvent> makeEventBusProvider<TEvent>({
  required Stream<String> Function(Ref ref, CancelToken cancel) openStream,
  required TEvent Function(Object? json) decodeEvent,
}) {
  return StreamProvider.autoDispose<TEvent>((ref) async* {
    final cancel = CancelToken();
    final Stream<String> stream = openStream(ref, cancel);

    ref.onDispose(() {
      cancel.cancel();
    });

    final lines = stream.transform(const LineSplitter());

    await for (final line in lines) {
      if (cancel.isCancelled) {
        break;
      }

      if (line.isEmpty) continue;

      try {
        final obj = jsonDecode(line);
        yield decodeEvent(obj);
      } catch (e, stack) {
        logger.e('Failed to parse wire event: $e', error: e, stackTrace: stack);
        // Optionally: yield a special error event or just skip
        continue;
      }
    }
  });
}

Stream<String> openPlayQueueStream(Ref ref, CancelToken cancel) async* {
  final dio = ref.watch(httpClientProvider);
  final conn = ref.read(connectionStateProvider.notifier);
  final url = '/queue/events';
  final resp = await dio.get<ResponseBody>(
    url,
    options: Options(responseType: ResponseType.stream),
    cancelToken: cancel,
  );

  if (!cancel.isCancelled) {
    conn.connected();
  }

  StreamTransformer<Uint8List, List<int>> unit8Transformer =
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

  yield* resp.data!.stream.transform(unit8Transformer).transform(utf8.decoder);
}

Stream<String> openExtDeviceStream(Ref ref, CancelToken cancel) async* {
  final dio = ref.watch(httpClientProvider);
  final url = '/device/events';
  final resp = await dio.get<ResponseBody>(
    url,
    options: Options(responseType: ResponseType.stream),
    cancelToken: cancel,
  );

  StreamTransformer<Uint8List, List<int>> unit8Transformer =
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

  yield* resp.data!.stream.transform(unit8Transformer).transform(utf8.decoder);
}

final playQueueEventBusProvider = makeEventBusProvider<PlayQueueEvent>(
  openStream: openPlayQueueStream,
  decodeEvent: (json) => PlayQueueEvent.fromJson(json as Map<String, Object?>),
);

final extDeviceEventBusProvider = makeEventBusProvider<ExtDeviceEvent>(
  openStream: openExtDeviceStream,
  decodeEvent: (json) => ExtDeviceEvent.fromJson(json as Map<String, Object?>),
);
