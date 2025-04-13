import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalinka/artist_browse_view.dart' show ArtistBrowseView;
import 'package:kalinka/browse_item_view.dart' show BrowseItemView;
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

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  _LibraryState();

  final TextEditingController _textEditingController = TextEditingController();
  static final List<SearchType> searchTypes = [
    SearchType.track,
    SearchType.album,
    SearchType.artist,
    SearchType.playlist,
  ];
  static final List<String> searchTypesStr = [
    'Albums',
    'Artists',
    'Tracks',
    'Playlists'
  ];

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
                  return Scaffold(
                      appBar: AppBar(
                        title: const Row(children: [
                          Icon(Icons.library_music),
                          SizedBox(width: 8),
                          Text('My Library')
                        ]),
                      ),
                      body: ChangeNotifierProvider<SearchTypeProvider>(
                          create: (_) => SearchTypeProvider(),
                          builder: (context, _) => _buildBody(context)));
                })));
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _textEditingController,
            onChanged: (text) {
              setState(() {});
            },
            decoration: InputDecoration(
              labelText: 'Type text to filter the list below',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              suffixIcon: _textEditingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _textEditingController.clear();
                        });
                      })
                  : null,
            ),
          ),
        ),
        _buildChipList(context),
        const SizedBox(height: 8.0),
        Expanded(child: _buildItemList(context)),
      ],
    );
  }

  Widget _buildChipList(BuildContext context) {
    final provider = context.watch<SearchTypeProvider>();
    final searchType = provider.searchType;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SegmentedButton<SearchType>(
          segments: List.generate(
            searchTypes.length,
            (index) => ButtonSegment(
              value: searchTypes[index],
              label: Text(searchTypesStr[index]),
            ),
          ),
          selected: {searchType},
          onSelectionChanged: (Set<SearchType> newSelection) {
            if (newSelection.isNotEmpty) {
              provider.updateSearchType(newSelection.first);
            }
          },
        ),
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return ChangeNotifierProxyProvider<SearchTypeProvider,
            BrowseItemDataProvider>(
        create: (context) => BrowseItemDataProvider.fromDataSource(
              dataSource: BrowseItemDataSource.favorites(
                  context.read<SearchTypeProvider>().searchType),
              itemsPerRequest: 30,
            ),
        update: (context, searchTypeProvider, dataProvider) {
          return BrowseItemDataProvider.fromDataSource(
            dataSource:
                BrowseItemDataSource.favorites(searchTypeProvider.searchType),
            itemsPerRequest: 30,
          );
        },
        builder: (context, _) => BrowseItemList(
              provider: context.watch<BrowseItemDataProvider>(),
              shrinkWrap: false,
              actionButtonIcon: const Icon(Icons.more_vert),
              actionButtonTooltip: "More options",
              onTap: (context, index, item) {
                if (item.canBrowse) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      if (item.browseType == 'artist') {
                        return ArtistBrowseView(browseItem: item);
                      }
                      return BrowseItemView(browseItem: item);
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
                      return BottomMenu(
                          parentContext: parentContext, browseItem: item);
                    });
              },
              pageSize: 0,
            ));
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
