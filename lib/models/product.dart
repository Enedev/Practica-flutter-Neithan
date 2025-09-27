class Product {
  final int id;
  final String title;
  final num price;
  final String description;
  final String category;
  final String image;
  //constructor
  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
  });
  //Lo use para para tomar un Map y convertirlo en un objeto
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'N/A',
      price: json['price'] as num? ?? 0.0,
      description: json['description'] as String? ?? 'Sin descripción',
      category: json['category'] as String? ?? 'general',
      image: (json['thumbnail'] ?? json['image'] ?? 'https://via.placeholder.com/150').toString(),
    );
  }
  // convierto la instancia de la api aun map, esto es necesario para enviar datos a la api
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
    };
  }
}