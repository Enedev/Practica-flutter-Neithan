import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late num _price;
  late String _description;
  late String _category;
  late String _image;
  
  // Para evitar que la notificación se muestre varias veces
  ProductState? _lastHandledState;

  @override
  void initState() {
    super.initState();
    // valores por defecto
    final product = widget.product;
    _title = product?.title ?? '';
    _price = product?.price ?? 0.0;
    _description = product?.description ?? '';
    _category = product?.category ?? '';
    _image =
        product?.image ??
        'https://dummyjson.com/image/i/products/1/thumbnail.jpg'; // Imagen por defecto
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastHandledState = Provider.of<ProductProvider>(context, listen: false).state;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Si estamos editando, usamos el ID existente; si es nuevo, usamos 0.
      final int productId = widget.product?.id ?? 0;

      final newProduct = Product(
        id: productId,
        title: _title,
        price: _price,
        description: _description,
        category: _category,
        image: _image,
      );

      _lastHandledState = null; 

      if (widget.product == null) {
        // Al agregar, enviamos el producto al Provider.
        // El Provider llama a la API y el nuevo producto tendrá el ID asignado por la API (>100).
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).addProduct(newProduct);
      } else {
        // Al editar, el Provider se encarga de llamar a la API (si ID <= 100)
        // o de actualizar localmente (si ID > 100).
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).updateProduct(newProduct);
      }
      // NOTA: Se elimina la navegación de aquí para permitir que el listener espere el resultado.
    }
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Campo de texto
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: TextFormField(
              initialValue: initialValue,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(
                    color: Colors.greenAccent,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 15.0,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce el $label.';
                }
                return null;
              },
              onSaved: onSaved,
            ),
          ),
        ),
      ],
    );
  }

  // notificación y navegación
  void _showSnackbarAndNavigate(ProductState state, String message, bool isEditing) {
    Color color = (state == ProductState.success) ? Colors.green : Colors.redAccent;
    String text = (state == ProductState.success) 
        ? (isEditing ? 'Actualización Exitosa' : 'Creación Exitosa') 
        : 'Error';
    
    // notificacion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text: $message'),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
    
    if (state == ProductState.success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final bool isFinalState = provider.state == ProductState.success || provider.state == ProductState.error;

          if (isFinalState && _lastHandledState == null) {
            
            final isSuccess = provider.state == ProductState.success;
            final message = isSuccess 
                ? (isEditing ? 'Producto actualizado.' : 'Producto creado.')
                : provider.errorMessage;
            
            _showSnackbarAndNavigate(provider.state, message, isEditing);
            
            _lastHandledState = provider.state;
          }
        });

        bool isLoading = provider.state == ProductState.loading;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              isEditing ? 'Editar Producto' : 'Agregar Producto',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Campos de Texto
                          _buildTextField(
                            label: 'Título',
                            initialValue: _title,
                            onSaved: (value) => _title = value!,
                          ),
                          _buildTextField(
                            label: 'Precio',
                            initialValue: _price.toString(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onSaved: (value) => _price = num.tryParse(value!) ?? 0.0,
                          ),
                          _buildTextField(
                            label: 'Descripción',
                            initialValue: _description,
                            onSaved: (value) => _description = value!,
                            keyboardType: TextInputType.multiline,
                          ),
                          _buildTextField(
                            label: 'Categoría',
                            initialValue: _category,
                            onSaved: (value) => _category = value!,
                          ),
                          _buildTextField(
                            label: 'URL de Imagen',
                            initialValue: _image,
                            onSaved: (value) => _image = value!,
                          ),
                          const SizedBox(height: 30),

                          // Botón
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitForm, // Deshabilita si está cargando
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Guardar Cambios' : 'Crear Producto',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Indicador de carga (Overlay)
              if (isLoading)
                Container(
                  color: Colors.black.withAlpha(127), 
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}