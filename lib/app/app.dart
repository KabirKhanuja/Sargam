import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'routes.dart';

// Global key for SnackBar
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// ValueNotifier for dynamic theme switching
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

// ValueNotifier for global loading indicator
final ValueNotifier<bool> isLoading = ValueNotifier(false);

class SargamApp extends StatelessWidget {
  const SargamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Sargam',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppTheme.darkTheme, // Ensure lightTheme is defined in AppTheme
          darkTheme: AppTheme.darkTheme.copyWith(
            scaffoldBackgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
            appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
              backgroundColor: AppTheme.darkTheme.colorScheme.surface,
              foregroundColor: AppTheme.darkTheme.colorScheme.onSurface,
              elevation: 2,
              shadowColor: AppTheme.darkTheme.colorScheme.primary.withOpacity(0.2),
            ),
            textTheme: AppTheme.darkTheme.textTheme.copyWith(
              bodyLarge: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface.withOpacity(0.9),
              ),
              bodyMedium: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            iconTheme: AppTheme.darkTheme.iconTheme.copyWith(
              color: AppTheme.darkTheme.colorScheme.primary,
            ),
          ),
          themeMode: mode,
          initialRoute: AppRoutes.home,
          routes: AppRoutes.routes,
          builder: (context, child) {
            // Error boundary for routes
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Something went wrong!',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            };

            // Accessibility: Adjust text scale factor
            return Stack(
              children: [
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.2),
                  child: child!,
                ),
                // Global loading indicator
                ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) {
                    if (!loading) return const SizedBox.shrink();
                    return Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          onGenerateRoute: (settings) {
            // Custom page transitions
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AppRoutes.routes[settings.name]!(context),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
            );
          },
        );
      },
    );
  }
}