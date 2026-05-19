// ============================================================
//  main.dart  –  App Entry Point
//  Personal Utility App | 5th-Semester MAD Project
//  Complete — Parts 1 through 5
// ============================================================
//
//  Responsibilities of this file:
//  1. WidgetsFlutterBinding.ensureInitialized()
//     Must be called before ANY native/platform code.
//
//  2. Supabase.initialize()
//     Boots the Supabase SDK with your project URL and anon key.
//     After this call, Supabase.instance.client is available
//     everywhere in the app.
//
//  3. MultiProvider(providers: [...])
//     Registers all ChangeNotifier providers at the root so
//     every screen can access them with context.watch() /
//     context.read() without manual dependency passing.
//
//     Registered providers:
//     • AuthProvider          → sign in / sign up / sign out
//     • BusinessCardProvider  → QR card CRUD + scan history
//     • RecordingProvider     → audio recording CRUD
//     (Unit Converter has no shared state — no provider needed)
//
//  4. AuthWrapper
//     Watches AuthProvider.isAuthenticated and shows either
//     HomeScreen (logged in) or LoginScreen (logged out).
//     This eliminates all manual auth-related navigation.
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Screens ────────────────────────────────────────────────
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/panel_selection_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home/home_screen.dart';

// ── Providers ──────────────────────────────────────────────
import 'providers/auth_provider.dart'; // Part 1
import 'providers/business_card_provider.dart'; // Part 2 & 3
import 'providers/recording_provider.dart'; // Part 2 & 5

// ══════════════════════════════════════════════════════════════
//  TODO: Replace these two values with your actual Supabase
//  project credentials before running the app.
//
//  Where to find them:
//  → https://supabase.com → your project
//  → Project Settings → API → "Project URL" and "anon public"
// ══════════════════════════════════════════════════════════════
const String supabaseUrl = 'https://imflrphnhkwyfxvrmdzf.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltZmxycGhuaGt3eWZ4dnJtZHpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMDQxNTgsImV4cCI6MjA4ODg4MDE1OH0.iATHA23CCdHl_OTt1HvJb6GmgcvYq7hTsIH8xzhIvCU';
// ─────────────────────────────────────────────────────────────

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  // Required before calling any Flutter plugin or native API
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — must complete before runApp()
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );

  runApp(const MyApp());
}

// ── MyApp ─────────────────────────────────────────────────
//  Root widget. Sets up Provider tree and MaterialApp theme.
// ─────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ── All providers registered here ───────────────────
      // create: (_) => ... runs ONCE when the provider is first
      // accessed. The provider lives as long as the app does.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessCardProvider()),
        ChangeNotifierProvider(create: (_) => RecordingProvider()),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'Personal Utility App',
        debugShowCheckedModeBanner: false,

        // ── Material 3 Theme ─────────────────────────────
        // ColorScheme.fromSeed() generates a complete harmonious
        // palette (primary, secondary, surface, error, etc.)
        // from a single seed colour.
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),

          // ── Card defaults ────────────────────────────────
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // ── Input field defaults ─────────────────────────
          // Applied to every TextFormField / TextField unless
          // individually overridden in a screen's decoration.
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),

          // ── ElevatedButton defaults ───────────────────────
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
            ),
          ),
        ),

        // ── Starting point ───────────────────────────────
        // AuthWrapper decides which screen to show based on
        // whether a Supabase session currently exists.
        builder: (context, child) {
          return _PasswordRecoveryNavigator(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthWrapper(),
      ),
    );
  }
}

// ── AuthWrapper ───────────────────────────────────────────
//
//  A pure routing widget — no business logic here.
//
//  It uses Consumer<AuthProvider> which means this widget
//  rebuilds automatically whenever AuthProvider calls
//  notifyListeners(). The three possible states are:
//
//  isLoading = true  → show a centered spinner
//              (happens during app startup while Supabase
//               checks for an existing stored session)
//
//  isAuthenticated = true  → show HomeScreen
//  isAuthenticated = false → show LoginScreen
//
//  Because AuthWrapper sits at the root of the Navigator,
//  no explicit Navigator.pushReplacement() is needed when
//  logging in or out — the widget tree just swaps.
// ─────────────────────────────────────────────────────────
class _PasswordRecoveryNavigator extends StatefulWidget {
  final Widget child;

  const _PasswordRecoveryNavigator({required this.child});

  @override
  State<_PasswordRecoveryNavigator> createState() =>
      _PasswordRecoveryNavigatorState();
}

class _PasswordRecoveryNavigatorState
    extends State<_PasswordRecoveryNavigator> {
  AuthProvider? _authProvider;
  bool _wasPasswordRecovery = false;
  String? _lastShownAuthLinkError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAuthProvider = context.read<AuthProvider>();
    if (_authProvider == nextAuthProvider) return;

    _authProvider?.removeListener(_handleAuthProviderChanged);
    _authProvider = nextAuthProvider;
    _authProvider?.addListener(_handleAuthProviderChanged);
    _handleAuthProviderChanged();
  }

  void _handleAuthProviderChanged() {
    final isPasswordRecovery = _authProvider?.isPasswordRecovery ?? false;
    final authLinkError = _authProvider?.authLinkErrorMessage;

    if (authLinkError != null && authLinkError != _lastShownAuthLinkError) {
      _lastShownAuthLinkError = authLinkError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('[Main] Showing auth link error: $authLinkError');
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(authLinkError),
            backgroundColor: Colors.red.shade700,
          ),
        );
        _authProvider?.clearAuthLinkError();
      });
    }

    if (!isPasswordRecovery || _wasPasswordRecovery == isPasswordRecovery) {
      _wasPasswordRecovery = isPasswordRecovery;
      return;
    }

    _wasPasswordRecovery = isPasswordRecovery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;
      debugPrint('[Main] Navigating to Reset Password screen.');
      navigator.popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ── Checking session on startup ────────────────────
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Route based on auth state ──────────────────────
        if (authProvider.isPasswordRecovery) {
          return const ResetPasswordScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const PanelSelectionScreen();
        }

        if (authProvider.isRoleLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.roleLoadError != null) {
          debugPrint(
            '[AuthWrapper] Navigation paused: ${authProvider.roleLoadError}',
          );
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.roleLoadError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AuthProvider>().signOut(),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final target =
            authProvider.isAdminSession ? 'admin panel' : 'user panel';
        debugPrint(
          '[AuthWrapper] Final navigation decision: $target '
          'source=${authProvider.roleSource} '
          'userId=${authProvider.currentUser?.id ?? 'none'} '
          'email=${authProvider.userEmail ?? 'none'} '
          'role=${authProvider.userRole?.name ?? 'none'}',
        );

        return authProvider.isAdminSession
            ? const AdminDashboardScreen()
            : const HomeScreen();
      },
    );
  }
}
