import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;
import 'dart:typed_data';

class AdminAddOfferController extends GetxController {
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();

  var Approved_by_admin = false.obs;
  var imageUrl = ''.obs; // To hold the image URL
  File? selectedImage; // For storing the selected image file

  // Firebase database reference
  final DatabaseReference offersRef = FirebaseDatabase.instance.ref().child('Offers');
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  var offerList = <String>[].obs; // List to store offer names
  var selectedoffer = ''.obs; // Selected offer

  final ImagePicker _picker = ImagePicker(); // For image picker

  @override
  void onInit() {
    super.onInit();
    fetchoffers(); // Load offers on initialization
  }

  // Method to fetch offers from Firebase Realtime Database
  void fetchoffers() {
    offersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        offerList.value = data.values.map((offer) {
          return offer['name'] as String;
        }).toList();

        // Set the first offer as selected by default
        if (offerList.isNotEmpty) {
          selectedoffer.value = offerList.first;
        }
      } else {
        offerList.clear(); // If no data, clear the list
      }
    }).onError((error) {
      Get.snackbar('Error', 'Failed to fetch offers: $error');
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
      final storageRef = FirebaseStorage.instance.ref().child('offer_images/$fileName');

      // Define metadata with contentType
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload the image with metadata
      final uploadTask = storageRef.putData(imageBytes, metadata);

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      print("******************************************");
      print(downloadUrl);
      print("******************************************");
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
      Reference storageRef = _storage.ref().child('offer_images/$fileName');

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
    Approved_by_admin = false.obs;
    imageUrl.value = ''; // To hold the image URL
    imageUrl.refresh();
  }

  String getCurrentDateAsString() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return formattedDate;
  }
  // Method to add product to Firebase Realtime Database
  void addoffer() {
    if (imageUrl.value.isEmpty) {
      Get.snackbar('Error', 'Please upload an image first.');
      return;
    }

    offersRef.push().set({
      'name_arabic': nameArabicController.text,
      'name': nameEnglishController.text,
      'Approved_by_admin': false,
      'URL': imageUrl.value, // Store the image URL
      'date': getCurrentDateAsString(), // Store the image URL
    }).then((_) {
      Get.snackbar('Success', 'offer added successfully!');
      clearControllers();
      imageUrl.value = '';
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to add offer: $error');
    });
  }
}

class AdminAddOffer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminAddOfferController controller = Get.put(AdminAddOfferController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New offer'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Input fields for each product detail
            TextField(controller: controller.nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)')),
            TextField(controller: controller.nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)')),
            // offer dropdown

            // Upload image button
            ElevatedButton(
              onPressed: controller.pickImage,
              child: Text('Upload Image'),
            ),

            // Display uploaded image (if any)
            Obx(() {
              return (controller.imageUrl.value.isNotEmpty & controller.nameEnglishController.text.isNotEmpty)
                  ? Image.network(controller.imageUrl.value, height: 150)
                  : SizedBox();
            }),
            // Checkbox for primary and secondary
            // Obx(() => CheckboxListTile(
            //   title: Text('Approved_by_admin'),
            //   value: controller.Approved_by_admin.value,
            //   onChanged: (val) => controller.Approved_by_admin.value = val!,
            // )),

            SizedBox(height: 20),

            // Button to submit the product to Firebase
            ElevatedButton(
              onPressed: controller.addoffer,
              child: Text('Add offer'),
            ),
          ],
        ),
      ),
    );
  }
}
