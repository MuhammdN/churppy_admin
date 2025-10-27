import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drawer.dart';

class OrderDetailScreen extends StatefulWidget {
  final int merchantId;
  final String orderNumber;
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

  /// ✅ NEW
  String? _selectedStatus;

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
            // ✅ Type-safety patch
            data['order']['order_number'] =
                data['order']['order_number'].toString();
            data['order']['total'] = (data['order']['total'] ?? 0).toString();
            data['order']['status'] = data['order']['status'].toString();

            // ✅ Items safe convert
            data['order']['items'] = (data['items'] ?? [])
                .map((i) => {
                      "item_name": (i['item_name'] ?? "").toString(),
                      "quantity": (i['quantity'] ?? "").toString(),
                      "amount": (i['amount'] ?? "").toString(),
                    })
                .toList();

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
    switch (status.toString()) {
      case "0":
        return "Pending";
      case "1":
        return "Delivered";
      case "2":
        return "Cancelled";
      default:
        return "Unknown";
    }
  }

  /// ✅ Status color mapping
  Color _getStatusColor(String status) {
    switch (status) {
      case "0":
        return Colors.orange;
      case "1":
        return Colors.purple;
      case "2":
        return Colors.red;
      default:
        return Colors.white;
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
                                /// ✅ Header
                                Container(
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

                                Divider(
                                  thickness: 2,
                                  color: Colors.grey.shade300,
                                ),

                                /// ✅ Back + Title
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 6),
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

                                /// ✅ Order Info
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
                                                  fontWeight:
                                                      FontWeight.w500),
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              "Date: ${_orderData!['order_date']} ${_orderData!['order_time']}",
                                              style:
                                                  const TextStyle(fontSize: 12),
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

                                /// ✅ Items Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "ORDER ITEMS DETAIL",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.purple,
                                        ),
                                      ),
                                      SizedBox(height: 14),
                                      Row(
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
                                    ],
                                  ),
                                ),
                                const Divider(),

                                /// ✅ Item List
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Column(
                                    children: [
                                      ...(_orderData!['items'] as List)
                                          .map((item) {
                                        return _buildOrderRow(
                                          item['item_name'].toString(),
                                          item['quantity'].toString(),
                                          "\$${item['amount'].toString()}",
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),

                                const Divider(),

                                /// ✅ Total
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Text(
                                      "Total: \$${_orderData!['total']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                /// ✅ Status Dropdown
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "Action / Change Status",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              _selectedStatus ??
                                                  _orderData!['status']),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButton<String>(
                                          value: _selectedStatus ??
                                              _orderData!['status'],
                                          underline: const SizedBox(),
                                          dropdownColor: Colors.lightGreen,
                                          icon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white),
                                          style: const TextStyle(
                                              color: Colors.white),
                                          onChanged: (value) {
                                            setState(
                                                () => _selectedStatus = value);
                                          },
                                          items: const [
                                            DropdownMenuItem(
                                              value: "0",
                                              child: Text("Pending",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            DropdownMenuItem(
                                              value: "1",
                                              child: Text("Delivered",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            DropdownMenuItem(
                                              value: "2",
                                              child: Text("Cancelled",
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                /// ✅ Save Button
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      onPressed: () {
                                        _showConfirmationDialog(
                                          context,
                                          "Save Order",
                                          "Are you sure you want to save this order?",
                                          () => _updateOrderStatus(),
                                        );
                                      },
                                      child: const Text("Save",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
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

  /// 🔁 Order Row
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
    BuildContext context,
    String title,
    String message,
    Function onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
              onConfirm();
            },
             child: const Text("Confirm", 
                style: TextStyle(color: Colors.white)), 
          ),
        ],
      ),
    );
  }

  /// ✅ Save Status API
  Future<void> _updateOrderStatus() async {
    try {
      final url =
          Uri.parse("https://churppy.eurekawebsolutions.com/api/order_detail.php");

      final response = await http.post(url, body: {
        "update": "1",
        "order_number": widget.orderNumber,
        "status": _selectedStatus.toString(),
      });

      final data = jsonDecode(response.body);

      if (data['status'] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order status updated"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchOrderDetail();
      }
    } catch (e) {
      print("❌ Update Error: $e");
    }
  }
}
