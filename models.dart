class Product {
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.minOrderValue,
    required this.ingredients,
    required this.images,
  });

  final String id, name, description;
  final double unitPrice, minOrderValue;
  final List<String> ingredients, images;

  String? get cover => images.isEmpty ? null : images.first;

  /// The minimum order is a MONEY value, not a unit price:
  /// min quantity = ceil(minOrderValue / unitPrice), computed in integer
  /// piastres to avoid floating point errors (100 / 10 -> 10 units).
  int get minQty {
    if (minOrderValue <= 0) return 1;
    final unit = (unitPrice * 100).round();
    final min = (minOrderValue * 100).round();
    if (unit <= 0) return 1;
    final q = (min + unit - 1) ~/ unit;
    return q < 1 ? 1 : q;
  }

  factory Product.fromMap(Map<String, dynamic> m) {
    final imgs = <Map<String, dynamic>>[
      for (final e in (m['product_images'] as List? ?? const []))
        Map<String, dynamic>.from(e as Map)
    ]..sort((a, b) =>
        ((a['sort_order'] ?? 0) as num).compareTo((b['sort_order'] ?? 0) as num));
    final urls = [for (final i in imgs) i['url'] as String];
    final cover = m['image_url'] as String?;
    if (cover != null && cover.isNotEmpty && !urls.contains(cover)) {
      urls.insert(0, cover);
    }
    return Product(
      id: m['id'] as String,
      name: (m['name'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      unitPrice: (m['unit_price'] as num).toDouble(),
      minOrderValue: ((m['min_order_value'] ?? 0) as num).toDouble(),
      ingredients: [for (final i in (m['ingredients'] as List? ?? const [])) '$i'],
      images: urls,
    );
  }
}

class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.imageUrl,
    required this.quantity,
    this.note = '',
  });

  final String productId, name, description;
  final double unitPrice;
  final String? imageUrl;
  int quantity;
  String note;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'description': description,
        'unitPrice': unitPrice,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'note': note,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: j['productId'] as String,
        name: j['name'] as String,
        description: (j['description'] ?? '') as String,
        unitPrice: (j['unitPrice'] as num).toDouble(),
        imageUrl: j['imageUrl'] as String?,
        quantity: j['quantity'] as int,
        note: (j['note'] ?? '') as String,
      );
}

class Address {
  Address({
    required this.id,
    required this.addressText,
    required this.latitude,
    required this.longitude,
    required this.landmark,
    required this.isDefault,
  });
  final String id, addressText, landmark;
  final double latitude, longitude;
  final bool isDefault;

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        id: m['id'] as String,
        addressText: (m['address_text'] ?? '') as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        landmark: (m['landmark'] ?? '') as String,
        isDefault: (m['is_default'] ?? false) as bool,
      );

  String get title => addressText.isNotEmpty
      ? addressText
      : '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class Review {
  Review({required this.rating, required this.comment, required this.author, required this.createdAt});
  final int rating;
  final String comment, author;
  final DateTime? createdAt;

  factory Review.fromMap(Map<String, dynamic> m) => Review(
        rating: (m['rating'] as num).toInt(),
        comment: (m['comment'] ?? '') as String,
        author: (m['author_name'] ?? '') as String,
        createdAt: DateTime.tryParse('${m['created_at']}'),
      );
}

class ContentBlock {
  ContentBlock({required this.section, required this.title, required this.body, required this.imageUrl});
  final String section, title, body;
  final String? imageUrl;
  factory ContentBlock.fromMap(Map<String, dynamic> m) => ContentBlock(
        section: (m['section'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        body: (m['body'] ?? '') as String,
        imageUrl: m['image_url'] as String?,
      );
}
