import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart'
    show DefaultBrowseItemDataSource;
import 'package:kalinka/constants.dart';
import 'package:kalinka/discover_source.dart';
import 'package:kalinka/source_module_preview_card.dart' show SourceModule;
import 'package:provider/provider.dart';
import 'package:kalinka/settings_screen.dart';
import 'package:kalinka/genre_filter_chips.dart';
import 'package:kalinka/custom_cache_manager.dart';
import 'package:kalinka/browse_item_cache.dart';

import 'data_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double textLabelHeight = 52;

  BrowseItemDataProvider _createProvider() {
    return BrowseItemDataProvider.fromDataSource(
      dataSource: DefaultBrowseItemDataSource(
          BrowseItem(id: '', canBrowse: true, canAdd: false)),
      itemsPerRequest: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrowseItemDataProvider>(
        create: (context) => _createProvider(),
        child: Scaffold(
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
          body: _buildBody(context),
        ));
  }

  Widget _buildBody(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<BrowseItemDataProvider>(builder: (context, provider, _) {
      return RefreshIndicator(
        onRefresh: () async {
          // Clear image cache
          await KalinkaMusicCacheManager.instance.emptyCache();

          // Invalidate all data caches including section providers
          BrowseItemCache().invalidate();

          // Refresh the main provider
          provider.refresh();
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
              _buildSections(context),
              const SizedBox(
                height: KalinkaConstants.kContentVerticalPadding * 2,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSections(BuildContext context) {
    final provider = context.watch<BrowseItemDataProvider>();
    if (provider.maybeItemCount == 0) {
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
        itemCount: provider.maybeItemCount,
        itemBuilder: (context, index) =>
            _buildSection(context, provider.getItem(index).item));
  }

  Widget _buildSection(BuildContext context, BrowseItem? section) {
    if (section != null) {
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
                    browseItem: section,
                  ),
                ),
              );
            }),
      );
    }
    return const SizedBox.shrink();
  }
}
