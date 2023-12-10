import 'package:flutter/material.dart';
import 'package:rpi_music/error_dialog.dart';
import 'package:rpi_music/event_listener.dart';
import 'package:rpi_music/player_datasource.dart';
import 'playbar.dart';
import 'playqueue.dart';
import 'nowplaying.dart';
import 'search.dart';

void main() {
  runApp(RpiMusic());
}

class RpiMusic extends StatelessWidget {
  RpiMusic({super.key}) {
    var host = '192.168.3.28';
    var port = 8000;
    EventListener().startListening('http://$host:$port/queue/events');
    PlayerDataSource();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rpi Music',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int currentPageIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();
  final List<Widget> pages = const <Widget>[
    NowPlaying(key: PageStorageKey<String>('now_playing'), imgSource: ''),
    PlayQueue(
      key: PageStorageKey<String>('queue'),
    ),
    Search(key: PageStorageKey<String>('search')),
  ];
  Function? closeErrorDialogCb;
  late String subscriptionId;

  _MyHomePageState();

  @override
  void initState() {
    super.initState();
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkError: (args) {
        closeErrorDialogCb =
            showReconnectDialog(context, message: 'Reconnecting...');
      },
      EventType.NetworkRecover: (args) {
        if (closeErrorDialogCb != null) {
          closeErrorDialogCb!();
          closeErrorDialogCb = null;
        }
      }
    });
    PlayerDataSource().onIsDataLoaded(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    PlayerDataSource().cancelOnIsDataLoaded();
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !PlayerDataSource().isDataLoaded()
        ? const SizedBox.expand()
        : Scaffold(
            bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PlayerDataSource().getTracks().isNotEmpty
                      ? const Playbar()
                      : const SizedBox.shrink(),
                  NavigationBar(
                    onDestinationSelected: (int index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                    },
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
                  )
                ]),
            body: PageStorage(
              bucket: bucket,
              child: pages[currentPageIndex],
            ));
  }
}
