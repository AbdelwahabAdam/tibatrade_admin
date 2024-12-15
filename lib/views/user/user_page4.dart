import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_picker/map_picker.dart';

class Page4Controller extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  var categories = <Category>[].obs;
  var selectedCategory = Rx<Category?>(null);
  var productNameController = TextEditingController();
  var productPriceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    var fetchedCategories = await _firestoreService.getCategories();
    categories.assignAll(fetchedCategories);
  }

  Future<void> addProduct() async {
    if (selectedCategory.value != null && productNameController.text.isNotEmpty && productPriceController.text.isNotEmpty) {
      await _firestoreService.addProductToCategory(
        selectedCategory.value!.id,
        productNameController.text,
        double.parse(productPriceController.text),
      );
      productNameController.clear();
      productPriceController.clear();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}

Future<void> _openMap(String lat, String long) async {
  final Uri googleUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$long");

  if (await canLaunchUrl(googleUrl)) {
    await launchUrl(googleUrl);
  } else {
    throw 'Could not launch $googleUrl';
  }
}

class Page4 extends StatelessWidget {
  final MapPickerController _mapPickerController = MapPickerController();
  final Page4Controller controller = Get.put(Page4Controller());
  late String lat;
  late String long;
  GoogleMapController? _controller;
  LatLng _pickedLocation = LatLng(37.7749, -122.4194); // Default location

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Product to Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The Google Map
                  MapPicker(
                    // MapPickerController
                    mapPickerController: _mapPickerController,
                    // The GoogleMap widget from google_maps_flutter package
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _pickedLocation,
                        zoom: 14.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _controller = controller;
                      },
                      onCameraMove: (position) {
                        _pickedLocation = position.target;
                      },
                    ),
                  ),
                  // Marker icon positioned at the center of the screen
                  Icon(Icons.location_pin, size: 50, color: Colors.red),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Access picked location and use it
                  print("Picked location: $_pickedLocation");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Location: $_pickedLocation")),
                  );
                },
                child: Text('Pick this Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }}
