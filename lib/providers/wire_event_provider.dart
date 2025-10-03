import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:kalinka/providers/monotonic_clock_provider.dart';
import 'package:logger/logger.dart' show Logger;
import 'package:kalinka/data_model/wire_events.dart'
    show WireEvent, WireEventStateChanged, WireEventStateReplay;

/// Single source-of-truth HTTP connection producing parsed WireEvent objects.
/// All other providers depend on this.
final wireEventsProvider = StreamProvider.autoDispose<WireEvent>((ref) async* {
  final dio = ref.watch(httpClientProvider);
  final cancel = CancelToken();
  final conn = ref.read(connectionStateProvider.notifier);
  final logger = Logger();

  // Keep the connection while there are listeners
  final link = ref.keepAlive();
  ref.onCancel(link.close);
  ref.onDispose(() => cancel.cancel('dispose'));

  Duration backoff = const Duration(seconds: 1);

  while (!cancel.isCancelled) {
    try {
      final resp = await dio.get<ResponseBody>(
        '/queue/events',
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

      final lines = resp.data!.stream
          .transform(unit8Transformer)
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (line.isEmpty) continue;

        try {
          final event = WireEvent.fromJson(jsonDecode(line));
          switch (event) {
            case WireEventStateChanged():
              event.payload.state.timestamp = ref
                  .read(monotonicClockProvider)
                  .elapsedMilliseconds;
              break;
            case WireEventStateReplay():
              event.payload.state.timestamp = ref
                  .read(monotonicClockProvider)
                  .elapsedMilliseconds;
              break;
            default:
              break;
          }
          yield event;
        } catch (e, stack) {
          logger.e(
            'Failed to parse wire event: $e',
            error: e,
            stackTrace: stack,
          );
          // Optionally: yield a special error event or just skip
          continue;
        }
      }
    } catch (e) {
      logger.w('Stream connection failure: $e');
    }

    conn.disconnected();
    if (cancel.isCancelled) break;
    await Future.delayed(backoff);
    if (backoff < const Duration(seconds: 30)) backoff *= 2;
  }
});
