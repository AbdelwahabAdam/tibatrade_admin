import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';

class Page2Controller extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  var categories = <Category>[].obs;
  var selectedCategory = Rx<Category?>(null);
  var selectedProduct = Rx<Product?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  void fetchCategories() {
    _firestoreService.getCategoriesWithProducts().listen((fetchedCategories) {
      categories.assignAll(fetchedCategories);
    });
  }

  Future<void> deleteProduct() async {
    if (selectedCategory.value != null && selectedProduct.value != null) {
      await _firestoreService.deleteProduct(selectedCategory.value!.id, selectedProduct.value!.id);
      // Refresh the categories list after deletion
      fetchCategories();
      selectedProduct.value = null;
      selectedCategory.value = null;
    }
  }
}

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Page2Controller controller = Get.put(Page2Controller());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Delete Product from Category'),
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
                  controller.selectedProduct.value = null;
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
            Text('Select Product:'),
            Obx(() {
              if (controller.selectedCategory.value == null) {
                return Text('Please select a category first.');
              }
              var products = controller.selectedCategory.value!.products;
              if (products.isEmpty) {
                return Text('No products available in this category.');
              }
              return DropdownButton<Product>(
                value: controller.selectedProduct.value,
                onChanged: (Product? newValue) {
                  controller.selectedProduct.value = newValue;
                },
                items: products.map((Product product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text(product.name),
                  );
                }).toList(),
              );
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await controller.deleteProduct();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product deleted successfully')),
                );
              },
              child: Text('Delete Product'),
            ),
          ],
        ),
      ),
    );
  }
}