import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../ui/widgets.dart';
import 'checkout_screen.dart';
import 'order_details_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Pull live prices / availability (admin changes appear without a new APK).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartService>().syncWithCatalog();
    });
  }

  Future<void> _editNote(CartItem it) async {
    final c = TextEditingController(text: it.note);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('orderNote')),
        content: TextField(controller: c, maxLines: 3, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('close'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t('save'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<CartService>().setNote(it.productId, c.text);
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final items = cart.items;
    return Scaffold(
      appBar: AppBar(),
      body: items.isEmpty
          ? Center(child: Text(context.t('cartEmpty'), style: const TextStyle(fontSize: 18)))
          : Column(children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Line()),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    // one independent row per product
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(it.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (it.description.isNotEmpty)
                              Text(it.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${context.t('quantity')}: ${it.quantity}'),
                          Text(money(context, it.lineTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                      if (it.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('• ${it.note}', style: const TextStyle(fontSize: 13)),
                        ),
                      Row(children: [
                        TextButton(
                          onPressed: () => cart.remove(it.productId), // removes this product only
                          child: Text(context.t('cancel')),
                        ),
                        TextButton(
                          onPressed: () => _editNote(it), // note for this product only
                          child: Text(context.t('orderNote')),
                        ),
                      ]),
                    ]);
                  },
                ),
              ),
              const Line(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  // Physical layout: checkout on the LEFT, details on the RIGHT.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                          child: Text(context.t('checkout')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const OrderDetailsScreen())),
                          child: Text(context.t('orderDetails')),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
    );
  }
}
