import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.85, -0.55),
            end: Alignment(0.90, 0.65),
            colors: [
              Color(0xFF8FC245),
              Color(0xFFB7D78A),
              Color(0xFFC3CFB2),
            ],
            stops: [0.08, 0.42, 0.96],
          ),
        ),
        child: Stack(
          children: [
            // Soft white radial highlight
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.55),
                      radius: 0.9,
                      colors: [
                        Colors.white12,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

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

            // CHURPPY logo
            Align(
              alignment: const Alignment(0, 0.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: screenW * 0.62,
              ),
            ),

            // GO Button (image)
            Align(
              alignment: const Alignment(0.90, 0.30),
              child: GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, Routes.login),
                child: Image.asset(
                  'assets/images/go_button.png',
                  width: screenW * 0.36,
                ),
              ),
            ),



      
            Positioned(
              bottom: 18,
              left: screenW * 0.17, // adjust spacing
              child: Text(
                "Churppy\nTrademark and Patent pending",
                textAlign: TextAlign.center, // 👈 center align
                style: GoogleFonts.inter(   // 👈 Inter font applied
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
