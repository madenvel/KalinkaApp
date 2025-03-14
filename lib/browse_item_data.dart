import 'package:kalinka/data_model.dart';

enum BrowseItemLoadingState {
  loading,
  loaded,
  error,
}

class BrowseItemData {
  final BrowseItem? item;
  final BrowseItemLoadingState loadingState;

  BrowseItemData({this.item, required this.loadingState});
}
