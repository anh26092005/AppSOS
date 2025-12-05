import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'package:provider/provider.dart';
import '../providers/active_sos_provider.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  State<VolunteerDashboardScreen> createState() =>
      _VolunteerDashboardScreenState();
}

class _VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  GoogleMapController? _mapController;

  // Current location (default fallback to Ho Chi Minh City if GPS fails)
  LatLng _currentLocation = const LatLng(10.8500, 106.6500);
  LatLng? _victimLocation;
  bool _isLocationLoaded = false;
  Set<Marker> _markers = {};
  bool _isReady = false;
  Timer? _locationUpdateTimer; // [NEW] Timer for periodic location updates

  // Check if Google Maps is supported on current platform
  bool _isGoogleMapsSupported = true;

  @override
  void initState() {
    super.initState();
    _checkPlatformSupport();
    _requestLocationPermission();
    _fetchStatus();

    // [NEW] Start periodic location updates every 10 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });

    // Load active case if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveCase();
    });
  }

  Future<void> _loadActiveCase() async {
    final provider = context.read<ActiveSosProvider>();
    if (!provider.hasActiveCase) {
      await provider.loadActiveCaseFromStorage();
    }
    _updateVictimLocation();
  }

  void _updateVictimLocation() {
    final provider = context.read<ActiveSosProvider>();
    if (provider.hasActiveCase) {
      final sosCase = provider.activeSosCase!['case'];
      final coords = sosCase['location']['coordinates'];
      if (coords != null && coords is List && coords.length == 2) {
        setState(() {
          _victimLocation = LatLng(
            coords[1],
            coords[0],
          ); // GeoJSON is [lng, lat]
          _updateMarkers();
        });

        // Fit bounds if map is ready
        if (_mapController != null && _currentLocation != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(_getBounds(), 100.0),
            );
          });
        }
      }
    }
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
      _isGoogleMapsSupported =
          true; // Will be caught by error handling if not supported
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationUpdateTimer?.cancel(); // [NEW] Cancel periodic updates
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
          CameraUpdate.newLatLngBounds(_getBounds(), 100.0),
        );

        // Update location to backend
        final token = FCMService.currentToken;
        if (token != null) {
          ApiService.registerDeviceToken(
                token,
                latitude: position.latitude,
                longitude: position.longitude,
              )
              .then((_) {
                print(
                  '✅ Location updated to backend: ${position.latitude}, ${position.longitude}',
                );
                print(
                  '📍 TNV current location: ${position.latitude}, ${position.longitude}',
                );
              })
              .catchError((e) {
                print('❌ Failed to update location: $e');
              });
        } else {
          print('⚠️ FCM Token is null, cannot update location');
        }
      });
    } catch (e) {
      // If location fails, use default
      setState(() {
        _isLocationLoaded = true;
        _updateMarkers();
      });
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final profile = await ApiService.fetchMyVolunteerProfile();
      if (profile != null && mounted) {
        setState(() {
          _isReady = profile['ready'] ?? false;
        });
      }
    } catch (e) {
      print('Error fetching volunteer status: $e');
    }
  }

  Future<void> _toggleReady(bool value) async {
    // Optimistic update
    setState(() {
      _isReady = value;
    });

    try {
      final res = await ApiService.toggleVolunteerReady();

      // Verify actual status from server response
      if (res['data'] != null && res['data']['ready'] != null) {
        final serverReady = res['data']['ready'];
        if (serverReady != value) {
          // If server mismatch, revert
          setState(() {
            _isReady = serverReady;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không thể thay đổi trạng thái. Server: $serverReady',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value ? 'Đã bật chế độ Sẵn sàng' : 'Đã chuyển sang Tạm nghỉ',
              ),
              backgroundColor: value ? Colors.green : Colors.grey,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isReady = !value;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')));
      }
    }
  }

  LatLngBounds _getBounds() {
    final locations = [_currentLocation];
    if (_victimLocation != null) {
      locations.add(_victimLocation!);
    }

    double? minLat, maxLat, minLng, maxLng;
    for (var loc in locations) {
      minLat = minLat == null
          ? loc.latitude
          : (loc.latitude < minLat ? loc.latitude : minLat);
      maxLat = maxLat == null
          ? loc.latitude
          : (loc.latitude > maxLat ? loc.latitude : maxLat);
      minLng = minLng == null
          ? loc.longitude
          : (loc.longitude < minLng ? loc.longitude : minLng);
      maxLng = maxLng == null
          ? loc.longitude
          : (loc.longitude > maxLng ? loc.longitude : maxLng);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  void _updateMarkers() {
    if (_isGoogleMapsSupported) {
      final provider = context.read<ActiveSosProvider>();
      final hasActiveCase = provider.hasActiveCase;
      final sosCase = hasActiveCase ? provider.activeSosCase!['case'] : null;
      final reporter = sosCase != null ? sosCase['reporterId'] : null;
      final victimName = hasActiveCase
          ? (reporter != null ? reporter['fullName'] : 'Nạn nhân')
          : 'Vị trí ứng cứu';

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
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Vị trí nạn nhân',
              snippet: victimName,
            ),
          ),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveSosProvider>();
    final hasActiveCase = provider.hasActiveCase;
    final sosCase = hasActiveCase ? provider.activeSosCase!['case'] : null;
    final reporter = sosCase != null ? sosCase['reporterId'] : null;

    // Calculate distance
    String distanceDisplay = 'Đang tính...';
    if (hasActiveCase && _victimLocation != null) {
      final distMeters = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        _victimLocation!.latitude,
        _victimLocation!.longitude,
      );
      if (distMeters < 1000) {
        distanceDisplay = '${distMeters.toStringAsFixed(0)}m';
      } else {
        distanceDisplay = '${(distMeters / 1000).toStringAsFixed(1)}km';
      }
    }

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeString =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF8E1), // Light beige
                  Color(0xFFFFECB3), // Slightly deeper beige
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Bar (Time & Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_4_bar,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.battery_full,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Title & Subtitle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tình Nguyện Viên',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD84315), // Deep Orange
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hãy là một tình nguyện viên từ tâm nhé!',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        color: Color(0xFFD84315),
                        size: 28,
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
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    if (_isLocationLoaded && _isGoogleMapsSupported)
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation,
                          zoom: 14.0,
                        ),
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
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
                      )
                    else if (!_isLocationLoaded)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFFF57F17),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đang tải bản đồ...',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildFallbackMap(),

                    // Location Controls
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLocationButton(
                            'Vị trí của bạn',
                            const Color(0xFF1976D2),
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
                            'Cách $distanceDisplay',
                            const Color(0xFF43A047),
                            Icons.directions_run,
                            onTap: () {
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
                            'Nạn nhân',
                            const Color(0xFFD32F2F),
                            Icons.location_on,
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

          // Activity Details Section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoạt động',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _isReady ? 'Sẵn sàng' : 'Tạm nghỉ',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isReady
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _isReady,
                              onChanged: _toggleReady,
                              activeColor: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!hasActiveCase)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Icon(
                              Icons.volunteer_activism,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có nhiệm vụ nào',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vui lòng giữ trạng thái "Sẵn sàng" để nhận thông báo',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.sos,
                                    color: Color(0xFF1976D2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  sosCase['code'] ?? 'SOS-???',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Nạn nhân',
                              reporter != null
                                  ? reporter['fullName'] ?? 'Không tên'
                                  : 'Không tên',
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Thông tin',
                              '${sosCase['emergencyType'] ?? 'KHẨN CẤP'}',
                              Icons.info_outline,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Liên hệ',
                              reporter != null
                                  ? reporter['phone'] ?? 'Không có SĐT'
                                  : 'Không có SĐT',
                              Icons.phone_outlined,
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Nội dung ứng cứu:',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sosCase['description'] ?? 'Không có mô tả',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Note: Backend currently doesn't have verification status, hiding for now or assuming false
                            /*
                            if (false)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFCC80),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFF57F17),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Chưa xác thực CCCD, vui lòng cẩn thận',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: const Color(0xFFE65100),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              */
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Action Button
                    Center(
                      child: GestureDetector(
                        onTap: _handleRescue,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6F00), Color(0xFFD84315)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFD84315,
                                ).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'ỨNG CỨU NGAY',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD84315),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/main');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/account');
            }
          },
          selectedItemColor: const Color(0xFFF57F17),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      color: Colors.grey.shade100,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Chế độ xem bản đồ',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đang mô phỏng vị trí trên Desktop',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Markers simulation
          if (_victimLocation != null)
            Positioned(
              right: 100,
              bottom: 150,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Nạn nhân',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.location_on, color: Colors.red, size: 32),
                ],
              ),
            ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w600,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xác nhận ứng cứu',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn ứng cứu cho trường hợp này không?',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.montserrat(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã gửi yêu cầu ứng cứu thành công!',
                    style: GoogleFonts.montserrat(),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57F17),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
