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
import 'package:kalinka/constants.dart';
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

  Widget _buildSearchResultTrackList(String title) {
    // Adding a key that changes when search text changes to ensure provider recreation
    final searchKey = Key('tracks-${_searchController.text}');

    return provider.ChangeNotifierProvider<BrowseItemDataProvider>(
        key: searchKey,
        create: (context) => BrowseItemDataProvider.fromDataSource(
            dataSource: BrowseItemDataSource.search(
                SearchType.track, _searchController.text)),
        builder: (context, _) =>
            _buildTrackList(context, title, totalSize: 5, onSeeMore: () {
              _setFilter(SearchFilter.tracks);
            }, onTap: _updateSearchHistoryAndRecentItems));
  }

  Widget _buildTrackList(BuildContext context, String title,
      {int? totalSize, VoidCallback? onSeeMore, Function(BrowseItem)? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: KalinkaConstants.kScreenContentHorizontalPadding,
              right: KalinkaConstants.kScreenContentHorizontalPadding,
              bottom: KalinkaConstants.kContentVerticalPadding),
          child: Row(
            children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (onSeeMore != null)
                TextButton(
                    style: TextButton.styleFrom(
                        padding: KalinkaConstants.kElevatedButtonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )),
                    onPressed: onSeeMore,
                    child: Text('See More'))
            ],
          ),
        ),
        BrowseItemList(
            pageSize: 5,
            size: totalSize,
            shrinkWrap: true,
            provider: context.watch<BrowseItemDataProvider>(),
            onTap: (context, index, item) {
              onTap?.call(item);
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
      await KalinkaPlayerProxy().add([trackId]);
      await KalinkaPlayerProxy().play();
    }
  }

  Widget _buildSearchResults() {
    final query = _searchController.text;
    return ListView.separated(
        itemCount: SearchType.values.length - 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: KalinkaConstants.kSpaceBetweenSections),
        itemBuilder: (_, index) {
          final searchType = SearchType.values[index + 1];
          if (searchType == SearchType.track) {
            return _buildSearchResultTrackList('Tracks');
          }

          return _buildHorizontalList(
              BrowseItemDataSource.search(searchType, query),
              onSeeMore: () => _setFilter(SearchFilter.values[index + 1]),
              onItemSelected: _updateSearchHistoryAndRecentItems);
        });
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

  const _LandingPageContent({
    required this.onSearchSelected,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchHistory = ref.watch(searchHistoryProvider);

    if (searchHistory.isEmpty && _hasNoRecentItems(ref)) {
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
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: KalinkaConstants.kContentVerticalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal:
                          KalinkaConstants.kScreenContentHorizontalPadding),
                  child: Text('Recent Searches',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal:
                            KalinkaConstants.kScreenContentHorizontalPadding,
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
          ),
        ],
        ..._buildRecentItemsSections()
            .expand((item) => [item, const SizedBox(height: 24)])
            .toList()
          ..removeLast(),
      ],
    );
  }

  bool _hasNoRecentItems(WidgetRef ref) {
    return ref.watch(recentTracksProvider).isEmpty &&
        ref.watch(recentAlbumsProvider).isEmpty &&
        ref.watch(recentArtistsProvider).isEmpty &&
        ref.watch(recentPlaylistsProvider).isEmpty;
  }

  List<Widget> _buildRecentItemsSections() {
    List<Widget> sections = [];

    // Each section is its own consumer widget to minimize rebuilds
    sections.add(_RecentTracksSection(onItemSelected: onItemSelected));
    sections.add(_RecentAlbumsSection(onItemSelected: onItemSelected));
    sections.add(_RecentArtistsSection(onItemSelected: onItemSelected));
    sections.add(_RecentPlaylistsSection(onItemSelected: onItemSelected));

    return sections;
  }
}

// Individual recent items sections to prevent unnecessary rebuilds
class _RecentTracksSection extends ConsumerWidget {
  final Function(BrowseItem) onItemSelected;

  const _RecentTracksSection({required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTracks = ref.watch(recentTracksProvider);
    if (recentTracks.isEmpty) return const SizedBox.shrink();

    final title = 'Recently Viewed ${SearchType.track.name.capitalize}s';
    return provider.ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider.fromDataSource(
            dataSource:
                StaticItemsBrowseItemDataSource.create(title, recentTracks)),
        builder: (context, _) =>
            _TrackListSection(title: title, onTap: onItemSelected));
  }
}

class _RecentAlbumsSection extends ConsumerWidget {
  final Function(BrowseItem) onItemSelected;

  const _RecentAlbumsSection({required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAlbums = ref.watch(recentAlbumsProvider);
    if (recentAlbums.isEmpty) return const SizedBox.shrink();

    final title = 'Recently Viewed ${SearchType.album.name.capitalize}s';
    return PreviewSectionCard(
      key: ValueKey('recent_albums_${recentAlbums.length}'),
      dataSource: StaticItemsBrowseItemDataSource.create(title, recentAlbums),
      seeAll: false,
      onItemSelected: onItemSelected,
    );
  }
}

class _RecentArtistsSection extends ConsumerWidget {
  final Function(BrowseItem) onItemSelected;

  const _RecentArtistsSection({required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentArtists = ref.watch(recentArtistsProvider);
    if (recentArtists.isEmpty) return const SizedBox.shrink();

    final title = 'Recently Viewed ${SearchType.artist.name.capitalize}s';
    return PreviewSectionCard(
      key: ValueKey('recent_artists_${recentArtists.length}'),
      dataSource: StaticItemsBrowseItemDataSource.create(title, recentArtists),
      seeAll: false,
      onItemSelected: onItemSelected,
    );
  }
}

class _RecentPlaylistsSection extends ConsumerWidget {
  final Function(BrowseItem) onItemSelected;

  const _RecentPlaylistsSection({required this.onItemSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentPlaylists = ref.watch(recentPlaylistsProvider);
    if (recentPlaylists.isEmpty) return const SizedBox.shrink();

    final title = 'Recently Viewed ${SearchType.playlist.name.capitalize}s';
    return PreviewSectionCard(
      key: ValueKey('recent_playlists_${recentPlaylists.length}'),
      dataSource:
          StaticItemsBrowseItemDataSource.create(title, recentPlaylists),
      seeAll: false,
      onItemSelected: onItemSelected,
    );
  }
}

class _TrackListSection extends StatelessWidget {
  final String title;
  final Function(BrowseItem) onTap;

  const _TrackListSection({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: KalinkaConstants.kScreenContentHorizontalPadding,
              right: KalinkaConstants.kScreenContentHorizontalPadding,
              bottom: KalinkaConstants.kContentVerticalPadding),
          child: Row(
            children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
            ],
          ),
        ),
        BrowseItemList(
            pageSize: 5,
            size: 5,
            shrinkWrap: true,
            provider: context.watch<BrowseItemDataProvider>(),
            onTap: (context, index, item) {
              onTap(item);
              _playTrack(context, item.track!.id, index);
            },
            onAction: (context, index, item) {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: false,
                useRootNavigator: true,
                scrollControlDisabledMaxHeightRatio: 0.7,
                builder: (_) => BottomMenu(
                  parentContext: context,
                  browseItem: item,
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
      await KalinkaPlayerProxy().add([trackId]);
      await KalinkaPlayerProxy().play();
    }
  }
}
