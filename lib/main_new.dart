import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'screens/login_screen.dart';
import 'screens/halls_tables_screen.dart';
import 'screens/table_detail_screen.dart';

void main() {
  runApp(const ProviderScope(child: ResPosApp()));
}

class ResPosApp extends ConsumerWidget {
  const ResPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant POS',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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
