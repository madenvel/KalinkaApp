import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_model.dart';

class RpiPlayerProxy {
  static final RpiPlayerProxy _instance = RpiPlayerProxy._internal();

  factory RpiPlayerProxy() {
    return _instance;
  }

  RpiPlayerProxy._internal();

  late PlayerState state;
  late List<Track> tracks = [];

  http.Client client = http.Client();
  final String host = '192.168.3.28';
  int port = 8000;

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    return Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: endpoint,
      queryParameters: queryParameters,
    );
  }

  Future<StatusMessage> play([int? index]) async {
    final url = _buildUri(
        '/queue/play', index != null ? {'index': index.toString()} : null);
    return client.get(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> add(String item) async {
    final url = _buildUri('/queue/add$item');
    return client.get(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> remove(int index) async {
    final url = _buildUri('/queue/remove', {'index': index.toString()});
    return client.get(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> addTracks(List<String> items) async {
    final url = _buildUri('/queue/add/tracks');
    final String encodedItems = jsonEncode(items);
    print('Encoded items: $encodedItems');
    return client
        .post(url,
            headers: {"Content-Type": "application/json"}, body: encodedItems)
        .then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> pause({bool paused = true}) async {
    final url = _buildUri('/queue/pause', {'paused': paused.toString()});
    return client.get(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> stop() async {
    final url = _buildUri('/queue/stop');
    return client.get(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<List<Track>> listTracks({int offset = 0, int limit = 30}) async {
    final url = _buildUri('/queue/list',
        {'offset': offset.toString(), 'limit': limit.toString()});
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to list tracks');
      }

      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((track) => Track.fromJson(track)).toList();
    });
  }

  Future<PlayerState> getState() async {
    final url = _buildUri('/queue/state');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get state, url=$url');
      }

      return PlayerState.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<List<BrowseItem>> search(SearchType queryType, String query) async {
    final url = _buildUri('/search/${queryType.toStringValue()}/$query');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to search for $queryType $query, url=$url');
      }

      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((browseItem) => BrowseItem.fromJson(browseItem)).toList();
    });
  }

  Future<List<BrowseItem>> browse(String query) async {
    final url = _buildUri('/browse$query');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to browse $query, url=$url');
      }

      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((browseItem) => BrowseItem.fromJson(browseItem)).toList();
    });
  }

  Future<void> clear() async {
    final url = _buildUri('/queue/clear');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to clear queue, url=$url');
      }
    });
  }

  StatusMessage statusMessageFromResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Request $response.request.url failed, url=$response.request.url');
    }
    return StatusMessage.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }
}
