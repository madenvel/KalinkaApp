import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerStatefulWidget, ConsumerState;

import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart';

import 'package:kalinka/constants.dart';
import 'package:kalinka/discover_source.dart';
import 'package:kalinka/source_attribution.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/providers/genre_filter_provider.dart';
import 'package:kalinka/genre_selector.dart';

import 'data_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  static const BrowseItem browseItem =
      BrowseItem(id: '', canBrowse: true, canAdd: false);

  static const BrowseItemsSourceDesc sourceDesc =
      DefaultBrowseItemsSourceDesc(browseItem);

  bool _hasActiveFilters() {
    final genreState = ref.watch(genreFilterProvider).valueOrNull;
    return genreState?.selectedGenres.isNotEmpty ?? false;
  }

  void _showFilterBottomSheet(BrowseItem currentSource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Filter ${currentSource.name ?? 'Source'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GenreSelector(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(browseItemsProvider(sourceDesc));
    final ThemeData theme = Theme.of(context);

    return asyncState.when(
      data: (state) {
        final sources = <BrowseItem>[];
        for (int i = 0; i < state.totalCount; i++) {
          final item = state.getItem(i);
          if (item != null) {
            sources.add(item);
          } else {
            // If any item is null, ensure it's loaded
            final notifier = ref.read(browseItemsProvider(sourceDesc).notifier);
            Future.microtask(() => notifier.ensureIndexLoaded(i));
          }
        }

        return Scaffold(
          appBar: sources.isNotEmpty
              ? AppBar(
                  toolbarHeight: 60,
                  title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int index = 0; index < sources.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              selected: _selectedIndex == index,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                }
                              },
                              showCheckmark: false,
                              avatar: Stack(
                                children: [
                                  SourceAttribution(
                                    id: sources[index].id,
                                    size: 24,
                                  ),
                                  if (_hasActiveFilters())
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              label: Text(sources[index].name ?? 'Unknown'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Badge(
                        isLabelVisible: _hasActiveFilters(),
                        child: const Icon(Icons.tune),
                      ),
                      onPressed: sources.isNotEmpty
                          ? () =>
                              _showFilterBottomSheet(sources[_selectedIndex])
                          : null,
                      tooltip:
                          'Filter ${sources.isNotEmpty ? sources[_selectedIndex].name : 'Source'}',
                    ),
                  ],
                )
              : AppBar(title: const Text('Discover')),
          body: sources.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                        KalinkaConstants.kContentVerticalPadding),
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                              text:
                                  'No input sources available. Please enable modules in the '),
                          TextSpan(
                            text: 'settings',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                DefaultTabController.of(context).animateTo(3);
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                )
              : IndexedStack(
                  index: _selectedIndex,
                  children: [
                    for (final item in sources)
                      RefreshIndicator(
                        onRefresh: () async {
                          await KalinkaMusicCacheManager.instance.emptyCache();
                          ref.invalidate(browseItemsProvider);
                        },
                        backgroundColor: theme.colorScheme.primary,
                        color: theme.colorScheme.onPrimary,
                        displacement: 20.0,
                        edgeOffset: 0.0,
                        strokeWidth: 3.0,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: DiscoverSource(
                            sourceDesc: DefaultBrowseItemsSourceDesc(item),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Discover')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text('Discover')),
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
