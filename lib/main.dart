import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'screens/login_screen.dart';
import 'screens/halls_tables_screen.dart';
import 'screens/table_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_service.dart';
import 'services/data_persistence_service.dart';
import 'utils/translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service
  await ApiService().initialize();
  
  // Initialize data persistence service
  await DataPersistenceService().getCacheInfo(); // This will initialize the service
  
  runApp(const ProviderScope(child: ResPosApp()));
}

class ResPosApp extends ConsumerWidget {
  const ResPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppTranslations.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primarySwatch: Colors.grey,
        primaryColor: const Color(0xFF000000), // Uber Black
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF000000), // Uber Black
          secondary: Color(0xFF000000), // Uber Green
          surface: Color(0xFFFFFFFF), // White
          background: Color(0xFFF6F6F6), // Light Grey
          onPrimary: Color(0xFFFFFFFF), // White text on black
          onSecondary: Color(0xFF000000), // Black text on green
          onSurface: Color(0xFF000000), // Black text on white
          onBackground: Color(0xFF000000), // Black text on light grey
          error: Color(0xFFE53E3E), // Red for errors
          onError: Color(0xFFFFFFFF), // White text on red
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFFFFFFFF),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFF000000)),
          bodyMedium: TextStyle(color: Color(0xFF000000)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
        ),
      ),
      routerConfig: GoRouter(
        initialLocation: currentUser == null ? '/login' : '/halls',
        redirect: (context, state) {
          final isLoggedIn = currentUser != null;
          final isOnLoginPage = state.uri.path == '/login';
          
          if (!isLoggedIn && !isOnLoginPage) {
            return '/login';
          }
          if (isLoggedIn && isOnLoginPage) {
            return '/halls';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/halls',
            name: 'halls',
            builder: (context, state) => const HallsTablesScreen(),
          ),
          GoRoute(
            path: '/table/:tableId',
            name: 'table',
            builder: (context, state) {
              final tableId = state.pathParameters['tableId']!;
              return TableDetailScreen(tableId: tableId);
            },
          ),
        ],
      ),
    );
  }
}
