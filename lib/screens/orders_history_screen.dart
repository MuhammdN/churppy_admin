import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'OrderDetailScreen.dart';
import 'drawer.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int? _merchantId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadMerchantIdAndFetchOrders();
  }

  /// ✅ SharedPreferences se merchant_id fetch karna
  Future<void> _loadMerchantIdAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString("user_id"); // merchant_id stored as user_id

    if (savedId != null) {
      setState(() {
        _merchantId = int.tryParse(savedId);
      });
      print("✅ Merchant ID (SharedPreferences): $_merchantId");

      if (_merchantId != null) {
        await _fetchOrders(_merchantId!);
      }
    } else {
      print("⚠️ No merchant_id found in SharedPreferences");
    }
  }

  /// ✅ API se orders fetch
  Future<void> _fetchOrders(int merchantId) async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/orders.php?merchant_id=$merchantId");

      final response = await http.get(url);

      print("🔗 API URL: $url");
      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List orders = data['orders'];
          setState(() {
            _orders = orders.map<Map<String, dynamic>>((o) {
              return {
                "order_number": o['order_number']?.toString() ?? "",
                "date": o['order_date']?.toString() ?? "",
                "amount": o['amount']?.toString() ?? "0",
                "status": o['status']?.toString() ?? "",
                "customer_id": o['customer_id']?.toString() ?? "",
              };
            }).toList();
          });
        } else {
          print("⚠️ API Error: ${data['message']}");
        }
      }
    } catch (e) {
      print("❌ Error fetching orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChurppyDrawer()),
                            );
                          },
                          child: Image.asset('assets/icons/menu.png',
                              width: 36, height: 36),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Image.asset(
                    'assets/images/truck.png',
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 2,
            color: Colors.grey.shade300,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Back + Title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade300,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              size: 20, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Orders History",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Header Row
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 2,
                          child: Text("Order No",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      const Expanded(
                          flex: 2,
                          child: Text("Date",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                     
                      const Expanded(
                          flex: 2,
                          child: Text("Status",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12))),
                      const Expanded(
                        flex: 1,
                        child: Text(
                          "Detail",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orders List
                Expanded(
                  child: _orders.isEmpty
                      ? const Center(child: Text("No orders found"))
                      : ListView.builder(
                          itemCount: _orders.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            Color statusColor;
                            switch (order['status']) {
                              case 'Pending':
                                statusColor = Colors.green;
                                break;
                              case 'Delivered':
                                statusColor = Colors.purple;
                                break;
                              case 'Cancel':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 9, horizontal: 5),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Row(
                                children: [
                                 Expanded(
  flex: 2,
  child: Text(
    order['order_number'],
    style: const TextStyle(
      fontSize: 10,            // 👈 chota font
      fontWeight: FontWeight.w600,
      overflow: TextOverflow.ellipsis,
    ),
  ),
),

                                  Expanded(
                                      flex: 2,
                                      child: Text(order['date'])),
                                

                                  // Status
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order['status'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // View Button
                                  Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final orderNumber =
                                            order['order_number'];
                                        final merchantId = _merchantId;
                                        final customerId =
                                            int.tryParse(order['customer_id']);

                                        if (orderNumber != null &&
                                            merchantId != null) {
                                          print("🟣 Merchant ID: $merchantId");
                                          print("🟣 Customer ID: $customerId");
                                          print(
                                              "🟣 Order Number: $orderNumber");

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderDetailScreen(
                                                merchantId: merchantId,
                                                customerId: customerId ?? 0,
                                                orderNumber: orderNumber,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 6),
                                        minimumSize: const Size(40, 30),
                                      ),
                                      child: const Text(
                                        "View",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 12,
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
    );
  }
}
