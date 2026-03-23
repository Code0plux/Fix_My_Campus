import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../auth/services/auth_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;
  final _authService = AuthService();
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {}); 
      }
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Issue Location"),
        backgroundColor: Color(0xFF91C788),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.green.shade100,
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(selectedLocation != null 
                    ? 'Location selected. Ready to create complaint.' 
                    : 'Tap on map to select location'),
                ),
                ElevatedButton(
                  onPressed: selectedLocation != null ? () {
                    Navigator.pushNamed(
                      context,
                      '/complaint',
                      arguments: selectedLocation,
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF91C788),
                  ),
                  child: Text('Create Complaint', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(13.0109, 80.2337),
                initialZoom: 16,
                maxZoom: 18,
                minZoom: 10,
                onTap: (tapPosition, point) {
                  print('Map tapped at: $point');
                  setState(() {
                    selectedLocation = point;
                  });
                  print('Selected location set to: $selectedLocation');
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
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 80,
                        height: 80,
                        child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}