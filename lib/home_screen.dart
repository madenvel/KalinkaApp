import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncValueX, ConsumerWidget, WidgetRef;

import 'package:kalinka/browse_item_data_provider_riverpod.dart';

import 'package:kalinka/constants.dart';
import 'package:kalinka/discover_source.dart';
import 'package:kalinka/source_module_preview_card.dart' show SourceModule;

import 'package:kalinka/settings_screen.dart';
import 'package:kalinka/genre_filter_chips.dart';
import 'package:kalinka/custom_cache_manager.dart';

import 'data_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  final BrowseItem browseItem =
      const BrowseItem(id: '', canBrowse: true, canAdd: false);

  BrowseItemsSourceDesc get sourceDesc =>
      DefaultBrowseItemsSourceDesc(browseItem);

  static const double textLabelHeight = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.explore),
            SizedBox(width: KalinkaConstants.kContentHorizontalPadding),
            Text('Discover')
          ]),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()));
                })
          ]),
      body: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return RefreshIndicator(
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
            _buildSections(context, ref),
            const SizedBox(
              height: KalinkaConstants.kContentVerticalPadding * 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSections(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browseItemsProvider(sourceDesc)).valueOrNull;
    final notifier = ref.read(browseItemsProvider(sourceDesc).notifier);

    if (state == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (state.totalCount == 0) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(KalinkaConstants.kContentVerticalPadding),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.separated(
        // Use NeverScrollableScrollPhysics for inner ListView to prevent scroll conflicts
        physics: const NeverScrollableScrollPhysics(),
        hitTestBehavior: HitTestBehavior.deferToChild,
        shrinkWrap: true,
        separatorBuilder: (context, index) =>
            const SizedBox(height: KalinkaConstants.kContentVerticalPadding),
        itemCount: state.totalCount,
        itemBuilder: (context, index) {
          final item = state.getItem(index);
          if (item == null) {
            Future.microtask(() => notifier.ensureIndexLoaded(index));
            return SizedBox(
                height: 40, child: Center(child: CircularProgressIndicator()));
          }

          return _buildSection(context, item);
        });
  }

  Widget _buildSection(BuildContext context, BrowseItem section) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: KalinkaConstants.kScreenContentHorizontalPadding),
      child: SourceModule(
          source: section,
          onShowMoreClicked: () {
            // Handle show more action
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiscoverSource(
                  sourceDesc: DefaultBrowseItemsSourceDesc(section),
                ),
              ),
            );
          }),
    );
  }
}
