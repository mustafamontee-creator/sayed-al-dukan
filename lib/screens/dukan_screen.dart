import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'product_screen.dart';

class DukanScreen extends StatefulWidget {
  const DukanScreen({super.key});
  @override
  State<DukanScreen> createState() => _DukanScreenState();
}

class _DukanScreenState extends State<DukanScreen> with WidgetsBindingObserver {
  late Future<List<Product>> _f;
  static const _heights = <double>[200, 250, 220, 180, 240]; // varied tile sizes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _f = context.read<Repo>().products();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Changes made later from the admin app appear when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    setState(() {
      _f = context.read<Repo>().products(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: SafeArea(
        child: Column(children: [
          // A compact, intentional dark header with equal-size action buttons.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_CartButton(), _NotificationButton()],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: Image.asset(
                          'assets/images/sayed_logo.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.t('sharaftuna'),
                          textDirection: Directionality.of(context),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.t('welcome'),
                          textDirection: Directionality.of(context),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _f,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.white));
                }
                if (snap.hasError) {
                  return ErrorView(error: snap.error!, onRetry: _reload, onDark: true);
                }
                final list = snap.data!;
                if (list.isEmpty) return const NotFoundView(onDark: true);
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: MasonryGridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: list.length,
                    itemBuilder: (_, i) => _Tile(list[i], _heights[i % _heights.length]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();
  @override
  Widget build(BuildContext context) {
    final n = context.watch<CartService>().count;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(color: AppColors.cartRed, shape: BoxShape.circle),
        child: Stack(alignment: Alignment.center, children: [
          const Icon(Icons.shopping_cart_outlined, color: AppColors.white),
          if (n > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                child: Text('$n',
                    style: const TextStyle(
                        color: Theme.of(context).colorScheme.onSurface, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
        child: const Icon(Icons.notifications_none, color: AppColors.black, size: 23),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.p, this.height);
  final Product p;
  final double height;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
      child: Container(
        height: height,
        decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: SizedBox(width: double.infinity, child: NetImage(p.cover))),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(money(context, p.unitPrice), style: const TextStyle(fontSize: 14)),
            ]),
          ),
        ]),
      ),
    );
  }
}
