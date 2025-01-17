import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
// import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart' show Platform;

class AdminAddSubCategoryController extends GetxController {
  final nameArabicController = TextEditingController();
  final nameEnglishController = TextEditingController();

  var Approved_by_admin = false.obs;
  var imageUrl = ''.obs; // To hold the image URL
  File? selectedImage; // For storing the selected image file

  // Firebase database reference
  final DatabaseReference SupCategoriesRef = FirebaseDatabase.instance.ref().child('SupCategories');
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  var categoryList = <String>[].obs; // List to store category names
  var selectedCategory = ''.obs; // Selected category

  final ImagePicker _picker = ImagePicker(); // For image picker

  @override
  void onInit() {
    super.onInit();
    fetchCategories(); // Load categories on initialization
  }

  // Method to fetch categories from Firebase Realtime Database
  void fetchCategories() {
    SupCategoriesRef.onValue.listen((event) {
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
      Get.snackbar('Error', 'Failed to fetch Sup categories: $error');
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
      final storageRef = FirebaseStorage.instance.ref().child('sup_category_images/$fileName');

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
      Reference storageRef = _storage.ref().child('sup_category_images/$fileName');

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

  // Method to add product to Firebase Realtime Database
  void addSupCategory() {
    if (imageUrl.value.isEmpty) {
      Get.snackbar('Error', 'Please upload an image first.');
      return;
    }

    SupCategoriesRef.push().set({
      'name_arabic': nameArabicController.text,
      'name': nameEnglishController.text,
      'Approved_by_admin': false,
      'URL': imageUrl.value, // Store the image URL
    }).then((_) {
      Get.snackbar('Success', 'Category added successfully!');
      clearControllers();
      imageUrl.value = '';
    }).catchError((error) {
      Get.snackbar('Error', 'Failed to add Category: $error');
    });
  }
}

class AdminAddSubCategory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AdminAddSubCategoryController controller = Get.put(AdminAddSubCategoryController());
    if (kIsWeb) {
      print('Running on the web');
    } else if (Platform.isAndroid) {
      print('Running on Android');
    } else if (Platform.isIOS) {
      print('Running on iOS');
    } else if (Platform.isMacOS) {
      print('Running on macOS');
    } else if (Platform.isWindows) {
      print('Running on Windows');
    } else if (Platform.isLinux) {
      print('Running on Linux');
    } else if (Platform.isFuchsia) {
      print('Running on Fuchsia');
    } else {
      print('Platform not recognized');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Sup Category'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Input fields for each product detail
            TextField(controller: controller.nameArabicController, decoration: InputDecoration(labelText: 'Name (Arabic)')),
            TextField(controller: controller.nameEnglishController, decoration: InputDecoration(labelText: 'Name (English)')),
            // Category dropdown

            // Upload image button
            ElevatedButton(
              onPressed:  controller.pickImage, //kIsWeb?  controller.pickImageWeb : controller.pickImage,
              child: Text('Upload Image'),
            ),

            // Display uploaded image (if any)
            // Display uploaded image (if any)
// Display uploaded image (with loading and error handling)
            Obx(() {
              if (controller.imageUrl.value.isNotEmpty) {
                return Column(
                  children: [
                    Text('Uploaded Image:'),
                    SizedBox(height: 10),
                    Image.network(
                      controller.imageUrl.value,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Handle any image loading errors
                        return Text('Error loading Image: $error');
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        // Handle image loading progress
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes!)
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Text('No image uploaded');
              }
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
              onPressed: controller.addSupCategory,
              child: Text('Add Sup Category'),
            ),
          ],
        ),
      ),
    );
  }
}
