import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker

class AdminApproveCategoryController extends GetxController {
  final searchController = TextEditingController();

  var CategoryList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredCategoryList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('categories');

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
        CategoryList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredCategoryList.value = CategoryList; // Initially set filtered list to full list
      } else {
        CategoryList.clear(); // If no data, clear the list
        filteredCategoryList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterProducts() {
    final query = searchController.text.toLowerCase();
    filteredCategoryList.value = CategoryList.where((product) {
      final productName = product['data']['name'].toString().toLowerCase();
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

class AdminApproveCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminApproveCategoryController controller = Get.put(AdminApproveCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Category'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of products
          Expanded(
            child: Obx(() {
              if (controller.filteredCategoryList.isEmpty) {
                return Center(child: Text('No Category found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredCategoryList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredCategoryList[index]['data'];
                  final productId = controller.filteredCategoryList[index]['id'];

                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Category: ${product['name_arabic']}'),
                    onTap: () => Get.to(() => EditCategoryPage(productId: productId, productData: product)),
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

class EditCategoryPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditCategoryPage({required this.productId, required this.productData});

  @override
  _EditCategoryPageState createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final AdminApproveCategoryController controller = Get.find();

  // Controllers for each field
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();

  var Approved_by_admin = false.obs;

  File? _imageFile; // To store the uploaded image file
  String _imageUrl = ''; // Store the current or updated image URL

  final ImagePicker _picker = ImagePicker(); // Image picker instance


  var deleteImageSource = false.obs;

  @override
  void initState() {
    super.initState();

    // Pre-fill the text fields with existing product data
    nameArabicController.text = widget.productData['name_arabic'] ?? '';
    nameEnglishController.text = widget.productData['name'] ?? '';

    _imageUrl = widget.productData['URL'] ?? ''; // Load the existing image URL

    Approved_by_admin.value = widget.productData['Approved_by_admin'] ?? false;
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
        title: Text('Approve Category'),
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
              value: Approved_by_admin.value,
              onChanged: (val) => Approved_by_admin.value = val!,
            )),

            SizedBox(height: 20),

            // Button to update the product in Firebase
            ElevatedButton(
              onPressed: () {
                // Use the uploaded image file or the existing URL
                final imageUrl = _imageFile != null ? _imageFile!.path : _imageUrl;

                final updatedProduct = {
                  'name_arabic': nameArabicController.text,
                  'name': nameEnglishController.text,
                  'URL': imageUrl, // Save the image URL or path
                  'Approved_by_admin': Approved_by_admin.value
                };

                controller.updateProduct(widget.productId, updatedProduct);
                controller.searchController.clear();
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Category'),
            ),
          ],
        ),
      ),
    );
  }
}