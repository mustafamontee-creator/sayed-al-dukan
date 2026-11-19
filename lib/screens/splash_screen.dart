import 'dart:async';

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
  static const _fadeDuration = Duration(milliseconds: 350);
  static const _revealAnimationAt = Duration(milliseconds: 500);

  VideoPlayerController? _videoController;
  late final Future<void> _updateCheck;
  bool _showStaticLogo = true;
  bool _fadingOut = false;
  bool _readyToEnter = false;
  bool _finishing = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _updateCheck = UpdateService.checkAndNotify().catchError((_) {});
    _waitUntilAppReady();
    _startIntroVideo();
  }

  Future<void> _waitUntilAppReady() async {
    await _updateCheck;
    if (!mounted) return;
    _readyToEnter = true;
    if (_videoFailed) {
      _finishIntro();
    }
    // If the clip is playing, the listener waits for its end. It is never
    // interrupted halfway through when the app becomes ready.
  }

  Future<void> _startIntroVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/animation/dukan_9x16_4k.mp4',
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
      _videoFailed = true;
      if (_readyToEnter) {
        _finishIntro();
      } else {
        // Keep startup recoverable if video decoding fails on a device.
        unawaited(_updateCheck.then((_) {
          if (mounted) _finishIntro();
        }));
      }
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
    if (value.hasError) {
      _videoFailed = true;
      if (_readyToEnter) _finishIntro();
      return;
    }

    final reachedEnd = !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 100);
    if (!reachedEnd) return;

    if (_readyToEnter) {
      _finishIntro();
    } else {
      // Loop only while the app is still preparing. Once ready, finish the
      // current complete play-through and then open the app.
      controller.seekTo(Duration.zero).then((_) {
        if (mounted && !_finishing && !_readyToEnter) {
          controller.play();
        } else if (mounted && !_finishing && _readyToEnter) {
          _finishIntro();
        }
      });
    }
  }

  Future<void> _finishIntro() async {
    if (_finishing) return;
    _finishing = true;

    final controller = _videoController;
    controller?.removeListener(_handleVideoProgress);
    if (mounted) setState(() => _fadingOut = true);
    await Future.delayed(_fadeDuration);
    if (!mounted) return;

    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
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

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: AnimatedOpacity(
            opacity: _fadingOut ? 0 : 1,
            duration: _fadeDuration,
            curve: Curves.easeOut,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (videoReady)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: controller!.value.size.width,
                        height: controller!.value.size.height,
                        child: VideoPlayer(controller!),
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: (!videoReady || _showStaticLogo) ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    'assets/images/splash_logo.webp',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 0.72,
                    height: MediaQuery.of(context).size.width * 0.72,
                    gaplessPlayback: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
