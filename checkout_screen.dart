import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';
import 'add_address_screen.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> _addrs = [];
  String? _sel;
  bool _loading = true, _review = false, _sending = false;
  Object? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    if (!auth.loggedIn) {
      // Login, then come straight back here. The cart is local so nothing is lost.
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await context.read<CartService>().syncWithCatalog();
      final a = await context.read<Repo>().addresses();
      if (!mounted) return;
      setState(() {
        _addrs = a;
        final keep = a.any((e) => e.id == _sel);
        if (!keep) {
          _sel = a.isEmpty ? null : (a.firstWhere((e) => e.isDefault, orElse: () => a.first)).id;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _err = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAddress() async {
    final added = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
    if (added == true) await _load();
  }

  Future<void> _send() async {
    final cart = context.read<CartService>();
    setState(() => _sending = true);
    try {
      final res = await context.read<Repo>().placeOrder(_sel!, cart.items);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => OrderPlacedScreen(orderNumber: '${res['order_number']}')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final addr = _addrs.where((a) => a.id == _sel).toList();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('checkout'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.black))
          : _err != null
              ? ErrorView(error: _err!, onRetry: _load)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Text(context.t('items'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final it in cart.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${it.name}  ×${it.quantity}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (it.note.isNotEmpty)
                              Text('• ${it.note}', style: const TextStyle(fontSize: 13)),
                          ]),
                        ),
                        Text(money(context, it.lineTotal)),
                      ]),
                    ),
                  const Line(),
                  const SizedBox(height: 12),
                  Text(context.t('selectAddress'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!_review) ...[
                    for (final a in _addrs)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.black,
                        value: a.id,
                        groupValue: _sel,
                        onChanged: (v) => setState(() => _sel = v),
                        title: Text(a.title),
                        subtitle: Text('${context.t('landmark')}: ${a.landmark}'),
                      ),
                    TextButton.icon(
                      onPressed: _addAddress,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(context.t('addAddress')),
                    ),
                  ] else if (addr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(addr.first.title),
                    Text('${context.t('landmark')}: ${addr.first.landmark}'),
                  ],
                  const SizedBox(height: 12),
                  const Line(),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(context.t('total'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(money(context, cart.total),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  if (!_review)
                    ElevatedButton(
                      onPressed: () {
                        if (_sel == null || cart.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(context.t('selectAddress'))));
                          return;
                        }
                        setState(() => _review = true);
                      },
                      child: Text(context.t('reviewOrder')),
                    )
                  else ...[
                    ElevatedButton(
                      onPressed: () {
                        if (!_sending) _send();
                      },
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : Text(context.t('placeOrder')),
                    ),
                    TextButton(
                        onPressed: _sending ? null : () => setState(() => _review = false),
                        child: Text(context.t('edit'))),
                  ],
                ]),
    );
  }
}

class OrderPlacedScreen extends StatefulWidget {
  const OrderPlacedScreen({super.key, required this.orderNumber});
  final String orderNumber;
  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  // Notifications are not enabled in this version. Do not request permission
  // automatically after checkout; ask only after the customer explicitly turns
  // on order updates in a future settings flow.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, size: 96),
            const SizedBox(height: 16),
            Text(context.t('orderPlaced'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${context.t('orderNumber')}: ${widget.orderNumber}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(context.t('backToShop')),
            ),
          ]),
        ),
      ),
    );
  }
}
