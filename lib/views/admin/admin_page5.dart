import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPage5Controller extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  var categories = <Category>[].obs;
  var selectedCategory = Rx<Category?>(null);
  var productNameController = TextEditingController();
  var productPriceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    var fetchedCategories = await _firestoreService.getCategories();
    categories.assignAll(fetchedCategories);
  }

  Future<void> addProduct() async {
    if (selectedCategory.value != null && productNameController.text.isNotEmpty && productPriceController.text.isNotEmpty) {
      await _firestoreService.addProductToCategory(
        selectedCategory.value!.id,
        productNameController.text,
        double.parse(productPriceController.text),
      );
      productNameController.clear();
      productPriceController.clear();
    }
  }
}


class AdminPage5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminPage5Controller controller = Get.put(AdminPage5Controller());
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    User? user = FirebaseAuth.instance.currentUser;
    String userEmail = user?.email ?? "Email not available";

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // COLUMN THAT WILL CONTAIN THE PROFILE
          Column(
            children:  [
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Junior Product Designer")
            ],
          )
        ],
      ),

    );
  }
}
