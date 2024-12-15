import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb


class AdminAddProductController extends GetxController {
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();
  final manufArabicController = TextEditingController();
  final manufEnglishController = TextEditingController();
  final lowestQuantityController = TextEditingController();
  final highestQuantityController = TextEditingController();
  final primaryPriceController = TextEditingController();
  final secondaryPriceController = TextEditingController();
  final primaryStockController = TextEditingController();
  final secondaryStockController = TextEditingController();
  final primaryWarningController = TextEditingController();
  final secondaryWarningController = TextEditingController();
  final offerController = TextEditingController();

  var isPrimary = false.obs;
  var isSecondary = false.obs;
  var imageUrl = ''.obs; // To hold the image URL
  File? selectedImage; // For storing the selected image file

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference categoriesRef = FirebaseDatabase.instance.ref().child('categories');
  final DatabaseReference supCategoriesRef = FirebaseDatabase.instance.ref().child('SupCategories');
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  var categoryList = <String>[].obs; // List to store category names
  var selectedCategory = ''.obs; // Selected category
  var selectedCategoryId = ''.obs; // Selected category
  var selectedSupCategory = ''.obs; // Selected category
  var selectedSupCategoryId = ''.obs; // Selected category
  var supCategoryList = <String>[].obs; // List to store category names

  final ImagePicker _picker = ImagePicker(); // For image picker

  @override
  void onInit() {
    super.onInit();
    fetchCategories(); // Load categories on initialization
    fetchSupCategories();
  }


