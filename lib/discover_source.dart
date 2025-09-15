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

class DiscoverSource extends ConsumerWidget {
  final BrowseItemsSourceDesc sourceDesc;

  const DiscoverSource({super.key, required this.sourceDesc});

  static final emptyPlaceholder = BrowseItem.empty.copyWith(
      catalog: Catalog.empty
          .copyWith(previewConfig: Preview(type: PreviewType.imageText)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(browseItemsProvider(sourceDesc));
    final notifier = ref.read(browseItemsProvider(sourceDesc).notifier);

    return asyncValue.when(
      data: (state) => SingleChildScrollView(
        // Use AlwaysScrollableScrollPhysics to ensure scrolling works even when content is small
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
                // Use NeverScrollableScrollPhysics for inner ListView to prevent scroll conflicts
                physics: const NeverScrollableScrollPhysics(),
                hitTestBehavior: HitTestBehavior.deferToChild,
                shrinkWrap: true,
                itemCount: state.totalCount,
                itemBuilder: (context, index) {
                  final item = state.getItem(index);

                  if (item == null) {
                    Future.microtask(() => notifier.ensureIndexLoaded(index));
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
      loading: () => SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(children: [
            PreviewSectionPlaceholder(browseItem: emptyPlaceholder),
            PreviewSectionPlaceholder(browseItem: emptyPlaceholder),
            PreviewSectionPlaceholder(browseItem: emptyPlaceholder)
          ])),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
