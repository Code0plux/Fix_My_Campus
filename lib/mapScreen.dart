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
    print('Dialog button pressed');
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
                  child: Text('Create Complaint'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(13.0109, 80.2337),
                initialZoom: 16,
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
                  errorTileCallback: (tile, error, stackTrace) {
                    print('Map tile error: $error');
                  },
                  fallbackUrl: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
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
      )
    //   floatingActionButton: selectedLocation != null
    //       ? FloatingActionButton.extended(
    //           onPressed: () {
    //             print('FAB pressed');
    //             Navigator.pushNamed(
    //               context,
    //               '/complaint',
    //               arguments: selectedLocation,
    //             );
    //           },
    //           // icon: Icon(Icons.add_comment),
    //           // label: Text('Create Complaint'),
    //           // backgroundColor: Colors.green,
    //         )
    //       : null,
     );
  }
}
