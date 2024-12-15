import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;

class AdminEditSubCategoryController extends GetxController {
  final searchController = TextEditingController();

  var categoryList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredCategoryList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('SupCategories');

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
      Get.snackbar('Success', 'Sup Category updated successfully!');
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
      Get.snackbar('Success', 'Sup Category Removed successfully!');
      if (deleteImageSource){
        deleteFileFromStorage(URL);
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to Category product: $error');
    });
  }
}

class AdminEditSubCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditSubCategoryController controller = Get.put(AdminEditSubCategoryController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Sup Category'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Sup Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of products
          Expanded(
            child: Obx(() {
              if (controller.filteredCategoryList.isEmpty) {
                return Center(child: Text('No Sup Category found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredCategoryList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredCategoryList[index]['data'];
                  final productId = controller.filteredCategoryList[index]['id'];

                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Sup Category: ${product['name_arabic']}'),
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
  final AdminEditSubCategoryController controller = Get.find();

  // Controllers for each field
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();

  var Approved_by_admin = false.obs;

  File? _imageFile; // To store the uploaded image file
  String _imageUrl = ''; // Store the current or updated image URL
  Uint8List? _webImageBytes;

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
      final storageRef = FirebaseStorage.instance.ref().child('sup_category_images/$fileName');
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
      final storageRef = FirebaseStorage.instance.ref().child('sup_category_images/$fileName');
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
        title: Text('Edit Sup Category'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)')),
            TextField(controller: nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)')),

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

            // Button to pick an image
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Upload Image'),
            ),

            // Checkbox for primary and secondary
            // Obx(() => CheckboxListTile(
            //   title: Text('Approved_by_admin'),
            //   value: Approved_by_admin.value,
            //   onChanged: (val) => Approved_by_admin.value = val!,
            // )),


            SizedBox(height: 20),

            // Button to update the product in Firebase
            ElevatedButton(
              onPressed: () {
                // Use the uploaded image file or the existing URL
                final imageUrl = _imageFile != null ? _imageFile!.path : _imageUrl;

                final updatedCategory = {
                  'name_arabic': nameArabicController.text,
                  'name': nameEnglishController.text,
                  'Approved_by_admin': false,
                  'URL': imageUrl, // Save the image URL or path
                };

                controller.updateCategory(widget.productId, updatedCategory);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Category'),
            ),
            SizedBox(height: 50,),
            Divider(color: Colors.grey),
            SizedBox(height: 20,),

            Obx(() => CheckboxListTile(
              title: Text('Delete Image Source'),
              value: deleteImageSource.value,
              onChanged: (val) => deleteImageSource.value = val!,
            )),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
               backgroundColor: Colors.red // Set the background color here
              ),
              onPressed: () {
                // Use the uploaded image file or the existing URL
                final imageUrl = _imageFile != null ? _imageFile!.path : _imageUrl;

                controller.deleteCategory(widget.productId, deleteImageSource.value, imageUrl);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Delete Product', style: TextStyle(
                color: Colors.white,
              ),),
            ),
          ],
        ),
      ),
    );
  }
}