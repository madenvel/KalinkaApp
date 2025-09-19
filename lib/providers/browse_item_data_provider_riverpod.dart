import 'dart:async' show StreamController, StreamSubscription;
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart'
    show
        BrowseItem,
        BrowseItemsList,
        Catalog,
        EntityId,
        Preview,
        PreviewContentTypeExtension,
        PreviewType,
        SearchType;
import 'package:kalinka/providers/connection_state_provider.dart';
import 'package:kalinka/providers/genre_filter_provider.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart'
    show KalinkaPlayerProxy, kalinkaProxyProvider;
import 'package:logger/logger.dart' show Logger;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

const int defaultItemsPerPage = 30;
const int maxRecentItemsSize = 5;

sealed class BrowseItemsSourceDesc {
  const BrowseItemsSourceDesc();

  BrowseItem get sourceItem;
  bool get canGenreFilter => false;
}

class DefaultBrowseItemsSourceDesc extends BrowseItemsSourceDesc {
  final BrowseItem browseItem;
  const DefaultBrowseItemsSourceDesc(this.browseItem);

  @override
  int get hashCode =>
      Object.hash(browseItem.id, browseItem.catalog?.previewConfig);

  @override
  BrowseItem get sourceItem => browseItem;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DefaultBrowseItemsSourceDesc &&
        other.browseItem.id == browseItem.id &&
        other.browseItem.catalog?.previewConfig ==
            browseItem.catalog?.previewConfig;
  }

  @override
  bool get canGenreFilter => browseItem.catalog?.canGenreFilter ?? false;
}

class SearchBrowseItemsSourceDesc extends BrowseItemsSourceDesc {
  final BrowseItem browseItem;
  final SearchType searchType;
  final String query;

  const SearchBrowseItemsSourceDesc(
      this.browseItem, this.searchType, this.query);

  @override
  BrowseItem get sourceItem => browseItem;

  @override
  int get hashCode => Object.hash(searchType, query);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchBrowseItemsSourceDesc &&
        other.searchType == searchType &&
        other.query == query;
  }
}

class UserFavoriteBrowseItemsDesc extends BrowseItemsSourceDesc {
  final BrowseItem browseItem;
  final SearchType searchType;
  final String filter;

  UserFavoriteBrowseItemsDesc(this.searchType, this.filter)
      : browseItem = BrowseItem(
          id: "user_favorite_${searchType.name}",
          name: "User Favorite ${searchType.name}",
          canBrowse: true,
          canAdd: true,
          catalog: Catalog(
            title: '',
            canGenreFilter: false,
            id: 'user_favorite_${searchType.name}',
            previewConfig: Preview(
              type: PreviewType.tile,
              contentType:
                  PreviewContentTypeExtension.fromSearchType(searchType),
            ),
          ),
        );

  @override
  int get hashCode => Object.hash(searchType, filter);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserFavoriteBrowseItemsDesc &&
        other.searchType == searchType &&
        other.filter == filter;
  }

  @override
  BrowseItem get sourceItem => browseItem;
}

class SharedPrefsBrowseItemsSourceDesc extends BrowseItemsSourceDesc {
  final BrowseItem browseItem;
  final String prefsKey;
  const SharedPrefsBrowseItemsSourceDesc(this.browseItem, this.prefsKey);

  @override
  int get hashCode => prefsKey.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedPrefsBrowseItemsSourceDesc &&
        other.prefsKey == prefsKey;
  }

  @override
  BrowseItem get sourceItem => browseItem;
}

abstract class BrowseItemsRepository {
  const BrowseItemsRepository();
  Future<BrowseItemsList> fetchItems(
      {required int offset, required int limit, List<String>? genreIds});

  Stream<void> get changes;

  void dispose() {}
}

class BrowseItemsState {
  final int totalCount;
  final int pageSize;
  final Map<int, List<BrowseItem>> pages;
  final Set<int> loadingPages;
  const BrowseItemsState({
    required this.totalCount,
    this.pageSize = 30,
    this.pages = const {},
    this.loadingPages = const {},
  });

