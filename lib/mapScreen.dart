import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'Auth/auth_service.dart';

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

  void _showComplaintDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFFFEFFDE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create Complaint',
              style: TextStyle(color: Color(0xFF52734D), fontWeight: FontWeight.bold)),
          content: const Text('Do you want to create a complaint for this location?',
              style: TextStyle(color: Color(0xFF52734D))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF52734D))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF91C788),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/complaint', arguments: selectedLocation);
              },
              child: const Text('Create Complaint'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Report Issue Location",
          style: TextStyle(color: Color(0xFF52734D), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFEFFDE),
        iconTheme: const IconThemeData(color: Color(0xFF52734D)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black,
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Color(0xFF91C788)),
                SizedBox(width: 8),
                Text('Tap on the map to select a location within CEG campus',
                    style: TextStyle(color: Color(0xFF91C788), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(13.0109, 80.2337),
                    initialZoom: 16,
                    minZoom: 15,
                    maxZoom: 18,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: LatLngBounds(
                        const LatLng(13.0060, 80.2300),
                        const LatLng(13.0195, 80.2410),
                      ),
                    ),
                    onTap: (tapPosition, point) {
                      if (_isInsideCampus(point)) {
                        setState(() => selectedLocation = point);
                        _showComplaintDialog();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a location within CEG campus'),
                            backgroundColor: Color(0xFF52734D),
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
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _campusBoundary,
                          color: const Color(0xFF91C788).withOpacity(0.15),
                          borderColor: const Color(0xFF52734D),
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
                            child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                          ),
                        ],
                      ),
                  ],
                ),
                // Blur overlay outside campus boundary
                IgnorePointer(
                  child: CustomPaint(
                    painter: _OutsideBlurPainter(
                      boundary: _campusBoundary,
                      mapController: _mapController,
                    ),
                    size: Size.infinite,
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

  _OutsideBlurPainter({required this.boundary, required this.mapController});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final campusPath = ui.Path();
    for (int i = 0; i < boundary.length; i++) {
      final point = mapController.camera.latLngToScreenPoint(boundary[i]);
      if (i == 0) {
        campusPath.moveTo(point.x, point.y);
      } else {
        campusPath.lineTo(point.x, point.y);
      }
    }
    campusPath.close();

    final outsidePath = ui.Path.combine(ui.PathOperation.difference, path, campusPath);

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

    canvas.drawPath(outsidePath, paint);
  }

  @override
  bool shouldRepaint(_OutsideBlurPainter oldDelegate) => true;
}
