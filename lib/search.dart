import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;

import 'package:kalinka/browse_item_data_provider_riverpod.dart'
    show
        SearchBrowseItemsSourceDesc,
        SharedPrefsBrowseItemsRepository,
        SharedPrefsBrowseItemsSourceDesc,
        browseItemRepositoryProvider;
import 'package:kalinka/browse_item_list.dart' show BrowseItemList;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/data_model.dart'
    show
        BrowseItem,
        Catalog,
        Preview,
        PreviewContentTypeExtension,
        PreviewType,
        SearchType,
        SearchTypeExtension;
import 'package:kalinka/preview_section.dart' show PreviewSection;
import 'search_history_provider.dart';

const int maxRecentItemsSize = 5;

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();

  static String generatePrefsKey(SearchType type) {
    return 'recent_${type.name}s';
  }

  static SharedPrefsBrowseItemsSourceDesc buildRecentlyViewedSourceDesc(
      SearchType type) {
    final key = generatePrefsKey(type);
    return SharedPrefsBrowseItemsSourceDesc(
      BrowseItem(
        id: key,
        name: 'Recently Viewed ${type.name}s',
        canBrowse: true,
        canAdd: true,
        catalog: Catalog(
          title: 'Recently Viewed ${type.name}s',
          canGenreFilter: false,
          id: key,
          previewConfig: Preview(
              type: type == SearchType.track
                  ? PreviewType.tile
                  : PreviewType.imageText,
              contentType: PreviewContentTypeExtension.fromSearchType(type),
              itemsCount: 5),
        ),
      ),
      key,
    );
  }
}

enum SearchFilter { all, tracks, albums, artists, playlists }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.all;
  final Map<SearchType, SharedPrefsBrowseItemsSourceDesc>
      _recentlyViewedSourceDesc = {
    for (var type in SearchType.values)
      type: SearchScreen.buildRecentlyViewedSourceDesc(type),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setFilter(SearchFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Widget _buildChip(String label, SearchFilter filter) {
    return FilterChip(
      label: Text(label),
      showCheckmark: false,
      selected: _selectedFilter == filter,
      onSelected: (selected) {
        if (selected) {
          _setFilter(filter);
        }
      },
    );
  }

  Widget _buildLandingPage() {
    return _LandingPageContent(
      onSearchSelected: (search) {
        setState(() {
          _searchController.text = search;
          _selectedFilter = SearchFilter.all;
        });
      },
      onItemSelected: _updateRecentItems,
    );
  }

  BrowseItem _createBrowseItem(String title, SearchType type,
      {int? itemsCount = 5}) {
    final id = 'search_${type.name}_${_searchController.text}';
    return BrowseItem(
      name: title,
      canBrowse: true,
      canAdd: false,
      id: id,
      catalog: Catalog(
        title: title,
        canGenreFilter: false,
        id: id,
        previewConfig: Preview(
          type: type == SearchType.track
              ? PreviewType.tile
              : PreviewType.imageText,
          rowsCount: 1,
          itemsCount: itemsCount,
          contentType: PreviewContentTypeExtension.fromSearchType(type),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text;

    return ListView.builder(
        itemCount: SearchType.values.length - 1,
        itemBuilder: (_, index) {
          final searchType = SearchType.values[index + 1];

          return PreviewSection(
            sourceDesc: SearchBrowseItemsSourceDesc(
              _createBrowseItem(
                searchType.name.capitalize,
                searchType,
              ),
              searchType,
              query,
            ),
            onSeeMore: () => _setFilter(SearchFilter.values[index + 1]),
            onItemSelected: _updateSearchHistoryAndRecentItems,
            showSourceAttribution: true,
          );
        });
  }

  Widget _buildCategoryResults(SearchFilter filter) {
    return BrowseItemList(
      sourceDesc: SearchBrowseItemsSourceDesc(
        _createBrowseItem(_selectedFilter.name, SearchType.values[filter.index],
            itemsCount: null),
        SearchType.values[filter.index],
        _searchController.text,
      ),
      onTap: (context, index, item) {
        if (item.track != null) {
          return;
        }

        _updateSearchHistoryAndRecentItems(item);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BrowseItemView(
                browseItem: item, onItemSelected: _updateRecentItems),
          ),
        );
      },
      onAction: (context, index, item) {
        showModalBottomSheet(
          context: context, // Use the builder context
          showDragHandle: true,
          isScrollControlled: false,
          useRootNavigator: true, // Good practice if navigating from the sheet
          scrollControlDisabledMaxHeightRatio: 0.7,
          builder: (_) => BottomMenu(
            // Use parentContext if needed for actions *outside* the sheet
            parentContext: context,
            browseItem: item, // Use specific item or the main one
          ),
        );
      },
      pageSize: 0,
      shrinkWrap: false,
      showSourceAttribution: true,
    );
  }

  void _updateRecentItems(BrowseItem item) {
    final sourceDesc = _recentlyViewedSourceDesc[
        SearchTypeExtension.fromBrowseType(item.browseType)];
    assert(sourceDesc != null);
    final repository = ref.read(browseItemRepositoryProvider(sourceDesc!));
    final sharedPrefsRepo =
        repository is SharedPrefsBrowseItemsRepository ? repository : null;

    sharedPrefsRepo?.add(item);
  }

  void _updateSearchHistory() {
    if (_searchController.text.isNotEmpty) {
      ref
          .read(searchHistoryProvider.notifier)
          .addSearchQuery(_searchController.text);
    }
  }

  void _updateSearchHistoryAndRecentItems(BrowseItem item) {
    _updateSearchHistory();
    _updateRecentItems(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: KalinkaConstants.kScreenContentHorizontalPadding,
        title: Center(
          child: SearchBar(
            constraints: BoxConstraints(minHeight: 40),
            controller: _searchController,
            elevation: WidgetStateProperty.all(0.0),
            hintText: 'Search...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
            ],
            onSubmitted: (value) {
              setState(() {});
            },
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        if (_searchController
            .text.isNotEmpty) // Show chips when focused or text exists
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
                  vertical: KalinkaConstants.kContentVerticalPadding),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: KalinkaConstants.kContentVerticalPadding),
                child: Row(
                  spacing: KalinkaConstants.kFilterChipSpace,
                  children: List.generate(SearchFilter.values.length, (index) {
                    final filter = SearchFilter.values[index];
                    return _buildChip(
                      filter.name.capitalize,
                      filter,
                    );
                  }),
                ),
              ),
            ),
          ),
        Expanded(
          child: _searchController.text.isNotEmpty
              ? (_selectedFilter == SearchFilter.all
                  ? _buildSearchResults()
                  : _buildCategoryResults(_selectedFilter))
              : _buildLandingPage(),
        ),
        const SizedBox(
          height: KalinkaConstants.kContentVerticalPadding * 2,
        ),
      ],
    );
  }
}

