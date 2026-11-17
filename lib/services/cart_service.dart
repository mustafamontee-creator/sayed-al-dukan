import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'repo.dart';

/// Cart is stored locally (survives app close) and mirrored to the server
/// when the customer is signed in.
class CartService extends ChangeNotifier {
  CartService(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'cart_v1';
  Repo? repo;

  final Map<String, CartItem> _items = {};
  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get count => _items.values.fold(0, (s, e) => s + e.quantity);
  double get total => _items.values.fold(0.0, (s, e) => s + e.lineTotal);

  Future<void> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      for (final j in jsonDecode(raw) as List) {
        final it = CartItem.fromJson(Map<String, dynamic>.from(j as Map));
        _items[it.productId] = it;
      }
    } catch (_) {/* corrupted cache: start empty */}
  }

  void add(Product p, int qty) {
    final ex = _items[p.id];
    if (ex != null) {
      ex.quantity += qty < 1 ? 1 : qty;
    } else {
      final q = qty < p.minQty ? p.minQty : qty;
      _items[p.id] = CartItem(
        productId: p.id,
        name: p.name,
        description: p.description,
        unitPrice: p.unitPrice,
        imageUrl: p.cover,
        quantity: q,
      );
    }
    _changed();
  }

  void remove(String productId) {
    _items.remove(productId);
    _changed();
  }

  void setNote(String productId, String note) {
    _items[productId]?.note = note.trim();
    _changed();
  }

  void clear() {
    _items.clear();
    _changed();
  }

  /// Aligns cart lines with the LIVE catalogue so that changes made later from
  /// the admin app (price, name, description, image, minimum order, hidden
  /// product) show up without a new APK. Orders are re-validated server-side.
  Future<void> syncWithCatalog() async {
    final r = repo;
    if (r == null) return;
    try {
      applyCatalog(await r.products(force: true));
    } catch (_) {/* offline: keep local lines */}
  }

  @visibleForTesting
  void applyCatalog(List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    var changed = false;
    for (final id in _items.keys.toList()) {
      final p = byId[id];
      final old = _items[id]!;
      if (p == null) {
        _items.remove(id);
        changed = true;
        continue;
      }
      final fresh = CartItem(
        productId: id,
        name: p.name,
        description: p.description,
        unitPrice: p.unitPrice,
        imageUrl: p.cover,
        quantity: old.quantity < p.minQty ? p.minQty : old.quantity,
        note: old.note,
      );
      if (jsonEncode(fresh.toJson()) != jsonEncode(old.toJson())) changed = true;
      _items[id] = fresh;
    }
    if (changed) _changed();
  }

  /// After sign-in: bring server cart items that are missing locally, then push.
  Future<void> mergeFromServer() async {
    final r = repo;
    if (r == null || !r.isLoggedIn) return;
    try {
      final rows = await r.serverCart();
      if (rows.isNotEmpty) {
        final products = await r.products();
        for (final row in rows) {
          final id = row['product_id'] as String;
          if (_items.containsKey(id)) continue;
          final p = products.where((e) => e.id == id).toList();
          if (p.isEmpty) continue;
          _items[id] = CartItem(
            productId: id,
            name: p.first.name,
            description: p.first.description,
            unitPrice: p.first.unitPrice,
            imageUrl: p.first.cover,
            quantity: row['quantity'] as int,
            note: (row['note'] ?? '') as String,
          );
        }
      }
      await _persist();
      notifyListeners();
      await r.pushCart(items);
    } catch (_) {/* offline: local cart stays authoritative */}
  }

  void _changed() {
    unawaited(_persist());
    notifyListeners();
    final r = repo;
    if (r != null && r.isLoggedIn) {
      unawaited(r.pushCart(items).catchError((_) {}));
    }
  }

  Future<void> _persist() =>
      _prefs.setString(_key, jsonEncode([for (final i in _items.values) i.toJson()]));
}
