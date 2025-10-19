import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'drawer.dart';

class PackageModel {
  final int packageId;
  final String packageName;
  final String churppyAlerts;
  final String customAlerts;
  final String services;
  final String menuOnServices;
  final String monthly;
  final String annualSave;
  final String selectPlan;

  PackageModel({
    required this.packageId,
    required this.packageName,
    required this.churppyAlerts,
    required this.customAlerts,
    required this.services,
    required this.menuOnServices,
    required this.monthly,
    required this.annualSave,
    required this.selectPlan,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageId: int.tryParse(json['package_id'].toString()) ?? 0,
      packageName: json['package_name'] ?? '',
      churppyAlerts: json['churppy_alerts'] ?? '',
      customAlerts: json['custom_alerts'] ?? '',
      services: json['services'] ?? '',
      menuOnServices: json['menu_on_services'] ?? '',
      monthly: json['monthly'] ?? '',
      annualSave: json['annual_save'] ?? '',
      selectPlan: json['select_plan'].toString(),
    );
  }
}

class ChurppyPlansScreen extends StatefulWidget {
  const ChurppyPlansScreen({super.key});

  @override
  State<ChurppyPlansScreen> createState() => _ChurppyPlansScreenState();
}

class _ChurppyPlansScreenState extends State<ChurppyPlansScreen> {
  final Color purple = const Color(0xFF804692);
  final Color green = const Color(0xFF1CC019);

  List<PackageModel> packages = [];
  bool isLoading = true;
  bool isSaving = false;

  String? merchantId;
  int? selectedPackageId;

  /// user choice (monthly / annual)
  String _selectedPlanType = 'monthly';

  @override
  void initState() {
    super.initState();
    _loadMerchantId();
    fetchPackages();
  }

