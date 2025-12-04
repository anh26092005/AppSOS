import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FloatingNavbar extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onHomePressed;
  final VoidCallback onActivityPressed;
  final VoidCallback onSOSPressed;
  final VoidCallback onProfilePressed;

  const FloatingNavbar({
    super.key,
    required this.selectedIndex,
    required this.onHomePressed,
    required this.onActivityPressed,
    required this.onSOSPressed,
    required this.onProfilePressed,
  });

  @override
  State<FloatingNavbar> createState() => _FloatingNavbarState();
}

class _FloatingNavbarState extends State<FloatingNavbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sosPulseController;
  bool _isVolunteer = false;

  @override
  void initState() {
    super.initState();
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(
        'auth_user',
      ); // ← FIX: Match ApiService key
      print('🔍 FloatingNavbar - userJson: $userJson');

      if (userJson != null) {
        final user = json.decode(userJson);
        final roles = user['roles'] as List<dynamic>? ?? [];

        print('🔍 FloatingNavbar - User roles: $roles');

        final isVol = roles.contains('TNV_CN') || roles.contains('TNV_TC');

        print('🔍 FloatingNavbar - Is Volunteer: $isVol');

        setState(() {
          _isVolunteer = isVol;
        });

        print('🔍 FloatingNavbar - _isVolunteer set to: $_isVolunteer');
      } else {
        print('⚠️ FloatingNavbar - No user data in SharedPreferences');
      }
    } catch (e) {
      print('❌ Error loading user role: $e');
    }
  }

  @override
  void dispose() {
    _sosPulseController.dispose();
    super.dispose();
  }

  Widget _buildSOSButton() {
    return AnimatedBuilder(
      animation: _sosPulseController,
      builder: (context, child) {
        final value = _sosPulseController.value;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onSOSPressed,
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 100,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Pulse rings với glow effect
                  ...List.generate(2, (index) {
                    final delay = index * 0.5;
                    final pulseValue = ((value + delay) % 1.0);
                    final size = 70.0 + (pulseValue * 30);
                    final opacity = (1 - pulseValue).clamp(0.0, 0.3);

                    return Positioned(
                      left: 50 - size / 2,
                      top: 35 - size / 2,
                      child: IgnorePointer(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.redAccent.withValues(
                                alpha: opacity,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Main button với viền trắng và glow effect
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print EVERY time build is called
    print('🎨 FloatingNavbar BUILD - _isVolunteer: $_isVolunteer');

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home icon
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: widget.selectedIndex == 0
                      ? const Color(0xFF1976D2)
                      : Theme.of(context).unselectedWidgetColor,
                ),
                iconSize: 28,
                onPressed: widget.onHomePressed,
              ),

              // Activity icon - ONLY for TNV (ẩn với USER thường)
              if (_isVolunteer)
                IconButton(
                  icon: Icon(
                    Icons.history,
                    color: widget.selectedIndex == 1
                        ? const Color(0xFF1976D2)
                        : Theme.of(context).unselectedWidgetColor,
                  ),
                  iconSize: 28,
                  onPressed: widget.onActivityPressed,
                ),

              // SOS button - ONLY for USER (ẩn với TNV)
              if (!_isVolunteer) _buildSOSButton(),

              // Profile icon
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: widget.selectedIndex == 3
                      ? const Color(0xFF1976D2)
                      : Theme.of(context).unselectedWidgetColor,
                ),
                iconSize: 28,
                onPressed: widget.onProfilePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
