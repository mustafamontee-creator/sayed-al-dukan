import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late int _qty = widget.product.minQty; // never below the computed minimum
  late Future<List<Review>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = context.read<Repo>().reviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final canMinus = _qty > p.minQty;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: p.images.length <= 1
                ? NetImage(p.cover)
                : PageView(children: [for (final u in p.images) NetImage(u)]),
          ),
        ),
        const SizedBox(height: 16),
        Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(money(context, p.unitPrice),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (p.minOrderValue > 0)
          Text(
            '${context.t('minOrder')}: ${money(context, p.minOrderValue)}  •  ${context.t('minQty')}: ${p.minQty}',
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 16),
        if (p.description.isNotEmpty) ...[
          Text(context.t('description'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(p.description),
          const SizedBox(height: 16),
        ],
        Text(context.t('quantity'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _RoundBtn(Icons.add, () => setState(() => _qty++)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('$_qty', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          _RoundBtn(Icons.remove, canMinus ? () => setState(() => _qty--) : null),
        ]),
        const SizedBox(height: 12),
        Center(
          child: Text('${context.t('total')}: ${money(context, _qty * p.unitPrice)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            context.read<CartService>().add(p, _qty);
            Navigator.of(context).pop();
          },
          child: Text(context.t('addToCart')),
        ),
        if (p.ingredients.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(context.t('ingredients'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          for (final i in p.ingredients) Text('• $i'),
        ],
        const SizedBox(height: 24),
        const Line(),
        const SizedBox(height: 12),
        Text(context.t('reviews'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        FutureBuilder<List<Review>>(
          future: _reviews,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()));
            }
            if (s.hasError || s.data!.isEmpty) {
              return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(context.t('noReviews')));
            }
            return Column(children: [
              for (final r in s.data!)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(i <= r.rating ? Icons.star : Icons.star_border, size: 18),
                      const SizedBox(width: 8),
                      Text(r.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    if (r.comment.isNotEmpty) Text(r.comment),
                  ]),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: onTap == null ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
              border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
              shape: BoxShape.circle),
          child: Icon(icon, color: onTap == null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onPrimary),
        ),
      );
}
