import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Para evitar que la notificación se muestre varias veces (igual que en Form)
  ProductState? _lastHandledState;

  @override
  void initState() {
    super.initState();
    
    // ✅ Inicializar _lastHandledState después del primer frame.
    // Esto previene que el listener reaccione al estado de 'success' heredado de la lista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
        // Establece el estado actual del provider como el último manejado, ignorándolo.
        _lastHandledState = Provider.of<ProductProvider>(context, listen: false).state;
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

  // Muestra el diálogo de confirmación para eliminar
  void _showDeleteConfirmation(BuildContext context, ProductProvider provider, Product product) {
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
              // Limpiamos el estado para que el listener reaccione al nuevo estado
              _lastHandledState = null; 
              provider.deleteProduct(product.id);
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    // Usamos Consumer para escuchar el estado del Provider para la eliminación
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        
        // Lógica de Listener: Reaccionar al estado final de la operación de eliminación
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // La condición ahora depende de que _lastHandledState haya sido reseteado (nulo) 
          // después de la confirmación Y que el estado actual no sea de carga/inicial.
          final bool isFinalState = provider.state == ProductState.success || provider.state == ProductState.error;

          if (isFinalState && _lastHandledState == null) {
            
            final message = (provider.state == ProductState.success)
                ? 'Producto "${widget.product.title}" eliminado correctamente.'
                : provider.errorMessage;
            
            _showSnackbar(context, provider.state, message);
            
            _lastHandledState = provider.state;
            
            // Si la eliminación fue exitosa, navegamos de vuelta a la lista
            if (provider.state == ProductState.success) {
                // Navegamos de vuelta a la primera ruta (ProductListScreen)
                // Se usa el postFrameCallback para asegurar que el Scaffold esté listo
                Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }
        });

        // Control de carga para deshabilitar botones
        bool isLoading = provider.state == ProductState.loading;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text(
              'Detalle del Producto',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Stack( // Usamos Stack para el overlay de carga, si se desea
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, 
                  children: [
                    // Imagen
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        widget.product.image,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
        
                    // Título
                    Text(
                      widget.product.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
        
                    // Precio
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Descripción
                    Container(
                      padding: const EdgeInsets.all(15.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(color: Colors.grey.shade700, width: 1),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Descripción:',
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.8),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.product.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
        
                    // Categoría
                    Text(
                      'Categoría: ${widget.product.category}',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.7),
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 30),
        
                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : () { // Deshabilita si está cargando
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductFormScreen(product: widget.product),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit, color: Colors.black),
                          label: const Text('Editar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : () => _showDeleteConfirmation(context, provider, widget.product), // Deshabilita si está cargando
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicador de carga (Overlay) si la eliminación tarda
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(127), 
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}