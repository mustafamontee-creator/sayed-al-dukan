import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../services/cart_service.dart';
import '../ui/widgets.dart';

/// All products, quantities, prices and the grand total on a single page.
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('orderDetails'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final it in cart.items) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${it.quantity} × ${money(context, it.unitPrice)}'),
                if (it.note.isNotEmpty) Text('• ${it.note}', style: const TextStyle(fontSize: 13)),
              ]),
            ),
            Text(money(context, it.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Line()),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(context.t('total'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(money(context, cart.total),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}
