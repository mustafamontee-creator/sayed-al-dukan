import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<Repo>().notifications();
  }

  Future<void> _refresh() async {
    setState(() => _future = context.read<Repo>().notifications());
    await _future;
  }

  String _statusTitle(BuildContext context, String status) {
    final en = context.lang == 'en';
    switch (status) {
      case 'pending':
        return en ? 'Order received' : 'تم استلام الطلب';
      case 'confirmed':
        return en ? 'Order confirmed' : 'تم تأكيد الطلب';
      case 'preparing':
        return en ? 'Order is being prepared' : 'جاري تجهيز الطلب';
      case 'shipped':
        return en ? 'Order on the way' : 'الطلب في الطريق';
      case 'delivered':
        return en ? 'Order delivered' : 'تم توصيل الطلب';
      case 'cancelled':
        return en ? 'Order cancelled' : 'تم إلغاء الطلب';
      default:
        return status;
    }
  }

  String _dateLabel(Object? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final en = context.lang == 'en';
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(context.t('notifications')),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.black));
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: _refresh,
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 130),
                  const Icon(Icons.notifications_none, size: 58, color: AppColors.black),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      context.t('noNotifications'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.black),
              itemBuilder: (context, index) {
                final row = rows[index];
                final order = row['orders'] is Map
                    ? Map<String, dynamic>.from(row['orders'] as Map)
                    : <String, dynamic>{};
                final status = (row['status'] ?? '').toString();
                final number = (order['order_number'] ?? '').toString();
                final note = (row['note'] ?? '').toString().trim();
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.black,
                    child: Icon(Icons.notifications_active_outlined, color: AppColors.white),
                  ),
                  title: Text(
                    _statusTitle(context, status),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text([
                      if (number.isNotEmpty) '${en ? 'Order' : 'الطلب'} #$number',
                      if (note.isNotEmpty) note,
                      _dateLabel(row['created_at']),
                    ].where((s) => s.isNotEmpty).join('\n')),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
