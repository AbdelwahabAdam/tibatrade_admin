import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';

class AdminPage4Controller extends GetxController {
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


class AdminPage4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminPage4Controller controller = Get.put(AdminPage4Controller());

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product to Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Category:'),
            Obx(() {
              if (controller.categories.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return DropdownButton<Category>(
                value: controller.selectedCategory.value,
                onChanged: (Category? newValue) {
                  controller.selectedCategory.value = newValue;
                },
                items: controller.categories.map((Category category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
              );
            }),
            SizedBox(height: 20),
            TextField(
              controller: controller.productNameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: controller.productPriceController,
              decoration: InputDecoration(labelText: 'Product Price'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await controller.addProduct();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product added successfully')),
                );
              },
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}