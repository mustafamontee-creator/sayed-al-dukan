import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/update_service.dart';
import '../services/update_notification_store.dart';
import 'notifications_screen.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _background = Color(0xFF516E96);
  static const _revealAnimationAt = Duration(milliseconds: 500);
  static const _fadeDuration = Duration(milliseconds: 450);

  VideoPlayerController? _videoController;
  late final Future<void> _updateCheck;
  bool _showStaticLogo = true;
  bool _fadingOut = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _updateCheck = UpdateService.checkAndNotify().catchError((_) {});
    _startLogoAnimation();
  }

  Future<void> _startLogoAnimation() async {
    final controller = VideoPlayerController.asset(
      'assets/animation/logo_intro.mp4',
    );
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_handleVideoProgress);
      setState(() {});
      await controller.play();
    } catch (_) {
      controller.removeListener(_handleVideoProgress);
      await controller.dispose();
      if (!mounted) return;
      _videoController = null;
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _finishIntro();
    }
  }

  void _handleVideoProgress() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized || _finishing) {
      return;
    }

    final value = controller.value;
    if (_showStaticLogo && value.position >= _revealAnimationAt) {
      setState(() => _showStaticLogo = false);
    }

    if (value.hasError ||
        (!value.isPlaying &&
            value.position >= value.duration - const Duration(milliseconds: 80))) {
      _finishIntro();
    }
  }

  Future<void> _finishIntro() async {
    if (_finishing) return;
    _finishing = true;

    if (mounted) {
      setState(() => _fadingOut = true);
    }
    await Future.delayed(_fadeDuration);
    await _updateCheck;
    if (!mounted) return;

    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const Shell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

    if (UpdateNotificationStore.pendingOpenNotifications) {
      UpdateNotificationStore.pendingOpenNotifications = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_handleVideoProgress);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final videoReady = controller?.value.isInitialized ?? false;
    final logoSize = MediaQuery.of(context).size.width * 0.82;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _fadingOut ? 0 : 1,
            duration: _fadeDuration,
            curve: Curves.easeOut,
            child: SizedBox.square(
              dimension: logoSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (videoReady) VideoPlayer(controller!),
                  if (_showStaticLogo || !videoReady)
                    Image.asset(
                      'assets/images/splash_logo.webp',
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
