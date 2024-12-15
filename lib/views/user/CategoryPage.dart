import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

class CategoryPageController extends GetxController {
  var categories = <Map<dynamic, dynamic>>[].obs;
  var filteredCategories = <Map<dynamic, dynamic>>[].obs;
  final searchController = TextEditingController();

  final DatabaseReference _categoryRef =
  FirebaseDatabase.instance.ref().child('categories');

  @override
  void onInit() {
    super.onInit();
    // Bind the real-time stream to the categories list
    _categoryRef.onValue.listen((event) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      // Filter categories based on Approved_by_admin being true
      List<Map<dynamic, dynamic>> categoryList = data.entries
          .map((entry) => {'key': entry.key, ...entry.value as Map})
          .where((category) => category['Approved_by_admin'] == true)
          .toList();
      categories.value = categoryList;
      filteredCategories.value = categoryList;
    });

    // Set up a listener for the search input
    searchController.addListener(() {
      filterCategories(searchController.text);
    });
  }

  void filterCategories(String query) {
    if (query.isEmpty) {
      filteredCategories.value = categories;
    } else {
      filteredCategories.value = categories
          .where((category) => category['name']
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    }
  }
}
/// Category Page
class CategoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CategoryPageController controller = Get.put(CategoryPageController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Categories', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search Category',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                if (controller.filteredCategories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredCategories.length,
                  itemBuilder: (context, index) {
                    var category = controller.filteredCategories[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to Product Page on category tap
                        Get.to(() =>
                            ProductPage(categoryName: category['name']));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: CategoryCard(
                          name: category['name'],
                          imageUrl: category['URL'],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category Card Widget
class CategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;

  const CategoryCard({
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows the image to overflow the card
      children: [
        Card(
          color: const Color(0xC9FFE0C5).withOpacity(0.79),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Container(
            height: 50, // Reduced height
            width: double.infinity, // Full width
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Text aligned in the middle of the card
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF053C1D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 5, // Overflow control, adjust based on the image height
          right: 16, // Align the image to the right
          child: Container(
            height: 80, // Set the desired height for the image
            width: 80, // Set the width for the image
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Circle shape for the image
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Product Page Controller
class ProductPageController extends GetxController {
  var products = <Map<dynamic, dynamic>>[].obs;
  var filteredProducts = <Map<dynamic, dynamic>>[].obs;
  final searchController = TextEditingController();

  final DatabaseReference _productRef =
  FirebaseDatabase.instance.ref().child('products');

  void fetchProducts(String categoryName) {
    _productRef.orderByChild('category_name').equalTo(categoryName).onValue.listen((event) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      // Filter products based on Approved_by_admin being true
      List<Map<dynamic, dynamic>> productList = data.entries
          .map((entry) => {'key': entry.key, ...entry.value as Map})
          .where((product) => product['Approved_by_admin'] == true)
          .toList();
      products.value = productList;
      filteredProducts.value = productList;
    });

    // Set up a listener for the search input
    searchController.addListener(() {
      filterProducts(searchController.text);
    });
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products
          .where((product) => product['name_english']
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    }
  }
}


//// Product Page
class ProductPage extends StatelessWidget {
  final String categoryName;

  const ProductPage({Key? key, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductPageController controller = Get.put(ProductPageController());
    controller.fetchProducts(categoryName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Products', style: TextStyle(color: Colors.black)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: controller.searchController,
                decoration: InputDecoration(
                  hintText: 'Search Product',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Obx(() {
                // Check if there are any products
                if (controller.products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nothing here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                // If products are loading
                if (controller.filteredProducts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    var product = controller.filteredProducts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ProductCard(
                        name: product['name_english'],
                        imageUrl: product['URL'],
                        price: product['primary_price'].toString(),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}


/// Product Card Widget
class ProductCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String price;

  const ProductCard({
    required this.name,
    required this.imageUrl,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows the image to overflow the card
      children: [
        Card(
          color: const Color(0xC9FFE0C5).withOpacity(0.79),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Container(
            height: 70, // Adjusted height
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Color(0xFF053C1D),
                          ),
                        ),
                        Text(
                          "\$ $price",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w300,
                            fontSize: 14,
                            color: Color(0xFF053C1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 5, // Overflow control, adjust based on the image height
          right: 16, // Align the image to the right
          child: Container(
            height: 80, // Set the desired height for the image
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
