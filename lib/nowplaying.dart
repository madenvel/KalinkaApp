import 'package:flutter/material.dart';
import 'playbar.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({Key? key, this.imgSource}) : super(key: key);

  final String? imgSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Now Playing'),
        ),
        body: Center(
            child: Column(children: [_buildImageWidget(), const Playbar()])));
  }

  Widget _buildImageWidget() {
    if (imgSource != null) {
      return Image(
        image: NetworkImage(imgSource!),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
