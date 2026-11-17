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
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _email = TextEditingController();
  final _emailCode = TextEditingController();
  bool _sent = false, _emailSent = false, _busy = false, _forgotMode = false;
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


  Future<void> _sendPhone() async {
    final phone = _e164();
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      setState(() => _err = context.t('invalidPhone'));
      return;
    }
    await _run(() async {
      await _auth.sendOtp(phone);
      if (mounted) setState(() => _sent = true);
    });
  }

  Future<void> _verifyPhone() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _err = context.t('invalidCode'));
      return;
    }
    await _run(() => _auth.verifyOtp(_e164(), code));
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

  Future<void> _verifyEmail() async {
    final code = _emailCode.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _err = context.t('invalidCode'));
      return;
    }
    await _run(() => _auth.verifyEmailOtp(_email.text.trim(), code));
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
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                        labelText: context.t('phone'), prefixText: '+20  ', hintText: '10XXXXXXXX'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                    onPressed: _busy ? null : _sendPhone,
                    icon: const Icon(Icons.phone_rounded, color: Colors.white),
                    label: Text(context.t('phoneLogin')),
                  ),
                ] else ...[
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('code')),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : _verifyPhone,
                    child: Text(context.t('verify')),
                  ),
                  TextButton(
                      onPressed: () => setState(() => _sent = false),
                      child: Text(context.t('back'))),
                ],
                const Divider(height: 28, color: AppColors.black),
                if (!_forgotMode && !_emailSent) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('email')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : _sendEmail,
                    child: Text(context.t('emailLogin')),
                  ),
                 ] else if (!_forgotMode && _emailSent) ...[
                  TextField(
                    controller: _emailCode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('code')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : _verifyEmail,
                    child: Text(context.t('verify')),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _emailSent = false),
                    child: Text(context.t('back')),
                  ),
                ],
                if (showGoogle) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.black, backgroundColor: Colors.white, minimumSize: const Size.fromHeight(48), side: const BorderSide(color: Color(0xFFDADCE0))),
                    onPressed: _busy ? null : () => _run(_auth.signInGoogle),
                    icon: const _GoogleMark(),
                    label: Text(context.t('google')),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() {
                      _forgotMode = !_forgotMode;
                      _emailSent = false;
                      _email.clear();
                      _emailCode.clear();
                      _err = null;
                    }),
                    child: Text(
                      context.t('forgotPassword'),
                      style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
                if (_forgotMode) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: context.t('email')),
                  ),
                  const SizedBox(height: 8),
                  if (!_emailSent)
                    OutlinedButton(
                      onPressed: _busy ? null : _sendEmail,
                      child: Text(context.t('sendCode')),
                    )
                  else ...[
                    TextField(
                      controller: _emailCode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: context.t('code')),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _verifyEmail,
                      child: Text(context.t('verify')),
                    ),
                  ],
                  TextButton(
                    onPressed: () => setState(() {
                      _forgotMode = false;
                      _emailSent = false;
                      _err = null;
                    }),
                    child: Text(context.t('back')),
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
