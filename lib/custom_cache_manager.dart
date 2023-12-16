import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RpiMusicCacheManager {
  static const key = 'RpiMusicAlbumArtCache';
  static final CacheManager instance = CacheManager(Config(
    key,
    stalePeriod: const Duration(days: 31),
    maxNrOfCacheObjects: 2000,
    repo: JsonCacheInfoRepository(databaseName: key),
  ));
}
