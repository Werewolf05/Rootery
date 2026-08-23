import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/rootery_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  bool _loading = false;

  late final AnimationController _enterCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();
  }

  void _handleLogin() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await AuthService.persistLocalLogin();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RooteryTheme.bgScaffold,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: BoxDecoration(
              color: RooteryTheme.bgDark,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: CustomPaint(
              painter: _LeafGridPainter(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rootery',
                      style: RooteryTheme.ui(
                        36,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart hydroponics, simplified.',
                      style: RooteryTheme.ui(
                        14,
                        color: RooteryTheme.textLow,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.67,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: const BoxDecoration(
                    color: RooteryTheme.bgSurface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [RooteryTheme.cardShadow],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: RooteryTheme.borderMid,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: RooteryTheme.ui(14),
                          decoration: _inputDecoration(
                            'Email',
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          style: RooteryTheme.ui(14),
                          decoration:
                              _inputDecoration(
                                'Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: RooteryTheme.textMid,
                                  ),
                                  onPressed: () => setState(
                                    () =>
                                        isPasswordVisible = !isPasswordVisible,
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 18),
                        _ScaleButton(
                          onTap: _loading ? () {} : _handleLogin,
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: RooteryTheme.green400,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [RooteryTheme.cardShadow],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: RooteryTheme.ui(
                                          16,
                                          weight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(
                            'Create account',
                            style: RooteryTheme.ui(
                              14,
                              color: RooteryTheme.green600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: RooteryTheme.ui(11, color: RooteryTheme.textMid),
      filled: true,
      fillColor: RooteryTheme.bgSubtle,
      prefixIcon: Icon(icon, color: RooteryTheme.textMid),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: RooteryTheme.borderMid),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: RooteryTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: RooteryTheme.green400),
      ),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _ScaleButton extends StatefulWidget {
  const _ScaleButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _LeafGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = RooteryTheme.green100.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final leaf = Paint()
      ..color = RooteryTheme.green100.withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.78, size.height * 0.12)
      ..quadraticBezierTo(
        size.width * 0.96,
        size.height * 0.22,
        size.width * 0.84,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.3,
        size.width * 0.78,
        size.height * 0.12,
      );
    canvas.drawPath(path, leaf);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

