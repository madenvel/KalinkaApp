import 'package:kalinka/data_model.dart'
    show BrowseItem, BrowseItemsList, Catalog, Preview, PreviewType;
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
