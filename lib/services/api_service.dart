import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String _baseUrl = 'https://dummyjson.com';

  Future<List<Product>> getProducts({int limit = 10, int skip = 0}) async {
    final url = Uri.parse('$_baseUrl/products?limit=$limit&skip=$skip');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // NUEVO MÉTODO DE BÚSQUEDA
  Future<List<Product>> searchProducts({required String query}) async {
    final url = Uri.parse('$_baseUrl/products/search?q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
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
  
  Future<Product> addProduct(Product product) async {
    final response = await http.post(
      // URL corregida
      Uri.parse('$_baseUrl/products/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toMap()),
    );

    if (response.statusCode == 201) {
      final dynamic data = json.decode(response.body);
      return Product.fromJson(data);
    } else {
      print('Error al agregar producto: ${response.body}'); 
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
      print('Error al actualizar producto: ${response.body}');
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