  BrowseItem? getItem(int index) {
    final p = index ~/ pageSize;
    final i = index % pageSize;
    final page = pages[p];
    if (page == null || i >= page.length) return null;
    return page[i];
  }

  BrowseItemsState copyWith({
    int? totalCount,
    int? pageSize,
    Map<int, List<BrowseItem>>? pages,
    Set<int>? loadingPages,
  }) {
    return BrowseItemsState(
      totalCount: totalCount ?? this.totalCount,
      pageSize: pageSize ?? this.pageSize,
      pages: pages ?? this.pages,
      loadingPages: loadingPages ?? this.loadingPages,
    );
  }

  bool get isComplete => pages.length * pageSize >= totalCount;
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('override in main()');
});

class BrowseItemsController extends AsyncNotifier<BrowseItemsState> {
  late BrowseItemsSourceDesc _desc;
  late BrowseItemsRepository _repository;
  late String _inputSource;
  final logger = Logger();

  BrowseItemsSourceDesc get desc => _desc;

  StreamSubscription<void>? _sub;

  BrowseItemsController(this._desc);

  @override
  Future<BrowseItemsState> build() async {
    // Keep the provider alive to prevent reloading when switching tabs or folding/unfolding
    ref.keepAlive();
    ref.watch(connectionStateProvider);

    _desc = desc;
    _repository = ref.read(browseItemRepositoryProvider(_desc));

    if (_desc.canGenreFilter) {
      _inputSource = EntityId.fromString(_desc.sourceItem.id).source;
      ref.watch(genreFilterProvider(_inputSource));
    } else {
      _inputSource = '';
    }

    _sub = _repository.changes.listen((_) {
      ref.invalidateSelf();
    });

    ref.onDispose(() => _sub?.cancel());
    final first = await _fetchPage(0, defaultItemsPerPage);
    return BrowseItemsState(
      totalCount: first.total, // or from desc
      pageSize: defaultItemsPerPage,
      pages: {0: first.items},
    );
  }

  Future<void> ensureIndexLoaded(int index) async {
    final s = state.value;
    if (s == null) return;

    final page = index ~/ s.pageSize;
    if (page * s.pageSize >= s.totalCount) return;
    if (s.pages.containsKey(page) || s.loadingPages.contains(page)) return;

    state = AsyncData(s.copyWith(
      loadingPages: {...s.loadingPages, page},
    ));

    final r = await _fetchPage(page, null);
    final after = state.value;
    if (after == null) return;

    final newPages = Map<int, List<BrowseItem>>.from(after.pages)
      ..[page] = r.items;
    final newLoading = Set<int>.from(after.loadingPages)..remove(page);

    state = AsyncData(after.copyWith(
        pages: newPages, loadingPages: newLoading, totalCount: r.total));
  }

  Future<BrowseItemsList> _fetchPage(int page, int? pageSize) async {
    final activePageSize =
        (pageSize ?? state.value?.pageSize ?? defaultItemsPerPage);
    final offset = page * activePageSize;
    final genreIds = _desc.canGenreFilter
        ? ref
            .read(genreFilterProvider(_inputSource))
            .value
            ?.selectedGenres
            .toList()
        : null;
    try {
      final res = await _repository.fetchItems(
          offset: offset, limit: activePageSize, genreIds: genreIds);
      return res;
    } catch (e) {
      logger.e("Error fetching browse items: $e");
      rethrow;
    }
  }
}

class DefaultBrowseItemsRepository extends BrowseItemsRepository {
  final KalinkaPlayerProxy kalinkaApi;
  final String id;
  const DefaultBrowseItemsRepository(this.kalinkaApi, this.id);

