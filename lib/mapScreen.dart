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

  void _showComplaintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Complaint'),
        content: Text('Do you want to create a complaint for this location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/complaint',
                arguments: selectedLocation,
              );
            },
            child: Text('Create Complaint'),
          ),
        ],
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
        title: Text("Report Issue Location"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(13.0109, 80.2337),
          initialZoom: 16,
          onTap: (tapPosition, point) {
            setState(() {
              selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
            userAgentPackageName: 'com.example.fix_my_campus',
          ),
          if (selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: selectedLocation!,
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: _showComplaintDialog,
                    child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
