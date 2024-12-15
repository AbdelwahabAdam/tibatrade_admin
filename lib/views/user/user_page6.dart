import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/auth_controller.dart';

class Page6 extends StatefulWidget {
  @override
  _Page6State createState() => _Page6State();
}

class _Page6State extends State<Page6> {
  LatLng? pickedLocation;

  void _openLocationPicker() async {
    final pickedData = await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            height: 400,
            width: 300,
            child: FlutterLocationPicker(
              initPosition: LatLong(23, 89),
              selectLocationButtonStyle: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
              ),
              selectedLocationButtonTextStyle: const TextStyle(fontSize: 18),
              selectLocationButtonText: 'Set Current Location',
              selectLocationButtonLeadingIcon: const Icon(Icons.check),
              initZoom: 11,
              minZoomLevel: 5,
              maxZoomLevel: 16,
              trackMyPosition: true,
              onError: (e) => print(e),
              onPicked: (pickedData) {
                Navigator.of(context).pop(pickedData); // Return the picked data
              },
            ),
          ),
        );
      },
    );

    // Print the picked data after selection
    if (pickedData != null) {
      print('Latitude: ${pickedData.latLong.latitude}');
      print('Longitude: ${pickedData.latLong.longitude}');
      print('Address: ${pickedData.address}');
      print('Country: ${pickedData.addressData['country']}');
    }
  }
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map Picker Example")),
      body: Column(
        children: [
          Container(
            child: Column(
              children: [
                Text("Delivery Address"),

              ],
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: _openLocationPicker,
              child: Text('Pick Location'),
            ),
          ),

          TextButton(onPressed: ()async {
            await authController.signOut();

          }, child: Text("SignOut")),
          TextButton(onPressed: ()async {
            await authController.clearSharedPreferences();

          }, child: Text("Clear shared")),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:tibatrade/controllers/firestore_controller.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:date_format/date_format.dart';
// import 'dart:async';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:map_picker/map_picker.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:flutter_svg/flutter_svg.dart';
//
// class Page6Controller extends GetxController {
//   final FirestoreService _firestoreService = FirestoreService();
//   var categories = <Category>[].obs;
//   var selectedCategory = Rx<Category?>(null);
//   var productNameController = TextEditingController();
//   var productPriceController = TextEditingController();
//
//   @override
//   void onInit() {
//     super.onInit();
//   }
//
//
// }
//
// class Page6 extends StatefulWidget {
//   @override
//   State<Page6> createState() => _Page6State();
// }
//
// class _Page6State extends State<Page6> {
//
//   final _controller = Completer<GoogleMapController>();
//   MapPickerController mapPickerController = MapPickerController();
//
//   CameraPosition cameraPosition = const CameraPosition(
//     target: LatLng(41.311158, 69.279737),
//     zoom: 14.4746,
//   );
//
//   var textController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         alignment: Alignment.topCenter,
//         children: [
//           MapPicker(
//             // pass icon widget
//             iconWidget: SvgPicture.asset(
//               "assets/location_icon.svg",
//               height: 60,
//             ),
//             //add map picker controller
//             mapPickerController: mapPickerController,
//             child: GoogleMap(
//               myLocationEnabled: true,
//               zoomControlsEnabled: false,
//               // hide location button
//               myLocationButtonEnabled: false,
//               mapType: MapType.normal,
//               //  camera position
//               initialCameraPosition: cameraPosition,
//               onMapCreated: (GoogleMapController controller) {
//                 _controller.complete(controller);
//               },
//               onCameraMoveStarted: () {
//                 // notify map is moving
//                 mapPickerController.mapMoving!();
//                 textController.text = "checking ...";
//               },
//               onCameraMove: (cameraPosition) {
//                 this.cameraPosition = cameraPosition;
//               },
//               onCameraIdle: () async {
//                 // notify map stopped moving
//                 mapPickerController.mapFinishedMoving!();
//                 //get address name from camera position
//                 List<Placemark> placemarks = await placemarkFromCoordinates(
//                   cameraPosition.target.latitude,
//                   cameraPosition.target.longitude,
//                 );
//
//                 // update the ui with the address
//                 textController.text =
//                 '${placemarks.first.name}, ${placemarks.first.administrativeArea}, ${placemarks.first.country}';
//               },
//             ),
//           ),
//           Positioned(
//             top: MediaQuery.of(context).viewPadding.top + 20,
//             width: MediaQuery.of(context).size.width - 50,
//             height: 50,
//             child: TextFormField(
//               maxLines: 3,
//               textAlign: TextAlign.center,
//               readOnly: true,
//               decoration: const InputDecoration(
//                   contentPadding: EdgeInsets.zero, border: InputBorder.none),
//               controller: textController,
//             ),
//           ),
//           Positioned(
//             bottom: 24,
//             left: 24,
//             right: 24,
//             child: SizedBox(
//               height: 50,
//               child: TextButton(
//                 child: const Text(
//                   "Submit",
//                   style: TextStyle(
//                     fontWeight: FontWeight.w400,
//                     fontStyle: FontStyle.normal,
//                     color: Color(0xFFFFFFFF),
//                     fontSize: 19,
//                     // height: 19/19,
//                   ),
//                 ),
//                 onPressed: () {
//                   print(
//                       "Location ${cameraPosition.target.latitude} ${cameraPosition.target.longitude}");
//                   print("Address: ${textController.text}");
//                 },
//                 style: ButtonStyle(
//                   backgroundColor:
//                   MaterialStateProperty.all<Color>(const Color(0xFFA3080C)),
//                   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                     RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15.0),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
//
// //
// // class Page6 extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     final Page6Controller controller = Get.put(Page6Controller());
// //     var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
// //     User? user = FirebaseAuth.instance.currentUser;
// //
// //     Future<Map<String, dynamic>?> getUserData() async {
// //       User? user = FirebaseAuth.instance.currentUser; // Ensure you have access to the current user
// //       if (user?.email == null) return null;
// //
// //       DocumentSnapshot userDoc = await FirebaseFirestore.instance
// //           .collection('users')
// //           .doc(user?.uid)
// //           .get();
// //       Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
// //
// //       return userData;
// //     }
// //
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         elevation: 0,
// //         backgroundColor: Colors.transparent,
// //         foregroundColor: Colors.black,
// //         title: const Text("PROFILE"),
// //         centerTitle: true,
// //         actions: [
// //           IconButton(
// //             onPressed: () {},
// //             icon: const Icon(Icons.settings_rounded),
// //           )
// //         ],
// //       ),
// //       body: ListView(
// //         padding: const EdgeInsets.all(10),
// //         children: [
// //           // COLUMN THAT WILL CONTAIN THE PROFILE
// //           Column(
// //             children:  [
// //               CircleAvatar(
// //                 radius: 50,
// //                 backgroundImage: NetworkImage(
// //                   "https://images.unsplash.com/photo-1554151228-14d9def656e4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=386&q=80",
// //                 ),
// //               ),
// //               SizedBox(height: 10),
// //               Text(
// //                 "userEmail",
// //                 style: TextStyle(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Text("Junior Product Designer")
// //             ],
// //           ),
// //           const SizedBox(height: 25),
// //           Row(
// //             children: List.generate(5, (index) {
// //               return Expanded(
// //                 child: Container(
// //                   height: 7,
// //                   margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
// //                   decoration: BoxDecoration(
// //                     borderRadius: BorderRadius.circular(10),
// //                     color:  Colors.blue,
// //                   ),
// //                 ),
// //               );
// //             }),
// //           ),
// //           const SizedBox(height: 35),
// //           ...List.generate(
// //             customListTiles.length,
// //                 (index) {
// //               final tile = customListTiles[index];
// //               return Padding(
// //                 padding: const EdgeInsets.only(bottom: 5),
// //                 child: Card(
// //                   elevation: 4,
// //                   shadowColor: Colors.black12,
// //                   child: ListTile(
// //                     leading: Icon(tile.icon),
// //                     title: Text(tile.title),
// //                     // trailing: const Icon(Icons.chevron_right),
// //                   ),
// //                 ),
// //               );
// //             },
// //           )
// //         ],
// //       ),
// //
// //     );
// //   }
// // }
//
// class ProfileCompletionCard {
//   final String title;
//   final String buttonText;
//   final IconData icon;
//   ProfileCompletionCard({
//     required this.title,
//     required this.buttonText,
//     required this.icon,
//   });
// }
//
//
// class CustomListTile {
//   final IconData icon;
//   final String title;
//   CustomListTile({
//     required this.icon,
//     required this.title,
//   });
// }
//
// List<CustomListTile> customListTiles = [
//   CustomListTile(
//     icon: Icons.email,
//     title: "Email:",
//   ),
//   CustomListTile(
//     icon: Icons.location_on_outlined,
//     title: "Location",
//   ),
//   CustomListTile(
//     title: "lastActive",
//     icon: Icons.login,
//   ),
//
// ];
