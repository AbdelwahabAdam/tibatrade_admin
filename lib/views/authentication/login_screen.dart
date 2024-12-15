import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tibatrade/controllers/auth_controller.dart';
import 'signup_screen.dart';
import 'forget_password_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height; // Get the screen height

    return Scaffold(
      extendBodyBehindAppBar: true, // Extends the body behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow of the AppBar
        title: const Text(
          'Log In',
          style: TextStyle(
            fontFamily: 'InriaSerif',
            fontWeight: FontWeight.w700,
            fontSize: 32,
            height: 1.14, // Line height
            color: Color(0xFF0A5129),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background half circles
          Positioned(
            top: -59, // Adjust to position correctly
            right: -90, // Adjust to position correctly
            child: Container(
              width: 204,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA85B)
                    .withOpacity(0.21), // Set the text color here
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50, // Adjust to position correctly
            left: -96, // Adjust to position correctly
            child: Container(
              width: 230,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA85B)
                    .withOpacity(0.21), // Set the text color here
                shape: BoxShape.circle,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight*0.18), // Adjust space under the AppBar
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                            border: InputBorder.none, labelText: 'Email'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            border: InputBorder.none, labelText: 'Password'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () => Get.to(() => ForgetPasswordScreen()),
                      child: const Text('Forget your password?'),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't Have Any Account ?",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => SignUpScreen()),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFFC2430D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Obx(() => authController.isLoading.value
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () {
                                authController.signIn(emailController.text,
                                    passwordController.text);
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    const Color(0xFF00572D)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                  ),
                                ),
                              )),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
