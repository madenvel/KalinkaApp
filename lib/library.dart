import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show
        AsyncValueX,
        ConsumerState,
        ConsumerStatefulWidget,
        Notifier,
        NotifierProvider;
import 'package:kalinka/providers/app_state_provider.dart'
    show playerStateProvider;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart';
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/constants.dart';
import 'package:kalinka/providers/kalinka_player_api_provider.dart';
import 'package:kalinka/playlist_creation_dialog.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/browse_item_list.dart';

import 'package:kalinka/data_model.dart';
import 'package:kalinka/shimmer.dart' show Shimmer;

class SearchTypeProvider extends Notifier<SearchType> {
  void updateSearchType(SearchType searchType) {
    if (state != searchType) {
      state = searchType;
    }
  }

  @override
  SearchType build() {
    return SearchType.album;
  }
}

class SearchControllerProvider extends Notifier<SearchController> {
  @override
  SearchController build() {
    final controller = SearchController();
    ref.onDispose(() {
      controller.dispose();
    });
    return controller;
  }
}

final searchControllerProvider =
    NotifierProvider<SearchControllerProvider, SearchController>(
  SearchControllerProvider.new,
);

final searchTypeProvider = NotifierProvider<SearchTypeProvider, SearchType>(
  SearchTypeProvider.new,
);

class Library extends ConsumerStatefulWidget {
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
  ConsumerState<Library> createState() => _LibraryState();
}

class _LibraryState extends ConsumerState<Library> {
  bool searchBarVisible = false;
  String previousSearchText = '';
  SearchType previousSearchType = SearchType.invalid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    if (searchBarVisible) {
      return SearchBar(
        autoFocus: true,
        constraints: BoxConstraints(minHeight: 40),
        controller: ref.watch(searchControllerProvider),
        elevation: WidgetStateProperty.all(0.0),
        hintText: 'Search...',
        leading: const Icon(Icons.search),
        onSubmitted: (text) {
          setState(() {
            previousSearchText = text;
          });
        },
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
                final textEdit = ref.read(searchControllerProvider).text;
                final searchType = ref.read(searchTypeProvider);
                if (textEdit.isEmpty && searchType == SearchType.playlist) {
                  return;
                }
                ref.read(searchControllerProvider).clear();
                ref
                    .read(searchTypeProvider.notifier)
                    .updateSearchType(SearchType.playlist);
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
    final searchType = ref.watch(searchTypeProvider);
    final notifier = ref.read(searchTypeProvider.notifier);
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
                      notifier.updateSearchType(Library.searchTypes[index]);
                    }),
              );
            })),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    final sourceDesc = UserFavoriteBrowseItemsDesc(
        ref.watch(searchTypeProvider),
        ref.watch(searchControllerProvider).text);

    final asyncValue = ref.watch(browseItemsProvider(sourceDesc));
    final state = asyncValue.valueOrNull;

    if (state == null || asyncValue.isLoading) {
      return Shimmer(
          child: BrowseItemListPlaceholder(browseItem: sourceDesc.sourceItem));
    }

    if (state.totalCount == 0) {
      final searchController = ref.read(searchControllerProvider);
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
                          ref.read(searchControllerProvider).clear();
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
      sourceDesc: sourceDesc,
      shrinkWrap: false,
      actionButtonTooltip: "More options",
      onTap: (context, index, item) {
        if (item.canBrowse) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return BrowseItemView(
                browseItem: item,
              );
            }),
          );
        } else if (item.canAdd) {
          _playTrack(context, item.id, index);
        }
      },
      onAction: (context, index, item) {
        final parentContext = context;
        showModalBottomSheet(
            context: context,
            showDragHandle: true,
            isScrollControlled: false,
            useRootNavigator: true,
            scrollControlDisabledMaxHeightRatio: 0.7,
            builder: (context) {
              return BottomMenu(parentContext: parentContext, browseItem: item);
            });
      },
      pageSize: 0,
      showSourceAttribution: true,
    );
  }

  void _playTrack(BuildContext context, String trackId, int index) async {
    final kalinkaApi = ref.read(kalinkaProxyProvider);
    final state = ref.read(playerStateProvider);

    bool needToAdd = true;
    if (state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      kalinkaApi.play(index);
    } else {
      await kalinkaApi.clear();
      await kalinkaApi.add([trackId]);
      await kalinkaApi.play();
    }
  }

  _buildCancelSearchButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cancel),
      onPressed: () {
        setState(() {
          searchBarVisible = false;
          ref.read(searchControllerProvider).clear();
        });
      },
    );
  }
}
