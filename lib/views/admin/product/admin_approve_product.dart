import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker

class AdminApproveProductController extends GetxController {
  final searchController = TextEditingController();

  var productList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredProductList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('products');

  @override
  void onInit() {
    super.onInit();
    setupRealtimeListener(); // Set up real-time listener
    searchController.addListener(() => filterProducts());
  }

  // Method to set up real-time listener for Firebase Realtime Database
  void setupRealtimeListener() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        productList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredProductList.value = productList; // Initially set filtered list to full list
      } else {
        productList.clear(); // If no data, clear the list
        filteredProductList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterProducts() {
    final query = searchController.text.toLowerCase();
    filteredProductList.value = productList.where((product) {
      final productName = product['data']['name_english'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateProduct(String id, Map<String, dynamic> updatedProduct) {
    dbRef.child(id).update(updatedProduct).then((_) {
      Get.snackbar('Success', 'Product updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update product: $error');
    });
  }
}

class AdminApproveProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminApproveProductController controller = Get.put(AdminApproveProductController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Products'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of products
          Expanded(
            child: Obx(() {
              if (controller.filteredProductList.isEmpty) {
                return Center(child: Text('No products found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredProductList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProductList[index]['data'];
                  final productId = controller.filteredProductList[index]['id'];

                  return ListTile(
                    title: Text(product['name_english']),
                    subtitle: Text('Category: ${product['category_name']}'),
                    onTap: () => Get.to(() => EditProductPage(productId: productId, productData: product)),
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

class EditProductPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditProductPage({required this.productId, required this.productData});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final AdminApproveProductController controller = Get.find();

  // Controllers for each field
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();
  final manufArabicController = TextEditingController();
  final manufEnglishController = TextEditingController();
  final categoryNameController = TextEditingController();
  final lowestQuantityController = TextEditingController();
  final highestQuantityController = TextEditingController();
  final primaryPriceController = TextEditingController();
  final secondaryPriceController = TextEditingController();
  final primaryStockController = TextEditingController();
  final secondaryStockController = TextEditingController();
  final primaryWarningController = TextEditingController();
  final secondaryWarningController = TextEditingController();
  final offerController = TextEditingController();

  var isApprovedbyAdmin = false.obs;
  var isPrimary = false.obs;
  var isSecondary = false.obs;
  File? _imageFile; // To store the uploaded image file
  String _imageUrl = ''; // Store the current or updated image URL

  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  void initState() {
    super.initState();

    // Pre-fill the text fields with existing product data
    nameArabicController.text = widget.productData['name_arabic'] ?? '';
    nameEnglishController.text = widget.productData['name_english'] ?? '';
    manufArabicController.text = widget.productData['manufacture_company_name_arabic'] ?? '';
    manufEnglishController.text = widget.productData['manufacture_company_name_english'] ?? '';
    categoryNameController.text = widget.productData['category_name'] ?? '';
    lowestQuantityController.text = widget.productData['lowest_quantity']?.toString() ?? '';
    highestQuantityController.text = widget.productData['highest_quantity']?.toString() ?? '';
    primaryPriceController.text = widget.productData['primary_price']?.toString() ?? '';
    secondaryPriceController.text = widget.productData['secondary_price']?.toString() ?? '';
    primaryStockController.text = widget.productData['primary_stock_quantity']?.toString() ?? '';
    secondaryStockController.text = widget.productData['secondary_stock_quantity']?.toString() ?? '';
    primaryWarningController.text = widget.productData['primary_warning_quantity']?.toString() ?? '';
    secondaryWarningController.text = widget.productData['secondary_warning_quantity']?.toString() ?? '';
    offerController.text = widget.productData['offer']?.toString() ?? '';

    _imageUrl = widget.productData['URL'] ?? ''; // Load the existing image URL

    isPrimary.value = widget.productData['primary'] ?? false;
    isSecondary.value = widget.productData['secondary'] ?? false;

    isApprovedbyAdmin.value = widget.productData['Approved_by_admin'] ?? false;

  }

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Product'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)'), enabled: false,),
            TextField(controller: nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)'), enabled: false),
            SizedBox(height: 20),


            SizedBox(height: 10),

            // Checkbox for primary and secondary
            Obx(() => CheckboxListTile(
              title: Text('Approved by Admin'),
              value: isApprovedbyAdmin.value,
              onChanged: (val) => isApprovedbyAdmin.value = val!,
            )),

            SizedBox(height: 20),

            // Button to update the product in Firebase
            ElevatedButton(
              onPressed: () {
                // Use the uploaded image file or the existing URL
                final imageUrl = _imageFile != null ? _imageFile!.path : _imageUrl;

                final updatedProduct = {
                  'name_arabic': nameArabicController.text,
                  'name_english': nameEnglishController.text,
                  'manufacture_company_name_arabic': manufArabicController.text,
                  'manufacture_company_name_english': manufEnglishController.text,
                  'category_name': categoryNameController.text,
                  'primary': isPrimary.value,
                  'secondary': isSecondary.value,
                  'lowest_quantity': double.tryParse(lowestQuantityController.text) ?? 0.0,
                  'highest_quantity': double.tryParse(highestQuantityController.text) ?? 0.0,
                  'primary_price': double.tryParse(primaryPriceController.text) ?? 0.0,
                  'secondary_price': double.tryParse(secondaryPriceController.text) ?? 0.0,
                  'primary_stock_quantity': double.tryParse(primaryStockController.text) ?? 0.0,
                  'secondary_stock_quantity': double.tryParse(secondaryStockController.text) ?? 0.0,
                  'primary_warning_quantity': double.tryParse(primaryWarningController.text) ?? 0.0,
                  'secondary_warning_quantity': double.tryParse(secondaryWarningController.text) ?? 0.0,
                  'offer': double.tryParse(offerController.text) ?? 0.0,
                  'URL': imageUrl, // Save the image URL or path
                  'Approved_by_admin': isApprovedbyAdmin.value
                };

                controller.updateProduct(widget.productId, updatedProduct);
                controller.searchController.clear();
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}