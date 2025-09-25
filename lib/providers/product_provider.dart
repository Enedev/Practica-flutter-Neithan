import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum ProductState { idle, loading, success, error }

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  String _errorMessage = '';
  ProductState _state = ProductState.idle;
  String _searchQuery = '';

  // Variables para la paginación
  int _currentPage = 0;
  bool _isLoadingMore = false;
  final int _pageSize = 10;
  bool _hasMoreProducts = true;

  List<Product> get products => _products;
  String get errorMessage => _errorMessage;
  ProductState get state => _state;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreProducts => _hasMoreProducts;

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      return product.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> fetchProducts() async {
    _setState(ProductState.loading);
    _currentPage = 0;
    _products = [];
    _hasMoreProducts = true;

    try {
      final fetchedProducts = await _apiService.getProducts(
        limit: _pageSize,
        skip: 0,
      );
      _products = fetchedProducts;
      _setState(ProductState.success);

      if (_products.length < _pageSize) {
        _hasMoreProducts = false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newProducts = await _apiService.getProducts(
        limit: _pageSize,
        skip: _currentPage * _pageSize,
      );

      if (newProducts.isEmpty) {
        _hasMoreProducts = false;
      } else {
        _products.addAll(newProducts);
      }
      
      _isLoadingMore = false;
      _setState(ProductState.success);

    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(int id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void _setState(ProductState newState) {
    _state = newState;
    notifyListeners();
  }
}