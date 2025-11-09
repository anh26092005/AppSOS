import 'package:flutter/material.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _sosActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _activateSOS() {
    setState(() {
      _sosActive = true;
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SOS Activated!'),
        content: const Text(
          'Emergency services have been notified. Your location has been shared with your emergency contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _sosActive = false;
              });
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseSize = 200.0;

    return Scaffold(
      backgroundColor: _sosActive ? Colors.red.shade50 : Colors.white,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final v1 = _controller.value;
                  final v2 = (v1 + 0.5) % 1.0;

                  Widget ring(double v) {
                    final size = baseSize + v * 150;
                    final opacity = (1 - v).clamp(0.0, 1.0);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: opacity * 0.4),
                          width: 12 * (1 - v * 0.7),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ring(v1),
                      ring(v2),
                      GestureDetector(
                        onTap: _activateSOS,
                        child: Container(
                          width: baseSize,
                          height: baseSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.red.shade300,
                                Colors.red.shade600,
                              ],
                              center: Alignment.topLeft,
                              radius: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Press the button to send emergency alert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your location will be shared with emergency services and your emergency contacts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

