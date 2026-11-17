import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../ui/widgets.dart';

/// Pops with `true` once the customer is signed in, so callers (checkout)
/// can continue without losing the cart.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _emailCode = TextEditingController();
  bool _sent = false, _emailSent = false, _busy = false;
  String? _err;
  late final AuthService _auth;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _auth.addListener(_check);
  }

  void _check() {
    if (_auth.loggedIn && mounted && !_done) {
      _done = true;
      Navigator.of(context).pop(true);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_check);
    _phone.dispose();
    _code.dispose();
    _email.dispose();
    _emailCode.dispose();
    super.dispose();
  }

  String _e164() {
    var p = _phone.text.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('00')) return '+${p.substring(2)}';
    if (p.startsWith('0')) p = p.substring(1);
    return '+20$p'; // Egypt is the only active region
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await f();
    } catch (e) {
      if (mounted) setState(() => _err = friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showApple = Platform.isIOS || Platform.isMacOS;
    final showGoogle = Platform.isAndroid || Platform.isIOS;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(children: [
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            color: AppColors.blue,
            child: SafeArea(
              bottom: false,
              child: Stack(children: [
                Center(child: Image.asset('assets/images/logo.jpeg', height: 260)),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!_sent) ...[
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                        labelText: context.t('phone'), prefixText: '+20  ', hintText: '10XXXXXXXX'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _run(() async {
                          await _auth.sendOtp(_e164());
                          if (mounted) setState(() => _sent = true);
                        }),
                    child: Text(context.t('phoneLogin')),
                  ),
                ] else ...[
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('code')),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _run(() => _auth.verifyOtp(_e164(), _code.text.trim())),
                    child: Text(context.t('verify')),
                  ),
                  TextButton(
                      onPressed: () => setState(() => _sent = false),
                      child: Text(context.t('back'))),
                ],
                const Divider(height: 28, color: AppColors.black),
                if (!_emailSent) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('email')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _run(() async {
                      await _auth.sendEmailOtp(_email.text.trim());
                      if (mounted) setState(() => _emailSent = true);
                    }),
                    child: Text(context.t('emailLogin')),
                  ),
                ] else ...[
                  TextField(
                    controller: _emailCode,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('code')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _run(
                      () => _auth.verifyEmailOtp(_email.text.trim(), _emailCode.text.trim()),
                    ),
                    child: Text(context.t('verify')),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _emailSent = false),
                    child: Text(context.t('back')),
                  ),
                ],
                if (showGoogle) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _run(_auth.signInGoogle),
                    child: Text(context.t('google')),
                  ),
                ],
                if (showApple) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _run(_auth.signInApple),
                    child: Text(context.t('apple')),
                  ),
                ],
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_err!, style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.bold)),
                  ),
                if (_busy)
                  const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator(color: AppColors.black))),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
