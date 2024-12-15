import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class AdminEditBannerController extends GetxController {
  final searchController = TextEditingController();

  var bannerList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredBannerList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('banner');

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
        bannerList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredBannerList.value = bannerList; // Initially set filtered list to full list
      } else {
        bannerList.clear(); // If no data, clear the list
        filteredBannerList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterProducts() {
    final query = searchController.text.toLowerCase();
    filteredBannerList.value = bannerList.where((banner) {
      final productName = banner['data']['name'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateBanner(String id, Map<String, dynamic> updatedBanner) {
    dbRef.child(id).update(updatedBanner).then((_) {
      Get.snackbar('Success', 'Banner updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update Banner: $error');
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
  void deleteBanner(String id, bool deleteImageSource, String URL) {
    dbRef.child(id).remove().then((_) {
      Get.snackbar('Success', 'Banner Removed successfully!');
      if (deleteImageSource){
        deleteFileFromStorage(URL);
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to Banner product: $error');
    });
  }
}

class AdminEditBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditBannerController controller = Get.put(AdminEditBannerController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Banner'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Banner',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of products
          Expanded(
            child: Obx(() {
              if (controller.filteredBannerList.isEmpty) {
                return Center(child: Text('No Banner found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredBannerList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredBannerList[index]['data'];
                  final productId = controller.filteredBannerList[index]['id'];

                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Banner: ${product['date']}'),
                    onTap: () => Get.to(() => EditBannerPage(productId: productId, productData: product)),
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

class EditBannerPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditBannerPage({required this.productId, required this.productData});

  @override
  _EditBannerPageState createState() => _EditBannerPageState();
}

class _EditBannerPageState extends State<EditBannerPage> {
  final AdminEditBannerController controller = Get.find();

  // Controllers for each field
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
  String getCurrentDateAsString() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Banner'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameEnglishController, decoration: InputDecoration(labelText: 'Name')),

            SizedBox(height: 20),

            // Image preview or placeholder
            _imageFile != null
                ? Image.file(_imageFile!, height: 200)
                : _imageUrl.isNotEmpty
                ? Image.network(_imageUrl, height: 200)
                : Placeholder(fallbackHeight: 200),

            SizedBox(height: 10),

            // Button to pick an image
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue // Set the background color here
              ),
              onPressed: _pickImage,
              child: Text('Upload Image', style: TextStyle(
                color: Colors.white,)),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green // Set the background color here
              ),
              onPressed: () {
                // Use the uploaded image file or the existing URL
                final imageUrl = _imageFile != null ? _imageFile!.path : _imageUrl;

                final updatedBanner = {
                  'name': nameEnglishController.text,
                  'Approved_by_admin':false,
                  'URL': imageUrl, // Save the image URL or path
                  'date': getCurrentDateAsString(),
                };

                controller.updateBanner(widget.productId, updatedBanner);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Banner', style: TextStyle(
                color: Colors.white,)),
            ),
            SizedBox(height: 50,),
            Divider(color: Colors.grey), // Divider widget
            SizedBox(height: 20),

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

                controller.deleteBanner(widget.productId, deleteImageSource.value, imageUrl);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Delete Banner', style: TextStyle(
                color: Colors.white,
              ),),
            ),
          ],
        ),
      ),
    );
  }
}