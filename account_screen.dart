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

  void _reload() {
    setState(() {
      _f = context.read<Repo>().addresses();
    });
  }

  Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(context, e))));
      }
    }
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.user?.id;
    if (uid != _uid) {
      _uid = uid;
      _f = uid == null ? null : context.read<Repo>().addresses();
    }
    if (!auth.loggedIn) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(context.t('loginToSee'), style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(context.t('login')),
              ),
            ]),
          ),
        ),
      );
    }
    final repo = context.read<Repo>();
    return SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: SizedBox(
            width: 96,
            height: 96,
            child: ClipOval(
              child: auth.avatarUrl != null
                  ? NetImage(auth.avatarUrl)
                  : Container(
                      color: AppColors.black,
                      child: const Icon(Icons.person, color: AppColors.white, size: 56)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (auth.email != null)
          Center(child: Text(maskEmail(auth.email), style: const TextStyle(fontSize: 16))),
        if (auth.phone != null)
          Center(
              child: Text(maskPhone(auth.phone),
                  textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 16))),
        const SizedBox(height: 20),
        const Line(),
        const SizedBox(height: 12),
        Text(context.t('addresses'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        FutureBuilder<List<Address>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.black)));
            }
            if (s.hasError) return ErrorView(error: s.error!, onRetry: _reload);
            return Column(children: [
              for (final a in s.data!)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      if (a.isDefault)
                        Text(context.t('defaultBadge'),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    Text('${context.t('landmark')}: ${a.landmark}'),
                    Row(children: [
                      if (!a.isDefault)
                        TextButton(
                          onPressed: () => _guard(() => repo.setDefaultAddress(a.id)),
                          child: Text(context.t('setDefault')),
                        ),
                      TextButton(
                        onPressed: () => _guard(() => repo.deleteAddress(a.id)),
                        child: Text(context.t('delete')),
                      ),
                    ]),
                  ]),
                ),
            ]);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            final ok = await Navigator.of(context)
                .push<bool>(MaterialPageRoute(builder: (_) => const AddAddressScreen()));
            if (ok == true) _reload();
          },
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(context.t('addAddress')),
        ),
      ]),
    );
  }
}
