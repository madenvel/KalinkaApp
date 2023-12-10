import 'package:flutter/material.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({Key? key, this.imgSource}) : super(key: key);

  final String? imgSource;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Now Playing'),
        ),
        body: Center(child: Column(children: [_buildImageWidget()])));
  }

  Widget _buildImageWidget() {
    if (imgSource != null && imgSource!.isNotEmpty) {
      return Image(
        image: NetworkImage(imgSource!),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
