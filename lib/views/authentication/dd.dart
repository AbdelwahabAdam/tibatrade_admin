// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:tibatrade/views/authentication/login_screen.dart';
// import '../../controllers/auth_controller.dart';
//
// class SignUpScreen extends StatefulWidget {
//   SignUpScreen({super.key});
//
//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final AuthController authController = Get.find<AuthController>();
//
//   final TextEditingController firstNameController = TextEditingController();
//   final TextEditingController lastNameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController confirmPasswordController =
//       TextEditingController();
//   final TextEditingController locationController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//
//   // Add a controller for Business Name
//   final TextEditingController businessNameController = TextEditingController();
//
//   ScrollController _scrollController = ScrollController();
//   bool _isScrolled = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _scrollController.addListener(() {
//       if (_scrollController.offset > 100 && !_isScrolled) {
//         setState(() {
//           _isScrolled = true;
//         });
//       } else if (_scrollController.offset <= 100 && _isScrolled) {
//         setState(() {
//           _isScrolled = false;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose(); // Dispose the controller to avoid memory leaks
//     super.dispose();
//   }
//
//   String countryCode = "+1"; // Default country code
//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       extendBodyBehindAppBar: true, // Extends the body behind the AppBar
//       appBar: AppBar(
//         backgroundColor: _isScrolled
//             ? Colors.white // AppBar becomes solid after scrolling
//             : Colors.transparent, // Initially transparent
//         elevation: _isScrolled ? 4 : 0, // Show shadow only when scrolled
//         title: const Text(
//           'Sign Up',
//           style: TextStyle(
//             fontFamily: 'InriaSerif',
//             fontWeight: FontWeight.w700,
//             fontSize: 32,
//             height: 1.14, // Line height
//             color: Color(0xFF0A5129),
//           ),
//         ),
//       ),
//       body: Stack(
//         children: [
//           // Background half circles (visual decorations)
//           Positioned(
//             top: -59,
//             right: -90,
//             child: Container(
//               width: 204,
//               height: 210,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFCA85B).withOpacity(0.21),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -50,
//             left: -96,
//             child: Container(
//               width: 230,
//               height: 210,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFCA85B).withOpacity(0.21),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           SingleChildScrollView(
//             controller: _scrollController, // Assign the scroll controller
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: screenHeight * 0.18), // Space under AppBar
//
//                   // First Name Field
//                   const Text(
//                     'First Name',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10.0),
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                       child: TextField(
//                         controller: firstNameController,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           labelText: 'First Name',
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//                   // Last Name Field
//                   const Text(
//                     'Last Name',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10.0),
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                       child: TextField(
//                         controller: lastNameController,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           labelText: 'Last Name',
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//                   // Business Name Field
//                   const Text(
//                     'Business Name',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10.0),
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                       child: TextField(
//                         controller: businessNameController,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           labelText: 'Business Name',
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//                   // Remaining fields go here (email, phone number, etc.)
//                   // Email Field
//                   const Text(
//                     'Email',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10.0),
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                       child: TextField(
//                         controller: emailController,
//                         decoration: const InputDecoration(
//                           border: InputBorder.none,
//                           labelText: 'Email',
//                         ),
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//                   // Other fields (Password, etc.)
//
//                   Obx(() => authController.isLoading.value
//                       ? const CircularProgressIndicator()
//                       : SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: () {
//                               String fullPhoneNumber =
//                                   countryCode + phoneController.text;
//
//                               authController.signUp(
//                                 firstNameController.text,
//                                 lastNameController.text,
//                                 emailController.text,
//                                 fullPhoneNumber,
//                                 passwordController.text,
//                                 businessNameController
//                                     .text, // Pass Business Name here
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor: const Color(0xFF00572D)),
//                             child: const Padding(
//                               padding: EdgeInsets.all(16.0),
//                               child: Text(
//                                 'Sign Up',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 16.0,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         )),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// //
// //
// //   {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       home: Scaffold(
// //         body: SingleChildScrollView(
// //           child: Container(
// //             padding: const EdgeInsets.symmetric(horizontal: 40),
// //             height: MediaQuery.of(context).size.height - 50,
// //             width: double.infinity,
// //             child: Column(
// //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: <Widget>[
// //                 Column(
// //                   children: <Widget>[
// //                     const SizedBox(height: 60.0),
// //                     const Text(
// //                       "Sign up",
// //                       style: TextStyle(
// //                         fontSize: 30,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     Text(
// //                       "Create your account",
// //                       style: TextStyle(fontSize: 15, color: Colors.grey[700]),
// //                     ),
// //                   ],
// //                 ),
// //                 Column(
// //                   children: <Widget>[
// //                     TextField(
// //                       controller: firstNameController,
// //                       decoration: InputDecoration(
// //                         hintText: "First Name",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.person),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: lastNameController,
// //                       decoration: InputDecoration(
// //                         hintText: "Last Name",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.person),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: emailController,
// //                       decoration: InputDecoration(
// //                         hintText: "Email",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.email),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: passwordController,
// //                       decoration: InputDecoration(
// //                         hintText: "Password",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.lock),
// //                       ),
// //                       obscureText: true,
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: confirmPasswordController,
// //                       decoration: InputDecoration(
// //                         hintText: "Confirm Password",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.lock),
// //                       ),
// //                       obscureText: true,
// //                     ),
// //                     const SizedBox(height: 20),
// //                     TextField(
// //                       controller: locationController,
// //                       decoration: InputDecoration(
// //                         hintText: "Location",
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(18),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                         fillColor: Colors.purple.withOpacity(0.1),
// //                         filled: true,
// //                         prefixIcon: const Icon(Icons.location_on),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 Obx(
// //                   () => authController.isLoading.value
// //                       ? CircularProgressIndicator()
// //                       : ElevatedButton(
// //                           onPressed: () {
// //                             if (passwordController.text !=
// //                                 confirmPasswordController.text) {
// //                               Get.snackbar("Error", "Passwords do not match");
// //                               return;
// //                             }
// //
// //                             authController.signUp(
// //                               emailController.text,
// //                               passwordController.text,
// //                               firstNameController.text,
// //                               lastNameController.text,
// //                               locationController.text,
// //                             );
// //                           },
// //                           child: const Text(
// //                             "Sign up",
// //                             style: TextStyle(fontSize: 20, color: Colors.white),
// //                           ),
// //                           style: ElevatedButton.styleFrom(
// //                             shape: const StadiumBorder(),
// //                             padding: const EdgeInsets.symmetric(vertical: 16),
// //                             backgroundColor: Colors.purple,
// //                           ),
// //                         ),
// //                 ),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: <Widget>[
// //                     const Text("Already have an account?"),
// //                     TextButton(
// //                       onPressed: () {},
// //                       child: const Text(
// //                         "Login",
// //                         style: TextStyle(color: Colors.purple),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
