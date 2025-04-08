import 'package:flutter/services.dart';
import 'package:kalinka/artist_browse_view.dart' show ArtistBrowseView;
import 'package:kalinka/tracks_browse_view.dart' show TracksBrowseView;
import 'package:kalinka/search_results_provider.dart';
import 'package:provider/provider.dart';
import 'package:kalinka/bottom_menu.dart';
import 'package:kalinka/custom_list_tile.dart';
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
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (_) => _buildProviders());
            }));
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
                SearchTypeProvider, SearchResultsProvider>(
            create: (_) => SearchResultsProvider(),
            update:
                (_, textController, searchTypeProvider, searchResultsProvider) {
              if (searchResultsProvider == null) {
                return SearchResultsProvider();
              }
              return searchResultsProvider
                ..updateSearchQuery(
                    textController.text, searchTypeProvider.searchType);
            },
            builder: (context, _) => _buildSearchPage(context)));
  }

  Widget _buildSearchPage(BuildContext context) {
    final textFieldController = context.watch<TextEditingController>();
    final searchTypeProvider = context.watch<SearchTypeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(
            title: const Row(children: [
          Icon(Icons.search_outlined),
          SizedBox(width: 8),
          Text('Search')
        ])),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: textFieldController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Search for albums, artists, tracks, playlists',
                suffixIcon: textFieldController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          textFieldController.clear();
                        })
                    : null,
              ),
            )),
        textFieldController.text.isNotEmpty
            ? _buildChipGroup(searchTypeProvider)
            : const SizedBox.shrink(),
        const SizedBox(height: 8),
        Expanded(
          child: textFieldController.text.isEmpty
              ? _buildSearchHistory(context)
              : _buildSearchResults(context),
        ),
      ],
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
    return SizedBox(
        height: 36,
        child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            children: List<Widget>.generate(4, (index) {
              return Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: FilterChip(
                    label: Text(searchTypesStr[index]),
                    selected: provider.searchType == searchTypes[index],
                    onSelected: (isSelected) {
                      if (isSelected) {
                        provider.updateSearchType(searchTypes[index]);
                      }
                    },
                  ));
            })));
  }

  Widget _buildSearchResults(BuildContext context) {
    final provider = context.watch<SearchResultsProvider>();
    final savedSearchProvider = context.read<SavedSearchProvider>();
    return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: provider.maybeCount,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          BrowseItem? item = provider.getItem(index);
          if (item == null) {
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              title: Container(
                height: 16,
                width: 100,
                color: Colors.grey,
                margin: const EdgeInsets.only(bottom: 4),
              ),
              subtitle: Container(
                height: 14,
                width: 60,
                color: Colors.grey,
              ),
            );
          }
          return CustomListTile(
              browseItem: item,
              onTap: () {
                savedSearchProvider.addSearch(item);
                if (item.canBrowse) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      if (item.browseType == 'artist') {
                        return ArtistBrowseView(browseItem: item);
                      }
                      return TracksBrowseView(browseItem: item);
                    }),
                  );
                } else if (item.canAdd) {
                  _playTrack(context, item.id);
                }
              },
              trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    final parentContext = context;
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
                  }));
        });
  }

  Widget _buildSearchHistory(BuildContext context) {
    final savedSearchProvider = context.watch<SavedSearchProvider>();

    return FutureBuilder(
        future: savedSearchProvider.ready,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _buildSearchHistoryContent(savedSearchProvider);
          }
          return const SizedBox.shrink();
        });
  }

  Widget _buildSearchHistoryContent(SavedSearchProvider provider) {
    return Column(children: [
      provider.savedSearches.isNotEmpty
          ? _buildSearchHistoryHeader(provider)
          : const SizedBox.shrink(),
      Expanded(
          child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: provider.savedSearches.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final browseItem = provider.savedSearches[index];
          return CustomListTile(
              browseItem: browseItem,
              trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    provider.removeSearchAt(index);
                  }),
              onTap: () {
                if (browseItem.canBrowse) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      if (browseItem.browseType == 'artist') {
                        return ArtistBrowseView(browseItem: browseItem);
                      }
                      return TracksBrowseView(browseItem: browseItem);
                    }),
                  );
                } else if (browseItem.canAdd) {
                  _playTrack(context, browseItem.id);
                }
                provider.moveToTop(index);
              });
        },
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
              child:
                  const Text('Delete All', style: TextStyle(color: Colors.red)),
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
