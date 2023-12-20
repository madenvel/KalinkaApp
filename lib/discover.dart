import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'data_provider.dart';

class Discover extends StatelessWidget {
  const Discover({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: ListView(
        children: [
          _buildSection('Top Albums', _buildHorizontalList(context)),
          _buildSection('Playlists', _buildHorizontalList(context)),
          _buildSection(
              'My Weekly Q',
              _buildWideImageWidget(
                context,
                'https://static.qobuz.com/images/dynamic/weekly_foreground_en.png',
              ),
              seeAll: false),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget horizontalList,
      {bool seeAll = true}) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              seeAll
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              child: const Text('See all >',
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () {})))
                  : const SizedBox.shrink()
            ]),
            horizontalList
          ],
        ));
  }

  Widget _buildHorizontalList(BuildContext context) {
    var size = MediaQuery.of(context).size.width / 2.5;
    var track = context.watch<PlayerStateProvider>().state.currentTrack;
    var image = track?.album?.image?.small;
    return Container(
        height: size + 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 10,
          separatorBuilder: (context, index) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            return Container(
                width: size,
                child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(5.0),
                              child: image != null
                                  ? Image.network(image, fit: BoxFit.fitWidth)
                                  : const SizedBox.shrink()),
                          const SizedBox(height: 8),
                          Flexible(
                              child: Text(track?.title ?? 'Unknown Title',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                          Text(
                            track?.performer?.name ?? 'Unknown Album',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          )
                        ])));
          },
        ));
  }

  static List<Color> myweeklyqColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.yellow
  ];

  Widget _buildWideImageWidget(BuildContext context, String imageUrl) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: myweeklyqColors[
                  getWeekOfYear(context.read<DateTimeProvider>().dateTime) %
                      myweeklyqColors.length]
              .withOpacity(0.5)),
      child: Stack(
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
              )),
          Positioned(
            right: 8,
            top: 56,
            child: IconButton(
              icon: const Icon(Icons.play_circle_filled),
              onPressed: () {
                // Add your play button logic here
              },
              color: Colors.white,
              iconSize: 48,
            ),
          ),
        ],
      ),
    );
  }

  int getWeekOfYear(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
