import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:get/get.dart';
import '../authentication/login_screen.dart';
import 'dart:async';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {

  int currentImageIndex = 0;
  List<String> images = [
    'splash_20.png',
    'splash_21.png',
    'splash_22.png',
    'splash_23.png',

  ];
  late Timer _timer;

  final PageController _pageController = PageController();
  final PageController _pageController2 = PageController();

  @override
  void initState() {
    super.initState();


      _timer = Timer.periodic(Duration(seconds: 4), (timer) {
        setState(() {
          currentImageIndex = (currentImageIndex + 1) % images.length;
        });
        if (currentImageIndex == images.length - 1) {
          _timer.cancel();
        }
      });


  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // IntroductionScreen with scrollController and custom navigation buttons
          IntroductionScreen(
            scrollControllers: [ _pageController, _pageController2 ],
            globalBackgroundColor: Colors.white,
            pages: [
              PageViewModel(
                useScrollView:true,
                reverse: true,
                titleWidget: const SizedBox(height: 50),
                bodyWidget: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        "All You Need And More!",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 33,
                          height: 1.14,
                          color: Color(0xFF0A5129),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 50),
                    Center(
                      child: Image(
                        image: AssetImage('assets/images/splash_1.png'),
                        height: 268,
                        width: 362,
                      ),
                    ),
                    SizedBox(height: 50),
                    Text(
                      "Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem ",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.14,
                        color: Color(0xFF676767),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              PageViewModel(
                useScrollView:true,
                reverse: true,
                titleWidget: const SizedBox(height: 50),
                bodyWidget:  Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text(
                        "Get Your Package Delivered Safely To You",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 33,
                          height: 1.14,
                          color: Color(0xFF0A5129),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: Image(
                        image: AssetImage('assets/images/${images[currentImageIndex]}',),
                        height: 268,
                        width: 362,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem Lorem ",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.14,
                        color: Color(0xFF676767),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            onDone: () => Get.offAll(LoginScreen()), // Handles the Done button
            showNextButton: true,
            showDoneButton: true,
            isProgress: true,
            isProgressTap: true,
            nextStyle: TextButton.styleFrom(
              alignment: Alignment.center,
              backgroundColor: const Color(0xFF0A5129),
              padding: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
              ),
              maximumSize: const Size(double.infinity, 50),
            ),
            doneStyle: TextButton.styleFrom(
              alignment: Alignment.center,
              backgroundColor: const Color(0xFF0A5129),
              padding: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
              ),
              maximumSize: const Size(double.infinity, 50),
            ),
            next: const Text(
              "Next",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            done: const Text(
              "Done",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            nextFlex: 1,
          ),

          // Skip button positioned at the top right
          Positioned(
            top: 40,
            right: 16,
            child: TextButton(
              onPressed: () => Get.to(() => LoginScreen()),
              child: const Text(
                "Skip",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0A5129),
                ),
              ),
            ),
          ),

          // Positioned circles (for decoration)
          Positioned(
            top: -59,
            right: -90,
            child: Container(
              width: 204,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA85B).withOpacity(0.21),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -96,
            child: Container(
              width: 230,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFFCA85B).withOpacity(0.21),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
