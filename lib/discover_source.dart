import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kalinka/data_model.dart';

import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart'
    show
        BrowseItemsSourceDesc,
        DefaultBrowseItemsSourceDesc,
        browseItemsProvider;
import 'package:kalinka/constants.dart';
import 'package:kalinka/preview_section.dart'
    show PreviewSection, PreviewSectionPlaceholder;
import 'package:kalinka/genre_filter_chips.dart';
import 'package:kalinka/custom_cache_manager.dart';

class DiscoverSource extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;

  const DiscoverSource({super.key, required this.sourceDesc});

  static final emptyPlaceholder = BrowseItem.empty.copyWith(
      catalog: Catalog.empty
          .copyWith(previewConfig: Preview(type: PreviewType.imageText)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseItem = sourceDesc.sourceItem;
    return Scaffold(
      appBar: AppBar(
        title: Text('Discover: ${browseItem.name ?? 'Unknown'}'),
      ),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final asyncValue = ref.watch(browseItemsProvider(sourceDesc));
    final notifier = ref.read(browseItemsProvider(sourceDesc).notifier);

    return asyncValue.when(
        data: (state) => RefreshIndicator(
              onRefresh: () async {
                // Clear image cache
                await KalinkaMusicCacheManager.instance.emptyCache();

                // Refresh the main provider
                ref.invalidate(browseItemsProvider);
              },
              // Color the background with the primary color
              backgroundColor: theme.colorScheme.primary,
              // Make the arrow/indicator use a contrasting color
              color: theme.colorScheme.onPrimary,
              // Ensure the indicator displays properly above content
              displacement: 20.0,
              // Place the indicator above the content
              edgeOffset: 0.0,
              strokeWidth: 3.0,
              child: SingleChildScrollView(
                // Use AlwaysScrollableScrollPhysics to ensure scrolling works even when content is small
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add GenreFilterChips at the top
                    const GenreFilterChips(),
                    ListView.builder(
                        // Use NeverScrollableScrollPhysics for inner ListView to prevent scroll conflicts
                        physics: const NeverScrollableScrollPhysics(),
                        hitTestBehavior: HitTestBehavior.deferToChild,
                        shrinkWrap: true,
                        itemCount: state.totalCount,
                        itemBuilder: (context, index) {
                          final item = state.getItem(index);

                          if (item == null) {
                            Future.microtask(
                                () => notifier.ensureIndexLoaded(index));
                            return PreviewSectionPlaceholder(
                                browseItem: sourceDesc.sourceItem);
                          }
                          return PreviewSection(
                              sourceDesc: DefaultBrowseItemsSourceDesc(item));
                        }),
                    const SizedBox(
                      height: KalinkaConstants.kContentVerticalPadding * 2,
                    ),
                  ],
                ),
              ),
            ),
        loading: () => Column(children: [
              PreviewSectionPlaceholder(browseItem: emptyPlaceholder),
              PreviewSectionPlaceholder(browseItem: emptyPlaceholder),
              PreviewSectionPlaceholder(browseItem: emptyPlaceholder)
            ]),
        error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error: $error'),
              ),
            ));
  }
}
