import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemsDataProvider;
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:provider/provider.dart';
import 'package:kalinka/genre_select_filter.dart';
import 'package:kalinka/settings_tab.dart';

import 'data_model.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  _DiscoverState();

  final navigatorKey = GlobalKey<NavigatorState>();
  final double textLabelHeight = 52;
  static const double contentPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    // Keep this one for dynamic resize of the content to work when screen size changes
    // MediaQuery.of(context).size;
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
                  return _buildWithProviders();
                })));
  }

  BrowseItemsDataProvider _createProvider() {
    return BrowseItemsDataProvider(
      parentItem: BrowseItem(
          id: 'root', url: '/catalog', canBrowse: true, canAdd: false),
      itemsPerRequest: 10,
    );
  }

  Widget _buildWithProviders() {
    return ChangeNotifierProvider<BrowseItemsDataProvider>(
        create: (context) => _createProvider(),
        child: Scaffold(
          appBar: AppBar(
              title: const Row(children: [
                Icon(Icons.explore),
                SizedBox(width: 8),
                Text('Discover')
              ]),
              actions: <Widget>[
                const GenreFilterButton(),
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SettingsTab()));
                    })
              ]),
          body: _buildBody(context),
        ));
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<BrowseItemsDataProvider>(builder: (context, provider, _) {
      return ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemCount: provider.maybeItemCount,
          itemBuilder: (context, index) =>
              _buildSection(context, provider.getItem(index).item));
    });
  }

  Widget _buildSection(BuildContext context, BrowseItem? section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child:
          PreviewSectionCard(section: section, contentPadding: contentPadding),
    );
  }
}