  Future<void> _loadMerchantId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      merchantId = prefs.getString("merchant_id");
    });
    debugPrint("✅ Loaded merchant_id: $merchantId");
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http.get(
        Uri.parse("https://churppy.eurekawebsolutions.com/api/fetch_packages.php"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "success") {
          setState(() {
            packages = (data["data"] as List)
                .map((e) => PackageModel.fromJson(e))
                .toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
    }
  }

  /// 🔹 Stripe amount (monthly/annual in cents) — annual 10% discount applied
  int _getStripeAmount() {
    if (selectedPackageId == null) return 0;
    final selectedPackage = packages.firstWhere(
      (pkg) => pkg.packageId == selectedPackageId,
      orElse: () => packages[0],
    );

    int monthly = 0;
    switch (selectedPackage.packageName.toLowerCase()) {
      case "ground":
        monthly = 49;
        break;
      case "aspire":
        monthly = 129;
        break;
      case "supreme":
        monthly = 399;
        break;
    }

    if (_selectedPlanType == 'annual') {
      final annual = monthly * 12 * 0.9; // ✅ 10% OFF
      return (annual.round()) * 100;
    } else {
      return monthly * 100;
    }
  }

  /// 🔹 DB amount (monthly/annual in USD) — annual 10% discount applied
  int _getDbAmount() {
    if (selectedPackageId == null) return 0;
    final selectedPackage = packages.firstWhere(
      (pkg) => pkg.packageId == selectedPackageId,
      orElse: () => packages[0],
    );

    int monthly = 0;
    switch (selectedPackage.packageName.toLowerCase()) {
      case "ground":
        monthly = 49;
        break;
      case "aspire":
        monthly = 129;
        break;
      case "supreme":
        monthly = 399;
        break;
    }

    if (_selectedPlanType == 'annual') {
      return (monthly * 12 * 0.9).round();
    } else {
      return monthly;
    }
  }

  Future<String?> _createPaymentIntent(int amount) async {
    try {
      final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/create_payment_intent.php");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount, "currency": "usd"}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["client_secret"];
      } else {
        debugPrint("❌ Status: ${response.statusCode}");
        debugPrint("❌ Body: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return null;
    }
  }

  /// 🔹 Show dialog to select Monthly/Annual before payment
  Future<void> _selectPlanTypeDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Choose Plan Type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: "monthly",
                groupValue: _selectedPlanType,
                onChanged: (v) {
                  setStateDialog(() => _selectedPlanType = v ?? 'monthly');
                },
                title: const Text("Monthly"),
              ),
              RadioListTile<String>(
                value: "annual",
                groupValue: _selectedPlanType,
                onChanged: (v) {
                  setStateDialog(() => _selectedPlanType = v ?? 'annual');
                },
                title: const Text("Annual (10% OFF)"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                savePlan();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> savePlan() async {
    if (merchantId == null || selectedPackageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merchant ID or package not selected")),
      );
      return;
    }

    final stripeAmount = _getStripeAmount();
    final dbAmount = _getDbAmount();

    if (stripeAmount <= 0 || dbAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid package or amount")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final clientSecret = await _createPaymentIntent(stripeAmount);
      if (clientSecret == null) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create payment intent")),
        );
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Churppy',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      final response = await http.post(
        Uri.parse("https://churppy.eurekawebsolutions.com/api/fetch_packages.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "merchant_id": merchantId,
          "package_id": selectedPackageId,
          "amount": dbAmount,
          "plan_type": _selectedPlanType, // ✅ New field
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint("📥 Save Plan Response: $data");

      if (data["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Plan saved"),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, "/login");
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Failed to save plan"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving plan: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 480.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardW),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'SELECT YOUR PLAN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _plansTable(),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  minimumSize: const Size(double.infinity, 60),
                                ),
                                onPressed: () {
                                  if (selectedPackageId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Please select a plan")),
                                    );
                                    return;
                                  }
                                  _selectPlanTypeDialog();
                                },
                                child: const Text(
                                  "GO GET CHURPPY",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isSaving)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {},
            child: Image.asset('assets/icons/menu.png', width: 40),
          ),
          Image.asset('assets/images/logo.png', width: 100),
          Image.asset('assets/images/truck.png', width: 60),
        ],
      ),
    );
  }

  Widget _plansTable() {
    if (packages.length < 3) {
      return const Text("Plans not available");
    }

    final essentials = packages[0];
    final business = packages[1];
    final enterprise = packages[2];

    final border = TableBorder.all(color: Colors.black54, width: 1);
    final headerBg = const Color(0xFFE7F6EA);

    Text _th(String t, {Color? color}) => Text(
          t,
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: color ?? Colors.black),
          textAlign: TextAlign.center,
        );

    Widget _cell(String t,
        {FontWeight w = FontWeight.w600,
        TextAlign ta = TextAlign.center,
        Color? c}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          t,
          style: TextStyle(fontSize: 12.5, fontWeight: w, color: c ?? Colors.black),
          textAlign: ta,
        ),
      );
    }

    return Table(
      border: border,
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          _cell(''),
          _th(essentials.packageName),
          _th(business.packageName, color: purple),
          Container(
              color: headerBg,
              child: _th(enterprise.packageName, color: green)),
        ]),
        TableRow(children: [
          _cell('Churppy Alerts', w: FontWeight.w700, c: purple),
          _cell(essentials.churppyAlerts),
          _cell(business.churppyAlerts),
          _cell(enterprise.churppyAlerts),
        ]),
        TableRow(children: [
          _cell('Custom Alerts'),
          _cell(essentials.customAlerts),
          _cell(business.customAlerts),
          _cell(enterprise.customAlerts),
        ]),
        TableRow(children: [
          _cell('Menu/Service'),
          _cell(essentials.services),
          _cell(business.services),
          _cell(enterprise.services),
        ]),
        TableRow(children: [
          _cell('Menu on Churppy'),
          _cell(essentials.menuOnServices),
          _cell(business.menuOnServices),
          _cell(enterprise.menuOnServices),
        ]),
        TableRow(children: [
          _cell('Monthly', w: FontWeight.w800),
          _cell(essentials.monthly, w: FontWeight.w900),
          _cell(business.monthly, w: FontWeight.w900),
          _cell(enterprise.monthly, w: FontWeight.w900),
        ]),
        TableRow(children: [
          _cell('Annual Save 10%', w: FontWeight.w800, c: green),
          _cell(essentials.annualSave),
          _cell(business.annualSave),
          _cell(enterprise.annualSave),
        ]),
        TableRow(children: [
          _cell('SELECT PLAN', w: FontWeight.w800),
          _selectCell(packageId: essentials.packageId),
          _selectCell(packageId: business.packageId),
          _selectCell(packageId: enterprise.packageId),
        ]),
      ],
    );
  }

  TableCell _selectCell({required int packageId}) {
    return TableCell(
      child: Center(
        child: Radio<int>(
          value: packageId,
          groupValue: selectedPackageId,
          onChanged: (v) {
            setState(() => selectedPackageId = v);
          },
          activeColor: green,
        ),
      ),
    );
  }
}
