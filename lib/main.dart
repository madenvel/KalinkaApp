import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kalinka/connection_manager.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'data_provider.dart';
import 'discover.dart';
import 'library.dart';
import 'playbar.dart';
import 'search.dart';
import 'swipable_tabs.dart';

void main() {
  runApp(const KalinkaMusic());
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
          theme: FlexThemeData.light(
            scheme: FlexScheme.red,
            colors: const FlexSchemeColor(
              primary: Color(0xFFD32F2F),
              primaryContainer: Color(0xFFEFCBCB),
              secondary: Color(0xFFD32F2F),
              secondaryContainer: Color(0xFFEFCBCB),
              tertiary: Color(0xFFD32F2F),
              tertiaryContainer: Color(0xFFEFCBCB),
              appBarColor: Color(0xFFD32F2F),
              error: Color(0xFFA00020),
            ),
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            surface: Colors.white,
            appBarOpacity: 0.95,
            subThemesData: const FlexSubThemesData(
              inputDecoratorSchemeColor: SchemeColor.primary,
            ),
          ),
          darkTheme: FlexThemeData.dark(
            scheme: FlexScheme.red,
            colors: const FlexSchemeColor(
              primary: Color(0xFFE74C3C),
              primaryContainer: Color(0xFF9E2A2B),
              secondary: Color(0xFFE74C3C),
              secondaryContainer: Color(0xFF9E2A2B),
              tertiary: Color(0xFFE74C3C),
              tertiaryContainer: Color(0xFF9E2A2B),
              appBarColor: Color(0xFF212121),
              error: Color(0xFFC45B67),
            ),
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            surface: Color(0xFF303030),
            appBarOpacity: 0.90,
            subThemesData: const FlexSubThemesData(
              inputDecoratorSchemeColor: SchemeColor.primary,
            ),
          ),
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
  final List<Widget> pages = const <Widget>[
    Discover(),
    Library(),
    Search(key: PageStorageKey<String>('search')),
  ];

  _MyHomePageState();

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
            body: PageStorage(
              bucket: bucket,
              child: pages[currentPageIndex],
            )));
  }
}
