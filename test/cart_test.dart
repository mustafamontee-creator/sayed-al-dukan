import 'package:flutter_test/flutter_test.dart';
import 'package:sayed_al_dukan/models/models.dart';
import 'package:sayed_al_dukan/services/cart_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Product prod(String id, double price, double min, {String name = 'منتج'}) => Product(
    id: id, name: name, description: 'وصف', unitPrice: price, minOrderValue: min,
    ingredients: const [], images: const []);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add enforces the minimum quantity and merges the same product', () async {
    final cart = CartService(await SharedPreferences.getInstance());
    cart.add(prod('a', 10, 100), 3); // minimum is 10 units
    expect(cart.items.single.quantity, 10);
    cart.add(prod('a', 10, 100), 5);
    expect(cart.items.single.quantity, 15);
    expect(cart.total, 150);
  });

  test('notes are per product, survive a reload, remove deletes one product', () async {
    final prefs = await SharedPreferences.getInstance();
    final cart = CartService(prefs);
    cart.add(prod('a', 10, 0), 1);
    cart.add(prod('b', 5, 0), 2);
    cart.setNote('a', 'بدون سكر');
    await Future<void>.delayed(Duration.zero);
    final again = CartService(prefs);
    await again.load();
    expect(again.items.firstWhere((i) => i.productId == 'a').note, 'بدون سكر');
    expect(again.items.firstWhere((i) => i.productId == 'b').note, '');
    again.remove('a');
    expect(again.items.map((i) => i.productId), ['b']);
  });

  test('catalogue changes (price, minimum, hidden) are applied to the cart', () async {
    final cart = CartService(await SharedPreferences.getInstance());
    cart.add(prod('a', 10, 0), 2);
    cart.add(prod('b', 10, 0), 1);
    cart.applyCatalog([prod('a', 20, 100, name: 'اسم جديد')]); // b hidden, a repriced
    expect(cart.items.length, 1);
    expect(cart.items.single.unitPrice, 20);
    expect(cart.items.single.name, 'اسم جديد');
    expect(cart.items.single.quantity, 5); // new minimum 100 / 20
  });

  test('Product.fromMap orders images and keeps the cover first', () {
    final p = Product.fromMap({
      'id': '1', 'name': 'n', 'unit_price': 10, 'min_order_value': 100,
      'image_url': 'cover.jpg',
      'product_images': [
        {'url': 'b.jpg', 'sort_order': 2},
        {'url': 'a.jpg', 'sort_order': 1},
      ],
    });
    expect(p.images, ['cover.jpg', 'a.jpg', 'b.jpg']);
    expect(p.minQty, 10);
  });
}
