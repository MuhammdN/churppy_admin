import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        /// ✅ Responsive background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover, // ensures background fills all screen sizes
          ),
        ),

        child: Stack(
          alignment: Alignment.center,
          children: [
            // Business Account image (top)
            Align(
              alignment: const Alignment(0, -0.80),
              child: Image.asset(
                'assets/images/business_account.png',
                width: screenW * 0.80,
              ),
            ),

            // Bell icon
            Align(
              alignment: const Alignment(0, -0.500),
              child: Image.asset(
                'assets/images/bell_churppy.png',
                width: screenW * 0.28,
              ),
            ),

 Center(
  child: Image.asset(
    'assets/images/logo.png',
    width: screenW * 0.7, // 90% of screen width
    fit: BoxFit.contain,  // keeps proper aspect ratio
  ),
),


            // GO Button (image)
            Align(
              alignment: const Alignment(0.90, 0.30),
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, Routes.login),
                child: Image.asset(
                  'assets/images/go_button.png',
                  width: screenW * 0.36,
                ),
              ),
            ),

            // ✅ Centered bottom text (always in center)
            Positioned(
              bottom: 18,
              left: 0,
              right: 0, // 👈 centers it automatically
              child: Text(
                "Churppy\nTrademark and Patent Pending",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
