import 'package:flutter/material.dart';
import 'package:kalinka/browse_item_data_provider.dart'
    show BrowseItemDataProvider;
import 'package:kalinka/browse_item_data_source.dart'
    show BrowseItemDataSource, DefaultBrowseItemDataSource;
import 'package:kalinka/constants.dart';
import 'package:kalinka/preview_section_card.dart' show PreviewSectionCard;
import 'package:provider/provider.dart';
import 'package:kalinka/genre_select_filter.dart';
import 'package:kalinka/settings_tab.dart';

import 'data_model.dart';

class Discover extends StatelessWidget {
  const Discover({super.key});

  static const double textLabelHeight = 52;

  BrowseItemDataProvider _createProvider() {
    return BrowseItemDataProvider.fromDataSource(
      dataSource: DefaultBrowseItemDataSource(BrowseItem(
          id: 'root', url: '/catalog', canBrowse: true, canAdd: false)),
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
    return Consumer<BrowseItemDataProvider>(builder: (context, provider, _) {
      return SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              hitTestBehavior: HitTestBehavior.deferToChild,
              shrinkWrap: true,
              separatorBuilder: (context, index) => const SizedBox(
                  height: KalinkaConstants.kSpaceBetweenSections),
              itemCount: provider.maybeItemCount,
              itemBuilder: (context, index) =>
                  _buildSection(context, provider.getItem(index).item))
        ],
      ));
    });
  }

  Widget _buildSection(BuildContext context, BrowseItem? section) {
    return PreviewSectionCard(
        dataSource:
            section != null ? BrowseItemDataSource.browse(section) : null);
  }
}