  @override
  Future<BrowseItemsList> fetchItems({
    required int offset,
    required int limit,
    List<String>? genreIds,
  }) async {
    return kalinkaApi.browse(id,
        offset: offset, limit: limit, genreIds: genreIds);
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

class SearchBrowseItemsRepository extends BrowseItemsRepository {
  const SearchBrowseItemsRepository(
    this.kalinkaApi,
    this.searchType,
    this.query,
  );

  final KalinkaPlayerProxy kalinkaApi;
  final SearchType searchType;
  final String query;

  @override
  Future<BrowseItemsList> fetchItems({
    required int offset,
    required int limit,
    List<String>? genreIds,
  }) async {
    return kalinkaApi.search(searchType, query, offset: offset, limit: limit);
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

class UserFavoriteBrowseItemsRepository extends BrowseItemsRepository {
  final KalinkaPlayerProxy kalinkaApi;
  final SearchType searchType;
  final String filter;

  UserFavoriteBrowseItemsRepository(
      {required this.kalinkaApi,
      required this.searchType,
      required this.filter});

  @override
  Future<BrowseItemsList> fetchItems(
      {required int offset, required int limit, List<String>? genreIds}) {
    return kalinkaApi.getFavorite(searchType,
        filter: filter, offset: offset, limit: limit);
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

class SharedPrefsBrowseItemsRepository implements BrowseItemsRepository {
  final SharedPreferences prefs;
  final String key;

  List<BrowseItem>? _cache;

  final _changes = StreamController<void>.broadcast();

  SharedPrefsBrowseItemsRepository({required this.prefs, required this.key});

  Future<void> _ensureLoaded() async {
    if (_cache != null) return;
    final itemsJson = prefs.getStringList(key) ?? const [];
    _cache = itemsJson
        .map((itemJson) {
          try {
            return BrowseItem.fromJson(jsonDecode(itemJson));
          } catch (e) {
            return [];
          }
        })
        .whereType<BrowseItem>()
        .toList(growable: true);
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<BrowseItemsList> fetchItems(
      {required int offset, required int limit, List<String>? genreIds}) async {
    await _ensureLoaded();
    final list = _cache!;
    final end = (offset + limit).clamp(0, list.length);
    final slice = list.sublist(offset, end);
    return BrowseItemsList(offset, limit, _cache!.length, slice);
  }

  Future<void> add(BrowseItem item) async {
    await _ensureLoaded();
    _cache!.removeWhere((i) => i.id == item.id);
    _cache!.insert(0, item); // or append
    _cache!.length > maxRecentItemsSize ? _cache!.removeLast() : null;
    await _persist();
    _changes.add(null); // notify watchers to refresh
  }

  Future<void> _persist() async {
    final raw = _cache!.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(key, raw);
  }

  @override
  void dispose() {
    _changes.close();
  }
}

class EmptyBrowseItemsRepository extends BrowseItemsRepository {
  const EmptyBrowseItemsRepository();

  @override
  Future<BrowseItemsList> fetchItems({
    required int offset,
    required int limit,
    List<String>? genreIds,
  }) async {
    return BrowseItemsList(
      offset,
      limit,
      0,
      [],
    );
  }

  @override
  Stream<void> get changes => const Stream<void>.empty();
}

const emptyBrowseItemRepository = EmptyBrowseItemsRepository();

final browseItemRepositoryProvider =
    Provider.family<BrowseItemsRepository, BrowseItemsSourceDesc>((ref, desc) {
  ref.watch(connectionStateProvider);
  final kalinkaApi = ref.read(kalinkaProxyProvider);
  final source = switch (desc) {
    DefaultBrowseItemsSourceDesc(:final browseItem) =>
      DefaultBrowseItemsRepository(kalinkaApi, browseItem.id),
    SearchBrowseItemsSourceDesc(:final searchType, :final query) =>
      SearchBrowseItemsRepository(kalinkaApi, searchType, query),
    UserFavoriteBrowseItemsDesc(:final searchType, :final filter) =>
      UserFavoriteBrowseItemsRepository(
          kalinkaApi: kalinkaApi, searchType: searchType, filter: filter),
    SharedPrefsBrowseItemsSourceDesc(:final prefsKey) =>
      SharedPrefsBrowseItemsRepository(
          prefs: ref.read(sharedPrefsProvider), key: prefsKey),
  };

  ref.onDispose(source.dispose);
  return source;
});

final browseItemsProvider = AsyncNotifierProvider.family<BrowseItemsController,
    BrowseItemsState, BrowseItemsSourceDesc>(
  BrowseItemsController.new,
);
