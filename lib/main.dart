import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:kalinka/connection_manager.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/home_screen.dart' show HomeScreen;
import 'package:kalinka/search.dart' show SearchScreen;
import 'package:kalinka/shimmer_effect.dart' show ShimmerProvider;
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'home_screen.dart';
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
    final lightTheme = FlexThemeData.light();
    final darkTheme = FlexThemeData.dark();
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => TrackListProvider()),
          ChangeNotifierProvider(create: (context) => PlayerStateProvider()),
          ChangeNotifierProvider(
              create: (context) => UserFavoritesIdsProvider()),
          ChangeNotifierProvider(create: (context) => GenreFilterProvider()),
          ChangeNotifierProvider(
              create: (context) => ConnectionSettingsProvider()),
          ChangeNotifierProvider(create: (context) => UserPlaylistProvider()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: MyCustomScrollBehavior(),
          title: 'Kalinka',
          theme: lightTheme.copyWith(
              chipTheme: lightTheme.chipTheme.copyWith(
                  selectedColor: lightTheme.colorScheme.primaryContainer),
              listTileTheme: lightTheme.listTileTheme.copyWith(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: KalinkaConstants.kContentHorizontalPadding),
                titleTextStyle: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: lightTheme.colorScheme.onSurface.darken(20),
                    fontWeight: FontWeight.w500,
                    fontSize: 15),
                subtitleTextStyle: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: lightTheme.colorScheme.onSurface.brighten(30)),
              )),
          darkTheme: darkTheme.copyWith(
              chipTheme: darkTheme.chipTheme.copyWith(
                  selectedColor: darkTheme.colorScheme.primaryContainer),
              listTileTheme: darkTheme.listTileTheme.copyWith(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: KalinkaConstants.kContentHorizontalPadding),
                titleTextStyle: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: darkTheme.colorScheme.onSurface.brighten(20),
                    fontWeight: FontWeight.w500,
                    fontSize: 15),
                subtitleTextStyle: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: darkTheme.colorScheme.onSurface.darken(30)),
              )),
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int currentPageIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  // Create a navigator key for each tab to maintain separate navigation states
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  _MyHomePageState();

  Widget _withPopScope(Widget child) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, _) {
          if (didPop) {
            return;
          }
          if (_navigatorKeys[currentPageIndex].currentState!.canPop()) {
            _navigatorKeys[currentPageIndex].currentState!.pop();
          } else {
            SystemNavigator.pop();
          }
        },
        child: child);
  }

  // Build a navigator for each tab
  Widget _buildNavigator(int index) {
    return Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => [
                    HomeScreen(),
                    Library(),
                    SearchScreen(),
                  ][index]);
        });
  }

  // Clear the navigator stack when switching tabs
  void _handleTabChange(int index) {
    if (currentPageIndex == index) {
      // If tapping the same tab, pop to first route
      if (_navigatorKeys[index].currentState!.canPop()) {
        _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
      }
    } else {
      // If we're switching tabs and there are routes in the stack, pop to first route
      if (_navigatorKeys[currentPageIndex].currentState != null &&
          _navigatorKeys[currentPageIndex].currentState!.canPop()) {
        _navigatorKeys[currentPageIndex]
            .currentState!
            .popUntil((route) => route.isFirst);
      }

      setState(() {
        currentPageIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShimmerProvider(this),
      child: ConnectionManager(
        child: _withPopScope(Scaffold(
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
                    onDestinationSelected: _handleTabChange,
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
            body: _buildNavigator(currentPageIndex))),
      ),
    );
  }
}
