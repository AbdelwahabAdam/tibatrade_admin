import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<List<Category>> getCategories() async {
    var snapshot = await _db.collection('categories').get();
    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }

  Future<void> addProductToCategory(String categoryId, String productName, double productPrice) async {
    var categoryRef = _db.collection('categories').doc(categoryId);
    await categoryRef.collection('products').add({
      'name': productName,
      'price': productPrice,
    });
  }

  Stream<List<Category>> getCategoriesWithProducts() {
    return _db.collection('categories').snapshots().asyncMap((snapshot) async {
      var categories = await Future.wait(snapshot.docs.map((doc) async {
        var category = Category.fromFirestore(doc);
        var productsSnapshot = await doc.reference.collection('products').get();
        category.products = productsSnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        return category;
      }).toList());
      return categories;
    });
  }
  Future<void> deleteProduct(String categoryId, String productId) async {
    await _db.collection('categories').doc(categoryId).collection('products').doc(productId).delete();
  }
  Future<void> populateRandomData() async {
    // Define sample data
    List<Map<String, dynamic>> categories = [
      {'name': 'Milk', 'products': [
        {'name': 'Mara3y', 'price': 1000.0},
        {'name': 'B5ero', 'price': 500.0}
      ]},
      {'name': 'Water', 'products': [
        {'name': 'Elano', 'price': 50.0},
        {'name': 'Aqua fina', 'price': 80.0}
      ]}
    ];

    // Populate Firestore with sample data
    for (var categoryData in categories) {
      DocumentReference categoryRef = await _db.collection('categories').add({
        'name': categoryData['name'],
      });
      for (var productData in categoryData['products']) {
        await categoryRef.collection('products').add({
          'name': productData['name'],
          'price': productData['price'],
        });
      }
    }
  }
}

class Category {
  final String id;
  final String name;
  List<Product> products;

  Category({required this.id, required this.name, this.products = const []});

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
    );
  }
}