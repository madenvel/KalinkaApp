import 'package:flutter/material.dart';
import 'package:rpi_music/event_listener.dart';
import 'package:rpi_music/rpiplayer_proxy.dart';
import 'playqueue.dart';
import 'nowplaying.dart';
import 'rest_types.dart';
import 'search.dart';

void main() {
  runApp(RpiMusic());
}

class RpiMusic extends StatelessWidget {
  RpiMusic({super.key}) {
    EventListener().startListening('http://192.168.3.28:8000/queue/events');
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rpi Music',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();

  @override
  void initState() {
    super.initState();
    _retrieveState();
    subscriptionId = EventListener().registerCallback({
      EventType.TrackChanged: (List<dynamic> args) {
        _retrieveState();
      },
    });
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId!);
    super.dispose();
  }

  void _retrieveState() {
    RpiPlayerProxy().getState().then((value) {
      setState(() {
        state = value;
      });
    }).catchError((error) {
      print("Error: $error");
    });
  }

  PlayerState? state;
  int currentPageIndex = 0;
  String? subscriptionId;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        // appBar: AppBar(
        //   // TRY THIS: Try changing the color here to a specific color (to
        //   // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        //   // change color while the other colors stay the same.
        //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        //   // Here we take the value from the MyHomePage object that was created by
        //   // the App.build method, and use it to set our appbar title.
        //   title: Text(widget.title),
        // ),
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.purple,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.music_note_outlined),
              icon: Icon(Icons.music_note),
              label: 'Now Playing',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.queue_music_outlined),
              icon: Icon(Icons.queue_music),
              label: 'Queue',
            ),
            NavigationDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search_outlined),
                label: 'Search'),
          ],
        ),
        body: <Widget>[
          NowPlaying(
            imgSource: state?.currentTrack?.album?.image?.large,
          ),
          const PlayQueue(),
          const Search(),
        ][currentPageIndex]);
  }
}
