import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_model.dart';

class KalinkaPlayerProxy {
  static final KalinkaPlayerProxy _instance = KalinkaPlayerProxy._internal();

  factory KalinkaPlayerProxy() {
    return _instance;
  }

  KalinkaPlayerProxy._internal();

  late PlayerState state;
  late List<Track> tracks = [];

  http.Client client = http.Client();
  String host = '';
  int port = 0;

  void connect(String host, int port) {
    this.host = host;
    this.port = port;
  }

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
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> next() async {
    final url = _buildUri('/queue/next');
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> previous() async {
    final url = _buildUri('/queue/prev');
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> add(String item) async {
    final url = _buildUri('/queue/add$item');
    return client.post(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> remove(int index) async {
    final url = _buildUri('/queue/remove', {'index': index.toString()});
    return client.post(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> addTracks(List<String> items) async {
    final url = _buildUri('/queue/add/tracks');
    final String encodedItems = jsonEncode(items);
    return client
        .post(url,
            headers: {"Content-Type": "application/json"}, body: encodedItems)
        .then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> pause({bool paused = true}) async {
    final url = _buildUri('/queue/pause', {'paused': paused.toString()});
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> stop() async {
    final url = _buildUri('/queue/stop');
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<TrackList> listTracks({int offset = 0, int limit = 100}) async {
    final url = _buildUri('/queue/list',
        {'offset': offset.toString(), 'limit': limit.toString()});
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to list tracks');
      }

      return TrackList.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
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

  Future<StatusMessage> setPlaybackMode(
      {bool? repeatOne, bool? repeatAll, bool? shuffle}) async {
    final url = _buildUri('/queue/mode', {
      if (repeatOne != null) 'repeat_single': repeatOne.toString(),
      if (repeatAll != null) 'repeat_all': repeatAll.toString(),
      if (shuffle != null) 'shuffle': shuffle.toString()
    });

    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<BrowseItemsList> search(SearchType queryType, String query,
      {int offset = 0, int limit = 30}) async {
    final url = _buildUri('/search/${queryType.toStringValue()}/$query',
        {'offset': offset.toString(), 'limit': limit.toString()});
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to search for $queryType $query, url=$url');
      }

      return BrowseItemsList.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<BrowseItemsList> browse(String query,
      {int offset = 0, int limit = 10, List<String>? genreIds}) async {
    final url = _buildUri('/browse$query', {
      'offset': offset.toString(),
      'limit': limit.toString(),
      ...genreIds != null ? {'genre_ids': genreIds} : {}
    });
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to browse $query, url=$url');
      }

      return BrowseItemsList.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<BrowseItemsList> browseItem(BrowseItem item,
      {int offset = 0, int limit = 10, List<String>? genreIds}) {
    if (item.canBrowse) {
      return browse(item.url, offset: offset, limit: limit, genreIds: genreIds);
    }

    return Future.value(BrowseItemsList(0, 0, 0, []));
  }

  Future<BrowseItem> getMetadata(String query) async {
    final url = _buildUri('/get$query');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get metadata for $query, url=$url');
      }

      return BrowseItem.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<BrowseItemsList> getFavorite(SearchType queryType,
      {int offset = 0, int limit = 10, String filter = ''}) async {
    final url = _buildUri('/favorite/list/${queryType.toStringValue()}', {
      'offset': offset.toString(),
      'limit': limit.toString(),
      'filter': filter
    });
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get favorite ${queryType.toStringValue()}, url=$url');
      }

      return BrowseItemsList.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<StatusMessage> addFavorite(SearchType queryType, String id) async {
    final url = _buildUri('/favorite/add/${queryType.toStringValue()}/$id');
    return client.put(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<StatusMessage> removeFavorite(SearchType queryType, String id) async {
    final url = _buildUri('/favorite/remove/${queryType.toStringValue()}/$id');
    return client.delete(url).then((response) {
      return statusMessageFromResponse(response);
    });
  }

  Future<FavoriteIds> getFavoriteIds() async {
    final url = _buildUri('/favorite/ids');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get favorite ids, url=$url');
      }

      return FavoriteIds.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<void> clear() async {
    final url = _buildUri('/queue/clear');
    return client.put(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to clear queue, url=$url');
      }
    });
  }

  Future<void> setVolume(int volume) async {
    final url = _buildUri('/device/set_volume',
        {'device_id': 'musiccast', 'volume': volume.toString()});
    return client.put(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to set volume to $volume, url=$url');
      }
    });
  }

  Future<Volume> getVolume() async {
    final url = _buildUri('/device/get_volume', {'device_id': 'musiccast'});
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get volume, url=$url');
      }
      return Volume.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<GenreList> getGenres() async {
    final url = _buildUri('/genre/list');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get genres, url=$url');
      }
      return GenreList.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<SeekStatusMessage> seek(int positionMs) async {
    final url = _buildUri(
        '/queue/current_track/seek', {'position_ms': positionMs.toString()});
    return client.put(url).then((response) {
      if (response.statusCode != 200) {
        var url = response.request?.url;
        throw Exception('Request $response.request.url failed, url=$url');
      }
      return SeekStatusMessage.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<Playlist> playlistCreate(String name, String? description) async {
    final url = _buildUri('/playlist/create',
        {'name': name, if (description != null) 'description': description});
    return client.post(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to create playlist, url=$url');
      }
      return Playlist.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<void> playlistDelete(String playlistId) async {
    final url = _buildUri('/playlist/delete', {'playlist_id': playlistId});
    return client.delete(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to delete playlist, url=$url, message=${response.body}');
      }
    });
  }

  Future<Playlist> playlistAddTracks(
      String playlistId, List<String> trackIds) async {
    final url = _buildUri('/playlist/add_tracks', {'playlist_id': playlistId});
    final String encodedItems = jsonEncode(trackIds);
    return client
        .post(url,
            headers: {"Content-Type": "application/json"}, body: encodedItems)
        .then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to add tracks to playlist, url=$url');
      }
      return Playlist.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<BrowseItemsList> playlistUserList(int offset, int limit) async {
    final url = _buildUri('/playlist/list');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to list user playlists, url=$url');
      }
      return BrowseItemsList.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<BrowseItemsList> suggest(
      {required BrowseItem item,
      required int offset,
      required int limit}) async {
    final url = _buildUri('/suggest/${item.browseType}', {
      'offset': offset.toString(),
      'limit': limit.toString(),
      'id': item.id.toString()
    });
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to suggest for ${item.url}, url=$url');
      }
      return BrowseItemsList.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<Map<String, dynamic>> getSettings() async {
    final url = _buildUri('/server/config');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to get settings, url=$url');
      }
      return json.decode(utf8.decode(response.bodyBytes));
    });
  }

  Future<ModulesAndDevices> listModules() async {
    final url = _buildUri('/server/modules');
    return client.get(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to list modules, url=$url');
      }
      return ModulesAndDevices.fromJson(
          json.decode(utf8.decode(response.bodyBytes)));
    });
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final url = _buildUri('/server/config');
    final String encodedSettings = jsonEncode(settings);
    final response = await client.put(url,
        headers: {"Content-Type": "application/json"}, body: encodedSettings);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to save settings, status: ${response.statusCode}, body: ${response.body}');
    }
  }

  Future<void> restartServer() async {
    final url = _buildUri('/server/restart');
    return client.put(url).then((response) {
      if (response.statusCode != 200) {
        throw Exception('Failed to restart server, url=$url');
      }
    });
  }

  StatusMessage statusMessageFromResponse(http.Response response) {
    if (response.statusCode != 200) {
      var url = response.request?.url;
      throw Exception('Request $response.request.url failed, url=$url');
    }
    return StatusMessage.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }
}
