import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';

class AuthService extends ChangeNotifier {
  StreamSubscription<AuthState>? _sub;
  User? user;
  Future<void> Function()? onSignedIn;

  bool get loggedIn => user != null;
  String? get email => user?.email;
  String? get phone => (user?.phone ?? '').isEmpty ? null : user!.phone;
  String? get avatarUrl {
    final m = user?.userMetadata;
    return (m?['avatar_url'] ?? m?['picture']) as String?;
  }

  GoTrueClient get _a {
    if (!AppConfig.isConfigured) throw const ConfigException();
    return Supabase.instance.client.auth;
  }

  void init() {
    if (!AppConfig.isConfigured) return;
    user = _a.currentUser;
    if (user != null) onSignedIn?.call();
    _sub = _a.onAuthStateChange.listen((s) {
      final was = user;
      user = s.session?.user;
      if (was == null && user != null) onSignedIn?.call();
      notifyListeners();
    });
  }

  Future<void> sendOtp(String e164Phone) =>
      _a.signInWithOtp(phone: e164Phone, shouldCreateUser: false);

  // Allow a new customer to create an account through email OTP.
  Future<void> sendEmailOtp(String emailAddress) =>
      _a.signInWithOtp(
        email: emailAddress.trim(),
        shouldCreateUser: true,
      );

  Future<void> verifyOtp(String e164Phone, String code) =>
      _a.verifyOTP(phone: e164Phone, token: code, type: OtpType.sms);

  Future<void> verifyEmailOtp(String emailAddress, String code) =>
      _a.verifyOTP(email: emailAddress.trim(), token: code, type: OtpType.email);

  Future<void> signInGoogle() => _a.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.oauthRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  Future<void> signInApple() =>
      _a.signInWithOAuth(OAuthProvider.apple, redirectTo: AppConfig.oauthRedirect);

  Future<void> changePassword(String newPassword) =>
      _a.updateUser(UserAttributes(password: newPassword));

  Future<void> signOut() => _a.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
