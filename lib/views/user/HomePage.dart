import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:carousel_slider/carousel_slider.dart'; // For image slider
import 'package:get/get.dart'; // If using GetX for state management
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _productRef =
      FirebaseDatabase.instance.ref().child('products');
  final DatabaseReference _offersRef =
      FirebaseDatabase.instance.ref().child('Offers');
  final DatabaseReference _bannerRef =
      FirebaseDatabase.instance.ref().child('banner');
  String? _selectedAddress;
  List<String> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchUserAddresses();
  }

  Future<void> _fetchUserAddresses() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    String userId = user!.uid;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      var locationData = userDoc['location'];

      if (locationData is List) {
        setState(() {
          _addresses = locationData
              .map((location) => location['name'] as String)
              .toList();
          if (_addresses.isNotEmpty) {
            _selectedAddress = _addresses[0];
          } else {
            _selectedAddress = null;
          }
        });
      }
    } else {
      setState(() {
        _addresses = []; // Handle case when no addresses exist
        _selectedAddress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Address',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _addresses.isNotEmpty
                      ? DropdownButton<String>(
                          value: _selectedAddress,
                          hint: Text('Select Address'),
                          items: _addresses.map((String address) {
                            return DropdownMenuItem<String>(
                              value: address,
                              child: Text(
                                address,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontStyle: FontStyle.normal,
                                  color: Color(0xFF00481B),
                                  fontSize: 15,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedAddress = newValue;
                            });
                          },
                        )
                      : ElevatedButton(
                          onPressed: () {
                            // Handle adding location, for example navigate to another screen
                            // Navigator.push(...);
                          },
                          child: Text('Add Address'),
                        ),
                ],
              ),
            ),
            // Search Bar Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Announcement Image (Fetched from Firebase)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder(
                future: _bannerRef.get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var bannerData = snapshot.data!.value as Map<dynamic, dynamic>;

                    // Find the banner with the latest date
                    var latestBanner;
                    DateTime latestDate = DateTime(2000); // Initialize with a past date

                    bannerData.forEach((key, value) {
                      DateTime date = DateTime.parse(value['date']);
                      if (date.isAfter(latestDate)) {
                        latestDate = date;
                        latestBanner = value;
                      }
                    });

                    if (latestBanner != null) {
                      print("Latest Banner Data: $latestBanner");
                      return Image.network(
                        latestBanner['URL'],
                        fit: BoxFit.cover,
                        width: 343,
                        height: 103,
                      );
                    } else {
                      return Text('No banner found');
                    }
                  }
                  return Center(child: CircularProgressIndicator());
                },
              )
            ),
            const SizedBox(height: 20),
            // The Spotlight Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'The Spotlight',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  color: Color(0xFF1D1E20),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Vertical Slider for Spotlight Offers (Fetched from Firebase)
            FutureBuilder(
              future: _offersRef.get(),
              builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                if (snapshot.hasData) {
                  Map<dynamic, dynamic> offersData =
                      snapshot.data!.value as Map<dynamic, dynamic>;
                  List<Widget> offerImages = offersData.values.map((offer) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(
                          15.0), // Adjust the radius for the desired roundness
                      child: Image.network(
                        offer['URL'],
                        fit: BoxFit.cover,
                        height: 100,
                        width: 300,
                      ),
                    );
                  }).toList();

                  return CarouselSlider(
                    items: offerImages,
                    options: CarouselOptions(
                      height: 100,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      // aspectRatio: 5
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 30),
            // Top Picks For You Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Top Picks For You',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.normal,
                  color: Color(0xFF1D1E20),
                  fontSize: 16,
                ),
              ),
            ),
            // Product Cards GridView
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder(
                future: _productRef.get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    Map<dynamic, dynamic> productsData =
                    snapshot.data!.value as Map<dynamic, dynamic>;

                    // Collecting all products from the 'products' node
                    List<Map<dynamic, dynamic>> products = [];
                    productsData.forEach((productId, productData) {
                      products.add(productData as Map<dynamic, dynamic>);
                    });

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(), // Prevent scroll conflict
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var product = products[index];
                        return ProductCard(
                          name: product['name_english'], // Product name in English
                          price: product['primary_price'].toDouble(), // Primary price of the product
                          imageUrl: product['URL'], // Product image URL
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator()); // Loading state
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Card Widget
class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String imageUrl;

  const ProductCard({
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageUrl,
              fit: BoxFit.cover, height: 100, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(name, style: const TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('\$${price.toString()}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                // Add to cart logic here
              },
            ),
          ),
        ],
      ),
    );
  }
}