class _LandingPageContent extends ConsumerWidget {
  final Function(String) onSearchSelected;
  final Function(BrowseItem) onItemSelected;
  final Map<SearchType, SharedPrefsBrowseItemsSourceDesc>
      _recentlyViewedSourceDesc = {
    for (var type in SearchType.values)
      type: SearchScreen.buildRecentlyViewedSourceDesc(type),
  };

  _LandingPageContent({
    required this.onSearchSelected,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchHistory = ref.watch(searchHistoryProvider);

    if (searchHistory.isEmpty) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 48),
            Text('Search for albums, artists, tracks, playlists',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentSearchHistory(ref),
        ...List.generate(SearchType.values.length - 1, (index) {
          SearchType type = SearchType.values[index + 1];
          final sourceDesc = _recentlyViewedSourceDesc[type];

          if (sourceDesc == null) {
            return const SizedBox.shrink();
          }

          return PreviewSection(
            sourceDesc: sourceDesc,
            onItemSelected: onItemSelected,
            showSourceAttribution: true,
            seeMore: false,
          );
        }),
      ],
    ));
  }

  Widget _buildRecentSearchHistory(WidgetRef ref) {
    final searchHistory = ref.watch(searchHistoryProvider);
    if (searchHistory.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: KalinkaConstants.kContentVerticalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
            child: Text('Recent Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
                  vertical: KalinkaConstants.kContentVerticalPadding),
              child: Row(
                spacing: KalinkaConstants.kFilterChipSpace,
                children: List.generate(searchHistory.length, (index) {
                  final search = searchHistory[index];
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 8),
                        Text(search),
                      ],
                    ),
                    onSelected: (_) => onSearchSelected(search),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
