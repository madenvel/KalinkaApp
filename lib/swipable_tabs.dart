import 'package:flutter/material.dart';

import 'nowplaying.dart';
import 'playqueue.dart';

class SwipableTabs extends StatefulWidget {
  const SwipableTabs({Key? key}) : super(key: key);

  @override
  _SwipableTabsState createState() => _SwipableTabsState();
}

class _SwipableTabsState extends State<SwipableTabs>
    with SingleTickerProviderStateMixin {
  late final TabController controller;
  int _index = 0;
  List<Widget> widgets = const [NowPlaying(), PlayQueue()];

  @override
  void initState() {
    super.initState();
    controller = TabController(
        length: widgets.length, initialIndex: _index, vsync: this);
    controller.addListener(() {
      setState(() {
        _index = controller.index;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(_index == 0 ? 'Now Playing' : 'Play Queue',
              style: const TextStyle(fontSize: 16)),
          TabPageSelector(
            color: Colors.black38,
            controller: controller,
            indicatorSize: 8,
          ),
        ]),
        centerTitle: true,
      ),
      // Building UI
      body: TabBarView(controller: controller, children: widgets),
    );
  }
}
