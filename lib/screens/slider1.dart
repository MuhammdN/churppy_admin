import 'dart:async';

import 'package:churppy_admin/screens/churppy_difference.dart';
import 'package:churppy_admin/screens/login.dart';
import 'package:churppy_admin/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Slider1 extends StatelessWidget {
  const Slider1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            /// MAIN CONTENT
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final scale = (w / 390).clamp(0.85, 1.25);
                double fs(double x) => x * scale;

                const cardBg = Color(0xFFF1FBE2);
                const orange = Color(0xFFFF9633);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: fs(20),
                      vertical: fs(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logo.png', width: fs(120)),
                        SizedBox(height: fs(8)),

                        // 🟡 MAIN CARD
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(fs(25)),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: fs(20),
                            vertical: fs(25),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'DISCOVER CHURPPY',
                                style: GoogleFonts.lemon(
                                  fontSize: fs(22),
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: fs(10)),

                              Text(
                                'A consumer-driven crowd sourcing platform offering Smart Delivery',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: fs(14),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: fs(18)),

                              Text(
                                'Why you’ll love CHURPPY!',
                                style: GoogleFonts.lemon(
                                  fontSize: fs(16),
                                  fontWeight: FontWeight.w800,
                                  color: orange,
                                ),
                              ),
                              SizedBox(height: fs(5)),

                              /// 🔥 CONTENT + IMAGE + INFO AUTO SLIDER
                              _AutoContentAndInfoSlider(fs: fs),

                              SizedBox(height: fs(3)),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (_) => Padding(
                                    padding: EdgeInsets.symmetric(horizontal: fs(15)),
                                    child: Container(
                                      width: fs(60),
                                      height: fs(2),
                                      decoration: BoxDecoration(
                                        color: orange,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: fs(30)),

                              _buildButton(
                                text: "Sign Up",
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildButton(
                                text: "Login",
                                color: const Color(0xFF8DC63F),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildButton(
                                text: "Foodtrucks | Mobile | Vendors (Business App)",
                                color: Colors.pink,
                                onTap: () {},
                              ),
                              const SizedBox(height: 12),
                              _buildButton(
                                text: "Explore More → The Churppy Difference",
                                color: Colors.lightBlue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChurppyDifference(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenH * 0.12), // space for bottom arrow
                      ],
                    ),
                  ),
                );
              },
            ),

            /// 🔙 BACK ARROW (BOTTOM LEFT)
            Positioned(
              bottom: 20,
              left: 20,
              child: InkWell(
                onTap: () => Navigator.pop(context), // ✅ back works
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black12,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔥 AUTO CONTENT + IMAGE + INFO SLIDER
/// ✔ PRESS & HOLD = PAUSE
/// ✔ RELEASE = RESUME
class _AutoContentAndInfoSlider extends StatefulWidget {
  final double Function(double) fs;
  const _AutoContentAndInfoSlider({required this.fs});

  @override
  State<_AutoContentAndInfoSlider> createState() =>
      _AutoContentAndInfoSliderState();
}

class _AutoContentAndInfoSliderState
    extends State<_AutoContentAndInfoSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_paused) return;
      _index = (_index + 1) % 3;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.fs;

    return GestureDetector(
      onTapDown: (_) => setState(() => _paused = true),
      onTapUp: (_) => setState(() => _paused = false),
      onTapCancel: () => setState(() => _paused = false),
      child: SizedBox(
        height: fs(300),
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _slide(
              fs,
              title: 'Find great food + services faster',
              bullets: [
                'Locate your favorite Foodtruck, mobile service or business',
                'Map Locator',
                'Instantly know When and Where they are',
              ],
              info:
                  "Tee’s Tasty Kitchen will be located at 33 Churppy Rd, Churppy, 33333 on October 9th from 11am to 6pm. Look Forward to Seeing You! ",
              time: "1hr 22mins left",
            ),
            _slide(
              fs,
              title: 'Know When+ Where',
              bullets: [
                'Receive Instant Churppy Alerts',
                'Get Real-time Offers',
                'Find Last Minute Deals',
              ],
              info:
                  "We Cooked Too Much!\nStop By Tee’s Tasty Kitchen, 101\nChurppy Corner,33333 by 9pm tonight and receive 25% OFF!!  ",
              time: "1hr 22mins left",
            ),
            _slide(
              fs,
              title: 'Churppy Chain',
              bullets: [
                'Allows vendors to Bundle Individual Orders together When they are In Your Area',
                'Stops back and forth to same office, dorm, etc.',
                'Saves Gas + Time',
                'Creates a Buzz',
              ],
              info:
                  "Someone in your area just ordered from Tee’s Tasty Kitchen, 101 Churppy College Court. Help Us Bundle Orders By Placing Your Own Order NOW! ",
              time: "Only 8 minutes left",
            ),
          ],
        ),
      ),
    );
  }

  Widget _slide(
    double Function(double) fs, {
    required String title,
    required List<String> bullets,
    required String info,
    required String time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lemon(
            fontSize: fs(15),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: fs(10)),
        ...bullets.map(
          (b) => Padding(
            padding: EdgeInsets.only(bottom: fs(6)),
            child: Text(
              "• $b",
              style: GoogleFonts.poppins(
                fontSize: fs(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: fs(18)),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fs(12)),
            border: Border.all(color: Colors.black26),
            color: Colors.white,
          ),
          padding: EdgeInsets.all(fs(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/truck.png',
                width: fs(80),
                height: fs(80),
                fit: BoxFit.contain,
              ),
              SizedBox(width: fs(10)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: fs(11.5),
                      color: Colors.black,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: info),
                      TextSpan(
                        text: time,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// BUTTON (UNCHANGED)
Widget _buildButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
