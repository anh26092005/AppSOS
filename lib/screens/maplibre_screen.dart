import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Widget hiển thị bản đồ Flutter Map với các tính năng cơ bản
/// Có thể dùng thay thế GoogleMap trong ứng dụng SOS
class MapLibreScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? title;

  const MapLibreScreen({
    Key? key,
    this.initialLat,
    this.initialLng,
    this.title = 'Bản đồ',
  }) : super(key: key);

  @override
  State<MapLibreScreen> createState() => _MapLibreScreenState();
}

class _MapLibreScreenState extends State<MapLibreScreen> {
  final MapController mapController = MapController();
  Position? currentPosition;
  List<Marker> markers = [];
  List<CircleMarker> circles = [];

  // Tọa độ mặc định (TP.HCM)
  static const double defaultLat = 10.762622;
  static const double defaultLng = 106.660172;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });

      // Di chuyển camera đến vị trí hiện tại
      mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );

      // Thêm marker tại vị trí hiện tại
      _addMarker(
        LatLng(position.latitude, position.longitude),
        label: 'Vị trí của bạn',
      );
    } catch (e) {
      print('Lỗi khi lấy vị trí: $e');
    }
  }

  /// Thêm marker tại vị trí được chỉ định
  void _addMarker(LatLng position, {String? label}) {
    setState(() {
      markers = [
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
              if (label != null)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ];
    });
  }

  /// Thêm vòng tròn bao quanh vị trí (radius tính bằng meters)
  void _addCircle(LatLng position, double radiusMeters) {
    setState(() {
      circles.add(
        CircleMarker(
          point: position,
          radius: radiusMeters,
          useRadiusInMeter: true,
          color: Colors.red.withOpacity(0.3),
          borderColor: Colors.red,
          borderStrokeWidth: 2,
        ),
      );
    });
  }

  /// Di chuyển camera đến vị trí cụ thể
  void _moveToLocation(double lat, double lng, {double zoom = 15.0}) {
    mapController.move(LatLng(lat, lng), zoom);
  }

  @override
  Widget build(BuildContext context) {
    // Xác định vị trí ban đầu
    final lat = widget.initialLat ??
                currentPosition?.latitude ??
                defaultLat;
    final lng = widget.initialLng ??
                currentPosition?.longitude ??
                defaultLng;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Bản đồ'),
        actions: [
          // Nút làm mới vị trí
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: 'Vị trí hiện tại',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Bản đồ Flutter Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 14.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                print('Clicked at: ${point.latitude}, ${point.longitude}');
                _addMarker(point, label: 'Vị trí được chọn');
              },
              onLongPress: (tapPosition, point) {
                _addMarker(point, label: 'Vị trí SOS');
                _addCircle(point, 500); // Vòng tròn bán kính 500m
              },
            ),
            children: [
              // Tile layer - OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_application_1',
                maxZoom: 19,
              ),
              // Circle layer
              CircleLayer(circles: circles),
              // Marker layer
              MarkerLayer(markers: markers),
            ],
          ),

          // Panel thông tin ở dưới cùng
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hướng dẫn:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Nhấn vào bản đồ để thêm marker'),
                    Text('• Giữ lâu để thêm marker + vòng tròn'),
                    Text('• Nhấn nút 📍 để về vị trí hiện tại'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Các nút floating action
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Nút zoom in
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                currentZoom + 1,
              );
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          // Nút zoom out
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final currentZoom = mapController.camera.zoom;
              mapController.move(
                mapController.camera.center,
                currentZoom - 1,
              );
            },
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}

