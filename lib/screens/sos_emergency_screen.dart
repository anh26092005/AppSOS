import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/active_sos_provider.dart';

class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key});

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  late AnimationController _holdController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _selectedEmergencyType = 'Y tế';

  LatLng _initialPosition = const LatLng(
    10.8231,
    106.6297,
  ); // TP.HCM coordinates

  List<Marker> _markers = [];

  // Map từ giá trị hiển thị (tiếng Việt) sang giá trị API (tiếng Anh)
  final Map<String, String> _emergencyTypesMap = {
    'Y tế': 'MEDICAL',
    'Cháy nổ': 'FIRE',
    'Tai nạn': 'ACCIDENT',
    'Trộm cắp': 'CRIME',
    'Thiên tai': 'NATURAL_DISASTER',
    'Khác': 'OTHER',
  };

  // List of emergency types for dropdown
  List<String> get _emergencyTypes => _emergencyTypesMap.keys.toList();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Schedule the SOS action to avoid blocking the animation listener
        // or triggering state changes during the notification phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _sendSOS();
            _holdController.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng bật dịch vụ vị trí'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quyền truy cập vị trí bị từ chối'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _markers = [
          Marker(
            point: LatLng(position.latitude, position.longitude),
            width: 80,
            height: 80,
            child: Column(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 40),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Text(
                    'Vị trí của bạn',
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ];
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật vị trí hiện tại'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lấy vị trí: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  bool _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên của bạn'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng lấy vị trí hiện tại trước'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _sendSOS() async {
    // Inputs are validated before animation starts, but double check doesn't hurt
    if (!_validateInputs()) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiService.sendSOS(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        emergencyType: _emergencyTypesMap[_selectedEmergencyType] ?? 'OTHER',
        description:
            'Tên: ${_nameController.text}\n${_descriptionController.text}',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Get caseId from response
      final caseData = response['data']?['case'];
      final caseId = caseData?['_id'];

      if (caseId != null) {
        // Update ActiveSosProvider to show banner
        if (mounted) {
          context.read<ActiveSosProvider>().setActiveCase(response['data']);
        }

        // Navigate to searching screen
        Navigator.pushReplacementNamed(
          context,
          '/sos-searching',
          arguments: {'caseId': caseId, 'caseData': caseData},
        );
      } else {
        // Fallback: just show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi tín hiệu SOS thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _nameController.clear();
      _descriptionController.clear();
    } on SosBannedException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Yêu cầu bị từ chối'),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi SOS: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1), // Light beige
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFB74D), // Orange
                      Color(0xFFFF6F00), // Deep Orange
                      Color(0xFFD84315), // Red Orange
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD84315).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cứu hộ khẩn cấp',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gửi vị trí và thông tin sự cố ngay lập tức.\nĐội cứu hộ sẽ hỗ trợ bạn.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Map Section
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _initialPosition,
                                  initialZoom: 15.0,
                                  minZoom: 3.0,
                                  maxZoom: 18.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.app_sos',
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(markers: _markers),
                                ],
                              ),
                              // Location Button Overlay
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: FloatingActionButton.small(
                                  onPressed: _isLoadingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  backgroundColor: Colors.white,
                                  elevation: 4,
                                  child: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.orange,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location,
                                          color: Colors.orange,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Form Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin chi tiết',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name Input
                            _buildTextField(
                              controller: _nameController,
                              hintText: 'Họ và tên của bạn (*)',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // Emergency Type Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedEmergencyType,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey,
                                  ),
                                  items: _emergencyTypes.map((String type) {
                                    IconData icon;
                                    Color color;
                                    switch (type) {
                                      case 'Y tế':
                                        icon = Icons.medical_services_outlined;
                                        color = Colors.red;
                                        break;
                                      case 'Tai nạn':
                                        icon = Icons.car_crash_outlined;
                                        color = Colors.orange;
                                        break;
                                      case 'Cháy nổ':
                                        icon = Icons
                                            .local_fire_department_outlined;
                                        color = Colors.deepOrange;
                                        break;
                                      case 'Trộm cắp':
                                        icon = Icons.security_outlined;
                                        color = Colors.purple;
                                        break;
                                      default:
                                        icon = Icons.warning_amber_rounded;
                                        color = Colors.grey;
                                    }
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              icon,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            type,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedEmergencyType = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description Input
                            _buildTextField(
                              controller: _descriptionController,
                              hintText: 'Mô tả sự cố / Ghi chú thêm...',
                              icon: Icons.notes_rounded,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // SOS Button
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTapDown: (_) {
                                if (_validateInputs()) {
                                  _holdController.forward();
                                }
                              },
                              onTapUp: (_) {
                                if (_holdController.isAnimating) {
                                  _holdController.reset();
                                }
                              },
                              onTapCancel: () {
                                _holdController.reset();
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Progress Indicator
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: AnimatedBuilder(
                                      animation: _holdController,
                                      builder: (context, child) {
                                        return CircularProgressIndicator(
                                          value: _holdController.value,
                                          strokeWidth: 8,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.redAccent),
                                          backgroundColor: Colors.grey.shade200,
                                        );
                                      },
                                    ),
                                  ),
                                  // Button
                                  Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF6F00), // Deep Orange
                                          Color(0xFFD84315), // Red Orange
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF6F00,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: const Color(
                                            0xFFD84315,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 60,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Inner ring
                                        Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.sos_rounded,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                            const Text(
                                              'GỬI NGAY',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Giữ 3 giây để gửi',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6F00), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
