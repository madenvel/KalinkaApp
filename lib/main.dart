import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:kalinka/connection_manager.dart';
import 'package:kalinka/search.dart' show SearchScreen;
import 'package:provider/provider.dart';
// import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'data_provider.dart';
import 'discover.dart';
import 'library.dart';
import 'playbar.dart';
import 'search.dart';
import 'swipable_tabs.dart';

void main() {
  runApp(ProviderScope(child: const KalinkaMusic()));
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class KalinkaMusic extends StatelessWidget {
  const KalinkaMusic({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => TrackListProvider()),
          ChangeNotifierProvider(create: (context) => PlayerStateProvider()),
          ChangeNotifierProvider(
              create: (context) => UserFavoritesIdsProvider()),
          ChangeNotifierProvider(create: (context) => GenreFilterProvider()),
          ChangeNotifierProvider(
              create: (context) => ConnectionSettingsProvider()),
          ChangeNotifierProvider(create: (context) => UserPlaylistProvider())
        ],
        child: MaterialApp(
          scrollBehavior: MyCustomScrollBehavior(),
          title: 'Kalinka',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system, // Follow system theme by default
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
  final PageStorageBucket bucket = PageStorageBucket();

  // Create a navigator key for each tab to maintain separate navigation states
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  _MyHomePageState();

  // Build a navigator for each tab
  Widget _buildNavigator(int index) {
    return Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => [
                    const Discover(),
                    const Library(),
                    const SearchScreen()
                  ][index]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectionManager(
        child: Scaffold(
            bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer<TrackListProvider>(builder: (context, provider, _) {
                    if (provider.trackList.isNotEmpty) {
                      return Playbar(onTap: () {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                opaque: false,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const SwipableTabs()));
                      });
                    } else {
                      return const SizedBox.shrink();
                    }
                  }),
                  NavigationBar(
                    onDestinationSelected: (int index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                    },
                    selectedIndex: currentPageIndex,
                    destinations: const <Widget>[
                      NavigationDestination(
                        selectedIcon: Icon(Icons.explore),
                        icon: Icon(Icons.explore_outlined),
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
            body: IndexedStack(
              index: currentPageIndex,
              children: List.generate(3, (index) => _buildNavigator(index)),
            )));
  }
}
