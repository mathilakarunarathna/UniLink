import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'pages/Student/login_page.dart';
import 'pages/Student/dashboard_page.dart';
import 'pages/Student/my_spot_page.dart';
import 'pages/Student/study_space_page.dart';
import 'pages/Student/cafeteria_page.dart';
import 'pages/Student/event_pass_page.dart';
import 'pages/Student/uni_feed_page.dart';
import 'pages/Student/shuttle_sync_page.dart';
import 'pages/Student/lost_found_page.dart';
import 'pages/Student/stay_finder_page.dart';
import 'pages/Student/profile_completion_page.dart';
import 'pages/Student/settings_page.dart';
import 'pages/Student/not_found_page.dart';
import 'pages/search_page.dart';
import 'pages/Student/uni_map.dart';
import 'pages/Student/notifications_page.dart';
import 'pages/welcome_page.dart';


import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/dashboard/presentation/dashboard_provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize App Check with a debug provider for development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, _) {
          return MaterialApp(
            title: 'Campus Connect Hub',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (context) => const WelcomePage(),
                  );
                case '/login':
                  return MaterialPageRoute(builder: (context) => LoginPage());
                case '/dashboard':
                  return MaterialPageRoute(
                    builder: (context) => DashboardPage(),
                  );
                case '/myspot':
                  return MaterialPageRoute(builder: (context) => MySpotPage());
                case '/studyspace':
                  return MaterialPageRoute(
                    builder: (context) => StudySpacePage(),
                  );
                case '/cafeteria':
                  return MaterialPageRoute(
                    builder: (context) => CafeteriaPage(),
                  );
                case '/eventpass':
                  return MaterialPageRoute(
                    builder: (context) => EventPassPage(),
                  );
                case '/unifeed':
                  return MaterialPageRoute(builder: (context) => UniFeedPage());
                case '/shuttlesync':
                  return MaterialPageRoute(
                    builder: (context) => ShuttleSyncPage(),
                  );
                case '/lostfound':
                  return MaterialPageRoute(
                    builder: (context) => LostFoundPage(),
                  );
                case '/stayfinder':
                  return MaterialPageRoute(
                    builder: (context) => const StayFinderPage(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  );
                case '/profile_completion':
                  return MaterialPageRoute(
                    builder: (context) => const ProfileCompletionPage(),
                  );
                case '/settings':
                  return MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  );
                case '/search':
                  return MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  );
                case '/notifications':
                  return MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  );
                case '/unimap':
                  return MaterialPageRoute(
                    builder: (context) => const UniMapPage(),
                  );

                default:
                  return MaterialPageRoute(
                    builder: (context) => const NotFoundPage(),
                  );
              }
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
