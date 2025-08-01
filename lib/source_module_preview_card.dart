import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod
    show
        AsyncValueX,
        ConsumerWidget,
        FutureProvider,
        StateNotifier,
        StateNotifierProvider,
        WidgetRef;
import 'package:kalinka/browse_item_data_provider.dart';
import 'package:kalinka/browse_item_data_source.dart' show BrowseItemDataSource;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/catalog_browse_item_view.dart'
    show CatalogBrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart'
    show BrowseItem, BrowseItemsList, BrowseType, PreviewType;
import 'package:kalinka/data_provider.dart' show GenreFilterProvider;
import 'package:kalinka/hero_tile.dart' show HeroTile;
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:kalinka/source_attribution.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;

class SourceCollapseStateNotifier
    extends riverpod.StateNotifier<Map<String, bool>> {
  SharedPreferencesWithCache? prefs;
  bool _isInitialized = false;

  SourceCollapseStateNotifier() : super({}) {
    _initializeState();
  }

  static const String kCollapsedKey = 'Kalinka.input_source.collapsed';

  Future<void> _initializeState() async {
    if (_isInitialized) return;

    try {
      prefs = await SharedPreferencesWithCache.create(
          cacheOptions: SharedPreferencesWithCacheOptions(allowList: {
        kCollapsedKey,
      }));

      final collapsedStateString = prefs?.getString(kCollapsedKey);
      if (collapsedStateString != null && collapsedStateString.isNotEmpty) {
        // Parse the stored JSON-like string back to Map<String, bool>
        final Map<String, String> queryParams =
            Uri.splitQueryString(collapsedStateString);
        final Map<String, bool> collapsedStateMap = queryParams
            .map((key, value) => MapEntry(key, value.toLowerCase() == 'true'));
        state = Map<String, bool>.from(collapsedStateMap);
      }

      _isInitialized = true;
    } catch (e) {
      // If there's an error reading from shared prefs, just use empty state
      _isInitialized = true;
    }
  }

  Future<void> _saveState() async {
    if (!_isInitialized || prefs == null) return;

    try {
      // Convert Map<String, bool> to a query string format for storage
      final String stateString = state.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${entry.value}')
          .join('&');
      await prefs!.setString(kCollapsedKey, stateString);
    } catch (e) {
      // Handle save errors gracefully
    }
  }

  Future<void> toggleCollapse(String sourceId) async {
    // Ensure initialization is complete before toggling
    await _initializeState();

    state = {
      ...state,
      sourceId: !(state[sourceId] ?? false),
    };

    // Save state after updating
    await _saveState();
  }

  bool isCollapsed(String sourceId) {
    return state[sourceId] ?? false;
  }
}

// Provider for individual source catalog data with seamless paging and caching
final sourceCatalogProvider =
    riverpod.FutureProvider.family<BrowseItemsList, String>(
        (ref, sourceId) async {
  final proxy = KalinkaPlayerProxy();
  return proxy.browse(sourceId, limit: 3);
});

// Provider for managing collapsed states of source modules
final sourceCollapseStateProvider = riverpod.StateNotifierProvider<
    SourceCollapseStateNotifier, Map<String, bool>>((ref) {
  return SourceCollapseStateNotifier();
});

class SourceModule extends riverpod.ConsumerWidget {
  final BrowseItem source;
  final VoidCallback? onShowMoreClicked;

  const SourceModule({super.key, required this.source, this.onShowMoreClicked});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
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

  Widget _buildTitleBar(
      BuildContext context, riverpod.WidgetRef ref, bool isCollapsed) {
    return ListTile(
      leading: SourceAttribution(id: source.id, size: 36.0),
      title: Text(
        source.name ?? 'Unknown Source',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: source.catalog?.description != null
          ? Text(source.catalog!.description!)
          : null,
      trailing: IconButton(
        icon: Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
        onPressed: () async {
          await ref
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
    final previewRows = _buildPreviewRows(
        context, catalog.items.where((item) => item != heroItem).toList());

    return Column(
      children: [
        if (heroItem != null)
          ChangeNotifierProxyProvider<GenreFilterProvider,
              BrowseItemDataProvider>(
            create: (_) => BrowseItemDataProvider.fromDataSource(
              dataSource: BrowseItemDataSource.browse(heroItem),
              itemCountLimit: 5,
            ),
            update: (_, genreFilterProvider, dataProvider) {
              final filterList = genreFilterProvider.filter.toList();
              if (dataProvider == null) {
                return BrowseItemDataProvider.fromDataSource(
                    dataSource: BrowseItemDataSource.browse(heroItem))
                  ..maybeUpdateGenreFilter(filterList);
              }
              dataProvider.maybeUpdateGenreFilter(filterList);
              return dataProvider;
            },
            child: Padding(
              padding: const EdgeInsets.only(
                  bottom: KalinkaConstants.kSpaceBetweenSections),
              child: HeroTile(
                onTap: (BrowseItem item) => _onTap(context, item),
              ),
            ),
          ),
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
      if (preview?.type == PreviewType.carousel) {
        return item;
      }
    }
    return null;
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
      rows.add(Padding(
        padding: const EdgeInsets.only(
            bottom: KalinkaConstants.kSpaceBetweenSections),
        child: PreviewSectionCard(
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
        ),
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
