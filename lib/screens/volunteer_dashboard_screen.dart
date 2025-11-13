import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() => _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  GoogleMapController? _mapController;
  
  // Sample SOS incident data
  final Map<String, dynamic> _currentIncident = {
    'id': 'SOS-303',
    'victimName': 'Nguyễn Bị Bé Năm',
    'gender': 'Nữ',
    'birthYear': 1999,
    'personalPhone': '0993824773',
    'relativePhone': '0923652374',
    'rescueContent': 'Tôi Gặp Tai nạn tại jhsgdshjadgsadg',
    'isVerified': false,
    'distance': '1.2Km',
    // Sample coordinates for Ho Chi Minh City (District 12 - Tô Ký area)
    'victimLat': 10.8500,
    'victimLng': 106.6500,
  };

  // Current location (default to Ho Chi Minh City)
  LatLng _currentLocation = const LatLng(10.8500, 106.6500);
  LatLng? _victimLocation;
  bool _isLocationLoaded = false;
  Set<Marker> _markers = {};
  
  // Check if Google Maps is supported on current platform
  // Google Maps Flutter only supports Android, iOS, and Web
  // For desktop (Windows/Linux/macOS), we show fallback map
  bool _isGoogleMapsSupported = true; // Will be set in initState

  @override
  void initState() {
    super.initState();
    _victimLocation = LatLng(
      _currentIncident['victimLat'] as double,
      _currentIncident['victimLng'] as double,
    );
    // Check platform support for Google Maps
    _checkPlatformSupport();
    _requestLocationPermission();
  }

  void _checkPlatformSupport() {
    // Google Maps only works on Android, iOS, and Web
    // For desktop platforms, we'll use fallback
    if (kIsWeb) {
      _isGoogleMapsSupported = true;
    } else {
      // Try to detect if we're on desktop
      // Since dart:io doesn't work on web, we'll use a different approach
      // For now, assume mobile platforms support it, desktop will show error/fallback
      _isGoogleMapsSupported = true; // Will be caught by error handling if not supported
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else {
      // Use default location if permission denied
      setState(() {
        _isLocationLoaded = true;
        _updateMarkers();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoaded = true;
        _updateMarkers();
        // Move camera to show both locations
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBounds(),
            100.0,
          ),
        );
      });
    } catch (e) {
      // If location fails, use default
      setState(() {
        _isLocationLoaded = true;
        _updateMarkers();
      });
    }
  }

  LatLngBounds _getBounds() {
    final locations = [_currentLocation];
    if (_victimLocation != null) {
      locations.add(_victimLocation!);
    }
    
    double? minLat, maxLat, minLng, maxLng;
    for (var loc in locations) {
      minLat = minLat == null ? loc.latitude : (loc.latitude < minLat ? loc.latitude : minLat);
      maxLat = maxLat == null ? loc.latitude : (loc.latitude > maxLat ? loc.latitude : maxLat);
      minLng = minLng == null ? loc.longitude : (loc.longitude < minLng ? loc.longitude : minLng);
      maxLng = maxLng == null ? loc.longitude : (loc.longitude > maxLng ? loc.longitude : maxLng);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _updateMarkers() {
    if (_isGoogleMapsSupported) {
      _markers = {
        // Current location marker (blue)
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Vị trí hiện tại',
            snippet: 'Vị trí của bạn',
          ),
        ),
        // Victim location marker (red)
        if (_victimLocation != null)
          Marker(
            markerId: const MarkerId('victim_location'),
            position: _victimLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Vị trí nạn nhân',
              snippet: _currentIncident['victimName'],
            ),
          ),
      };
    }
  }

  Widget _buildFallbackMap() {
    return Container(
      color: Colors.grey.shade200,
      child: Stack(
        children: [
          // Map placeholder with markers
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bản đồ (Chỉ hỗ trợ Android/iOS/Web)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng chạy trên thiết bị di động',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Current location indicator
          Positioned(
            left: MediaQuery.of(context).size.width * 0.3,
            top: MediaQuery.of(context).size.height * 0.2,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Vị trí hiện tại',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Victim location indicator
          if (_victimLocation != null)
            Positioned(
              right: MediaQuery.of(context).size.width * 0.3,
              bottom: MediaQuery.of(context).size.height * 0.2,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentIncident['victimName'] ?? 'Nạn nhân',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Time display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.signal_cellular_4_bar, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Icon(Icons.battery_full, size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Row(
                    children: [
                      Text(
                        'Tình Nguyện Viên',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2), // Blue
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hãy là một tình nguyện viên từ tâm nhé!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Map Section
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Google Map (only for Android, iOS, and Web)
                      if (_isLocationLoaded && _isGoogleMapsSupported)
                        Builder(
                          builder: (context) {
                            try {
                              return GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _currentLocation,
                                  zoom: 14.0,
                                ),
                                onMapCreated: (GoogleMapController controller) {
                                  _mapController = controller;
                                  // Adjust camera to show both locations
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (_victimLocation != null) {
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngBounds(
                                          _getBounds(),
                                          100.0,
                                        ),
                                      );
                                    }
                                  });
                                },
                                markers: _markers,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                mapType: MapType.normal,
                                zoomControlsEnabled: false,
                                compassEnabled: true,
                              );
                            } catch (e) {
                              // If Google Maps is not supported (e.g., on desktop)
                              return _buildFallbackMap();
                            }
                          },
                        )
                      else if (!_isLocationLoaded)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Đang tải bản đồ...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Fallback map for Windows/Linux/Mac desktop
                        _buildFallbackMap(),
                      // Location buttons overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLocationButton(
                              'Vị trí hiện tại',
                              Colors.blue,
                              Icons.my_location,
                              onTap: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: _currentLocation,
                                      zoom: 15.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildLocationButton(
                              'Cách bạn ${_currentIncident['distance']}',
                              Colors.green,
                              Icons.location_on,
                              onTap: () {
                                // Show both locations
                                if (_victimLocation != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngBounds(
                                      _getBounds(),
                                      100.0,
                                    ),
                                  );
                                }
                              },
                            ),
                            _buildLocationButton(
                              'Vị trí nạn nhân',
                              Colors.red,
                              Icons.location_searching,
                              onTap: () {
                                if (_victimLocation != null) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: _victimLocation!,
                                        zoom: 15.0,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Activity Details Section
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity Header
                      const Text(
                        'Hoạt động',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Incident Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SOS Code
                            Text(
                              _currentIncident['id'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Victim Info
                            _buildInfoRow('Họ và tên Nạn nhân:', _currentIncident['victimName']),
                            const SizedBox(height: 8),
                            _buildInfoRow('Giới tính:', _currentIncident['gender']),
                            const SizedBox(height: 8),
                            _buildInfoRow('Năm sinh:', _currentIncident['birthYear'].toString()),
                            const SizedBox(height: 8),
                            _buildInfoRow('SĐT cá nhân:', _currentIncident['personalPhone']),
                            const SizedBox(height: 8),
                            _buildInfoRow('SĐT người thân:', _currentIncident['relativePhone']),
                            const SizedBox(height: 12),
                            // Rescue Content
                            const Text(
                              'Nội dung ứng cứu:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentIncident['rescueContent'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Verification Warning
                            if (!_currentIncident['isVerified'])
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Chưa xác thực CCCD, TNV nên cẩn thận',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Swipe Instructions
                      Center(
                        child: Text(
                          'Kéo sang phải để ứng cứu, kéo sang trái để bỏ qua',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Rescue Button
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange,
                              width: 3,
                            ),
                            color: Colors.white,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _handleRescue();
                              },
                              borderRadius: BorderRadius.circular(60),
                              child: const Center(
                                child: Text(
                                  'Ứng Cứu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar (similar to main screen)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: 1, // Volunteer screen is active
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/main');
              } else if (index == 2) {
                Navigator.pushNamed(context, '/account');
              }
            },
            selectedItemColor: const Color(0xFF1976D2),
            unselectedItemColor: Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade600,
              Colors.red.shade800,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/sos-emergency');
            },
            borderRadius: BorderRadius.circular(35),
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
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildLocationButton(
    String label,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _handleRescue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận ứng cứu'),
        content: const Text('Bạn có chắc chắn muốn ứng cứu cho trường hợp này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã gửi yêu cầu ứng cứu thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              // TODO: Navigate to rescue details or update status
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