  Future<String?> fetchCategoryUID(String categoryName) async {
    try {
      // Query the categories to find a match for the given category name
      final snapshot = await categoriesRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Iterate over the entries to find the matching category name
        for (var entry in data.entries) {
          if (entry.value['name'] == categoryName) {
            return entry.key; // Return the UID (entry.key) if found
          }
        }
      }

      // Return null if no category matches the given name
      return null;

    } catch (e) {
      print('Error fetching category UID: $e');
      return null;
    }
  }


  Future<String?> fetchSupCategoryUID(String categoryName) async {
    try {
      // Query the categories to find a match for the given category name
      final snapshot = await supCategoriesRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        // Iterate over the entries to find the matching category name
        for (var entry in data.entries) {
          if (entry.value['name'] == categoryName) {
            return entry.key; // Return the UID (entry.key) if found
          }
        }
      }
      // Return null if no category matches the given name
      return null;

    } catch (e) {
      print('Error fetching Sup category UID: $e');
      return null;
    }
  }

  // Method to fetch categories from Firebase Realtime Database
  void fetchCategories() {
    categoriesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        categoryList.value = data.values.map((category) {
          return category['name'] as String;
        }).toList();

        // Set the first category as selected by default
        if (categoryList.isNotEmpty) {
          selectedCategory.value = categoryList.first;

        }
      } else {
        categoryList.clear(); // If no data, clear the list
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch categories: $error');
    });
  }

  void fetchSupCategories() {
    supCategoriesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        supCategoryList.value = data.values.map((category) {
          return category['name'] as String;
        }).toList();

        // Set the first category as selected by default
        if (supCategoryList.isNotEmpty) {
          selectedSupCategory.value = supCategoryList.first;
        }
      } else {
        supCategoryList.clear(); // If no data, clear the list
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch categories: $error');
    });
  }

  // Method to pick an image
  Future<void> pickImage() async {
    try {
      XFile? pickedFile;

      if (kIsWeb) {
        // For Web: Use the web-compatible image picker
        pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else if (Platform.isAndroid || Platform.isIOS) {
        // For Mobile (Android/iOS)
        pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      } else {
        Get.snackbar('Unsupported Platform', 'Image picking is only supported on Android, iOS, and Web.');
        return;
      }

      if (pickedFile != null) {
        // Use a File for mobile platforms and Uint8List for web
        if (kIsWeb) {
          // Web: Use byte data for the selected image
          final imageBytes = await pickedFile.readAsBytes();
          await uploadImageToFirebaseWeb(imageBytes, pickedFile.name);
        } else {
          selectedImage = File(pickedFile.path);
          await uploadImageToFirebase();
        }
      } else {
        Get.snackbar('No Image Selected', 'Please select an image.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

// Firebase Web Upload
  Future<void> uploadImageToFirebaseWeb(Uint8List imageBytes, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');

      // Define metadata with contentType
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload the image with metadata
      final uploadTask = storageRef.putData(imageBytes, metadata);

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      imageUrl.value = downloadUrl;
      imageUrl.refresh();
      Get.snackbar('Success', 'Image uploaded successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }
  // Method to upload image to Firebase Storage
  Future<void> uploadImageToFirebase() async {
    if (selectedImage != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('product_images/$fileName');

      try {
        await storageRef.putFile(selectedImage!); // Upload the image
        String downloadUrl = await storageRef.getDownloadURL(); // Get the URL of the uploaded image
        imageUrl.value = downloadUrl; // Update the URL observable
        imageUrl.refresh();
        Get.snackbar('Success', 'Image uploaded successfully!');
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload image: $e');
      }
    }
  }

  void clearControllers() {

    nameArabicController.clear();
    nameEnglishController.clear();
    manufArabicController.clear();
    manufEnglishController.clear();
    lowestQuantityController.clear();
    highestQuantityController.clear();
    primaryPriceController.clear();
    secondaryPriceController.clear();
    primaryStockController.clear();
    secondaryStockController.clear();
    primaryWarningController.clear();
    secondaryWarningController.clear();
    offerController.clear();

    isPrimary = false.obs;
    isSecondary = false.obs;
    imageUrl.value = ''; // To hold the image URL
    imageUrl.refresh();
  }
  // Method to add product to Firebase Realtime Database
  void addProduct() async {
    if (imageUrl.value.isEmpty) {
      Get.snackbar('Error', 'Please upload an image first.');
      return;
    }

    var selectedCategoryId = await  fetchCategoryUID( selectedCategory.value);
    var selectedSupCategoryId = await  fetchSupCategoryUID( selectedSupCategory.value);
    // print("*************************************************************************************");
    // print(selectedCategoryId);
    // print(selectedSupCategoryId);
    // print("*************************************************************************************");

    dbRef.push().set({
      'name_arabic': nameArabicController.text,
      'name_english': nameEnglishController.text,
      'manufacture_company_name_arabic': manufArabicController.text,
      'manufacture_company_name_english': manufEnglishController.text,
      'category_name': selectedCategory.value, // Use the selected category
      'category_id': selectedCategoryId, // Use the selected category
      'sup_category_name': selectedSupCategory.value, // Use the selected category
      'sup_category_id': selectedSupCategoryId, // Use the selected category
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
      'URL': imageUrl.value, // Store the image URL
      'Approved_by_admin': false,
    }).then((_) {
      Get.snackbar('Success', 'Product added successfully!');
      clearControllers();
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to add product: $error');
    });

    imageUrl.value = ''; // To hold the image URL
    imageUrl.refresh();

  }
}

class AdminAddProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminAddProductController controller = Get.put(AdminAddProductController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Input fields for each product detail
            TextField(controller: controller.nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)')),
            TextField(controller: controller.nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)')),
            TextField(controller: controller.manufArabicController, decoration: InputDecoration(labelText: 'Manufacture Company (Arabic)')),
            TextField(controller: controller.manufEnglishController, decoration: InputDecoration(labelText: 'Manufacture Company (English)')),

            // Category dropdown
            Obx(() {
              return DropdownButtonFormField<String>(
                value: controller.selectedCategory.value.isNotEmpty ? controller.selectedCategory.value : null,
                hint: Text('Select Category'),
                onChanged: (value) => controller.selectedCategory.value = value!,
                items: controller.categoryList.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              );
            }),

            Obx(() {
              return DropdownButtonFormField<String>(
                value: controller.selectedSupCategory.value.isNotEmpty ? controller.selectedSupCategory.value : null,
                hint: Text('Select Sup Category'),
                onChanged: (value) => controller.selectedSupCategory.value = value!,
                items: controller.supCategoryList.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              );
            }),
            TextField(controller: controller.lowestQuantityController, decoration: InputDecoration(labelText: 'Lowest Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.highestQuantityController, decoration: InputDecoration(labelText: 'Highest Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.primaryPriceController, decoration: InputDecoration(labelText: 'Primary Price'), keyboardType: TextInputType.number),
            TextField(controller: controller.secondaryPriceController, decoration: InputDecoration(labelText: 'Secondary Price'), keyboardType: TextInputType.number),
            TextField(controller: controller.primaryStockController, decoration: InputDecoration(labelText: 'Primary Stock Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.secondaryStockController, decoration: InputDecoration(labelText: 'Secondary Stock Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.primaryWarningController, decoration: InputDecoration(labelText: 'Primary Warning Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.secondaryWarningController, decoration: InputDecoration(labelText: 'Secondary Warning Quantity'), keyboardType: TextInputType.number),
            TextField(controller: controller.offerController, decoration: InputDecoration(labelText: 'Offer'), keyboardType: TextInputType.number),

            // Upload image button
            ElevatedButton(
              onPressed: controller.pickImage,
              child: Text('Upload Image'),
            ),

            // Display uploaded image (if any)
          Obx(() {
            return controller.imageUrl.value.isNotEmpty
                ? Image.network(controller.imageUrl.value, height: 150)
                : SizedBox();
          }),
            // Checkbox for primary and secondary
            Obx(() => CheckboxListTile(
              title: Text('Primary'),
              value: controller.isPrimary.value,
              onChanged: (val) => controller.isPrimary.value = val!,
            )),
            Obx(() => CheckboxListTile(
              title: Text('Secondary'),
              value: controller.isSecondary.value,
              onChanged: (val) => controller.isSecondary.value = val!,
            )),

            SizedBox(height: 20),

            // Button to submit the product to Firebase
            ElevatedButton(
              onPressed: controller.addProduct,
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
