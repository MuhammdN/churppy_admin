import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:churppy_admin/screens/signup_screen.dart';
class ChurppyDifference extends StatelessWidget {
  const ChurppyDifference({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.9, 1.2);
    double fs(double x) => x * scale;

    const purple = Color(0xFF8A3FFC);
    const green = Color(0xFF8DC63F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(25)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: fs(120),
                  ),
                  SizedBox(height: fs(20)),

                  // Title
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "The ",
                          style: GoogleFonts.lemon(
                            color: Colors.black,
                            fontSize: fs(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: "CHURPPY ",
                          style: GoogleFonts.lemon(
                            color: Colors.purple,
                            fontSize: fs(22),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(
                          text: "Difference",
                          style: GoogleFonts.lemon(
                            color: Colors.black,
                            fontSize: fs(20),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: fs(25)),

                  // Paragraphs
                  _sectionTitle("Why we created Churppy?", fs),
                  _sectionText(
                    "Have you ever been at work and one of your co-workers had food that smelled amazing and thought to yourself, if I knew that they were ordering, I would’ve ordered something too. Well, now you can without being nosey! Sign up for Churppy Alerts and when a restaurant is coming to your office, you can order your own individual order - but be quick - time is ticking!",
                    fs,
                  ),

                  _sectionTitle("Locate Foodtrucks, Your Local Mobile Business and Service Vendor", fs),
                  _sectionText(
                    "Missing your favorite foodtruck, or local bbq smoker guy/gal, your mobile pet groomer or need a small repair, with an instant Churppy Alert, you can know where and when they will be in your area to stop by, grab a plate or get a service call in.",
                    fs,
                  ),

                  _sectionTitle("Real-time Churppy Alerts", fs),
                  _sectionText(
                    "Late night munchies, work finds you on the other side of town, or maybe you just landed in a new city, find out what’s open or has closing deals with the Churppy Difference!!",
                    fs,
                  ),

                  _sectionTitle("Bundle Deliveries and Services", fs),
                  _sectionText(
                    "Churppy Chains helps restaurants and business to bundle individual orders together over a short period of time so that they can avoid going back and forth to the same office building or dorm. This saves gas, time, and helps keep our planet green!",
                    fs,
                  ),

                  _sectionTitle("Upload Menu", fs),
                  _sectionText(
                    "Small businesses want to cut their overhead not add to it. Churppy allows businesses to post either a pdf or a full customer ordering platform.",
                    fs,
                  ),

                  _sectionTitle("Last Call Deals and Instant Churppy Alerts", fs),
                  _sectionText(
                    "Find Active Churppy Alerts with deals to concerts, basketball and football games, tennis matches, join a team match for golf or pickelball! Save your favorite vendor and Share Alerts with Friend, Family and Co-workers.",
                    fs,
                  ),

                  _sectionTitle("Businesses - Customize Your Alerts", fs),
                  _sectionText(
                    "Our creative team can create unique Churppy Alerts just for you that meet your needs. Contact Us for more details.",
                    fs,
                  ),

                  SizedBox(height: fs(40)),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _button(
                          "Foodtrucks | Mobile | Customer App\nEnter HERE",
                          Colors.purple,
                          () {
                            debugPrint("Vendors pressed");
                          },
                        ),
                      ),
                      SizedBox(width: fs(12)),
                      Expanded(
                        child: _button(
                          "Customers\nJOIN | Sign In",
                          green,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: fs(40)),
                ],
              ),
            ),

            // 🔙 Back Arrow Button
            Positioned(
              top: fs(15),
              left: fs(10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String text, double Function(double) fs) {
  return Padding(
    padding: EdgeInsets.only(top: fs(10), bottom: fs(6)),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.lemonada(
          fontSize: fs(15),
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    ),
  );
}

Widget _sectionText(String text, double Function(double) fs) {
  return Padding(
    padding: EdgeInsets.only(bottom: fs(12)),
    child: Text(
      text,
      textAlign: TextAlign.justify,
      style: GoogleFonts.poppins(
        fontSize: fs(12),
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        height: 1.55,
      ),
    ),
  );
}

Widget _button(String text, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.lemonada(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
