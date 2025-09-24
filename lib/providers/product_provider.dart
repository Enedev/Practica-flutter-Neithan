import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum ProductState { idle, loading, success, error }

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  ProductState _state = ProductState.idle;
  String _errorMessage = '';

  List<Product> get products => _products;
  ProductState get state => _state;
  String get errorMessage => _errorMessage;

  // READ: Fetch products from the API
  // En ProductProvider
  Future<void> fetchProducts({String? category}) async {
    _setState(ProductState.loading);
    try {
      // Llama al servicio con la categoría, en este caso 'electronics'
      final fetchedProducts = await _apiService.getProducts(category: category);
      _products = fetchedProducts;
      _setState(ProductState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  // CREATE: Add a new product
  Future<void> addProduct(Product product) async {
    _setState(ProductState.loading);
    try {
      // Simulate API call and add to local list
      // In a real app, you'd handle the response from the API
      final newProduct = await _apiService.addProduct(product);
      _products.add(newProduct);
      _setState(ProductState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  // UPDATE: Edit an existing product
  Future<void> updateProduct(Product product) async {
    _setState(ProductState.loading);
    try {
      // Simulate API call and update local list
      await _apiService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      _setState(ProductState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  // DELETE: Remove a product
  Future<void> deleteProduct(int id) async {
    _setState(ProductState.loading);
    try {
      // Simulate API call and remove from local list
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _setState(ProductState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  // Internal helper to update state and notify listeners
  void _setState(ProductState newState) {
    _state = newState;
    notifyListeners();
  }
}
