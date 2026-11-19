import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../services/update_service.dart';
import 'about_screen.dart';
import 'account_screen.dart';
import 'dukan_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Bottom bar order, left -> right: About, Search, Dukan, Account, Settings.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) UpdateService.checkAndShow(context);
      });
    });
  }
  static const _pages = <Widget>[
    AboutScreen(), SearchScreen(), DukanScreen(), AccountScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = <(IconData?, String)>[
      (Icons.info_outline, context.t('about')),
      (Icons.search, context.t('search')),
      (null, context.t('shop')),
      (Icons.person_outline, context.t('account')),
      (Icons.settings_outlined, context.t('settings')),
    ];
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.075, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey('$_i-${context.lang}'), child: _pages[_i]),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 74,
            child: Directionality(
              textDirection: TextDirection.ltr, // fixed physical order
              child: Row(
                children: [
                  for (var n = 0; n < items.length; n++)
                    Expanded(
                      child: InkWell(
                        onTap: () { if (_i != n) setState(() => _i = n); },
                        child: n == 2
                            ? Center(
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: colors.primary, shape: BoxShape.circle),
                                  child: Text(items[n].$2,
                                      style: TextStyle(
                                          color: colors.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(items[n].$1, color: _i == n ? colors.primary : colors.onSurface, size: _i == n ? 28 : 24),
                                  const SizedBox(height: 3),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(opacity: animation, child: child),
                                    child: Text(items[n].$2,
                                      key: ValueKey('${context.lang}-${items[n].$2}'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: _i == n ? FontWeight.bold : FontWeight.normal)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
