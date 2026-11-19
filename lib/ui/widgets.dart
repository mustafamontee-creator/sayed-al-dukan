import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../core/format.dart';
import '../core/strings.dart';

String money(BuildContext c, num v) => '${formatNumber(v)} ${c.t('currency')}';

String friendlyError(BuildContext c, Object e) {
  if (e is ConfigException) return c.t('errNotConfigured');
  if (e is SocketException) return c.t('errOffline');
  if (e is PostgrestException) {
    final m = e.message;
    if (m.contains('below_minimum')) return c.t('errBelowMin');
    if (m.contains('product_unavailable')) return c.t('errUnavailable');
    return c.t('errGeneric');
  }
  if (e is AuthException) {
    final message = e.message.toLowerCase();
    if (message.contains('over_email_send_rate_limit') || message.contains('email rate limit exceeded') || message.contains('rate limit')) return c.t('errEmailRateLimit');
    return e.message;
  }
  return c.t('errGeneric');
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry, this.onDark = false});
  final Object error;
  final VoidCallback onRetry;
  final bool onDark;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = onDark ? colors.onPrimary : colors.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(friendlyError(context, error),
              textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              style: onDark
                  ? ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: colors.onPrimary)
                  : null,
              onPressed: onRetry,
              child: Text(context.t('retry')),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Uses the ORIGINAL supplied artwork + the exact text requested.
class BrandedEmptyView extends StatelessWidget {
  const BrandedEmptyView({
    super.key,
    required this.message,
    this.onDark = false,
  });

  final String message;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: onDark ? const Color(0xFF315F8C) : colors.primary,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/brand/mark.svg',
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: onDark ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => BrandedEmptyView(
        message: context.t('notFound'),
        onDark: onDark,
      );
}

class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String? url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const _Blank(Icons.image_outlined);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      placeholder: (_, __) => const _Blank(null),
      errorWidget: (_, __, ___) => const _Blank(Icons.broken_image_outlined),
    );
  }
}

class _Blank extends StatelessWidget {
  const _Blank(this.icon);
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: icon == null ? null : Center(child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class Line extends StatelessWidget {
  const Line({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(color: Theme.of(context).dividerColor, thickness: 1, height: 1);
}
