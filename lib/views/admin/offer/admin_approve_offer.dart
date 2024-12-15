import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker

class AdminApproveOfferController extends GetxController {
  final searchController = TextEditingController();

  var OfferList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredOfferList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Offers');

  @override
  void onInit() {
    super.onInit();
    setupRealtimeListener(); // Set up real-time listener
    searchController.addListener(() => filterOffers());
  }

  // Method to set up real-time listener for Firebase Realtime Database
  void setupRealtimeListener() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        OfferList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredOfferList.value = OfferList; // Initially set filtered list to full list
      } else {
        OfferList.clear(); // If no data, clear the list
        filteredOfferList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterOffers() {
    final query = searchController.text.toLowerCase();
    filteredOfferList.value = OfferList.where((product) {
      final productName = product['data']['name'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateOffer(String id, Map<String, dynamic> updatedOffer) {
    dbRef.child(id).update(updatedOffer).then((_) {
      Get.snackbar('Success', 'Offer updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update product: $error');
    });
  }
}

class AdminApproveOffer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminApproveOfferController controller = Get.put(AdminApproveOfferController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Offer'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                labelText: 'Search Offer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // List of products
          Expanded(
            child: Obx(() {
              if (controller.filteredOfferList.isEmpty) {
                return Center(child: Text('No Offer found.'));
              }

              return ListView.builder(
                itemCount: controller.filteredOfferList.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredOfferList[index]['data'];
                  final productId = controller.filteredOfferList[index]['id'];

                  return ListTile(
                    title: Text(product['name']),
                    subtitle: Text('Offer: ${product['name_arabic']}'),
                    onTap: () => Get.to(() => EditOfferPage(productId: productId, productData: product)),
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

class EditOfferPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditOfferPage({required this.productId, required this.productData});

  @override
  _EditOfferPageState createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  final AdminApproveOfferController controller = Get.find();

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
        title: Text('Approve Offer'),
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

                final updatedOffer = {
                  'name_arabic': nameArabicController.text,
                  'name': nameEnglishController.text,
                  'URL': imageUrl, // Save the image URL or path
                  'Approved_by_admin': Approved_by_admin.value
                };

                controller.updateOffer(widget.productId, updatedOffer);
                controller.searchController.clear();
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Offer'),
            ),
          ],
        ),
      ),
    );
  }
}