import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report Issue Location")),
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
                  child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
