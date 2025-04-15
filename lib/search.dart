import 'package:flutter/services.dart' show SystemNavigator;
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart';
import 'package:kalinka/browse_item_list.dart' show BrowseItemList;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
import 'package:kalinka/search_results_provider.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/kalinkaplayer_proxy.dart';

import 'data_model.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
          if (didPop) {
            return;
          }
          if (navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop();
          } else {
            SystemNavigator.pop();
          }
        },
        child: Navigator(
            key: navigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) {
                  return _buildProviders();
                })));
  }

  Widget _buildProviders() {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<TextEditingController>(
              create: (_) => TextEditingController()),
          ChangeNotifierProvider<SearchTypeProvider>(
              create: (_) => SearchTypeProvider()),
          ChangeNotifierProvider<SavedSearchProvider>(
            create: (_) => SavedSearchProvider(),
          )
        ],
        child: ChangeNotifierProxyProvider2<TextEditingController,
                SearchTypeProvider, BrowseItemDataProvider>(
            create: (_) => BrowseItemDataProvider.fromDataSource(
                dataSource: BrowseItemDataSource.empty()),
            update: (_, textController, searchTypeProvider, __) {
              if (textController.text.isEmpty) {
                return BrowseItemDataProvider.fromDataSource(
                    dataSource: BrowseItemDataSource.empty());
              }
              return BrowseItemDataProvider.fromDataSource(
                  dataSource: BrowseItemDataSource.search(
                      searchTypeProvider.searchType, textController.text));
            },
            builder: (context, _) => _buildSearchPage(context)));
  }

  Widget _buildSearchPage(BuildContext context) {
    final textFieldController = context.watch<TextEditingController>();
    final searchTypeProvider = context.watch<SearchTypeProvider>();
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Padding(
          padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 8.0,
              top: MediaQuery.of(context).padding.top + 8.0),
          child: TextField(
            clipBehavior: Clip.antiAlias,
            controller: textFieldController,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              labelText: 'Search for albums, artists, tracks, playlists',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: textFieldController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        textFieldController.clear();
                      })
                  : null,
            ),
          ),
        ),
      ),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: textFieldController.text.isNotEmpty
                ? _buildChipGroup(searchTypeProvider)
                : const SizedBox.shrink()),
        Expanded(
          child: textFieldController.text.isEmpty
              ? _buildSearchHistory(context)
              : _buildSearchResults(context),
        ),
      ]),
    );
  }

  Widget _buildChipGroup(SearchTypeProvider provider) {
    final List<String> searchTypesStr = [
      'Albums',
      'Artists',
      'Tracks',
      'Playlists'
    ];
    final List<SearchType> searchTypes = [
      SearchType.album,
      SearchType.artist,
      SearchType.track,
      SearchType.playlist
    ];
    return Row(
      children: [
        const Divider(height: 1),
        Expanded(
          child: SegmentedButton<SearchType>(
            segments: List.generate(searchTypes.length, (index) {
              return ButtonSegment<SearchType>(
                value: searchTypes[index],
                label: Text(searchTypesStr[index]),
              );
            }),
            selected: {provider.searchType},
            showSelectedIcon: false,
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                provider.updateSearchType(selected.first);
              }
            },
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide.none),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: MaterialStateProperty.all(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.watch<BrowseItemDataProvider>();
    final savedSearchProvider = context.read<SavedSearchProvider>();
    return BrowseItemList(
        provider: provider,
        onTap: (context, index, item) {
          savedSearchProvider.addSearch(item);
          if (item.canBrowse) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return BrowseItemView(browseItem: item);
              }),
            );
          } else if (item.canAdd) {
            _playTrack(context, item.id);
          }
        },
        onAction: (_, __, BrowseItem item) {
          final parentContext = navigatorKey.currentState?.context ?? context;
          showModalBottomSheet(
              context: context,
              showDragHandle: true,
              isScrollControlled: false,
              useRootNavigator: true,
              scrollControlDisabledMaxHeightRatio: 0.7,
              builder: (context) {
                return BottomMenu(
                    parentContext: parentContext, browseItem: item);
              });
        },
        pageSize: 0,
        shrinkWrap: false);
  }

  Widget _buildSearchHistory(BuildContext context) {
    final provider = context.watch<SavedSearchProvider>();
    return Column(children: [
      provider.totalItemCount > 0
          ? _buildSearchHistoryHeader(provider)
          : const SizedBox.shrink(),
      Expanded(
          child: BrowseItemList(
        provider: provider,
        onTap: (__, index, item) {
          if (item.canBrowse) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                return BrowseItemView(browseItem: item);
              }),
            );
          } else if (item.canAdd) {
            _playTrack(context, item.id);
          }

          provider.moveToTop(index);
        },
        onAction: (_, index, item) {
          provider.removeSearchAt(index);
        },
        actionButtonIcon: const Icon(Icons.delete),
        actionButtonTooltip: 'Delete',
        pageSize: 0,
        shrinkWrap: false,
      ))
    ]);
  }

  Widget _buildSearchHistoryHeader(SavedSearchProvider provider) {
    return Row(children: [
      const Padding(
          padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
          child: Text('Previous searches',
              style: TextStyle(fontWeight: FontWeight.bold))),
      const Spacer(),
      Padding(
          padding: const EdgeInsets.only(right: 15, top: 4, bottom: 4),
          child: ElevatedButton(
              child: Text(
                'Delete All',
              ),
              onPressed: () {
                provider.clearHistory();
              })),
    ]);
  }

  void _playTrack(BuildContext context, String trackId) async {
    PlayerState state = context.read<PlayerStateProvider>().state;

    bool needToAdd = true;
    if (state.currentTrack?.id == trackId) {
      needToAdd = false;
    }

    if (!needToAdd) {
      KalinkaPlayerProxy().play(state.index);
    } else {
      await KalinkaPlayerProxy().clear();
      await KalinkaPlayerProxy().addTracks([trackId]);
      await KalinkaPlayerProxy().play();
    }
  }
}
