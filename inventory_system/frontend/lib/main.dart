/// Application Entry Point
/// 
/// Sets up the top-level app configuration, initializes global state management ([MultiProvider]),
/// and determines the initial routing based on user authentication status.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // AnalyticsProvider depends on Products; it automatically recalculates 
        // when the product library updates.
        ChangeNotifierProxyProvider<ProductProvider, AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
          update: (_, productProvider, analyticsProvider) =>
              analyticsProvider!..updateFromProducts(productProvider.products),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Inventory Management',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // Use Consumer to conditionally show Login or Dashboard
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return authProvider.isLoggedIn
                  ? const DashboardScreen()
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
