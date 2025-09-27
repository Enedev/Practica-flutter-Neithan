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
  
  // Variable para evitar que la notificación se dispare repetidamente
  ProductState? _lastHandledState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      // ✅ CORRECCIÓN: Inicializar _lastHandledState aquí para ignorar el estado de carga inicial.
      _lastHandledState = Provider.of<ProductProvider>(context, listen: false).state;
    });

    // cargar más productos al llegar al final del scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<ProductProvider>(context, listen: false).loadMoreProducts();
      }
    });
  }

  // Función para mostrar la notificación
  void _showSnackbar(BuildContext context, ProductState state, String message) {
    Color color = (state == ProductState.success) ? Colors.green : Colors.redAccent;
    String text = (state == ProductState.success) ? 'Operación Exitosa' : 'Error en la Operación';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text: $message'),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
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
                Provider.of<ProductProvider>(context, listen: false).updateSearchQuery(query);
              },
            ),
          ),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          
          // Lógica de Notificación para operaciones CRUD (Delete)
          // Se ejecuta después de que el frame ha sido construido
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // ✅ CONDICIÓN REFINADA: Solo reaccionar si es un estado final y no ha sido manejado (es decir, fue disparado por una acción reciente).
            final bool isFinalState = provider.state == ProductState.success || provider.state == ProductState.error;
            
            if (isFinalState && _lastHandledState == null) {
              
              final isSuccess = provider.state == ProductState.success;
              final message = isSuccess 
                  ? 'Operación completada: Producto actualizado o eliminado.' // Mensaje genérico para operaciones que regresan a esta vista
                  : provider.errorMessage;
              
              _showSnackbar(context, provider.state, message);
              
              // Actualiza el estado manejado para prevenir notificaciones duplicadas
              _lastHandledState = provider.state;
            }
          });

          switch (provider.state) {
            case ProductState.loading:
              // Muestra el indicador solo si la lista principal o la búsqueda están cargando
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            case ProductState.error:
              // Muestra el error solo si es un error de carga principal
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
                        // Pasamos _lastHandledState setter para resetearlo en el botón de eliminar
                        return ProductListItem(
                          product: product,
                          onDeleteConfirmed: () => _lastHandledState = null,
                        ); 
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
  // ✅ NUEVO: Callback para resetear el estado de la notificación en la pantalla padre
  final VoidCallback onDeleteConfirmed; 
  
  const ProductListItem({
    super.key,
    required this.product,
    required this.onDeleteConfirmed, // Requerimos el nuevo callback
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
                          // ✅ CORRECCIÓN: 1. Llamar al callback para resetear el estado de notificación en el widget padre.
                          onDeleteConfirmed();
                          
                          // Llamamos a deleteProduct
                          provider.deleteProduct(product.id);
                          
                          // 2. Cerrar el diálogo.
                          Navigator.of(context).pop();
                          // El consumer en ProductListScreen ahora manejará la notificación de forma específica.
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