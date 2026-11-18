import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/search_util.dart';
import '../core/strings.dart';
import '../models/models.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';
import 'product_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  late Future<List<Product>> _f;
  bool _wasEmpty = true;

  @override
  void initState() {
    super.initState();
    _f = context.read<Repo>().products();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _c,
              onChanged: (v) {
                final empty = v.trim().isEmpty;
                setState(() {
                  // pick up the freshest catalogue each time a new search starts
                  if (_wasEmpty && !empty) _f = context.read<Repo>().products();
                  _wasEmpty = empty;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                hintText: context.t('search'),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _f,
              builder: (context, s) {
                if (_c.text.trim().isEmpty) return const SizedBox.shrink();
                if (s.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.hasError) {
                  return ErrorView(
                      error: s.error!,
                      onRetry: () {
                        setState(() {
                          _f = context.read<Repo>().products(force: true);
                        });
                      });
                }
                final res = s.data!.where((p) => fuzzyMatches(_c.text, p.name)).toList();
                if (res.isEmpty) return const NotFoundView();
                return ListView.separated(
                  itemCount: res.length,
                  separatorBuilder: (_, __) => const Line(),
                  itemBuilder: (_, i) {
                    final p = res[i];
                    return ListTile(
                      leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(8), child: NetImage(p.cover))),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(money(context, p.unitPrice)),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
