import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS/macOS features
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0B0E14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5722),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: const ExerciseHomeScreen(),
    );
  }
}

class NavItem {
  final String title;
  final IconData icon;
  final String assetPath;

  const NavItem({
    required this.title,
    required this.icon,
    required this.assetPath,
  });
}

class ExerciseHomeScreen extends StatefulWidget {
  const ExerciseHomeScreen({super.key});

  @override
  State<ExerciseHomeScreen> createState() => _ExerciseHomeScreenState();
}

class _ExerciseHomeScreenState extends State<ExerciseHomeScreen> {
  late final WebViewController _controller;
  int _currentIndex = 0;
  int _loadingProgress = 0;
  bool _isLoading = true;

  final List<NavItem> _navItems = const [
    NavItem(
      title: 'Meýilnama',
      icon: Icons.fitness_center_rounded,
      assetPath: 'assets/exercise/index.html',
    ),
    NavItem(
      title: 'Maşklar',
      icon: Icons.menu_book_rounded,
      assetPath: 'assets/exercise/mashklar.html',
    ),
    NavItem(
      title: 'Gyzyşmak',
      icon: Icons.local_fire_department_rounded,
      assetPath: 'assets/exercise/razminka.html',
    ),
    NavItem(
      title: 'Ösüş & BMI',
      icon: Icons.insights_rounded,
      assetPath: 'assets/exercise/osush.html',
    ),
    NavItem(
      title: 'Suw',
      icon: Icons.water_drop_rounded,
      assetPath: 'assets/exercise/suw.html',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0E14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _syncTabWithUrl(url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _syncTabWithUrl(change.url!);
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadFlutterAsset(_navItems[0].assetPath);
    _controller = controller;
  }

  void _syncTabWithUrl(String url) {
    for (int i = 0; i < _navItems.length; i++) {
      final fileName = _navItems[i].assetPath.split('/').last;
      if (url.endsWith(fileName) || url.contains('/$fileName')) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        break;
      }
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      _controller.reload();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    _controller.loadFlutterAsset(_navItems[index].assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else {
          // If at root or can't go back, check if not on first tab
          if (_currentIndex != 0) {
            _onTabSelected(0);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                  backgroundColor: const Color(0xFF161B22),
                  color: const Color(0xFFFF5722),
                  minHeight: 2.5,
                ),
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(
              top: BorderSide(
                color: Color(0x1FFFFFFF),
                width: 0.5,
              ),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: const Color(0xFF161B22),
              indicatorColor: const Color(0x33FF5722),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF5722),
                  );
                }
                return const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8B949E),
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: Color(0xFFFF5722),
                    size: 24,
                  );
                }
                return const IconThemeData(
                  color: Color(0xFF8B949E),
                  size: 22,
                );
              }),
            ),
            child: NavigationBar(
              height: 65,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.title,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
