import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final DocumentSnapshot complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  String _currentStatus = 'pending';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.complaint['status'] ?? 'pending';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaint.id)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() => _currentStatus = newStatus);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_work':
        return Colors.blue;
      case 'fixed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.complaint.data() as Map<String, dynamic>;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint Details'),
        backgroundColor: Color(0xFF91C788),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_currentStatus),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentStatus.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Complaint Details
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complaint Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(data['complaint'] ?? 'No complaint text'),
                    SizedBox(height: 16),
                    Text('User Email: ${data['userEmail'] ?? 'Unknown'}'),
                    SizedBox(height: 8),
                    if (data['latitude'] != null && data['longitude'] != null)
                      Text('Location: ${data['latitude'].toStringAsFixed(4)}, ${data['longitude'].toStringAsFixed(4)}'),
                    SizedBox(height: 8),
                    if (data['createdAt'] != null)
                      Text('Submitted: ${(data['createdAt'] as Timestamp).toDate().toString().split('.')[0]}'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Location Map Section
            if (data['latitude'] != null && data['longitude'] != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complaint Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Container(
                        height: 200,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(data['latitude'], data['longitude']),
                            initialZoom: 16.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                              subdomains: ['0', '1', '2', '3'],
                              userAgentPackageName: 'com.example.fix_my_campus',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(data['latitude'], data['longitude']),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Coordinates: ${data['latitude'].toStringAsFixed(6)}, ${data['longitude'].toStringAsFixed(6)}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Image Section
            if (data['imageUrl'] != null) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complaint Image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: data['imageUrl'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Loading image...'),
                                ],
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.grey[600]),
                                  SizedBox(height: 8),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Action Buttons
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating || _currentStatus == 'under_work' 
                                ? null 
                                : () => _updateStatus('under_work'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isUpdating 
                                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('Mark Under Work'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating || _currentStatus == 'fixed' 
                                ? null 
                                : () => _updateStatus('fixed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: _isUpdating 
                                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('Mark Fixed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}