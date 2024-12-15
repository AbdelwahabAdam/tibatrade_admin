import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';
import 'package:tibatrade/controllers/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';

class AdminPage3Controller extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  var users = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading(true);
    try {
      QuerySnapshot querySnapshot = await firestore.collection('users').get();
      users.value = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> sendNotification(String deviceToken, String title, String message, String userEmail) async {
    try {
      // Generate a new notification ID
      String notificationId = _databaseReference.child('notifications').push().key!;

      // Push notification details to Firebase Realtime Database
      await _databaseReference.child('notifications').child(notificationId).set({
        'userdetails': {
          'deviceToken': deviceToken,
          'userEmail': userEmail,
        },
        'message': message,
        'title': title,
        'useremail': userEmail,
        'deviceID': deviceToken,
      });

      print('Notification pushed to Realtime Database successfully');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
class AdminPage3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminPage3Controller controller = Get.put(AdminPage3Controller());

    return Scaffold(
      appBar: AppBar(
        title: Text('Send notification to a user'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (controller.users.isEmpty) {
          return Center(child: Text('No users found'));
        } else {
          return ListView.builder(
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              var user = controller.users[index];
              return ListTile(
                title: Text(user['email']),
                subtitle: Text(user['deviceToken'] ?? 'No device token'),
                trailing: ElevatedButton(
                  onPressed: () {
                    if (user['deviceToken'] != null) {
                      // Call sendNotification with required parameters
                      controller.sendNotification(
                        user['deviceToken'],
                        'Notification Title', // Example title
                        'This is the notification message.', // Example message
                        user['email'],
                      );
                      Get.snackbar('Notification', 'Notification sent to ${user['email']}');
                    } else {
                      Get.snackbar('Error', 'No device token found for ${user['email']}');
                    }
                  },
                  child: Text('Send Notification'),
                ),
              );
            },
          );
        }
      }),
    );
  }
}