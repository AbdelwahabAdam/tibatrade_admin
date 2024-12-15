import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // For File class (mobile platforms)
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;

class AdminEditCategoryController extends GetxController {
  final searchController = TextEditingController();

  var categoryList = <Map<String, dynamic>>[].obs; // List to hold all products
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
        categoryList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredCategoryList.value = categoryList; // Initially set filtered list to full list
      } else {
        categoryList.clear(); // If no data, clear the list
        filteredCategoryList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterProducts() {
    final query = searchController.text.toLowerCase();
    filteredCategoryList.value = categoryList.where((category) {
      final productName = category['data']['name'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateCategory(String id, Map<String, dynamic> updatedCategory) {
    dbRef.child(id).update(updatedCategory).then((_) {
      Get.snackbar('Success', 'Category updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update Category: $error');
    });
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
  void deleteCategory(String id, bool deleteImageSource, String URL) {
    dbRef.child(id).remove().then((_) {
      Get.snackbar('Success', 'Category Removed successfully!');
      if (deleteImageSource){
        deleteFileFromStorage(URL);
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to Category product: $error');
    });
  }
}

class AdminEditCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditCategoryController controller = Get.put(AdminEditCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Category'),
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
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();
  var Approved_by_admin = false.obs;

  File? _imageFile;
  Uint8List? _webImageBytes;
  String _imageUrl = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameArabicController.text = widget.productData['name_arabic'] ?? '';
    nameEnglishController.text = widget.productData['name'] ?? '';
    _imageUrl = widget.productData['URL'] ?? '';
    Approved_by_admin.value = widget.productData['Approved_by_admin'] ?? false;
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
      final storageRef = FirebaseStorage.instance.ref().child('category_images/$fileName');
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
      final storageRef = FirebaseStorage.instance.ref().child('category_images/$fileName');
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
        title: Text('Edit Category'),
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
            SizedBox(height: 20),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("_imageUrl : ${_imageUrl}");
                final updatedCategory = {
                  'name_arabic': nameArabicController.text,
                  'name': nameEnglishController.text,
                  'Approved_by_admin': false,
                  'URL': _imageUrl,
                };
                Get.find<AdminEditCategoryController>()
                    .updateCategory(widget.productId, updatedCategory);
                // Update category logic
                Get.back();
              },
              child: Text('Update Category'),
            ),
          ],
        ),
      ),
    );
  }
}