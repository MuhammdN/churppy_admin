import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drawer.dart';

class OrderDetailScreen extends StatefulWidget {
  final int merchantId;
  final String orderNumber ;
  final int customerId;

  const OrderDetailScreen({
    super.key,
    required this.merchantId,
    required this.customerId,
    required this.orderNumber,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/order_detail.php?order_number=${widget.orderNumber}");
      final response = await http.get(url);

      print("🔗 API URL: $url");
      print("📥 Status Code: ${response.statusCode}");
      print("📥 Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _orderData = data['order'];
          });
        } else {
          print("⚠️ API Error: ${data['message']}");
        }
      }
    } catch (e) {
      print("❌ Error fetching order detail: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Convert status code to text
  String _mapStatus(dynamic status) {
    if (status == null) return "Unknown";
    switch (status.toString()) {
      case "0":
        return "Pending";
      case "1":
        return "Delivered";
      case "2":
        return "Cancelled";
      default:
        return status.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const ChurppyDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orderData == null
            ? const Center(child: Text("No order details found"))
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints:
                BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔰 Top Header Row
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Builder(
                              builder: (ctx) => GestureDetector(
                                onTap: () =>
                                    Scaffold.of(ctx).openDrawer(),
                                child: Image.asset(
                                    "assets/icons/menu.png",
                                    width: 32,
                                    height: 32),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset("assets/images/logo.png",
                                height: 26),
                            const Spacer(),
                            Flexible(
                              child: Image.asset(
                                "assets/images/truck.png",
                                height: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(
                        height: 1,
                        thickness: 2,
                        color: Colors.grey.shade300,
                      ),

                      /// 🔰 Header + Info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 10, 16, 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade300,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    size: 20, color: Colors.black),
                                onPressed: () =>
                                    Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Orders Details",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Order No: ${_orderData!['order_number']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    "Date: ${_orderData!['order_date'].toString()} ${_orderData!['order_time'].toString()}",
                                    style: const TextStyle(
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                "Customer Name: ${_orderData!['customer_name'] ?? ''}"),
                            Text(
                                "Email: ${_orderData!['email'] ?? ''}"),
                            Text(
                                "Address: ${_orderData!['address'] ?? ''}"),
                            Text(
                                "Phone: ${_orderData!['contact_no'] ?? ''}"),
                          ],
                        ),
                      ),

                      const Divider(),

                      /// 🔰 Order Items + Details + Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "ORDER ITEMS DETAIL",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Row(
                              children: [
                                Expanded(
                                    flex: 4,
                                    child: Text("Item Name",
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text("Qty",
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Amount",
                                        style: TextStyle(
                                            fontWeight:
                                            FontWeight.bold))),
                              ],
                            ),
                            const Divider(),

                            /// ✅ Dynamic items list
                            ...(_orderData!['items'] as List)
                                .map((item) {
                              return _buildOrderRow(
                                item['item_name'] ?? '',
                                item['quantity'].toString(),
                                "\$${item['amount'].toString()}",
                              );
                            }).toList(),

                            const Divider(),

                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Total: \$${_orderData!['total'].toString()}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                      "Action / Change Status",
                                      style: TextStyle(
                                          fontWeight:
                                          FontWeight.w500)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius:
                                    BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _mapStatus(
                                        _orderData!['status']),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            /// 🔘 Only Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(6)),
                                ),
                                onPressed: () {
                                  _showConfirmationDialog(
                                      context,
                                      "Save Order",
                                      "Are you sure you want to save this order?");
                                },
                                child: const Text("Save",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15)),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔁 Order Row Builder
  static Widget _buildOrderRow(String item, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(item, style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 1,
              child: Text(qty, style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(amount, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// 🔁 Confirm Dialog
  static void _showConfirmationDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "$title confirmed.",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
