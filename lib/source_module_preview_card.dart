import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValueX,
        ConsumerWidget,
        FutureProvider,
        StateNotifier,
        StateNotifierProvider,
        WidgetRef;
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/catalog_browse_item_view.dart'
    show CatalogBrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart'
    show BrowseItem, BrowseItemsList, BrowseType, CardSize, PreviewType;
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;

class SourceCollapseStateNotifier extends StateNotifier<Map<String, bool>> {
  SourceCollapseStateNotifier() : super({});

  void toggleCollapse(String sourceId) {
    state = {
      ...state,
      sourceId: !(state[sourceId] ?? false),
    };
  }

  bool isCollapsed(String sourceId) {
    return state[sourceId] ?? false;
  }
}

// Provider for individual source catalog data with seamless paging and caching
final sourceCatalogProvider =
    FutureProvider.family<BrowseItemsList, String>((ref, sourceId) async {
  final proxy = KalinkaPlayerProxy();
  return proxy.browse(sourceId, limit: 3);
});

// Provider for managing collapsed states of source modules
final sourceCollapseStateProvider =
    StateNotifierProvider<SourceCollapseStateNotifier, Map<String, bool>>(
        (ref) {
  return SourceCollapseStateNotifier();
});

class SourceModule extends ConsumerWidget {
  final BrowseItem source;
  final VoidCallback? onShowMoreClicked;

  const SourceModule({super.key, required this.source, this.onShowMoreClicked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapseState = ref.watch(sourceCollapseStateProvider);
    final isCollapsed = collapseState[source.id] ?? false;
    final sourceCatalog = ref.watch(sourceCatalogProvider(source.id));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _buildTitleBar(context, ref, isCollapsed),
          if (!isCollapsed)
            sourceCatalog.when(
              data: (catalog) => _buildExpandedContent(context, catalog),
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading ${source.name}: $error',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, WidgetRef ref, bool isCollapsed) {
    return ListTile(
      leading: source.catalog?.image?.small != null
          ? CircleAvatar(
              backgroundImage: NetworkImage(source.catalog!.image!.small!),
            )
          : CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                source.name?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      title: Text(
        source.name ?? 'Unknown Source',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: source.catalog?.description != null
          ? Text(source.catalog!.description!)
          : null,
      trailing: IconButton(
        icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
        onPressed: () {
          ref
              .read(sourceCollapseStateProvider.notifier)
              .toggleCollapse(source.id);
        },
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, BrowseItemsList catalog) {
    if (catalog.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No content available'),
      );
    }

    // Find hero item (first large image item or fallback to first item)
    final heroItem = _findHeroItem(catalog.items);

    // Build preview rows (max 3)
    final previewRows = _buildPreviewRows(context, catalog.items);

    return Column(
      children: [
        if (heroItem != null) HeroTile(item: heroItem),
        ...previewRows,
        if (catalog.total > 3) _buildShowMoreButton(context),
        const SizedBox(height: 16),
      ],
    );
  }

  BrowseItem? _findHeroItem(List<BrowseItem> items) {
    // First try to find an item with preview_config type=image and card_size=large
    for (final item in items) {
      final preview = item.catalog?.previewConfig;
      if (preview?.type == PreviewType.imageText &&
          preview?.cardSize == CardSize.large) {
        return item;
      }
    }
    // Fallback to first item with catalog
    return items.where((item) => item.catalog != null).firstOrNull;
  }

  void _onTap(BuildContext context, BrowseItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        if (item.browseType == BrowseType.catalog) {
          return CatalogBrowseItemView(
              dataSource: BrowseItemDataSource.browse(item),
              onTap: (item) => _onTap(context, item));
        }

        return BrowseItemView(browseItem: item);
      }),
    );
  }

  List<Widget> _buildPreviewRows(BuildContext context, List<BrowseItem> items) {
    final rows = <Widget>[];

    for (final item in items) {
      // if (item.catalog?.previewConfig == null) continue;

      // final preview = item.catalog!.previewConfig!;

      rows.add(PreviewSectionCard(
        dataSource: BrowseItemDataSource.browse(item),
        rowsCount: 1,
        onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CatalogBrowseItemView(
                  dataSource: BrowseItemDataSource.browse(item),
                  onTap: (item) {
                    if (item.canBrowse) {
                      _onTap(context, item);
                    }
                  }),
            ),
          );
        },
      ));
    }

    return rows;
  }

  Widget _buildShowMoreButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
          vertical: KalinkaConstants.kContentVerticalPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onShowMoreClicked,
          icon: const Icon(Icons.arrow_forward),
          label: Text('Show more from ${source.name}'),
        ),
      ),
    );
  }
}

class HeroTile extends StatelessWidget {
  final BrowseItem item;

  const HeroTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () {
          // TODO: Handle hero tile tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped ${item.name}')),
          );
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Stack(
            children: [
              // Background image
              if (item.image?.large != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.image!.large!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackImage(),
                  ),
                )
              else
                _buildFallbackImage(),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),

              // Title overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.catalog?.description != null)
                      Text(
                        item.catalog!.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.blue[600]!],
        ),
      ),
      child: Center(
        child: Text(
          item.name?.substring(0, 2).toUpperCase() ?? '??',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
