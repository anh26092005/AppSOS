import 'package:flutter/material.dart';

class WelcomeSOSScreen extends StatefulWidget {
  const WelcomeSOSScreen({super.key});

  @override
  State<WelcomeSOSScreen> createState() => _WelcomeSOSScreenState();
}

class _WelcomeSOSScreenState extends State<WelcomeSOSScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseSize = 180.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo và tiêu đề
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emergency,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'SOS App',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'An toàn của bạn là ưu tiên hàng đầu của chúng tôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Vòng tròn SOS, hiệu ứng
              Center(
                child: AnimatedBuilder(
                  animation: _ac,
                  builder: (context, _) {
                    final v1 = _ac.value;
                    final v2 = (v1 + 0.5) % 1.0;

                    Widget ring(double v) {
                      final size = baseSize + v * 120; // 180 -> 300
                      final opacity = (1 - v).clamp(0.0, 1.0);
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: opacity * 0.35),
                            width: 10 * (1 - v * 0.7),
                          ),
                        ),
                      );
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        ring(v1),
                        ring(v2),
                        // Nút tròn SOS
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Container(
                            width: baseSize,
                            height: baseSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.red.shade400,
                                  Colors.red.shade700,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              // Nút Login và Sign Up
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Đăng Nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Đăng Ký',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Powered by UTH TEAM',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
