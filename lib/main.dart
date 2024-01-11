import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rpi_music/event_listener.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'discover.dart';
import 'library.dart';
import 'playbar.dart';
import 'search.dart';
import 'swipable_tabs.dart';

void main() {
  runApp(RpiMusic());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class RpiMusic extends StatelessWidget {
  RpiMusic({super.key}) {
    var host = '192.168.3.28';
    var port = 8000;
    EventListener().startListening('http://$host:$port/queue/events');
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var listTileTheme = Theme.of(context).listTileTheme.copyWith(
        titleTextStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        subtitleTextStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey));
    return MultiProvider(
        providers: [
          Provider<DateTimeProvider>(create: (context) => DateTimeProvider()),
          ChangeNotifierProvider(create: (context) => TrackListProvider()),
          ChangeNotifierProvider(create: (context) => PlayerStateProvider()),
          ChangeNotifierProvider(create: (context) => TrackProgressProvider()),
          ChangeNotifierProvider(create: (context) => UserFavoritesProvider()),
          ChangeNotifierProvider(create: (context) => SearchResultsProvider()),
          ChangeNotifierProvider(create: (context) => GenreFilterProvider()),
          ChangeNotifierProxyProvider<GenreFilterProvider,
              DiscoverSectionProvider>(
            create: (context) => DiscoverSectionProvider(),
            update: (BuildContext context, GenreFilterProvider value,
                DiscoverSectionProvider? previous) {
              if (previous != null) {
                previous.update(value.filter);
                return previous;
              } else {
                return DiscoverSectionProvider(genreIds: value.filter);
              }
            },
          ),
          ChangeNotifierProvider(create: (context) => VolumeControlProvider()),
        ],
        child: MaterialApp(
          scrollBehavior: MyCustomScrollBehavior(),
          title: 'Rpi Music',
          theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              visualDensity: VisualDensity.compact,
              // colorSchemeSeed: Colors.black,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                // ···
                brightness: Brightness.light,
              ),
              listTileTheme: listTileTheme
              /* light theme settings */
              ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            visualDensity: VisualDensity.compact,
            // colorSchemeSeed: Colors.black,
            listTileTheme: listTileTheme,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              // ···
              brightness: Brightness.dark,
            ),
            /* dark theme settings */
          ),
          themeMode: ThemeMode.dark,
          /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
          home: const MyHomePage(),
        ));
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
  bool _connected = false;
  final PageStorageBucket bucket = PageStorageBucket();
  final List<Widget> pages = const <Widget>[
    Discover(),
    Library(),
    Search(key: PageStorageKey<String>('search')),
  ];
  late String subscriptionId;

  _MyHomePageState();

  @override
  void initState() {
    super.initState();
    Provider.of<TrackListProvider>(context, listen: false).getTracks();
    Provider.of<PlayerStateProvider>(context, listen: false).getState();
    subscriptionId = EventListener().registerCallback({
      EventType.NetworkDisconnected: (args) {
        setState(() {
          _connected = false;
        });
      },
      EventType.NetworkConnected: (args) {
        setState(() {
          _connected = true;
        });
      }
    });
  }

  @override
  void dispose() {
    EventListener().unregisterCallback(subscriptionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isQueueNotEmpty =
        context.watch<TrackListProvider>().trackList.isNotEmpty;
    return Stack(children: [
      Scaffold(
          bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                isQueueNotEmpty
                    ? Playbar(onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SwipableTabs()));
                      })
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
                      selectedIcon: Icon(Icons.compass_calibration),
                      icon: Icon(Icons.compass_calibration_outlined),
                      label: 'Discover',
                    ),
                    NavigationDestination(
                      selectedIcon: Icon(Icons.library_music),
                      icon: Icon(Icons.library_music_outlined),
                      label: 'My Library',
                    ),
                    NavigationDestination(
                        icon: Icon(Icons.search),
                        selectedIcon: Icon(Icons.search_outlined),
                        label: 'Search'),
                  ],
                )
              ]),
          body: _withTransparentGradient(PageStorage(
            bucket: bucket,
            child: pages[currentPageIndex],
          ))),
      _connected == false
          ? Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const SizedBox.shrink(),
    ]);
  }

  Widget _withTransparentGradient(Widget widget) {
    return Stack(children: [
      widget,
      IgnorePointer(
          child: Positioned.fill(
              bottom: 0,
              child: Align(
                  alignment: Alignment.bottomCenter, child: _buildGradient()))),
    ]);
  }

  Widget _buildGradient() {
    var color = Theme.of(context).primaryColor;
    return Container(
        height: 30,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0), color])));
  }
}
