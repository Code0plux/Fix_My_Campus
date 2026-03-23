import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'Auth/auth_service.dart';
import 'Screen/user_complaints_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;
  final _authService = AuthService();
  final MapController _mapController = MapController();

  // CEG Campus boundary polygon points
  static const List<LatLng> _campusBoundary = [
    LatLng(13.008855634985396, 80.23058935243694),
    LatLng(13.006965703766896, 80.24015896942836),
    LatLng(13.008012179719158, 80.24031504371942),
    LatLng(13.014058425808152, 80.24032725389321),
    LatLng(13.016162111320604, 80.24058046744041),
    LatLng(13.016986872348106, 80.23751258068226),
    LatLng(13.017188193577024, 80.23761104886614),
    LatLng(13.018060793873374, 80.23822045264315),
    LatLng(13.018987686047764, 80.23741497609993),
    LatLng(13.018917308507428, 80.23728923441334),
    LatLng(13.017820054126169, 80.2364096228806),
    LatLng(13.016676519598736, 80.23594569600363),
    LatLng(13.015474767970941, 80.23486212169001),
    LatLng(13.015058678690655, 80.23412800174204),
    LatLng(13.014849888402182, 80.23342740327078),
    LatLng(13.014342043881106, 80.23284531168245),
    LatLng(13.011857368676775, 80.23243268032134),
    LatLng(13.011875050325143, 80.2311357107815),
    LatLng(13.008855634985396, 80.23058935243694),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool _isInsideCampus(LatLng point) {
    int intersections = 0;
    final x = point.longitude;
    final y = point.latitude;
    for (int i = 0; i < _campusBoundary.length - 1; i++) {
      final x1 = _campusBoundary[i].longitude;
      final y1 = _campusBoundary[i].latitude;
      final x2 = _campusBoundary[i + 1].longitude;
      final y2 = _campusBoundary[i + 1].latitude;
      if ((y1 > y) != (y2 > y) && x < (x2 - x1) * (y - y1) / (y2 - y1) + x1) {
        intersections++;
      }
    }
    return intersections % 2 != 0;
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Issue Location"),
        backgroundColor: const Color(0xFF91C788),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserComplaintsScreen(),
                ),
              );
            },
            tooltip: 'My Complaints',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.green.shade100,
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(selectedLocation != null
                      ? 'Location selected. Ready to create complaint.'
                      : 'Tap on map to select location'),
                ),
                ElevatedButton(
                  onPressed: selectedLocation != null
                      ? () {
                          Navigator.pushNamed(
                            context,
                            '/complaint',
                            arguments: selectedLocation,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF91C788),
                  ),
                  child: const Text('Create Complaint',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(13.0109, 80.2337),
                initialZoom: 16,
                maxZoom: 18,
                minZoom: 10,
                onTap: (tapPosition, point) {
                  if (_isInsideCampus(point)) {
                    setState(() {
                      selectedLocation = point;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a location within CEG campus'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.fix_my_campus',
                  maxZoom: 18,
                  minZoom: 1,
                  retinaMode: false,
                  tileProvider: NetworkTileProvider(),
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _campusBoundary,
                      color: const Color(0xFF91C788).withOpacity(0.15),
                      borderColor: const Color(0xFF91C788),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_pin,
                            size: 40, color: Colors.red),
                      ),
                  ],
                ),
                // Blur overlay outside campus boundary
                IgnorePointer(
                  child: LayoutBuilder(
                    builder: (context, constraints) => CustomPaint(
                      painter: _OutsideBlurPainter(
                        boundary: _campusBoundary,
                        mapController: _mapController,
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutsideBlurPainter extends CustomPainter {
  final List<LatLng> boundary;
  final MapController mapController;
  final Size size;

  _OutsideBlurPainter({
    required this.boundary,
    required this.mapController,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final screenPoints = boundary.map((latlng) {
      final point = mapController.camera.latLngToScreenPoint(latlng);
      return Offset(point.x, point.y);
    }).toList();

    final campusPath = ui.Path()..addPolygon(screenPoints, true);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fullPath = ui.Path()..addRect(fullRect);
    final outsidePath = ui.Path.combine(ui.PathOperation.difference, fullPath, campusPath);

    canvas.saveLayer(fullRect, Paint());
    canvas.drawPath(
      outsidePath,
      Paint()..color = Colors.black.withOpacity(0.18),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OutsideBlurPainter old) =>
      old.mapController.camera.zoom != mapController.camera.zoom ||
      old.mapController.camera.center != mapController.camera.center;
}
