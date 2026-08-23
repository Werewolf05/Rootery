import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rootery_app/theme/rootery_theme.dart';
import 'package:rootery_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();

    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        try {
          final shouldAutoLogin = await AuthService.shouldAutoLogin();
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            shouldAutoLogin ? '/main' : '/login',
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6F4EA), RooteryTheme.bgScaffold],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: RooteryTheme.bgSurface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: RooteryTheme.borderLight),
                      boxShadow: const [RooteryTheme.cardShadow],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 92,
                          height: 92,
                          child: Image.asset(
                            'assets/images/gov.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance,
                              size: 56,
                              color: RooteryTheme.green600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Department of Science and Technology',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RooteryTheme.ui(
                            15,
                            weight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: RooteryTheme.textHigh,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Government of India',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RooteryTheme.ui(
                            12,
                            color: RooteryTheme.textMid,
                            weight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RooteryTheme.green50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: RooteryTheme.borderLight),
                          ),
                          child: Text(
                            'ROOTERY',
                            style: RooteryTheme.mono(
                              11,
                              color: RooteryTheme.green600,
                              weight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Hydroponics Platform',
                          style: RooteryTheme.ui(
                            13,
                            color: RooteryTheme.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  Text(
                    'Loading dashboard...',
                    style: RooteryTheme.ui(
                      16,
                      weight: FontWeight.w500,
                      color: RooteryTheme.textHigh,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 8,
                          backgroundColor: RooteryTheme.green100,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            RooteryTheme.green400,
                          ),
                        ),
                      );
                    },
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
