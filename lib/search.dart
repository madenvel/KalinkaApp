import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/bottom_menu.dart' show BottomMenu;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart'
    show BrowseItemDataSource, StaticItemsBrowseItemDataSource;
import 'package:kalinka/browse_item_list.dart' show BrowseItemList;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/data_model.dart'
    show BrowseItem, PlayerState, SearchType;
import 'package:kalinka/data_provider.dart' show PlayerStateProvider;
import 'package:kalinka/kalinkaplayer_proxy.dart' show KalinkaPlayerProxy;
import 'package:kalinka/preview_section_card.dart';
import 'package:kalinka/recent_items_provider.dart';
import 'package:provider/provider.dart' as provider
    show ChangeNotifierProvider, ReadContext, WatchContext;
import 'search_history_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum SearchFilter { all, tracks, albums, artists, playlists }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilter _selectedFilter = SearchFilter.all;

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedFilter == filter,
        onSelected: (selected) {
          if (selected) {
            _setFilter(filter);
          }
        },
      ),
    );
  }

  Widget _buildHorizontalList(BrowseItemDataSource dataSource,
      {VoidCallback? onSeeMore, Function(BrowseItem)? onItemSelected}) {
    // Use a key based on dataSource hashCode to ensure rebuild when it changes
    return PreviewSectionCard(
      key: ValueKey(dataSource.hashCode),
      dataSource: dataSource,
      seeAll: onSeeMore != null,
      onSeeAll: onSeeMore,
      onItemSelected: onItemSelected,
    );
  }

  Widget _buildLandingPage() {
    // Get search history from the provider
    // Get recent items from their respective providers
    final recentTracks = ref.watch(recentTracksProvider);
    final recentAlbums = ref.watch(recentAlbumsProvider);
    final recentArtists = ref.watch(recentArtistsProvider);
    final recentPlaylists = ref.watch(recentPlaylistsProvider);

    // Group all recent items by SearchType
    final Map<SearchType, List<BrowseItem>> recentItems = {
      SearchType.track: recentTracks,
      SearchType.album: recentAlbums,
      SearchType.artist: recentArtists,
      SearchType.playlist: recentPlaylists,
    };

    final searchHistory = ref.watch(searchHistoryProvider);

    if (searchHistory.isEmpty &&
        recentTracks.isEmpty &&
        recentAlbums.isEmpty &&
        recentArtists.isEmpty &&
        recentPlaylists.isEmpty) {
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

    return ListView(
      children: [
        if (searchHistory.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Text('Previous searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, right: 8.0, top: 8.0, bottom: 24.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: searchHistory
                  .map((search) => ActionChip(
                        label: Text(search),
                        onPressed: () {
                          setState(() {
                            _searchController.text = search;
                            _selectedFilter = SearchFilter.all;
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
          ..._buildRecentItemsList(recentItems)
              .expand((item) => [item, const SizedBox(height: 24)])
              .toList()
            ..removeLast(),
        ],
      ],
    );
  }

  List<Widget> _buildRecentItemsList(
      Map<SearchType, List<BrowseItem>> recentItems) {
    List<Widget> recentItemsWidgets = [];
    for (var searchType in SearchType.values.sublist(1)) {
      final items = recentItems[searchType] ?? [];
      if (items.isNotEmpty) {
        final title = 'Recently Viewed ${searchType.name.capitalize}s';
        if (searchType == SearchType.track) {
          recentItemsWidgets.add(_buildRecentTracksList(title, items));
        } else {
          // For other types, we can use a different data source
          recentItemsWidgets.add(_buildHorizontalList(
            StaticItemsBrowseItemDataSource.create(title, items),
            onItemSelected: _updateRecentItems,
          ));
        }
      }
    }
    return recentItemsWidgets;
  }

  Widget _buildRecentTracksList(String title, List<BrowseItem> items) {
    return provider.ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider.fromDataSource(
            dataSource: StaticItemsBrowseItemDataSource.create(title, items)),
        builder: (context, _) => _buildTrackList(context, title));
  }

  Widget _buildSearchResultTrackList(String title) {
    return provider.ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider.fromDataSource(
            dataSource: BrowseItemDataSource.search(
                SearchType.track, _searchController.text)),
        builder: (context, _) =>
            _buildTrackList(context, title, totalSize: 5, onSeeMore: () {
              _setFilter(SearchFilter.tracks);
            }));
  }

  Widget _buildTrackList(BuildContext context, String title,
      {int? totalSize, VoidCallback? onSeeMore}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: Row(
            children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onSeeMore != null)
                TextButton(
                  onPressed: onSeeMore,
                  child: const Text('See more'),
                ),
            ],
          ),
        ),
        BrowseItemList(
            pageSize: 5,
            size: totalSize,
            shrinkWrap: true,
            provider: context.watch<BrowseItemDataProvider>(),
            onTap: (context, index, item) {
              _updateRecentItems(item);
              _playTrack(context, item.track!.id, index);
            },
            onAction: (context, index, item) {
              showModalBottomSheet(
                context: context, // Use the builder context
                showDragHandle: true,
                isScrollControlled: false,
                useRootNavigator:
                    true, // Good practice if navigating from the sheet
                scrollControlDisabledMaxHeightRatio: 0.7,
                builder: (_) => BottomMenu(
                  // Use parentContext if needed for actions *outside* the sheet
                  parentContext: context,
                  browseItem: item, // Use specific item or the main one
                ),
              );
            }),
      ],
    );
  }

  void _playTrack(BuildContext context, String trackId, int index) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      KalinkaPlayerProxy().play(index);
    } else {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().addTracks([trackId]);
      await KalinkaPlayerProxy().play();
    }
  }

  Widget _buildSearchResults() {
    final query = _searchController.text;
    return ListView(
      children: [
        for (var i = 1; i < SearchType.values.length; i++)
          if (SearchType.values[i] == SearchType.track)
            _buildSearchResultTrackList('Tracks')
          else
            _buildHorizontalList(
                BrowseItemDataSource.search(SearchType.values[i], query),
                onSeeMore: () => _setFilter(SearchFilter.values[i]),
                onItemSelected: _updateSearchHistoryAndRecentItems),
      ],
    );
  }

  Widget _buildCategoryResults(SearchFilter filter) {
    // Adding a key that changes whenever filter or search text changes
    // ensures the provider is recreated with new data
    final searchKey = Key('${_selectedFilter.name}-${_searchController.text}');

    return provider.ChangeNotifierProvider<BrowseItemDataProvider>(
      key: searchKey,
      create: (context) => BrowseItemDataProvider.fromDataSource(
        dataSource: BrowseItemDataSource.search(
          SearchType.values[filter.index],
          _searchController.text,
        ),
      ),
      builder: (context, __) {
        return BrowseItemList(
          provider: context.watch<BrowseItemDataProvider>(),
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
              useRootNavigator:
                  true, // Good practice if navigating from the sheet
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
        );
      },
    );
  }

  void _updateRecentItems(BrowseItem item) {
    if (item.track != null) {
      ref.read(recentTracksProvider.notifier).addItem(item);
    } else if (item.album != null) {
      ref.read(recentAlbumsProvider.notifier).addItem(item);
    } else if (item.artist != null) {
      ref.read(recentArtistsProvider.notifier).addItem(item);
    } else if (item.playlist != null) {
      ref.read(recentPlaylistsProvider.notifier).addItem(item);
    }
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
        titleSpacing: 8.0,
        title: Center(
          child: SearchBar(
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Wrap(
                // Use Wrap for chips
                children: [
                  _buildChip('All', SearchFilter.all),
                  _buildChip('Tracks', SearchFilter.tracks),
                  _buildChip('Albums', SearchFilter.albums),
                  _buildChip('Artists', SearchFilter.artists),
                  _buildChip('Playlists', SearchFilter.playlists),
                ],
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
      ],
    );
  }
}
