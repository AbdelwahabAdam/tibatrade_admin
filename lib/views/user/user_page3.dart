import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';

class Page3Controller extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> populateData() async {
    await _firestoreService.populateRandomData();
  }
}


class Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Page3Controller controller = Get.put(Page3Controller());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Populate Firestore with Random Data'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await controller.populateData();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Random data populated in Firestore')),
            );
          },
          child: Text('Populate Firestore'),
        ),
      ),
    );
  }
}