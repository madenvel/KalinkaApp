import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/catalog_browse_item_view.dart'
    show CatalogBrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/data_provider.dart' show GenreFilterProvider;
import 'package:kalinka/large_image_preview_card.dart'
    show LargeImagePreviewCard;
import 'package:kalinka/preview_section_grid.dart' show SectionPreviewGrid;
import 'package:kalinka/browse_item_view.dart';
import 'package:kalinka/shimmer_widget.dart';
import 'package:provider/provider.dart'
    show ChangeNotifierProxyProvider, Consumer;

class PreviewSectionCard extends StatelessWidget {
  final BrowseItemDataSource? dataSource;
  final int? rowsCount;
  final bool seeAll;
  final VoidCallback? onSeeAll;
  final Function(BrowseItem)? onItemSelected;

  const PreviewSectionCard(
      {super.key,
      this.dataSource,
      this.rowsCount,
      this.seeAll = true,
      this.onSeeAll,
      this.onItemSelected});

  void _onTap(BuildContext context, BrowseItem item) {
    onItemSelected?.call(item);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        if (item.browseType == 'catalog') {
          return CatalogBrowseItemView(
              dataSource: BrowseItemDataSource.browse(item),
              onTap: (item) => _onTap(context, item));
        }

        return BrowseItemView(browseItem: item);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = dataSource?.item;
    final image = section?.image?.large ??
        section?.image?.small ??
        section?.image?.thumbnail;
    final hasImage = image != null && image.isNotEmpty;
    if (section == null) {
      return _buildSectionPlaceholder(context, const SectionPreviewGrid());
    }

    return _buildWithBrowseDataProvider(
      context,
      Consumer(
        builder: (context, BrowseItemDataProvider dataProvider, child) {
          final hasNoItems = dataProvider.totalItemCount == 0;
          return _buildSectionPreview(
            context,
            section,
            hasImage
                ? LargeImagePreviewCard(section: section)
                : (hasNoItems
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: KalinkaConstants
                                .kScreenContentHorizontalPadding,
                            vertical: KalinkaConstants.kContentVerticalPadding),
                        child: const Text('No items found'),
                      )
                    : SectionPreviewGrid(
                        dataProvider: dataProvider,
                        onTap: (item) => _onTap(context, item))),
            seeAll: !hasImage && !hasNoItems && seeAll,
          );
        },
      ),
    );
  }

  Widget _buildWithBrowseDataProvider(BuildContext context, Widget child) {
    final catalog = dataSource?.item.catalog;
    final crossAxisCount = rowsCount ?? catalog?.previewConfig?.rowsCount ?? 2;
    final itemsCount = dataSource?.item.catalog?.previewConfig?.itemsCount ??
        5 * crossAxisCount;

    return ChangeNotifierProxyProvider<GenreFilterProvider,
            BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider.fromDataSource(
            dataSource: dataSource!, itemCountLimit: itemsCount),
        update: (_, genreFilterProvider, dataProvider) {
          final filterList = genreFilterProvider.filter.toList();
          if (dataProvider == null) {
            return BrowseItemDataProvider.fromDataSource(
                dataSource: dataSource!)
              ..maybeUpdateGenreFilter(filterList);
          }
          dataProvider.maybeUpdateGenreFilter(filterList);
          return dataProvider;
        },
        child: child);
  }

  Widget _buildSectionPreview(
      BuildContext context, BrowseItem? item, Widget child,
      {bool seeAll = true}) {
    if (item == null) {
      return _buildSectionPlaceholder(context, child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: KalinkaConstants.kScreenContentHorizontalPadding,
              right: KalinkaConstants.kScreenContentHorizontalPadding,
              bottom: KalinkaConstants.kTitleContentVerticalSpace),
          child: Row(children: [
            Text(
              item.name ?? 'Unknown Section',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (seeAll)
              TextButton(
                  style: TextButton.styleFrom(
                      padding: KalinkaConstants.kElevatedButtonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )),
                  onPressed: onSeeAll ??
                      () {
                        if (item.canBrowse) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CatalogBrowseItemView(
                                    dataSource: dataSource!,
                                    onTap: (item) => _onTap(context, item),
                                  )));
                        }
                      },
                  child: Text('See more')),
          ]),
        ),
        if (item.description != null)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
                vertical: KalinkaConstants.kContentVerticalPadding),
            child: Text(item.description!),
          ),
        child
      ],
    );
  }

  Widget _buildSectionPlaceholder(BuildContext context, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
          child: Row(children: [
            ShimmerWidget(width: 100, height: 20),
            const Spacer(),
            ShimmerWidget(
              width: 40,
              height: 20,
            )
          ]),
        ),
        const SizedBox(height: KalinkaConstants.kTitleContentVerticalSpace),
        child
      ],
    );
  }
}
