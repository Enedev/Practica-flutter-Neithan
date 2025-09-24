import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String _baseUrl = 'https://fakestoreapi.com';

  // GET: Fetch all products
  // En ApiService
  Future<List<Product>> getProducts({String? category}) async {
    String url = '$_baseUrl/products';

    // Si se proporciona una categoría, ajustamos la URL
    if (category != null) {
      url = '$_baseUrl/products/category/$category';
    }

    // Agregamos el límite de 20 para mejorar el rendimiento
    url = '$url?limit=10';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // GET: Fetch a single product by ID
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/products/$id'));

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to load product');
    }
  }

  // POST: Add a new product
  Future<Product> addProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toMap()),
    );

    if (response.statusCode == 201) {
      final dynamic data = json.decode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to add product');
    }
  }

  // PUT: Update an existing product
  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toMap()),
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to update product');
    }
  }

  // DELETE: Delete a product by ID
  Future<void> deleteProduct(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/products/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }
}
