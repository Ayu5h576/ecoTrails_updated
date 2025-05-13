import 'dart:async';
import 'package:eco_trails/firebase_options.dart';
import 'package:eco_trails/models/place.dart';
import 'package:eco_trails/pages/app/bookmark_page.dart';
import 'package:eco_trails/pages/app/category_page.dart';
import 'package:eco_trails/pages/app/home_page.dart';
import 'package:eco_trails/pages/app/map_page.dart';
import 'package:eco_trails/pages/app/start_travel_page.dart';
import 'package:eco_trails/pages/app/travel_history_page.dart';
import 'package:eco_trails/pages/app/trip_plan_page.dart';
import 'package:eco_trails/pages/app/trip_planner_page.dart';
import 'package:eco_trails/pages/authentication/signin_page.dart';
import 'package:eco_trails/pages/authentication/signup_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  debugPaintSizeEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔐 Request location permission
    await _requestLocationPermission();

    runApp(const MyApp());
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}

Future<void> _requestLocationPermission() async {
  final status = await Permission.location.request();
  if (status.isDenied || status.isPermanentlyDenied) {
    print("Location permission denied.");
  } else if (status.isGranted) {
    print("Location permission granted.");
  }
}

final GoRouter _router = GoRouter(
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn =
        state.matchedLocation == '/signin' ||
        state.matchedLocation == '/signup';

    if (!isLoggedIn && !loggingIn) return '/signin';
    if (isLoggedIn && loggingIn) return '/home';
    return null;
  },
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/', builder: (context, state) => SignInPage()),
    GoRoute(path: '/signin', builder: (context, state) => SignInPage()),
    GoRoute(path: '/signup', builder: (context, state) => SignupPage()),
    GoRoute(path: '/home', builder: (context, state) => HomePage()),
    GoRoute(path: '/cat', builder: (context, state) => CategoryPage()),
    GoRoute(path: '/map', builder: (context, state) => MapScreen()),
    GoRoute(path: '/bookmarks', builder: (context, state) => BookmarkScreen()),

    GoRoute(path: '/tripPlan', builder: (context, state) => TripPlanPage()),

    GoRoute(path: '/history', builder: (context, state) => TravelHistoryPage()),
    GoRoute(
      path: '/place',
      builder: (context, state) {
        final place = state.extra as Place;
        return TravelScreen(place: place);
      },
    ),
    GoRoute(
      path: '/trip-planner',
      builder: (context, state) {
        final place = state.extra as Place;
        return TripPlannerPage(place: place);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Eco Trails",
      routerConfig: _router,
      theme: ThemeData(),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
