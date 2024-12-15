import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;

class AdminEditProductController extends GetxController {
  final searchController = TextEditingController();

  var productList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredProductList = <Map<String, dynamic>>[].obs; // List to hold filtered products
  final DatabaseReference categoriesRef = FirebaseDatabase.instance.ref().child('categories');
  final DatabaseReference supCategoriesRef = FirebaseDatabase.instance.ref().child('SupCategories');

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

  void deleteFileFromStorage(String downloadUrl) async {
    // Create a reference to the file to be deleted
    Reference reference = FirebaseStorage.instance.refFromURL(downloadUrl);

    try {
      // Delete the file
      await reference.delete();
      Get.snackbar('Success', 'Image deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Error deleting Image: $e');
    }
  }

  // Method to Remove the product in Firebase
  void deleteProduct(String id, bool deleteImageSource, String URL) {
    dbRef.child(id).remove().then((_) {
      Get.snackbar('Success', 'Product Removed successfully!');
      if (deleteImageSource){
        deleteFileFromStorage(URL);
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to Remove product: $error');
    });
  }

}

class AdminEditProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditProductController controller = Get.put(AdminEditProductController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Products'),
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
  // Controllers for fields
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

  // State variables
  var isPrimary = false.obs;
  var isSecondary = false.obs;
  File? _imageFile;
  String _imageUrl = '';
  var deleteImageSource = false.obs;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImageBytes;
  // Category and Sup Category
  String? selectedCategory;
  String? selectedSupCategory;
  List<String> categoryList = [];
  List<String> supCategoryList = [];

  @override
  void initState() {
    super.initState();

    // Pre-fill text fields with existing product data
    nameArabicController.text = widget.productData['name_arabic'] ?? '';
    nameEnglishController.text = widget.productData['name_english'] ?? '';
    manufArabicController.text =
        widget.productData['manufacture_company_name_arabic'] ?? '';
    manufEnglishController.text =
        widget.productData['manufacture_company_name_english'] ?? '';
    lowestQuantityController.text =
        widget.productData['lowest_quantity']?.toString() ?? '';
    highestQuantityController.text =
        widget.productData['highest_quantity']?.toString() ?? '';
    primaryPriceController.text =
        widget.productData['primary_price']?.toString() ?? '';
    secondaryPriceController.text =
        widget.productData['secondary_price']?.toString() ?? '';
    primaryStockController.text =
        widget.productData['primary_stock_quantity']?.toString() ?? '';
    secondaryStockController.text =
        widget.productData['secondary_stock_quantity']?.toString() ?? '';
    primaryWarningController.text =
        widget.productData['primary_warning_quantity']?.toString() ?? '';
    secondaryWarningController.text =
        widget.productData['secondary_warning_quantity']?.toString() ?? '';
    offerController.text = widget.productData['offer']?.toString() ?? '';

    _imageUrl = widget.productData['URL'] ?? '';
    isPrimary.value = widget.productData['primary'] ?? false;
    isSecondary.value = widget.productData['secondary'] ?? false;

    selectedCategory = widget.productData['category_name'] ?? '';
    selectedSupCategory = widget.productData['sup_category_name'] ?? '';

    fetchCategories();
    fetchSupCategories();
  }

  // Fetch categories from Firebase
  Future<void> fetchCategories() async {
    try {
      final snapshot = await Get.find<AdminEditProductController>()
          .categoriesRef
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          categoryList =
              data.values.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // Fetch sup categories from Firebase
  Future<void> fetchSupCategories() async {
    try {
      final snapshot = await Get.find<AdminEditProductController>()
          .supCategoriesRef
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          supCategoryList =
              data.values.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error fetching sup categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        if (kIsWeb) {
          // For web platforms
          final webImageBytes = await pickedFile.readAsBytes();
          final fileName = pickedFile.name;
          await uploadImageToFirebaseWeb(webImageBytes, fileName);
        } else {
          // For mobile platforms
          final imageFile = File(pickedFile.path);
          setState(() {
            _imageFile = imageFile;
          });
          await uploadImageToFirebase(imageFile);
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload image: $e');
      }
    } else {
      Get.snackbar('No Image Selected', 'Please select an image.');
    }
  }

  Future<void> uploadImageToFirebaseWeb(Uint8List imageBytes, String fileName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await storageRef.putData(imageBytes, metadata);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _webImageBytes = imageBytes;
        _imageUrl = downloadUrl;
      });
      print("_imageUrl : ${_imageUrl}");
      Get.snackbar('Success', 'Image uploaded successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }

  Future<void> uploadImageToFirebase(File imageFile) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance.ref().child('product_images/$fileName');
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _imageUrl = downloadUrl;
      });
      print("_imageUrl : ${_imageUrl}");
      Get.snackbar('Success', 'Image uploaded successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameArabicController,
              decoration: InputDecoration(labelText: 'Name (Arabic)'),
            ),
            TextField(
              controller: nameEnglishController,
              decoration: InputDecoration(labelText: 'Name (English)'),
            ),
            TextField(
              controller: manufArabicController,
              decoration:
              InputDecoration(labelText: 'Manufacture Company (Arabic)'),
            ),
            TextField(
              controller: manufEnglishController,
              decoration:
              InputDecoration(labelText: 'Manufacture Company (English)'),
            ),
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: categoryList.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            // Sup Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedSupCategory,
              decoration: InputDecoration(labelText: 'Sup Category'),
              items: supCategoryList.map((supCategory) {
                return DropdownMenuItem(
                  value: supCategory,
                  child: Text(supCategory),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSupCategory = value;
                });
              },
            ),
            TextField(
              controller: lowestQuantityController,
              decoration: InputDecoration(labelText: 'Lowest Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: highestQuantityController,
              decoration: InputDecoration(labelText: 'Highest Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: primaryPriceController,
              decoration: InputDecoration(labelText: 'Primary Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: secondaryPriceController,
              decoration: InputDecoration(labelText: 'Secondary Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: primaryStockController,
              decoration: InputDecoration(labelText: 'Primary Stock Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: secondaryStockController,
              decoration:
              InputDecoration(labelText: 'Secondary Stock Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: primaryWarningController,
              decoration:
              InputDecoration(labelText: 'Primary Warning Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: secondaryWarningController,
              decoration:
              InputDecoration(labelText: 'Secondary Warning Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: offerController,
              decoration: InputDecoration(labelText: 'Offer'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!, height: 200)
                : _imageUrl.isNotEmpty
                ? Image.network(_imageUrl, height: 200)
                : Placeholder(fallbackHeight: 200),
            SizedBox(height: 10),
            if (_webImageBytes != null)
              Image.memory(_webImageBytes!, height: 200)
            else if (_imageFile != null)
              Image.file(_imageFile!, height: 200)
            else if (_imageUrl.isNotEmpty)
                Image.network(_imageUrl, height: 200)
              else
                Placeholder(fallbackHeight: 200),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload Image'),
            ),
            Obx(() => CheckboxListTile(
              title: Text('Primary'),
              value: isPrimary.value,
              onChanged: (val) => isPrimary.value = val!,
            )),
            Obx(() => CheckboxListTile(
              title: Text('Secondary'),
              value: isSecondary.value,
              onChanged: (val) => isSecondary.value = val!,
            )),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final updatedProduct = {
                  'name_arabic': nameArabicController.text,
                  'name_english': nameEnglishController.text,
                  'manufacture_company_name_arabic':
                  manufArabicController.text,
                  'manufacture_company_name_english':
                  manufEnglishController.text,
                  'category_name': selectedCategory,
                  'sup_category_name': selectedSupCategory,
                  'primary': isPrimary.value,
                  'secondary': isSecondary.value,
                  'lowest_quantity':
                  double.tryParse(lowestQuantityController.text) ?? 0.0,
                  'highest_quantity':
                  double.tryParse(highestQuantityController.text) ?? 0.0,
                  'primary_price':
                  double.tryParse(primaryPriceController.text) ?? 0.0,
                  'secondary_price':
                  double.tryParse(secondaryPriceController.text) ?? 0.0,
                  'primary_stock_quantity':
                  double.tryParse(primaryStockController.text) ?? 0.0,
                  'secondary_stock_quantity':
                  double.tryParse(secondaryStockController.text) ?? 0.0,
                  'primary_warning_quantity':
                  double.tryParse(primaryWarningController.text) ?? 0.0,
                  'secondary_warning_quantity':
                  double.tryParse(secondaryWarningController.text) ?? 0.0,
                  'offer': double.tryParse(offerController.text) ?? 0.0,
                  'URL': _imageFile != null ? _imageFile!.path : _imageUrl,
                };

                Get.find<AdminEditProductController>()
                    .updateProduct(widget.productId, updatedProduct);
                Get.back();
              },
              child: Text('Update Product'),
            ),
          ],
        ),
      ),
    );
  }
}