import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/auth_controller.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  User? loggedInUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  int loyalPoints = 0;
  double walletAmount = 0.0;
  String language = 'English';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        // Fetch user data from Firestore
        fetchUserData();
      }
    } catch (e) {
      print(e);
    }
  }

  void fetchUserData() async {
    print("loggedInUser: $loggedInUser");
    print("loggedInUser: ${loggedInUser!.uid}");

    if (loggedInUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(loggedInUser!.uid).get();
      var userData = userDoc.data();
      print("**********************************************************");
      print("userDoc: ${userDoc.get("firstName")}");
      print("**********************************************************");
      setState(() {
        userName = userDoc.get('firstName');
        loyalPoints = int.parse(userDoc.get('loyalPoints'));
        walletAmount = double.parse(userDoc.get('wallet'));
        language = userDoc.get('language');
      });
    }
  }
  final AuthController authController = Get.find<AuthController>();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.verified, color: Colors.blue),
              ),
              SizedBox(height: 10),
              buildListTile(Icons.person, 'Profile', ''),
              buildListTile(Icons.location_on, 'Addresses', ''),
              buildListTile(Icons.shopping_bag, 'Orders', ''),
              buildListTile(Icons.loyalty, 'Loyal Point', '$loyalPoints Points', Colors.orange),
              buildListTile(Icons.account_balance_wallet, 'Wallet', '$walletAmount EGP', Colors.orange),
              buildListTile(Icons.language, 'Language', language, Colors.orange),
              buildListTile(Icons.favorite_border, 'Wishlist', ''),
              buildListTile(Icons.info_outline, 'About Us', ''),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: ()async {
                  await authController.signOut();
                  // Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile buildListTile(IconData icon, String title, String value, [Color? valueColor]) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(color: valueColor ?? Colors.black),
      ),
    );
  }
}
