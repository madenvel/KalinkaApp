import 'package:kalinka/data_model.dart';

class LazyLoadingList {
  int _totalItems = 0;
  bool _hasLoaded = false;

  final List<BrowseItem?> _results = [];

  List<BrowseItem?> get results => _results;
  int get totalItems => _totalItems;
  bool get hasLoaded => _hasLoaded;

  Future<BrowseItemsList> performRequest(int offset, int limit) {
    return Future.value(BrowseItemsList(offset, limit, 0, []));
  }

  Future<void> loadMoreItems(int chunkSize) async {
    if (_hasLoaded && _results.length >= _totalItems) {
      return;
    }
    _hasLoaded = false;
    _results.add(null);
    onLoading();

    performRequest(_results.length - 1, chunkSize).then((value) {
      _results.removeLast();
      _results.addAll(value.items);
      _totalItems = value.total;
      _hasLoaded = true;
      onLoaded();
    });
  }

  void reset() {
    _results.clear();
    _totalItems = 0;
    _hasLoaded = false;
  }

  void onLoading() {}
  void onLoaded() {}
}
