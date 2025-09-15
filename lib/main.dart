import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerState, ConsumerStatefulWidget, ProviderScope;
import 'package:kalinka/providers/browse_item_data_provider_riverpod.dart'
    show sharedPrefsProvider;
import 'package:kalinka/connection_manager.dart';
import 'package:kalinka/constants.dart';
import 'package:kalinka/home_screen.dart' show HomeScreen;
import 'package:kalinka/providers/notification_service_provider.dart'
    show notificationServiceProvider;
import 'package:kalinka/search.dart' show SearchScreen;
import 'package:kalinka/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'home_screen.dart';
import 'library.dart';
import 'playbar.dart';
import 'search.dart';
import 'swipable_tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
  ], child: const KalinkaMusic()));
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Kalinka',
      theme: lightTheme.copyWith(
          chipTheme: lightTheme.chipTheme
              .copyWith(selectedColor: lightTheme.colorScheme.primaryContainer),
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
          chipTheme: darkTheme.chipTheme
              .copyWith(selectedColor: darkTheme.colorScheme.primaryContainer),
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
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with TickerProviderStateMixin {
  int currentPageIndex = 0;
  final PageStorageBucket bucket = PageStorageBucket();

  // Create a navigator key for each tab to maintain separate navigation states
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
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
                    SettingsScreen()
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
    ref.watch(notificationServiceProvider);
    return ConnectionManager(
      child: _withPopScope(Scaffold(
          bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Playbar(onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SwipableTabs(),
                    ),
                  );
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
                    NavigationDestination(
                        icon: Icon(Icons.settings),
                        selectedIcon: Icon(Icons.settings_outlined),
                        label: 'Settings')
                  ],
                )
              ]),
          body: _buildNavigator(currentPageIndex))),
    );
  }
}
