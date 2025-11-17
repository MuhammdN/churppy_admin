import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'theme.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  // ✅ Stripe ko publishable key set karo (pk_... wali key from Stripe dashboard)
  Stripe.publishableKey = "pk_test_51S5zcnRrXfDjT97KJW5stvP7bGYTJZAiBsLYkWM4rhC8kDW6s1hqWsO6EY3h21m7PJVCLc4CeJXYOuZ562DW6VbZ00PmGFh5bv";

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Churppy Admin',
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      initialRoute: Routes.splash,
      onGenerateRoute: RouteGenerator.generate,
    );
  }
}
