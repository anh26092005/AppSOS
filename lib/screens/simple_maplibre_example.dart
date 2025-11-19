import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ví dụ đơn giản nhất về cách sử dụng Flutter Map với MapLibre tiles
/// Chỉ hiển thị bản đồ cơ bản
class SimpleMapLibreExample extends StatefulWidget {
  const SimpleMapLibreExample({Key? key}) : super(key: key);

  @override
  State<SimpleMapLibreExample> createState() => _SimpleMapLibreExampleState();
}

class _SimpleMapLibreExampleState extends State<SimpleMapLibreExample> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Map - Ví dụ đơn giản'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          // Vị trí ban đầu: TP.HCM
          initialCenter: LatLng(10.762622, 106.660172),
          initialZoom: 14.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          // Tile layer - sử dụng OpenStreetMap tiles miễn phí
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_application_1',
            maxZoom: 19,
          ),
          // Có thể thêm các layer khác ở đây
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

