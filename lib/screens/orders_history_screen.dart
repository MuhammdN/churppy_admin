import 'dart:convert';
import 'package:churppy_admin/screens/profile.dart';
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

  // ✅ ADDED FOR PROFILE IMAGE
  String? userId;
  String? profileImage;
  String? firstName;
  String? lastName;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchantIdAndFetchOrders();
    _loadUserId(); // ✅ Load profile data
  }

  /// ✅ Load user_id then fetch profile
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString("user_id");

    debugPrint("✅ Logged-in User ID (OrdersHistory): $savedUserId");

    setState(() {
      userId = savedUserId;
    });

    if (savedUserId != null) {
      await _fetchUserProfile(savedUserId);
    }
    
    setState(() {
      _profileLoading = false;
    });
  }

  /// ✅ Fetch User Profile
  Future<void> _fetchUserProfile(String uid) async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/user.php?id=$uid");

    try {
      final res = await http.get(url);
      debugPrint("📥 Profile Response (OrdersHistory): ${res.body}");

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);

        if (result["status"] == "success") {
          final data = result["data"];

          setState(() {
            profileImage = data["image"];     // ✅ full URL already
            firstName = data["first_name"];
            lastName = data["last_name"];
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Profile Fetch Error (OrdersHistory): $e");
    }
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
      drawer: const ChurppyDrawer(), // ✅ Drawer added
      body: SafeArea(
        child: Column(
          children: [
            /// 🔰 HEADER - UPDATED WITH PROFILE IMAGE
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
                  
                  /// ✅ PROFILE IMAGE INSTEAD OF TRUCK ICON
                  _profileLoading 
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: profileImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    profileImage!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) {
                                      return const Icon(Icons.person,
                                          size: 40, color: Colors.grey);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 40, color: Colors.grey),
                        ),
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 2,
              color: Colors.grey.shade300,
            ),

            // Back + Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _orders.isEmpty
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
      ),
    );
  }
}