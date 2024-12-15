import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tibatrade/views/home_screen.dart';
import 'package:tibatrade/views/authentication/login_screen.dart';
import '../views/intro_screens/intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notification_controller.dart';

class AuthController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final NotificationService _notificationService = NotificationService();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // AuthController(this.flutterLocalNotificationsPlugin);
  var isLoading = false.obs;
  var isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(isLoggedIn, handleAuthChanged);
    auth.authStateChanges().listen((User? user) {
      isLoggedIn(user != null);
    });
    _checkFirstSeen();
    _initFCM();
    _startListeningToDatabase();
  }

  void _startListeningToDatabase() {
    _databaseReference.child('your_node').onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        _notificationService.showNotification(event.snapshot.value.toString());
      }
    });
  }
  Future<bool> isAdmin() async {
    User? user = auth.currentUser;

    if (user?.email == null) return false;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userDoc.exists) {
        bool isAdmin = userData?["isAdmin"];
        return isAdmin;
      } else {
        return false;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return false;
    }
  }

  Future <void> handleAuthChanged(bool isLoggedIn) async{
    if (Get.isRegistered<GetMaterialController>()) {
      if (isLoggedIn) {
        _saveUserDetails();
        Get.offAll(() => HomeScreen());
      } else {
        _checkFirstSeen();
      }
    } else {
      Future.delayed(Duration(milliseconds: 100), () => handleAuthChanged(isLoggedIn));
    }
  }

  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _checkFirstSeen() async {
    // Initialize SharedPreferences to check if 'seen' is already set
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);

    // If the app has been seen before, check authentication state
    if (_seen) {
      // Check if a user is authenticated
      if (auth.currentUser != null) {
        // Navigate to HomeScreen if user is authenticated
        Get.offAll(() => HomeScreen());
      } else {
        // Navigate to LoginScreen if user is not authenticated
        Get.offAll(() => LoginScreen());
      }
    } else {
      // If the app is being opened for the first time
      prefs.setBool('seen', true); // Set 'seen' to true for future checks
      Get.offAll(() => IntroScreen()); // Navigate to IntroScreen
    }
  }

  Future<void> _saveUserDetails() async {
    String? token = await messaging.getToken();
    User? user = auth.currentUser;

    if (user != null) {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'deviceToken': token,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _initFCM() async {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Got a message whilst the app was terminated!');
        print('Message data: ${message.data}');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show notification
        _showNotification(message.notification);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Handle the notification click event
    });


    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showNotification(RemoteNotification? notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',  // Use named parameters
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      notification?.title,
      notification?.body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }



  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }
  // Sign Up
  Future<void> signUp(String firstName, String lastName,String email, String phoneNumber, String password, String businessName, String location) async {
    try {
      isLoading(true);
      await auth.createUserWithEmailAndPassword(email: email, password: password);
      String? token = await messaging.getToken();
      User? user = auth.currentUser;

      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'firstName': firstName,
          'lastName': lastName,
          'location': location,
          'phoneNumber': phoneNumber,
          'businessName': businessName,
          'verified': false,
          'isAdmin': false,
          'lastActive': DateTime.now(),
          'deviceToken': token,
        }, SetOptions(merge: true));
      }

    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Sign In
  Future<void> signIn(String email, String password) async {
    try {
      isLoading(true);
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      isLoading(true);
      await auth.sendPasswordResetEmail(email: email);
      Get.snackbar('Success', 'Password reset email sent');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      isLoading(true);
      await auth.signOut();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading(false);
    }
  }
}
