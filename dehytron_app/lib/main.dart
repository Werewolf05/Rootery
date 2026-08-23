import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Theme
import 'package:rootery_app/theme/rootery_theme.dart';

// Services
import 'package:rootery_app/services/data_service.dart';

// Screens
import 'package:rootery_app/screens/splash_screen.dart';
import 'package:rootery_app/screens/login/login_screen.dart';
import 'package:rootery_app/screens/marketplace_screen.dart';
import 'package:rootery_app/screens/feedback_screen.dart';
import 'package:rootery_app/screens/reports_screen.dart';
import 'package:rootery_app/screens/auth/signup_screen.dart';
import 'package:rootery_app/screens/auth/profile_screen.dart';
import 'package:rootery_app/screens/main_navigation.dart';
import 'package:rootery_app/screens/hydroponics/hydro_dashboard_screen.dart';
import 'package:rootery_app/screens/hydroponics/hydro_control_screen.dart';
import 'package:rootery_app/screens/hydroponics/hydro_sensors_screen.dart';
import 'package:rootery_app/screens/hydroponics/hydro_batches_screen.dart';
import 'package:rootery_app/screens/hydroponics/hydro_settings_screen.dart';

const bool kFrontendOnlyDemo = false;

// Route builders
Widget _splashRoute(BuildContext context) => const SplashScreen();
Widget _loginRoute(BuildContext context) => const LoginScreen();
Widget _mainNavigationRoute(BuildContext context) =>
    const MainNavigationScreen();
Widget _hydroDashboardRoute(BuildContext context) =>
    const HydroDashboardScreen();
Widget _hydroControlRoute(BuildContext context) => const HydroControlScreen();
Widget _hydroSensorsRoute(BuildContext context) => const HydroSensorsScreen();
Widget _hydroBatchesRoute(BuildContext context) => const HydroBatchesScreen();
Widget _hydroSettingsRoute(BuildContext context) => const HydroSettingsScreen();
Widget _marketplaceRoute(BuildContext context) => const MarketplaceScreen();
Widget _feedbackRoute(BuildContext context) => const FeedbackScreen();
Widget _reportsRoute(BuildContext context) => const ReportsScreen();
Widget _signupRoute(BuildContext context) => const SignupScreen();
Widget _profileRoute(BuildContext context) => const ProfileScreen();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error plumbing.
  FlutterError.onError = (details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString());
  };
  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'A rendering error occurred',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Always initialize Supabase so any Supabase.instance usage in UI/services is safe.
  // Network failures can still happen later, but this prevents render-time assertion crashes.
  try {
    await Supabase.initialize(
      url: 'https://yiyqgbdpuesjpzirrdcy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlpeXFnYmRwdWVzanB6aXJyZGN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNzQ1MjksImV4cCI6MjA4OTg1MDUyOX0.ENwp2gj8df8zTnceMS8j-p00dchHUqeT03XxNB6GR5U',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e, st) {
    debugPrint('Supabase init error: $e');
    debugPrint(st.toString());
  }

  if (!kFrontendOnlyDemo) {
    // Initialize data service for real-time updates only in full backend mode.
    DataService().initialize();
  } else {
    debugPrint(
      'Running in frontend-only demo mode (backend polling disabled).',
    );
  }

  runApp(const RooteryApp());
}

class RooteryApp extends StatelessWidget {
  const RooteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool showDebugOverlay =
        ModalRoute.of(context)?.settings.name == '/__debug_overlay__';
    return ValueListenableBuilder<bool>(
      valueListenable: RooteryTheme.highContrastMode,
      builder: (context, highContrast, _) => MaterialApp(
        title: 'Rootery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: highContrast
              ? Colors.white
              : (kIsWeb
                    ? RooteryTheme.bgScaffold.withOpacity(0.98)
                    : RooteryTheme.bgScaffold),
          cardColor: RooteryTheme.bgSurface,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          iconButtonTheme: const IconButtonThemeData(
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(48, 48)),
            ),
          ),
          listTileTheme: const ListTileThemeData(
            minLeadingWidth: 32,
            minVerticalPadding: 8,
          ),
          colorScheme: const ColorScheme.light().copyWith(
            primary: highContrast
                ? RooteryTheme.green900
                : RooteryTheme.green400,
            secondary: RooteryTheme.green600,
            error: RooteryTheme.redAlert,
            surface: RooteryTheme.bgSurface,
            onSurface: Colors.black,
          ),
        ),
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          Widget Function(BuildContext) builder;

          switch (settings.name) {
            case '/splash':
              builder = _splashRoute;
              break;
            case '/login':
              builder = _loginRoute;
              break;
            case '/signup':
              builder = _signupRoute;
              break;
            case '/main':
              builder = _mainNavigationRoute;
              break;
            case '/dashboard':
            case '/farmer-dashboard':
              builder = _hydroDashboardRoute;
              break;
            case '/controls':
              builder = _hydroControlRoute;
              break;
            case '/manual-control':
              builder = _hydroControlRoute;
              break;
            case '/auto-mode':
              builder = _hydroSensorsRoute;
              break;
            case '/logs':
              builder = _hydroSensorsRoute;
              break;
            case '/device-settings':
              builder = _hydroSettingsRoute;
              break;
            case '/analytics':
              builder = _hydroSensorsRoute;
              break;
            case '/sensors':
              builder = _hydroSensorsRoute;
              break;
            case '/batches':
              builder = _hydroBatchesRoute;
              break;
            case '/marketplace':
              builder = _marketplaceRoute;
              break;
            case '/app-settings':
              builder = _hydroSettingsRoute;
              break;
            case '/feedback':
              builder = _feedbackRoute;
              break;
            case '/profile':
              builder = _profileRoute;
              break;
            case '/reports':
              builder = _reportsRoute;
              break;
            default:
              return null;
          }

          // Apply fade transition animation
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                builder(context),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 350),
            settings: settings,
          );
        },
        builder: (context, child) {
          final media = MediaQuery.of(context);
          RooteryTheme.setDeviceTextScaleForWidth(media.size.width);
          final baseScale = media.textScaler.scale(1);
          final combinedScale = (baseScale * RooteryTheme.deviceTextScale)
              .clamp(0.88, 1.35);
          final responsiveMedia = media.copyWith(
            textScaler: TextScaler.linear(combinedScale),
          );

          final Widget contentWithFooter = child ?? const SizedBox.shrink();

          if (!showDebugOverlay) {
            return MediaQuery(data: responsiveMedia, child: contentWithFooter);
          }

          return MediaQuery(
            data: responsiveMedia,
            child: Stack(
              children: [
                contentWithFooter,
                Positioned(
                  right: 8,
                  bottom: 46,
                  child: Opacity(
                    opacity: 0.85,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RooteryTheme.accentGreen.withOpacity(0.4),
                        ),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Debug Overlay'),
                            Text('Platform: ${kIsWeb ? 'Web' : 'Native'}'),
                            Text(
                              'Time: ${DateTime.now().toIso8601String().substring(11, 19)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
