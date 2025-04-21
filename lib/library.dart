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

class Library extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TextEditingController()),
          ChangeNotifierProvider<SearchTypeProvider>(
              create: (_) => SearchTypeProvider())
        ],
        builder: (context, _) {
          return ChangeNotifierProxyProvider2<SearchTypeProvider,
                  TextEditingController, BrowseItemDataProvider>(
              create: (context) => BrowseItemDataProvider.fromDataSource(
                  dataSource: BrowseItemDataSource.empty()),
              update: (context, searchTypeProvider, textEditingController,
                  dataProvider) {
                return BrowseItemDataProvider.fromDataSource(
                    dataSource: BrowseItemDataSource.favorites(
                        searchTypeProvider.searchType,
                        textEditingController.text),
                    itemsPerRequest: 100);
              },
              builder: (context, _) => Scaffold(
                    appBar: AppBar(
                      title: const Row(children: [
                        Icon(Icons.library_music),
                        SizedBox(width: 8),
                        Text('My Library')
                      ]),
                      actions: [
                        _buildActionButton(context),
                      ],
                    ),
                    body: _buildBody(context),
                  ));
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
                final textEdit = context.read<TextEditingController>();
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

  Widget _buildFilterTextField(BuildContext context) {
    final controller = context.watch<TextEditingController>();
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: KalinkaConstants.kScreenContentHorizontalPadding,
          vertical: KalinkaConstants.kContentVerticalPadding),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Type text to filter the list below',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                  })
              : null,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildFilterTextField(context),
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
            children: List.generate(searchTypes.length, (index) {
              final isSelected = searchTypes[index] == searchType;
              return Padding(
                padding: EdgeInsets.only(
                  right: KalinkaConstants.kContentHorizontalPadding,
                ),
                child: FilterChip(
                    label: Text(searchTypesStr[index]),
                    selected: isSelected,
                    onSelected: (_) {
                      provider.updateSearchType(searchTypes[index]);
                    }),
              );
            })),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return BrowseItemList(
      provider: context.watch<BrowseItemDataProvider>(),
      shrinkWrap: false,
      actionButtonIcon: const Icon(Icons.more_vert),
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
}
