import 'dart:async';
import 'dart:typed_data';

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
  String? get contactPhone => (user?.userMetadata?['contact_phone'] ?? '').toString().trim().isEmpty
      ? null
      : user!.userMetadata!['contact_phone'].toString();
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
  Future<void> signInEmailPassword(String emailAddress, String password) async {
    await _a.signInWithPassword(email: emailAddress.trim(), password: password);
  }

  Future<void> sendPasswordReset(String emailAddress) =>
      _a.resetPasswordForEmail(
        emailAddress.trim(),
        redirectTo: AppConfig.oauthRedirect,
      );

  Future<void> sendEmailOtp(String emailAddress) =>
      _a.signInWithOtp(
        email: emailAddress.trim(),
        shouldCreateUser: true,
        emailRedirectTo: AppConfig.oauthRedirect,
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

  Future<void> updateProfile({
    required String fullName,
    required String contactPhone,
  }) async {
    final current = user;
    if (current == null) throw StateError('not_authenticated');
    await _a.updateUser(UserAttributes(data: {
      'full_name': fullName.trim(),
      'contact_phone': contactPhone.trim(),
    }));
    await Supabase.instance.client.from('profiles').update({
      'full_name': fullName.trim(),
      'contact_phone': contactPhone.trim(),
    }).eq('id', current.id);
    user = _a.currentUser;
    notifyListeners();
  }

  Future<void> updateAvatar(List<int> bytes) async {
    final current = user;
    if (current == null) throw StateError('not_authenticated');
    final path = '${current.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage.from('profile-avatars').uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
        cacheControl: '3600',
      ),
    );
    final url = Supabase.instance.client.storage
        .from('profile-avatars')
        .getPublicUrl(path);
    await _a.updateUser(UserAttributes(data: {'avatar_url': url}));
    user = _a.currentUser;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) =>
      _a.updateUser(UserAttributes(password: newPassword));

  Future<void> signOut() => _a.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
