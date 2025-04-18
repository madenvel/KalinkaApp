import 'package:kalinka/data_model.dart'
    show BrowseItem, BrowseItemsList, Catalog, Preview, PreviewType, SearchType;
import 'package:kalinka/kalinkaplayer_proxy.dart';

abstract class BrowseItemDataSource {
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  });

  String get key;

  BrowseItem get item;

  bool get isValid;

  static BrowseItemDataSource browse(BrowseItem parentItem) {
    return DefaultBrowseItemDataSource(parentItem);
  }

  static BrowseItemDataSource suggestions(BrowseItem parentItem) {
    return SuggestionsBrowseItemDataSource(parentItem);
  }

  static BrowseItemDataSource search(SearchType searchType, String query) {
    return SearchBrowseItemDataSource(searchType, query);
  }

  static BrowseItemDataSource favorites(SearchType searchType, String filter) {
    return UserFavoriteBrowseItemDataSource(searchType, filter);
  }

  static BrowseItemDataSource empty() {
    return EmptyBrowseItemDataSource();
  }
}

class EmptyBrowseItemDataSource implements BrowseItemDataSource {
  @override
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  }) async {
    return BrowseItemsList(0, 0, 0, []);
  }

  @override
  String get key => 'empty';

  @override
  BrowseItem get item => BrowseItem(
        name: '',
        subname: '',
        id: '',
        url: '',
        canBrowse: false,
        canAdd: false,
        catalog: null,
      );

  @override
  bool get isValid => true;
}

class DefaultBrowseItemDataSource implements BrowseItemDataSource {
  final proxy = KalinkaPlayerProxy();
  final BrowseItem parentItem;

  DefaultBrowseItemDataSource(this.parentItem) {
    assert(parentItem.canBrowse);
  }

  @override
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  }) async {
    return proxy.browseItem(parentItem,
        offset: offset, limit: limit, genreIds: genreFilter);
  }

  @override
  String get key => parentItem.url;

  @override
  BrowseItem get item => parentItem;

  @override
  bool get isValid => parentItem.canBrowse;
}

class SuggestionsBrowseItemDataSource implements BrowseItemDataSource {
  final proxy = KalinkaPlayerProxy();
  final BrowseItem parentItem;
  late BrowseItem catalogItem;
  bool _isValid = true;

  SuggestionsBrowseItemDataSource(this.parentItem) {
    catalogItem = BrowseItem(
      name: parentItem.name,
      subname: parentItem.subname,
      id: parentItem.id,
      url: parentItem.url,
      canBrowse: true,
      canAdd: false,
      catalog: Catalog(
        id: parentItem.id,
        previewConfig: Preview(
            type: PreviewType.imageText, aspectRatio: 1.0, rowsCount: 1),
        title: '',
        canGenreFilter: false,
      ),
    );
  }

  @override
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  }) async {
    return proxy
        .suggest(item: parentItem, offset: offset, limit: limit)
        .catchError((e) {
      _isValid = false;
      throw e;
    });
  }

  @override
  String get key => '${parentItem.url}_suggestions';

  @override
  BrowseItem get item => catalogItem;

  @override
  bool get isValid => _isValid;
}

class SearchBrowseItemDataSource implements BrowseItemDataSource {
  final proxy = KalinkaPlayerProxy();
  final SearchType searchType;
  final String query;
  late BrowseItem _item;
  bool _isValid = true;

  SearchBrowseItemDataSource(this.searchType, this.query) {
    _item = BrowseItem(
      name: 'Search: $query',
      subname: 'Results for $query',
      id: 'search_${searchType.name}_$query',
      url: '/search/${searchType.name}/$query',
      canBrowse: true,
      canAdd: false,
      catalog: Catalog(
        id: 'search_${searchType.name}_$query',
        previewConfig: Preview(
            type: PreviewType.imageText, aspectRatio: 1.0, rowsCount: 1),
        title: 'Search Results',
        canGenreFilter: false,
      ),
    );
  }

  @override
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  }) async {
    return proxy
        .search(searchType, query, offset: offset, limit: limit)
        .catchError((e) {
      _isValid = false;
      throw e;
    });
  }

  @override
  String get key => 'search_${searchType.name}_$query';

  @override
  BrowseItem get item => _item;

  @override
  bool get isValid => _isValid;
}

class UserFavoriteBrowseItemDataSource implements BrowseItemDataSource {
  final proxy = KalinkaPlayerProxy();
  final SearchType searchType;
  final String filter;
  late BrowseItem _item;
  bool _isValid = true;

  UserFavoriteBrowseItemDataSource(this.searchType, this.filter) {
    String title;

    switch (searchType) {
      case SearchType.album:
        title = 'Albums';
        break;
      case SearchType.artist:
        title = 'Artists';
        break;
      case SearchType.track:
        title = 'Tracks';
        break;
      case SearchType.playlist:
        title = 'Playlists';
        break;
      default:
        title = 'Favorites';
    }

    _item = BrowseItem(
      name: title,
      subname: '',
      id: 'favorites_${searchType.name}_$filter',
      url: '/favorites/list/${searchType.name}?filter=$filter',
      canBrowse: true,
      canAdd: false,
      catalog: Catalog(
        id: 'favorites_${searchType.name}',
        previewConfig: Preview(
            type: PreviewType.imageText, aspectRatio: 1.0, rowsCount: 1),
        title: title,
        canGenreFilter: false,
      ),
    );
  }

  @override
  Future<BrowseItemsList> fetch({
    required int offset,
    required int limit,
    required List<String> genreFilter,
  }) async {
    return proxy
        .getFavorite(searchType, filter: filter, offset: offset, limit: limit)
        .catchError((e) {
      _isValid = false;
      return BrowseItemsList(0, 0, 0, []);
    });
  }

  @override
  String get key => 'favorites_${searchType.name}_$filter';

  @override
  BrowseItem get item => _item;

  @override
  bool get isValid => _isValid;
}
