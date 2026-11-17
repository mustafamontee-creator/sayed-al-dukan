import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../models/models.dart';

/// All server access lives here (UI never talks to Supabase directly).
class Repo {
  Repo(this.prefs);
  final SharedPreferences prefs;
  static const _cacheKey = 'products_cache_v1';
  List<Product>? _mem;

  SupabaseClient get _db {
    if (!AppConfig.isConfigured) throw const ConfigException();
    return Supabase.instance.client;
  }

  bool get isLoggedIn =>
      AppConfig.isConfigured && Supabase.instance.client.auth.currentUser != null;
  String get _uid => _db.auth.currentUser!.id;

  // ---- products -----------------------------------------------------------
  /// Network first; falls back to the last cached list when offline.
  Future<List<Product>> products({bool force = false}) async {
    if (!force && _mem != null) return _mem!;
    try {
      final rows = await _db
          .from('products')
          .select('*, product_images(url, sort_order)')
          .eq('is_active', true)
          .order('sort_order')
          .order('created_at');
      await prefs.setString(_cacheKey, jsonEncode(rows));
      return _mem = [for (final r in rows) Product.fromMap(Map<String, dynamic>.from(r))];
    } catch (e) {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        return _mem = [
          for (final r in (jsonDecode(cached) as List))
            Product.fromMap(Map<String, dynamic>.from(r as Map))
        ];
      }
      rethrow;
    }
  }

  Future<List<Review>> reviews(String productId) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return [for (final r in rows) Review.fromMap(Map<String, dynamic>.from(r))];
  }

  Future<List<ContentBlock>> content() async {
    final rows = await _db
        .from('app_content')
        .select()
        .eq('is_published', true)
        .order('sort_order');
    return [for (final r in rows) ContentBlock.fromMap(Map<String, dynamic>.from(r))];
  }

  // ---- addresses ----------------------------------------------------------
  Future<List<Address>> addresses() async {
    final rows = await _db
        .from('addresses')
        .select()
        .eq('user_id', _uid)
        .order('is_default', ascending: false)
        .order('created_at');
    return [for (final r in rows) Address.fromMap(Map<String, dynamic>.from(r))];
  }

  Future<void> addAddress({
    required String text,
    required double lat,
    required double lng,
    required String landmark,
    required bool makeDefault,
  }) async {
    if (makeDefault) {
      await _db.from('addresses').update({'is_default': false}).eq('user_id', _uid);
    }
    await _db.from('addresses').insert({
      'user_id': _uid,
      'address_text': text,
      'latitude': lat,
      'longitude': lng,
      'landmark': landmark,
      'is_default': makeDefault,
    });
  }

  Future<void> setDefaultAddress(String id) async {
    await _db.from('addresses').update({'is_default': false}).eq('user_id', _uid);
    await _db.from('addresses').update({'is_default': true}).eq('id', id).eq('user_id', _uid);
  }

  Future<void> deleteAddress(String id) async {
    await _db.from('addresses').delete().eq('id', id).eq('user_id', _uid);
  }

  // ---- profile ------------------------------------------------------------
  Future<Map<String, dynamic>?> profile() async {
    final row = await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> updateProfile({required String name, required String contactPhone}) async {
    await _db
        .from('profiles')
        .update({'full_name': name, 'contact_phone': contactPhone}).eq('id', _uid);
  }

  // ---- cart sync ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> serverCart() async {
    final rows = await _db.from('cart_items').select('product_id, quantity, note').eq('user_id', _uid);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<void> pushCart(List<CartItem> items) async {
    await _db.from('cart_items').delete().eq('user_id', _uid);
    if (items.isEmpty) return;
    await _db.from('cart_items').insert([
      for (final i in items)
        {'user_id': _uid, 'product_id': i.productId, 'quantity': i.quantity, 'note': i.note}
    ]);
  }

  // ---- orders -------------------------------------------------------------
  /// Prices, minimums and totals are re-validated on the server
  /// (see supabase/schema.sql -> place_order). Returns {order_id, order_number}.
  Future<Map<String, dynamic>> placeOrder(String addressId, List<CartItem> items) async {
    final res = await _db.rpc('place_order', params: {
      'p_address_id': addressId,
      'p_items': [
        for (final i in items)
          {'product_id': i.productId, 'quantity': i.quantity, 'note': i.note}
      ],
    });
    return Map<String, dynamic>.from(res as Map);
  }
}
