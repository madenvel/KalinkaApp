import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/playlist_creation_dialog.dart';
import 'package:kalinka/search_results_provider.dart' show SearchTypeProvider;
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/data_provider.dart';
import 'package:kalinka/browse_item_data_provider.dart';
import 'package:kalinka/browse_item_data_source.dart';
import 'package:kalinka/browse_item_list.dart';

import 'data_model.dart';
import 'kalinkaplayer_proxy.dart';

class Library extends StatefulWidget {
  const Library({super.key});

  static final List<SearchType> searchTypes = [
    SearchType.track,
    SearchType.album,
    SearchType.artist,
    SearchType.playlist,
  ];
  static final List<String> searchTypesStr = [
    'Tracks',
    'Albums',
    'Artists',
    'Playlists'
  ];

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  bool searchBarVisible = false;
  String previousSearchText = '';
  SearchType previousSearchType = SearchType.invalid;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SearchController()),
          ChangeNotifierProvider<SearchTypeProvider>(
              create: (_) => SearchTypeProvider())
        ],
        builder: (context, _) {
          return ChangeNotifierProxyProvider2<SearchTypeProvider,
                  SearchController, BrowseItemDataProvider>(
              create: (context) => BrowseItemDataProvider.fromDataSource(
                  dataSource: BrowseItemDataSource.empty()),
              update: (context, searchTypeProvider, searchController,
                  dataProvider) {
                if (dataProvider == null ||
                    searchController.text != previousSearchText ||
                    previousSearchType != searchTypeProvider.searchType) {
                  previousSearchText = searchController.text;
                  previousSearchType = searchTypeProvider.searchType;
                  return BrowseItemDataProvider.fromDataSource(
                      dataSource: BrowseItemDataSource.favorites(
                          searchTypeProvider.searchType, searchController.text),
                      itemsPerRequest: 100);
                }
                return dataProvider;
              },
              builder: (context, _) => Scaffold(
                    appBar: AppBar(
                      titleSpacing: KalinkaConstants.kContentHorizontalPadding,
                      title: _buildAppBarTitle(context),
                      actions: !searchBarVisible
                          ? [
                              _buildSearchButton(context),
                              _buildActionButton(context),
                            ]
                          : [_buildCancelSearchButton(context)],
                    ),
                    body: _buildBody(context),
                  ));
        });
  }

  Widget _buildAppBarTitle(BuildContext context) {
    if (searchBarVisible) {
      final controller = context.watch<SearchController>();
      return SearchBar(
        autoFocus: true,
        constraints: BoxConstraints(minHeight: 40),
        controller: controller,
        elevation: WidgetStateProperty.all(0.0),
        hintText: 'Search...',
        leading: const Icon(Icons.search),
      );
    }
    return const Row(children: [
      Icon(Icons.library_music),
      SizedBox(width: 8),
      Text('My Library')
    ]);
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Search',
        onPressed: () {
          setState(() {
            searchBarVisible = !searchBarVisible;
          });
        });
  }

  Widget _buildActionButton(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.playlist_add),
        tooltip: 'Create New Playlist',
        onPressed: () {
          PlaylistCreationDialog.show(
              context: context,
              onCreateCallback: (playlistId) {
                final textEdit = context.read<SearchController>();
                final searchTypeProvider = context.read<SearchTypeProvider>();
                if (textEdit.text.isEmpty &&
                    searchTypeProvider.searchType == SearchType.playlist) {
                  context.read<BrowseItemDataProvider>().refresh();
                  return;
                }
                textEdit.clear();
                searchTypeProvider.updateSearchType(SearchType.playlist);
              });
        });
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildChipList(context),
        const SizedBox(height: 8),
        Expanded(child: _buildItemList(context)),
      ],
    );
  }

  Widget _buildChipList(BuildContext context) {
    final provider = context.watch<SearchTypeProvider>();
    final searchType = provider.searchType;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
            horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
            vertical: KalinkaConstants.kContentVerticalPadding),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(Library.searchTypes.length, (index) {
              final isSelected = Library.searchTypes[index] == searchType;
              return Padding(
                padding: KalinkaConstants.kFilterChipPadding,
                child: FilterChip(
                    label: Text(Library.searchTypesStr[index]),
                    selected: isSelected,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    showCheckmark: false,
                    onSelected: (_) {
                      provider.updateSearchType(Library.searchTypes[index]);
                    }),
              );
            })),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    final provider = context.watch<BrowseItemDataProvider>();
    if (provider.maybeItemCount == 0) {
      final searchController = context.read<SearchController>();
      return Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.search, size: 96),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: KalinkaConstants.kContentVerticalPadding),
                  child: const Text('No items found',
                      style: TextStyle(fontSize: 18)),
                ),
                if (searchBarVisible && searchController.text.isNotEmpty)
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          context.read<SearchController>().clear();
                          searchBarVisible = false;
                        });
                      },
                      child: const Text('Clear filter'))
              ],
            ),
            const SizedBox(width: 96),
          ]),
          const Spacer()
        ],
      );
    }
    return BrowseItemList(
      provider: provider,
      shrinkWrap: false,
      actionButtonTooltip: "More options",
      onTap: (context, index, item) {
        if (item.canBrowse) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return BrowseItemView(browseItem: item);
            }),
          );
        } else if (item.canAdd) {
          _playTrack(context, item.id, index);
        }
      },
      onAction: (context, index, item) {
        final parentContext = context;
        // A bit of a hack to reload favorites in case of any changes.
        // Doesn't always work so needs to be revisited.
        final favoriteIdsProvider = context.read<UserFavoritesIdsProvider>();
        final searchTypeProvider = context.read<SearchTypeProvider>();
        final initialCount = favoriteIdsProvider.countByType;
        showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: false,
            useRootNavigator: true,
            scrollControlDisabledMaxHeightRatio: 0.7,
            builder: (context) {
              return BottomMenu(parentContext: parentContext, browseItem: item);
            }).then((_) {
          final newCount = favoriteIdsProvider.countByType;
          final type = searchTypeProvider.searchType;
          if (context.mounted && initialCount[type] != newCount[type]) {
            context.read<BrowseItemDataProvider>().refresh();
          }
        });
      },
      pageSize: 0,
      showSourceAttribution: true,
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

  _buildCancelSearchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cancel),
      onPressed: () {
        setState(() {
          searchBarVisible = false;
          context.read<SearchController>().clear();
        });
      },
    );
  }
}
