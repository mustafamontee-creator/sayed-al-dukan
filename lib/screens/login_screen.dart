import 'dart:io' show Platform;
import 'package:flutter/services.dart';

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
  final _email = TextEditingController();
  bool _emailSent = false, _busy = false;
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
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _err = context.t('invalidEmail'));
      return;
    }
    await _run(() async {
      await _auth.sendEmailOtp(email);
      if (mounted) setState(() => _emailSent = true);
    });
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
                // Phone sign-in is intentionally deferred to a future release.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E9EB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5D7DA)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.phone_rounded, color: Color(0xFF777B80)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t('phoneLogin'),
                        style: const TextStyle(
                          color: Color(0xFF777B80),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D7DA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.t('soon'),
                        style: const TextStyle(
                          color: Color(0xFF55595E),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 28, color: AppColors.black),
                if (!_emailSent) ...[
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: context.t('email'))),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _busy ? null : _sendEmail, child: Text(context.t('emailLogin'))),
                ] else ...[
                  Text(context.t('emailLinkSent'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextButton(onPressed: _busy ? null : () => setState(() { _emailSent = false; _err = null; }), child: Text(context.t('back'))),
                ],
                if (showGoogle) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.black, backgroundColor: Colors.white, minimumSize: const Size.fromHeight(48), side: const BorderSide(color: Color(0xFFDADCE0))),
                    onPressed: _busy ? null : () => _run(_auth.signInGoogle),
                    icon: const _GoogleMark(),
                    label: Text(context.t('google')),
                  ),
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


class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => const SweepGradient(
      colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
    ).createShader(bounds),
    child: const Text('G', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
  );
}
