import 'dart:io'; // For File class
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;

class AdminEditOfferController extends GetxController {
  final searchController = TextEditingController();

  var offerList = <Map<String, dynamic>>[].obs; // List to hold all products
  var filteredOfferList = <Map<String, dynamic>>[].obs; // List to hold filtered products

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child('Offers');

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
        offerList.value = data.entries.map((e) {
          return {
            'id': e.key,
            'data': Map<String, dynamic>.from(e.value),
          };
        }).toList();
        filteredOfferList.value = offerList; // Initially set filtered list to full list
      } else {
        offerList.clear(); // If no data, clear the list
        filteredOfferList.clear();
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch products: $error');
    });
  }

  // Filter products based on search input
  void filterProducts() {
    final query = searchController.text.toLowerCase();
    filteredOfferList.value = offerList.where((offer) {
      final productName = offer['data']['name'].toString().toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  // Method to update the product in Firebase
  void updateOffer(String id, Map<String, dynamic> updatedOffer) {
    dbRef.child(id).update(updatedOffer).then((_) {
      Get.snackbar('Success', 'Offer updated successfully!');
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to update Offer: $error');
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
  void deleteOffer(String id, bool deleteImageSource, String URL) {
    dbRef.child(id).remove().then((_) {
      Get.snackbar('Success', 'Offer Removed successfully!');
      if (deleteImageSource){
        deleteFileFromStorage(URL);
      }
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to Offer product: $error');
    });
  }
}

class AdminEditOffer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminEditOfferController controller = Get.put(AdminEditOfferController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Offer'),
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
  final AdminEditOfferController controller = Get.find();

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
      final storageRef = FirebaseStorage.instance.ref().child('offer_images/$fileName');
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
      final storageRef = FirebaseStorage.instance.ref().child('offer_images/$fileName');
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

  String getCurrentDateAsString() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Offer'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)')),
            TextField(controller: nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)')),

            SizedBox(height: 20),

            // Image preview or placeholder
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

                final updatedOffer = {
                  'name_arabic': nameArabicController.text,
                  'name': nameEnglishController.text,
                  'Approved_by_admin':false,
                  'URL': imageUrl, // Save the image URL or path
                  'date': getCurrentDateAsString(),
                };

                controller.updateOffer(widget.productId, updatedOffer);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Update Offer', style: TextStyle(
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

                controller.deleteOffer(widget.productId, deleteImageSource.value, imageUrl);
                Get.back(); // Go back to the previous screen
              },
              child: Text('Delete Offer', style: TextStyle(
                color: Colors.white,
              ),),
            ),
          ],
        ),
      ),
    );
  }
}