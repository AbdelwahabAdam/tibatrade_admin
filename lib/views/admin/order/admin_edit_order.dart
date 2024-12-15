import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminEditOrderController extends GetxController {
  final searchController = TextEditingController();

  var orderList = <Map<String, dynamic>>[].obs; // List to hold all orders
  var filteredOrderList = <Map<String, dynamic>>[].obs; // List to hold filtered orders

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('orders');

  @override
  void onInit() {
    super.onInit();
    setupRealtimeListener(); // Set up real-time listener
    searchController.addListener(() => filterOrders());
  }

  // Method to set up real-time listener for Firebase Realtime Database
  void setupRealtimeListener() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        orderList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredOrderList.value = orderList; // Initially set filtered list to full list
      } else {
        orderList.clear(); // If no data, clear the list
        filteredOrderList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch orders: $error');
    });
  }

  // Filter orders based on search input
  void filterOrders() {
    final query = searchController.text.toLowerCase();
    filteredOrderList.value = orderList.where((order) {
      final orderName = order['data']['user_name'].toString().toLowerCase();
      return orderName.contains(query);
    }).toList();
  }

  // Method to update the order in Firebase
  void updateOrder(String id, Map<String, dynamic> updatedOrder) {
    dbRef.child(id).update(updatedOrder).then((_) {
      // Get.snackbar('Success', 'Order updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update Order: $error');
    });
  }

  // Method to update item status in the order
  void updateItemStatus(String orderId, String itemId, String newStatus) {
    dbRef.child('$orderId/items/$itemId/status').set(newStatus).then((_) {
      // Get.snackbar('Success', 'Item status updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update item status: $error');
    });
  }
}

class AdminEditOrder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditOrderController controller = Get.put(AdminEditOrderController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Orders'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Order',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of orders
          Expanded(
            child: Obx(() {
              if (controller.filteredOrderList.isEmpty) {
                return Center(child: Text('No Order found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredOrderList.length,
                itemBuilder: (context, index) {
                  final order = controller.filteredOrderList[index]['data'];
                  final orderId = controller.filteredOrderList[index]['id'];

                  return ListTile(
                    title: Text(order['user_name']),
                    subtitle: Text('Order ID: $orderId\nStatus: ${order['status']}'),
                    onTap: () => Get.to(() => EditOrderPage(orderId: orderId, orderData: order)),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class EditOrderPage extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  EditOrderPage({required this.orderId, required this.orderData});

  @override
  _EditOrderPageState createState() => _EditOrderPageState();
}


class _EditOrderPageState extends State<EditOrderPage> {
  final AdminEditOrderController controller = Get.find();

  // Holds the new statuses for each item
  Map<String, String> itemStatuses = {};
  String? selectedOrderStatus;  // Holds the selected order status

  @override
  void initState() {
    super.initState();
    // Initialize item statuses and order status with current values
    final items = Map<String, dynamic>.from(widget.orderData['items'] ?? {});
    items.forEach((key, value) {
      final itemData = Map<String, dynamic>.from(value);
      itemStatuses[key] = itemData['status'] ?? 'available';
    });

    // Initialize order status
    selectedOrderStatus = widget.orderData['status'];
  }

  @override
  Widget build(BuildContext context) {
    final items = Map<String, dynamic>.from(widget.orderData['items'] ?? {});

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Order'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display non-editable order details
            Text('Order Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Order ID: ${widget.orderId}'),
            Text('Customer Name: ${widget.orderData['user_name'] ?? 'Unknown'}'),
            Text('Order Date: ${widget.orderData['date'] ?? 'Unknown'}'),
            Text('Current Status: ${ widget.orderData['status']}'),
            SizedBox(height: 20),

            // Dropdown to update order status
            Text('Order Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedOrderStatus,
              onChanged: (newStatus) {
                setState(() {
                  selectedOrderStatus = newStatus;
                });
              },
              items: ['pending', 'completed', 'cancelled']
                  .map((status) => DropdownMenuItem(
                child: Text(status),
                value: status,
              ))
                  .toList(),
            ),
            SizedBox(height: 20),

            // Display each item's status with dropdown
            Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...items.entries.map((entry) {
              final itemId = entry.key;
              final itemData = Map<String, dynamic>.from(entry.value);

              return ListTile(
                title: Text(itemData['product_name'] ?? 'Unnamed Product'),
                subtitle: Text('Quantity: ${itemData['quantity'] ?? 0}\nCurrent Status: ${itemData['status'] ?? 'unknown'}'),
                trailing: DropdownButton<String>(
                  value: itemStatuses[itemId],
                  onChanged: (newStatus) {
                    setState(() {
                      itemStatuses[itemId] = (newStatus ?? itemStatuses[itemId])!;
                    });
                  },
                  items: ['available', 'out_of_stock']
                      .map((status) => DropdownMenuItem(
                    child: Text(status),
                    value: status,
                  ))
                      .toList(),
                ),
              );
            }).toList(),

            // Update button to update both order status and all item statuses
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {

                // Update the order status first
                controller.updateOrder(widget.orderId, {'status': selectedOrderStatus});

                // Update the statuses of all items
                items.forEach((itemId, _) {
                  controller.updateItemStatus(widget.orderId, itemId, itemStatuses[itemId]!);
                });
                Get.back();


                setState(() {
                    widget.orderData['status'] = selectedOrderStatus;
                    Get.snackbar('Success', 'Order and item statuses updated successfully!');
                  });

              },
              child: Text('Update Order and Item Statuses'),
            ),
          ],
        ),
      ),
    );
  }
}
