import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });

    // cargar más productos al llegar al final del scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<ProductProvider>(context, listen: false).loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // responsive
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Si el ancho es >= 600px, usamos 2 columnas.
    if (screenWidth >= 600) {
      return 2; 
    } else {
      return 1; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final crossAxisCount = _getCrossAxisCount(context); 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Tienda en Flutter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              ),
              onChanged: (query) {
                provider.updateSearchQuery(query);
              },
            ),
          ),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          switch (provider.state) {
            case ProductState.loading:
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            case ProductState.error:
              return Center(child: Text('Error: ${provider.errorMessage}', style: const TextStyle(color: Colors.white)));
            case ProductState.success:
            case ProductState.idle:
              if (provider.filteredProducts.isEmpty) {
                return const Center(child: Text('No products found.', style: TextStyle(color: Colors.white)));
              }
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // productos en 1 o 2 columnas.
                  SliverGrid( 
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount, 
                      //3.8 para 1 columna, 4.8 para 2 columnas
                      childAspectRatio: (crossAxisCount == 1) ? 3.8 : 4.8, 
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 0.0, 
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = provider.filteredProducts[index];
                        return ProductListItem(product: product); 
                      },
                      childCount: provider.filteredProducts.length,
                    ),
                  ),

                  // SliverToBoxAdapter: Indicador de carga
                  if (provider.hasMoreProducts)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          // Ocupa el ancho completo
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// la card de los products
class ProductListItem extends StatelessWidget {
  final Product product;
  
  const ProductListItem({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10.0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            product.image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.white),
          ),
        ),
        title: Text(
          product.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: TextStyle(color: const Color.fromRGBO(255, 255, 255, 0.7)),
        ),
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
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[850],
                    title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
                    content: Text('¿Estás seguro de que quieres eliminar ${product.title}?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteProduct(product.id);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
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