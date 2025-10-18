
import 'package:churppy_admin/screens/Review_Churppy_Screen.dart';
import 'package:churppy_admin/screens/churppy_alert_plan.dart';
import 'package:churppy_admin/screens/create_churppy_alert_screen.dart';
import 'package:churppy_admin/screens/dashboard_screen.dart';
import 'package:churppy_admin/screens/login.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';

class Routes {
  static const splash    = '/';
  static const login     = '/login';
  static const signup = '/signup';
  static const dashboard = '/dashboard';
  static const create_churppy_alert = '/create_churppy_alert';
  static const Review_Churppy_Screen = '/Review_Churppy_Screen';
  static const churppy_alert_plan= '/churppy_alert_plan';

}

/// single place se saari route creation
class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return _page(const SplashScreen());
      case Routes.login:
        return _page(const LoginScreen());
      case Routes.signup:
        return _page(const SignupScreen());
      case Routes.dashboard:
        return _page(const DashboardScreen());
      // case Routes.create_churppy_alert:
      //   return _page(const ChurppyAlertScreen());
      // case Routes.Review_Churppy_Screen:
      //   return _page(const ReviewChurppyScreen());
      case Routes.churppy_alert_plan:
        return _page(const ChurppyPlansScreen ());
      default:
        return _page(
          Scaffold(
            body: Center(child: Text('No route: ${settings.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);
}
