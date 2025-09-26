import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

enum ProductState { idle, loading, success, error }

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  int _tempIdCounter = -1; 
  
  List<Product> _products = [];
  String _errorMessage = '';
  ProductState _state = ProductState.idle;
  String _searchQuery = '';

  int _currentPage = 0;
  bool _isLoadingMore = false;
  final int _pageSize = 10;
  bool _hasMoreProducts = true;
  static const int _realProductLimit = 100;
  
  List<Product> _searchResults = [];

  List<Product> get products => _products;
  String get errorMessage => _errorMessage;
  ProductState get state => _state;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreProducts => _hasMoreProducts;

  List<Product> get filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _searchResults;
  }
  
  void _setState(ProductState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- FUNCIÓN DE FUSIÓN DE PRODUCTOS ---
  void _mergeProducts(List<Product> newProducts) {
      for (var newProduct in newProducts) {
        final index = _products.indexWhere((p) => p.id == newProduct.id);

        if (index == -1) {
          _products.add(newProduct);
        }
      }
  }
  
  // --- FUNCIÓN CENTRAL DE SINCRONIZACIÓN ---
  void _syncLists(Product updatedProduct) {
    final productId = updatedProduct.id;

    // 1. Sincronizar _products (fuente de verdad)
    final productIndex = _products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      _products[productIndex] = updatedProduct;
    }

    // 2. Sincronizar _searchResults (vista de búsqueda)
    if (_searchQuery.isNotEmpty) {
      final searchIndex = _searchResults.indexWhere((p) => p.id == productId);
      if (searchIndex != -1) {
        _searchResults[searchIndex] = updatedProduct;
      }
    }
  }

  // --- Funciones de Fetch y Paginación ---

  Future<void> fetchProducts() async {
    _setState(ProductState.loading);
    
    // Reinicia la lista, pero conservando los productos creados localmente (ID < 0)
    final localCreatedProducts = _products.where((p) => p.id < 0).toList();
    _products = localCreatedProducts; 
    
    _currentPage = 0;
    _hasMoreProducts = true;

    try {
      final fetchedProducts = await _apiService.getProducts(
        limit: _pageSize,
        skip: 0,
      );
      
      _mergeProducts(fetchedProducts); 
      
      _setState(ProductState.success);

      if (fetchedProducts.length < _pageSize) {
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
        _mergeProducts(newProducts); 
      }
      
      _isLoadingMore = false;
      _setState(ProductState.success);

    } catch (e) {
      _isLoadingMore = false;
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  // --- Búsqueda (API + Fusión en Caché) ---
  Future<void> updateSearchQuery(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      // 1. Obtener resultados de la API para la consulta.
      List<Product> apiResults = await _apiService.searchProducts(query: query);
      
      // 2. FUSIONAR resultados en _products (actuando como si fuera un scroll).
      _mergeProducts(apiResults);

      // 3. Llenar _searchResults SOLO con los productos de _products que coinciden.
      _searchResults = _products
          .where((product) => product.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      notifyListeners();

    } catch (e) {
      _errorMessage = 'Error al buscar en la API: ${e.toString()}';
      _searchResults = [];
      _setState(ProductState.error);
    }
  }

  // --- CRUD (Crear, Actualizar, Eliminar) ---

  Future<void> addProduct(Product product) async {
    try {
      final newProduct = await _apiService.addProduct(product);
      
      final uniqueProduct = Product(
        id: _tempIdCounter--, 
        title: newProduct.title,
        price: newProduct.price,
        description: newProduct.description,
        category: newProduct.category,
        image: newProduct.image,
      );
      
      _products.insert(0, uniqueProduct);

      if (_searchQuery.isNotEmpty && uniqueProduct.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        _searchResults.insert(0, uniqueProduct);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    if (updatedProduct.id >= 0 && updatedProduct.id <= _realProductLimit) {
      try {
        await _apiService.updateProduct(updatedProduct);
      } catch (e) {
        _errorMessage = e.toString();
        _setState(ProductState.error);
        return;
      }
    }
    
    // Sincronizar ambas listas con el producto actualizado.
    _syncLists(updatedProduct);
    
    notifyListeners();
  }

  Future<void> deleteProduct(int id) async {
    try {
      // Elimina de _products
      _products.removeWhere((p) => p.id == id);

      if (id >= 0 && id <= _realProductLimit) { 
        await _apiService.deleteProduct(id);
      }
      
      // Elimina de _searchResults
      if (_searchQuery.isNotEmpty) {
        _searchResults.removeWhere((p) => p.id == id);
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProductState.error);
    }
  }
}