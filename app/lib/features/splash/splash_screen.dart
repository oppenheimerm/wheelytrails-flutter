import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Add a small delay to show the branding (aesthetic requirement)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check auth status from provider
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
          'assets/images/wheelytrails-logo.svg',
          width: 120, // Slightly larger than login (90)
          colorFilter: const ColorFilter.mode(
            Color(0xFF2D5A27), // Forest Green tint
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
