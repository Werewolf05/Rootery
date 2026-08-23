import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rootery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Create progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation
    _controller.forward();

    // Navigate to next screen after delay
    Timer(const Duration(seconds: 3), () {
      // Navigate to your home screen here
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()),
      // );
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
      backgroundColor: const Color(0xFF0D2847), // Dark blue background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            
            // Logo Card
            Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E), // Dark green
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CustomPaint(
                      painter: LogoPainter(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'ROOTERY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    'í•˜ëŠ˜ì„ ë‹´ì€ ì‹í’ˆ ê±´ì¡°ê¸°',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Additional text
                  const Text(
                    'ì‚¶ì„ í’ìš”ë¡­ê²Œí•˜ëŠ” ê±´ì¡°ì‹í’ˆ ì†”ë£¨ì…˜',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 2),
            
            // Initializing text and progress bar
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  const Text(
                    'Initializing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Progress bar
                  SizedBox(
                    width: 260,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            // Background bar
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            // Progress bar
                            FractionallySizedBox(
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC107), // Yellow/amber
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the logo
class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw golden circle (incomplete)
    paint.color = const Color(0xFFFFD700); // Gold color
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.4, size.height * 0.5),
      radius: size.width * 0.3,
    );
    canvas.drawArc(
      rect,
      -2.4, // Start angle
      4.7, // Sweep angle (not complete circle)
      false,
      paint,
    );

    // Draw leaf
    paint.color = const Color(0xFF90C695); // Light green
    paint.style = PaintingStyle.fill;

    final leafPath = Path();
    final centerX = size.width * 0.55;
    final centerY = size.height * 0.45;
    
    // Create leaf shape
    leafPath.moveTo(centerX, centerY - 15);
    leafPath.quadraticBezierTo(
      centerX + 20, centerY - 10,
      centerX + 25, centerY + 10,
    );
    leafPath.quadraticBezierTo(
      centerX + 15, centerY + 5,
      centerX, centerY - 15,
    );

    canvas.drawPath(leafPath, paint);

    // Draw leaf vein
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = const Color(0xFF6B9F71);
    
    final veinPath = Path();
    veinPath.moveTo(centerX, centerY - 15);
    veinPath.lineTo(centerX + 15, centerY + 5);
    
    canvas.drawPath(veinPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
