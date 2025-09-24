import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'package:fake_store_app/screens/product_detail_screen.dart';
import 'package:fake_store_app/screens/product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // En _ProductListScreenState
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Llama al fetch de productos de la categoría 'electronics'
      Provider.of<ProductProvider>(
        context,
        listen: false,
      ).fetchProducts(category: 'electronics');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake Store')),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          switch (provider.state) {
            case ProductState.loading:
              return const Center(child: CircularProgressIndicator());
            case ProductState.error:
              return Center(child: Text('Error: ${provider.errorMessage}'));
            case ProductState.success:
            case ProductState.idle: // The initial state before fetching
              if (provider.products.isEmpty) {
                return const Center(child: Text('No products found.'));
              }
              return ListView.builder(
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return ProductListItem(product: product);
                },
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Image.network(
          product.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        ),
        title: Text(product.title),
        subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        trailing: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Show a confirmation dialog before deleting
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar Eliminación'),
                    content: Text(
                      '¿Estás seguro de que quieres eliminar ${product.title}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Call the delete method from the provider
                          provider.deleteProduct(product.id);
                          // Dismiss the dialog
                          Navigator.of(context).pop();
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
