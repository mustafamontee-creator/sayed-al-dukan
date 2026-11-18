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
  bool _showSuggestions = true;

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

  void _selectSuggestion(Product product) {
    setState(() {
      _c.value = TextEditingValue(
        text: product.name,
        selection: TextSelection.collapsed(offset: product.name.length),
      );
      _showSuggestions = false;
      _wasEmpty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                final empty = v.trim().isEmpty;
                setState(() {
                  if (_wasEmpty && !empty) _f = context.read<Repo>().products();
                  _wasEmpty = empty;
                  _showSuggestions = true;
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
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
                    },
                  );
                }

                final res = s.data!
                    .where((p) => fuzzyMatches(_c.text, p.name))
                    .toList();
                if (res.isEmpty) return const NotFoundView();

                final suggestions = res.take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showSuggestions && suggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                        child: Text(
                          'مقترحات البحث',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          separatorBuilder: (_, __) => const Line(),
                          itemBuilder: (_, i) {
                            final p = suggestions[i];
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.search, color: colors.onSurfaceVariant),
                              title: Text(p.name),
                              onTap: () => _selectSuggestion(p),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    Expanded(
                      child: ListView.separated(
                        itemCount: res.length,
                        separatorBuilder: (_, __) => const Line(),
                        itemBuilder: (_, i) {
                          final p = res[i];
                          return ListTile(
                            leading: SizedBox(
                              width: 56,
                              height: 56,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: NetImage(p.cover),
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(money(context, p.unitPrice)),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductScreen(product: p),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
