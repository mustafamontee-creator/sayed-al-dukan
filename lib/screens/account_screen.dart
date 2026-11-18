import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/repo.dart';
import '../ui/widgets.dart';
import 'add_address_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<List<Address>>? _f;
  String? _uid;

  static const yellow = Color(0xFFFFC94A);
  static const red = Color(0xFFD94747);

  void _reload() => setState(() => _f = context.read<Repo>().addresses());

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(context, e))),
      );
    }
    if (mounted) _reload();
  }

  Future<void> _logout(AuthService auth) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.t('logout')),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(d, true),
            child: Text(context.t('logout')),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await auth.signOut();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(context, e))),
      );
    }
  }

  Future<void> _changePassword(AuthService auth) async {
    final password = TextEditingController();
    final confirm = TextEditingController();
    var saving = false;
    var obscure = true;
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.t('changePassword')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: context.t('newPassword'),
                  suffixIcon: IconButton(
                    onPressed: () => setDialogState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirm,
                obscureText: obscure,
                decoration: InputDecoration(labelText: context.t('confirmPassword')),
              ),
              const SizedBox(height: 8),
              Text(context.t('passwordHint'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: Text(context.t('cancel')),
            ),
            FilledButton(
              onPressed: saving ? null : () async {
                final p = password.text;
                if (p.length < 8 || p != confirm.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('passwordValidation'))),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await auth.changePassword(p);
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() => saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyError(context, e))),
                    );
                  }
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.t('save')),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    confirm.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('passwordSaved'))),
      );
    }
  }

  Widget _section(String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(children: [
        Icon(icon, size: 19, color: colors.secondary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.onSurface)),
      ]),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    final colors = Theme.of(context).colorScheme;
    final soft = Theme.of(context).brightness == Brightness.dark
        ? colors.surfaceContainerHigh
        : const Color(0xFFE8F0F7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: colors.secondary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface)),
        ])),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageColor = theme.scaffoldBackgroundColor;
    final cardColor = colors.surface;
    final blueSoftColor = isDark ? colors.surfaceContainerHigh : const Color(0xFFE8F0F7);
    final greenColor = isDark ? const Color(0xFF8AD5A8) : const Color(0xFF238653);
    final greenSoftColor = isDark ? const Color(0xFF244536) : const Color(0xFFE7F5EC);
    final lineColor = colors.outlineVariant;
    final mutedColor = colors.onSurfaceVariant;
    final auth = context.watch<AuthService>();
    final uid = auth.user?.id;
    if (uid != _uid) {
      _uid = uid;
      _f = uid == null ? null : context.read<Repo>().addresses();
    }

    if (!auth.loggedIn) {
      return Container(
        color: pageColor,
        child: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 76, height: 76,
                decoration: BoxDecoration(color: blueSoftColor, shape: BoxShape.circle),
                child: const Icon(Icons.person_outline_rounded, size: 40, color: AppColors.blue)),
              const SizedBox(height: 16),
              Text(context.t('loginToSee'), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(context.t('login')),
              )),
            ]),
          ),
        ))),
      );
    }

    final repo = context.read<Repo>();
    final metadata = auth.user?.userMetadata ?? {};
    final displayName = (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();
    final emailVerified = auth.user?.emailConfirmedAt?.isNotEmpty ?? false;
    final phoneVerified = auth.user?.phoneConfirmedAt?.isNotEmpty ?? false;
    final verified = emailVerified || phoneVerified;

    return Container(
      color: pageColor,
      child: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(26)),
            child: Column(children: [
              Align(alignment: AlignmentDirectional.centerStart,
                child: Text(context.t('account'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600))),
              const SizedBox(height: 14),
              Container(width: 88, height: 88, padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 2)),
                child: ClipOval(child: auth.avatarUrl != null
                  ? NetImage(auth.avatarUrl)
                  : Container(color: blueSoftColor, child: const Icon(Icons.person_rounded, color: AppColors.blue, size: 52)))),
              const SizedBox(height: 12),
              Text(displayName.isEmpty ? context.t('account') : displayName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              if (auth.email != null) ...[
                const SizedBox(height: 4),
                Text(maskEmail(auth.email), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
              if (auth.phone != null) ...[
                const SizedBox(height: 3),
                Text(maskPhone(auth.phone), textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                decoration: BoxDecoration(color: verified ? greenSoftColor : Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(verified ? Icons.verified_rounded : Icons.info_outline_rounded, color: verified ? greenColor : Colors.white, size: 17),
                  const SizedBox(width: 6),
                  Text(verified ? 'حساب موثوق' : 'الحساب غير موثّق بعد',
                    style: TextStyle(color: verified ? greenColor : Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _section(context.t('accountInfo'), Icons.manage_accounts_outlined),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              if (displayName.isNotEmpty) _info(Icons.person_outline, context.t('name'), displayName),
              if (auth.email != null) ...[
                if (displayName.isNotEmpty) Divider(height: 1, color: lineColor),
                _info(Icons.email_outlined, context.t('email'), maskEmail(auth.email)),
              ],
              if (auth.phone != null) ...[
                Divider(height: 1, color: lineColor),
                _info(Icons.phone_outlined, context.t('phone'), maskPhone(auth.phone)),
              ],
            ]),
          ),
          const SizedBox(height: 22),
          _section(context.t('addresses'), Icons.location_on_outlined),
          FutureBuilder<List<Address>>(
            future: _f,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) return const Padding(
                padding: EdgeInsets.all(22), child: Center(child: CircularProgressIndicator(color: AppColors.blue)));
              if (s.hasError) return ErrorView(error: s.error!, onRetry: _reload);
              final addresses = s.data ?? <Address>[];
              if (addresses.isEmpty) return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Icon(Icons.add_location_alt_outlined, size: 34, color: mutedColor),
                  const SizedBox(height: 8),
                  Text('لا توجد عناوين مضافة', style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
                  const SizedBox(height: 4),
                  Text('أضف عنوانك لتسهيل توصيل طلباتك', style: TextStyle(color: mutedColor, fontSize: 12)),
                ]),
              );
              return Column(children: [
                for (final a in addresses) Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardColor, borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: a.isDefault ? const Color(0xFFBFE5CD) : lineColor)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 38, height: 38,
                        decoration: BoxDecoration(color: blueSoftColor, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.location_on_outlined, color: AppColors.blue)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: colors.onSurface))),
                      if (a.isDefault) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: greenSoftColor, borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.check_circle, color: greenColor, size: 14), const SizedBox(width: 4),
                          Text('افتراضي', style: TextStyle(color: greenColor, fontSize: 11, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 9),
                    Text('${context.t('landmark')}: ${a.landmark}', style: TextStyle(color: mutedColor, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      if (!a.isDefault) OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: greenColor, side: BorderSide(color: greenColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _guard(() => repo.setDefaultAddress(a.id)),
                        icon: const Icon(Icons.check_circle_outline, size: 17),
                        label: const Text('تعيين كافتراضي'),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: red),
                        onPressed: () async {
                          final yes = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                            title: Text(context.t('delete')),
                            content: const Text('هل تريد حذف هذا العنوان؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.t('cancel'))),
                              TextButton(onPressed: () => Navigator.pop(d, true), child: Text(context.t('delete'))),
                            ],
                          ));
                          if (yes == true) _guard(() => repo.deleteAddress(a.id));
                        },
                        icon: const Icon(Icons.delete_outline, size: 17),
                        label: Text(context.t('delete')),
                      ),
                    ]),
                  ]),
                ),
              ]);
            },
          ),
          const SizedBox(height: 6),
          SizedBox(height: 54, child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: yellow, foregroundColor: const Color(0xFF49370A),
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
              if (ok == true) _reload();
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(context.t('addAddress'), style: const TextStyle(fontWeight: FontWeight.w800)),
          )),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.secondary,
                backgroundColor: cardColor,
                side: BorderSide(color: colors.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () => _changePassword(auth),
              icon: const Icon(Icons.lock_reset_rounded),
              label: Text(context.t('changePassword'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(height: 52, child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: red, side: BorderSide(color: red.withValues(alpha: 0.45)),
              backgroundColor: isDark ? const Color(0xFF3B2525) : const Color(0xFFFFF2F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () => _logout(auth),
            icon: const Icon(Icons.logout_rounded),
            label: Text(context.t('logout'), style: const TextStyle(fontWeight: FontWeight.w800)),
          )),
        ],
      )),
    );
  }
}
