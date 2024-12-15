import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:intl/intl.dart';

class AdminApproveBannerController extends GetxController {
  final searchController = TextEditingController();

  var BannerList = <Map<String, dynamic>>[].obs; // List to hold all banners
  var filteredBannerList = <Map<String, dynamic>>[].obs; // List to hold filtered banners

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('banner');

  @override
  void onInit() {
    super.onInit();
    setupRealtimeListener(); // Set up real-time listener
    searchController.addListener(() => filterBanners());
  }

  // Method to set up real-time listener for Firebase Realtime Database
  void setupRealtimeListener() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        BannerList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredBannerList.value = BannerList; // Initially set filtered list to full list
      } else {
        BannerList.clear(); // If no data, clear the list
        filteredBannerList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch banners: $error');
    });
  }

  // Filter banners based on search input
  void filterBanners() {
    final query = searchController.text.toLowerCase();
    filteredBannerList.value = BannerList.where((product) {
      final productName = product['data']['name'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateBanner(String id, Map<String, dynamic> updatedBanner) {
    dbRef.child(id).update(updatedBanner).then((_) {
      Get.snackbar('Success', 'Banner updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update product: $error');
    });
  }
}

class AdminApproveBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminApproveBannerController controller = Get.put(AdminApproveBannerController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Banner'),
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

          // List of banners
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
  final AdminApproveBannerController controller = Get.find();

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
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return formattedDate;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Banner'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameEnglishController, decoration: InputDecoration(labelText: 'Name'), enabled: false,),
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

                final updatedBanner = {
                  'name': nameEnglishController.text,
                  'URL': imageUrl, // Save the image URL or path
                  'Approved_by_admin': Approved_by_admin.value,
                  'date': getCurrentDateAsString(),
                };

                controller.updateBanner(widget.productId, updatedBanner);
                controller.searchController.clear();
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Banner'),
            ),
          ],
        ),
      ),
    );
  }
}