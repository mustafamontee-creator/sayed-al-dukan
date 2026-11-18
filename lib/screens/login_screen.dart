import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../services/auth_service.dart';
import '../ui/widgets.dart';

/// Pops with true once the customer is signed in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _emailSent = false;
  bool _obscurePassword = true;
  bool _busy = false;
  String? _err;
  String? _notice;
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
    _password.dispose();
    super.dispose();
  }

  bool get _validEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  Future<void> _signIn() async {
    if (!_validEmail) {
      setState(() => _err = context.t('invalidEmail'));
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _err = context.t('passwordRequired'));
      return;
    }
    await _run(() => _auth.signInEmailPassword(_email.text, _password.text));
  }

  Future<void> _sendEmail() async {
    if (!_validEmail) {
      setState(() => _err = context.t('invalidEmail'));
      return;
    }
    await _run(() async {
      await _auth.sendEmailOtp(_email.text);
      if (mounted) setState(() => _emailSent = true);
    });
  }

  Future<void> _forgotPassword() async {
    if (!_validEmail) {
      setState(() => _err = context.t('enterEmailForReset'));
      return;
    }
    await _run(() async {
      await _auth.sendPasswordReset(_email.text);
      if (mounted) setState(() => _notice = context.t('resetEmailSent'));
    });
  }

  void _resetEmail() {
    setState(() {
      _emailSent = false;
      _err = null;
      _notice = null;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _err = null;
      _notice = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _err = friendlyError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showApple = Platform.isIOS || Platform.isMacOS;
    final showGoogle = Platform.isAndroid || Platform.isIOS;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            PositionedDirectional(
              top: 2,
              start: 4,
              child: IconButton(
                tooltip: context.t('close'),
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.t('login'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('tagline'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (!_emailSent) ...[
                        TextField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: context.t('email'),
                            prefixIcon: const Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _busy ? null : _signIn(),
                          decoration: InputDecoration(
                            labelText: context.t('password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? context.t('showPassword')
                                  : context.t('hidePassword'),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _busy ? null : _forgotPassword,
                            child: Text(context.t('forgotPassword')),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FilledButton(
                          onPressed: _busy ? null : _signIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(context.t('signInWithPassword')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Divider(color: colors.outlineVariant)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                context.t('or'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: colors.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _sendEmail,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(context.t('createAccountEmail')),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.mark_email_read_outlined, color: colors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  context.t('emailLinkSent'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : _resetEmail,
                          child: Text(context.t('back')),
                        ),
                      ],
                      if (showGoogle) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _run(_auth.signInGoogle),
                          icon: const _GoogleMark(),
                          label: Text(context.t('google')),
                        ),
                      ],
                      if (showApple) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _run(_auth.signInApple),
                          icon: const Icon(Icons.apple_rounded, size: 22),
                          label: Text(context.t('apple')),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_rounded, color: colors.onSurfaceVariant),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.t('phoneLogin'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                context.t('soon'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_notice != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _notice!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_err != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _err!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (_busy) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ).createShader(bounds),
        child: const Text(
          'G',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
      );
}
