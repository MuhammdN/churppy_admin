import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'drawer.dart'; // ✅ Drawer import

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  bool _loading = true;
  bool _error = false;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  /// ✅ Fetch user_id (merchant_id) from SharedPreferences
  Future<void> _fetchPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final merchantId = prefs.getString("user_id");

      debugPrint("🟩 Loaded merchant(user)_id => $merchantId");

      if (merchantId == null) {
        setState(() {
          _error = true;
          _loading = false;
        });
        return;
      }

      final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/payments.php?merchant_id=$merchantId",
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['status'] == "success") {
          setState(() {
            _payments = data['payments'];
            _loading = false;
          });
        } else {
          setState(() {
            _error = true;
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade600;
      case 'failed':
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChurppyDrawer(), // ✅ Drawer added
      body: SafeArea(
        child: Column(
          children: [
            /// 🔰 HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Image.asset(
                        "assets/icons/menu.png",
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    "assets/images/logo.png",
                    height: 26,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Image.asset(
                      "assets/images/truck.png",
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            /// 🟢 Title Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: Colors.black, size: fs(20)),
                  ),
                  Text(
                    'Payment Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: fs(16),
                    ),
                  ),
                  SizedBox(width: fs(20)), // ✅ Placeholder to balance
                ],
              ),
            ),

            /// 📄 TABLE HEADER
            Container(
              color: Colors.grey.shade100,
              padding: EdgeInsets.symmetric(vertical: fs(10), horizontal: fs(15)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Order ID',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Date',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Amount',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                  ),
                ],
              ),
            ),

            /// 🧾 PAYMENT DATA
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error
                      ? Center(
                          child: Text(
                          "Error loading payments!",
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: fs(15),
                              fontWeight: FontWeight.w500),
                        ))
                      : _payments.isEmpty
                          ? Center(
                              child: Text(
                                "No payments found.",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: fs(15),
                                    fontWeight: FontWeight.w500),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _payments.length,
                              itemBuilder: (context, index) {
                                final p = _payments[index];

                                final orderId = p['order_number']?.toString() ?? "—";
                                final date = p['order_date']?.toString() ?? "";
                                final amount = p['amount']?.toString() ?? "0";
                                final status = p['payment_status'].toString();

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: fs(10), horizontal: fs(15)),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade300, width: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(orderId,
                                            style: TextStyle(fontSize: fs(13))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(date,
                                            style: TextStyle(fontSize: fs(13))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text("\$$amount",
                                            style: TextStyle(fontSize: fs(13))),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: fs(8), vertical: fs(4)),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(fs(6)),
                                          ),
                                          child: Text(
                                            status,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.w600,
                                              fontSize: fs(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
