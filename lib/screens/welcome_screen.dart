import 'package:flutter/material.dart';

void main() => runApp(const SOSApp());

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOS',
      theme: ThemeData(useMaterial3: true),
      home: const WelcomeSOSScreen(),
    );
  }
}

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
                            color: Colors.blueAccent.withOpacity(
                              opacity * 0.35,
                            ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SOS pressed')),
                            );
                          },
                          child: Container(
                            width: baseSize,
                            height: baseSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color.fromARGB(255, 255, 244, 247),
                                  const Color.fromARGB(2255, 255, 244, 247),
                                ],
                                center: Alignment.topLeft,
                                radius: 1.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 6,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.redAccent,
                                  letterSpacing: 2,
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
