import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class KalinkaMusicCacheManager {
  static const key = 'KalinkaAlbumArtCache';
  static final CacheManager instance = CacheManager(Config(
    key,
    stalePeriod: const Duration(days: 1),
    maxNrOfCacheObjects: 500,
    fileService: HttpFileService(),
  ));
}
