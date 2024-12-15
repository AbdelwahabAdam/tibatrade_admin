import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/firestore_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';

class Page5Controller extends GetxController {
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
}

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Page5Controller controller = Get.put(Page5Controller());
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    User? user = FirebaseAuth.instance.currentUser;

    Future<Map<String, dynamic>?> getUserData() async {
      if (user?.email == null) return null;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      return userData;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text("PROFILE"),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("No user data available"));
          } else {
            var userData = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // COLUMN THAT WILL CONTAIN THE PROFILE
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                       "https://images.unsplash.com/photo-1554151228-14d9def656e4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=386&q=80",
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      userData["firstName"] ?? "userName",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(userData["lastName"] ?? ""),
                  ],
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 7,
                        margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:  Colors.blue,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 35),
                ...List.generate(
                  customListTiles.length,
                      (index) {
                    final tile = [
                      CustomListTile(
                        icon: Icons.email,
                        title: "Email: ${userData['email']}",
                      ),
                      CustomListTile(
                        icon: Icons.location_on_outlined,
                        title: "Location: ${userData['location']}",
                      ),
                      CustomListTile(
                        title: "lastActive: ${formatDate(userData['lastActive'].toDate(), [yyyy, '-', M, '-', d])}",
                        icon: Icons.login,
                      ),

                    ][index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        child: ListTile(
                          leading: Icon(tile.icon),
                          title: Text(tile.title),
                          // trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                )
              ],
            );
          }
        },
      ),
    );
  }
}

//
// class Page5 extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final Page5Controller controller = Get.put(Page5Controller());
//     var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
//     User? user = FirebaseAuth.instance.currentUser;
//
//     Future<Map<String, dynamic>?> getUserData() async {
//       User? user = FirebaseAuth.instance.currentUser; // Ensure you have access to the current user
//       if (user?.email == null) return null;
//
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user?.uid)
//           .get();
//       Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
//
//       return userData;
//     }
//
//
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         foregroundColor: Colors.black,
//         title: const Text("PROFILE"),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             onPressed: () {},
//             icon: const Icon(Icons.settings_rounded),
//           )
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(10),
//         children: [
//           // COLUMN THAT WILL CONTAIN THE PROFILE
//           Column(
//             children:  [
//               CircleAvatar(
//                 radius: 50,
//                 backgroundImage: NetworkImage(
//                   "https://images.unsplash.com/photo-1554151228-14d9def656e4?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=386&q=80",
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 "userEmail",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text("Junior Product Designer")
//             ],
//           ),
//           const SizedBox(height: 25),
//           Row(
//             children: List.generate(5, (index) {
//               return Expanded(
//                 child: Container(
//                   height: 7,
//                   margin: EdgeInsets.only(right: index == 4 ? 0 : 6),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     color:  Colors.blue,
//                   ),
//                 ),
//               );
//             }),
//           ),
//           const SizedBox(height: 35),
//           ...List.generate(
//             customListTiles.length,
//                 (index) {
//               final tile = customListTiles[index];
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 5),
//                 child: Card(
//                   elevation: 4,
//                   shadowColor: Colors.black12,
//                   child: ListTile(
//                     leading: Icon(tile.icon),
//                     title: Text(tile.title),
//                     // trailing: const Icon(Icons.chevron_right),
//                   ),
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//
//     );
//   }
// }

class ProfileCompletionCard {
  final String title;
  final String buttonText;
  final IconData icon;
  ProfileCompletionCard({
    required this.title,
    required this.buttonText,
    required this.icon,
  });
}


class CustomListTile {
  final IconData icon;
  final String title;
  CustomListTile({
    required this.icon,
    required this.title,
  });
}

List<CustomListTile> customListTiles = [
  CustomListTile(
    icon: Icons.email,
    title: "Email:",
  ),
  CustomListTile(
    icon: Icons.location_on_outlined,
    title: "Location",
  ),
  CustomListTile(
    title: "lastActive",
    icon: Icons.login,
  ),

];