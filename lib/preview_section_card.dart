import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/catalog_browse_item_view.dart'
    show CatalogBrowseItemView;
import 'package:kalinka/data_model.dart' show BrowseItem;
import 'package:kalinka/large_image_preview_card.dart'
    show LargeImagePreviewCard;
import 'package:kalinka/preview_section_grid.dart' show SectionPreviewGrid;
import 'package:kalinka/tracks_browse_view.dart';

class PreviewSectionCard extends StatelessWidget {
  final BrowseItemDataSource? dataSource;
  final double contentPadding;

  const PreviewSectionCard(
      {super.key, this.dataSource, this.contentPadding = 8.0});

  void _onTap(BuildContext context, BrowseItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        if (item.browseType == 'catalog') {
          return CatalogBrowseItemView(
              dataSource: BrowseItemDataSource.browse(item),
              onTap: (item) => _onTap(context, item));
        }

        return TracksBrowseView(browseItem: item);
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
    return (section == null)
        ? _buildSectionPlaceholder(context, const SectionPreviewGrid())
        : _buildSectionPreview(
            context,
            section,
            hasImage
                ? LargeImagePreviewCard(
                    section: section, contentPadding: contentPadding)
                : SectionPreviewGrid(
                    dataSource: dataSource,
                    onTap: (item) => _onTap(context, item)),
            seeAll: !hasImage);
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
          padding: EdgeInsets.all(contentPadding),
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
                  child: const Text('More', style: TextStyle(fontSize: 16)),
                  onPressed: () {
                    if (item.canBrowse) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CatalogBrowseItemView(
                                dataSource: dataSource!,
                                onTap: (item) => _onTap(context, item),
                              )));
                    }
                  })
          ]),
        ),
        if (item.description != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4.0),
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
          padding: EdgeInsets.all(contentPadding),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ]),
        ),
        child
      ],
    );
  }
}
