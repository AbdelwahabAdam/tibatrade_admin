import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // For Firebase Realtime Database
import 'package:carousel_slider/carousel_slider.dart'; // For image slider
import 'package:get/get.dart'; // If using GetX for state management

class Page7 extends StatefulWidget {
  @override
  _Page7State createState() => _Page7State();
}

class _Page7State extends State<Page7> {
  // References to Firebase Realtime Database
  final DatabaseReference _productRef =
      FirebaseDatabase.instance.ref().child('categories');
  final DatabaseReference _offersRef =
      FirebaseDatabase.instance.ref().child('Offers');
  final DatabaseReference _bannerRef =
      FirebaseDatabase.instance.ref().child('banner');

  // Example data (dropdown, search query)
  String? _selectedAddress;
  List<String> _addresses = [
    'Glim Alexandria - Egypt',
    'Cairo - Egypt'
  ]; // Placeholder addresses

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50,),
            // Delivery Address Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Address',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
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
                            // height: 19/19,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedAddress = newValue;
                      });
                    },
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
            SizedBox(height: 20),
            // Announcement Image (Fetched from Firebase)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder(
                future: _bannerRef.get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    var bannerData =
                        snapshot.data!.value as Map<dynamic, dynamic>;
                    return Image.network(
                      bannerData['URL'],
                      fit: BoxFit.cover,
                    );
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
            const SizedBox(height: 20),
            // The Spotlight Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('The Spotlight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    return Image.network(offer['URL'], fit: BoxFit.cover);
                  }).toList();

                  return CarouselSlider(
                    items: offerImages,
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      enlargeCenterPage: true,
                    ),
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 20),
            // Top Picks For You Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Top Picks For You',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),
            // Product Cards GridView
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder(
                future: _productRef.get(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.hasData) {
                    Map<dynamic, dynamic> categories =
                        snapshot.data!.value as Map<dynamic, dynamic>;

                    // Collecting all products from all categories
                    List<Map<dynamic, dynamic>> products = [];
                    categories.forEach((key, categoryData) {
                      Map<dynamic, dynamic> categoryProducts =
                          categoryData['products'];
                      categoryProducts.forEach((productId, productData) {
                        products.add(productData);
                      });
                    });
                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          NeverScrollableScrollPhysics(), // Prevent scroll conflict
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        var product = products[index];
                        return ProductCard(
                          name: product['name'],
                          price: product['price'],
                          imageUrl: product['URL'],
                        );
                      },
                    );
                  }
                  return Center(
                      child: CircularProgressIndicator()); // Loading state
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
            child: Text(name, style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('\$${price.toString()}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          Spacer(),
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
