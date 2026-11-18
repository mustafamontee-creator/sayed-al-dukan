import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../services/repo.dart';
import '../services/update_notification_store.dart';
import '../services/update_service.dart';
import '../ui/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late Future<Map<String, dynamic>?> _updateFuture;

  @override
  void initState() {
    super.initState();
    _future = context.read<Repo>().notifications();
    _updateFuture = _loadUpdate();
    UpdateNotificationStore.markRead();
  }

  Future<Map<String, dynamic>?> _loadUpdate() async {
    final update = await UpdateNotificationStore.read();
    if (update == null) return null;
    final current = await PackageInfo.fromPlatform();
    final installedCode = int.tryParse(current.buildNumber) ?? 0;
    final updateCode = (update['version_code'] as num?)?.toInt() ?? 0;
    if (updateCode <= installedCode) {
      await UpdateNotificationStore.markRead();
      return null;
    }
    return update;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<Repo>().notifications();
      _updateFuture = _loadUpdate();
    });
    await _future;
    await _updateFuture;
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

  Widget _updateCard(BuildContext context, Map<String, dynamic> update) {
    final en = context.lang == 'en';
    final version = (update['version_name'] ?? '').toString();
    final description = (en
            ? update['description_en']
            : update['description_ar'])
        ?.toString()
        .trim() ?? '';
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF0B3),
                  child: const Icon(Icons.system_update_alt, color: Color(0xFF765A00)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    en ? 'New app update' : 'تحديث جديد لسيد الدكان',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colors.onSurface),
                  ),
                ),
                Text(
                  en ? 'v$version' : 'الإصدار $version',
                  style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description.isNotEmpty
                  ? description
                  : (en ? 'Improvements and fixes are ready.' : 'توجد تحسينات وإصلاحات جديدة.'),
              style: TextStyle(height: 1.5, color: colors.onSurface),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => UpdateService.checkAndShow(context),
                icon: const Icon(Icons.download_rounded),
                label: Text(en ? 'View and install update' : 'عرض التحديث وتثبيته'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final en = context.lang == 'en';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.t('notifications')),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _refresh);
          }
          final rows = snapshot.data ?? [];
          return FutureBuilder<Map<String, dynamic>?>(
            future: _updateFuture,
            builder: (context, updateSnapshot) {
              if (updateSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final update = updateSnapshot.data;
              final itemCount = rows.length + (update == null ? 0 : 1);
              if (itemCount == 0) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 64),
                      BrandedEmptyView(message: context.t('notFound')),
                      const SizedBox(height: 64),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                  itemBuilder: (context, index) {
                    if (update != null && index == 0) {
                      return _updateCard(context, update);
                    }
                    final row = rows[index - (update == null ? 0 : 1)];
                    final order = row['orders'] is Map
                        ? Map<String, dynamic>.from(row['orders'] as Map)
                        : <String, dynamic>{};
                    final status = (row['status'] ?? '').toString();
                    final number = (order['order_number'] ?? '').toString();
                    final note = (row['note'] ?? '').toString().trim();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.notifications_active_outlined, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      title: Text(
                        _statusTitle(context, status),
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
          );
        },
      ),
    );
  }
}
