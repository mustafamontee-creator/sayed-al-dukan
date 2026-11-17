import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
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
  static const _pages = <Widget>[
    AboutScreen(), SearchScreen(), DukanScreen(), AccountScreen(), SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
        child: KeyedSubtree(key: ValueKey(_i), child: _pages[_i]),
      ),
      bottomNavigationBar: Container(
        color: AppColors.white,
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
                                  decoration: const BoxDecoration(
                                      color: AppColors.black, shape: BoxShape.circle),
                                  child: Text(items[n].$2,
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(items[n].$1, color: AppColors.black, size: _i == n ? 28 : 24),
                                  const SizedBox(height: 3),
                                  Text(items[n].$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: _i == n ? FontWeight.bold : FontWeight.normal)),
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
