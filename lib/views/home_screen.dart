import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/auth_controller.dart';
import 'package:tibatrade/views/admin/category/admin_add_category.dart';
import 'package:tibatrade/views/admin/category/admin_approve_category.dart';
import 'package:tibatrade/views/admin/category/admin_edit_category.dart';
import 'admin/banner/admin_add_banner.dart';
import 'admin/banner/admin_approve_banner.dart';
import 'admin/banner/admin_edit_banner.dart';
import 'admin/offer/admin_add_offer.dart';
import 'admin/offer/admin_approve_offer.dart';
import 'admin/offer/admin_edit_offer.dart';
import 'admin/order/admin_edit_order.dart';
import 'admin/product/admin_add_product.dart';
import 'admin/product/admin_approve_product.dart';
import 'admin/product/admin_edit_product.dart';
import 'admin/sub_category/admin_add_sub_category.dart';
import 'admin/sub_category/admin_approve_sub_category.dart';
import 'admin/sub_category/admin_edit_sub_category.dart';
import 'admin/admin_page3.dart';
import 'admin/admin_page4.dart';
import 'admin/admin_page5.dart';
import 'user/CategoryPage.dart';
import 'user/user_page2.dart';
import 'user/user_page3.dart';
import 'user/user_page4.dart';
import 'user/user_page5.dart';
import 'user/user_page6.dart';
import 'user/HomePage.dart';
import 'user/userProfile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Widget> _widgetOptions = [];
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = true;
  bool isAdmin = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _setWidgetOptions();
    _initializeFirebaseMessaging();
  }

  void _initializeFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showNotification(
            message.notification!.title, message.notification!.body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });

    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> _setWidgetOptions() async {
    isAdmin = await authController.isAdmin();
    setState(() {
      _widgetOptions = isAdmin
          ? <Widget>[
              AdminAddProduct(),
              AdminEditProduct(),
              AdminApproveProduct(),

              AdminAddCategory(),
              AdminEditCategory(),
              AdminApproveCategory(),

        AdminAddSubCategory(),
        AdminEditSubCategory(),
        AdminApproveSubCategory(),

              AdminAddOffer(),
              AdminEditOffer(),
        AdminApproveOffer(),

        AdminAddBanner(),
        AdminEditBanner(),
        AdminApproveBanner(),

        AdminEditOrder(),
              AdminPage3(),
            ]
          : <Widget>[
        HomePage(),
        CategoryPage(),
              Page6(),
              UserProfilePage(),
              // Page5(),
            ];
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _widgetOptions.elementAt(_selectedIndex),
      appBar: isAdmin
          ? AppBar(
              title: Text("Admin Home"),
              actions: isAdmin
                  ? [
                      IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: () async {
                          await authController.signOut();
                          _selectedIndex = 0;
                          // Get.offAll(() => HomeScreen());
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await authController.clearSharedPreferences();
                        },
                      ),
                    ]
                  : [
                      IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: () async {
                          await authController.signOut();
                          _selectedIndex = 0;
                          // Get.offAll(() => HomeScreen());
                        },
                      ),
                    ],
            )
          : null,
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: GNav(
              gap: 8,
              color: Colors.black,
              activeColor: Colors.white,
              // tabBackgroundColor: const Color(0xFF0F7C9E),
              padding: EdgeInsets.all(16),
              tabs: isAdmin
                  ? [
                      GButton(
                        icon: Icons.add,
                        iconColor: Colors.black,
                        text: 'Add Product',
                        backgroundColor: const Color(0xFF0F7C9E).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.edit,
                        text: 'Edit Product',
                        backgroundColor:const Color(0xFF0F7C9E).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.done_outline_rounded,
                        text: 'Approve Product',
                        backgroundColor: const Color(0xFF0F7C9E).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.add,
                        text: 'Add Category',
                        backgroundColor: const Color(0xFFDD5227).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.edit,
                        backgroundColor: const Color(0xFFDD5227).withOpacity(0.67),
                        text: 'Edit Category',
                      ),
                      GButton(
                        icon: Icons.done_outline_rounded,
                        text: 'Approve Category',
                        backgroundColor: const Color(0xFFDD5227).withOpacity(0.67),
                        textColor: Colors.white,
                      ),

                GButton(
                  icon: Icons.add,
                  text: 'Add Sup Category',
                  backgroundColor: const Color(0xFFDD5227).withOpacity(0.50),
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.edit,
                  backgroundColor: const Color(0xFFDD5227).withOpacity(0.50),
                  text: 'Edit Sup Category',
                ),
                GButton(
                  icon: Icons.done_outline_rounded,
                  text: 'Approve Sup Category',
                  backgroundColor: const Color(0xFFDD5227).withOpacity(0.50),
                  textColor: Colors.white,
                ),




                      GButton(
                        icon: Icons.add,
                        iconColor: Colors.black,
                        text: 'Add Offer',
                        backgroundColor:const Color(0xFF02723C).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.edit,
                        text: 'Edit Offer',
                        backgroundColor: const Color(0xFF02723C).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.done_outline_rounded,
                        text: 'Approve Offer',
                        backgroundColor: const Color(0xFF02723C).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.add,
                        text: 'Add Panner',
                        backgroundColor: const Color(0xFFDD5227).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.edit,
                        text: 'Edit Panner',
                        backgroundColor: Color(0xFF755DBA).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.done_outline_rounded,
                        text: 'Approve Panner',
                        backgroundColor: Color(0xFF755DBA).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        icon: Icons.delivery_dining,
                        text: 'Orders',
                        backgroundColor: Color(0xFF755DBA).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                GButton(
                        icon: Icons.edit,
                        text: 'Edit Orders',
                        backgroundColor: Color(0xFF755DBA).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                    ]
                  : [
                      GButton(
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        icon: Icons.home,
                        text: 'Home',
                        backgroundColor: Color(0xFF0F7C9E).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        icon: Icons.shopping_bag_outlined,
                        text: 'Categories',
                        backgroundColor: Color(0xFF02723C).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        icon: Icons.shopping_cart_outlined,
                        text: 'Cart',
                        backgroundColor: Color(0xFFDD5227).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                      GButton(
                        textStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        icon: Icons.more_horiz,
                        text: 'More',
                        backgroundColor: Color(0xFF755DBA).withOpacity(0.67),
                        textColor: Colors.white,
                      ),
                    ],
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
