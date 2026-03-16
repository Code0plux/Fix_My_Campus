import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'complaint_detail_screen.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => _AdminMapViewState();
}

class _AdminMapViewState extends State<AdminMapView> {
  List<DocumentSnapshot> complaints = [];
  List<ComplaintCluster> clusters = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .get();
      
      setState(() {
        complaints = snapshot.docs;
        clusters = _createClusters(complaints);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading complaints: $e');
      setState(() => isLoading = false);
    }
  }

  List<ComplaintCluster> _createClusters(List<DocumentSnapshot> complaints) {
    List<ComplaintCluster> clusters = [];
    const double clusterRadius = 0.001; // ~100 meters

    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      double lat = data['latitude'];
      double lng = data['longitude'];
      
      // Find existing cluster within radius
      ComplaintCluster? nearbyCluster;
      for (var cluster in clusters) {
        double distance = _calculateDistance(lat, lng, cluster.latitude, cluster.longitude);
        if (distance <= clusterRadius) {
          nearbyCluster = cluster;
          break;
        }
      }
      
      if (nearbyCluster != null) {
        // Add to existing cluster
        nearbyCluster.complaints.add(complaint);
      } else {
        // Create new cluster
        clusters.add(ComplaintCluster(
          latitude: lat,
          longitude: lng,
          complaints: [complaint],
        ));
      }
    }
    
    return clusters;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Distance().as(LengthUnit.Kilometer, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }

  Color _getClusterColor(List<DocumentSnapshot> complaints) {
    int pendingCount = 0;
    int underWorkCount = 0;
    int fixedCount = 0;
    
    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      String status = data['status'] ?? 'pending';
      
      switch (status) {
        case 'pending':
          pendingCount++;
          break;
        case 'under_work':
          underWorkCount++;
          break;
        case 'fixed':
          fixedCount++;
          break;
      }
    }
    
    // Priority: pending > under_work > fixed
    if (pendingCount > 0) return Colors.red;
    if (underWorkCount > 0) return Colors.orange;
    return Colors.green;
  }

  void _showClusterDialog(ComplaintCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cluster.complaints.length} Complaint(s) at this location'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cluster.complaints.length,
            itemBuilder: (context, index) {
              var complaint = cluster.complaints[index];
              var data = complaint.data() as Map<String, dynamic>;
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, size: 20),
                            ),
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.description, size: 20),
                        ),
                  title: Text(
                    data['complaint'] ?? 'No complaint text',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Status: ${data['status'] ?? 'pending'}'),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(data['status'] ?? 'pending'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (data['status'] ?? 'pending').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailScreen(complaint: complaint),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints Map'),
        backgroundColor: Color(0xFF91C788),
        actions: [
            IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadComplaints();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No complaints with location found'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Legend
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem('Pending', Colors.red),
                          _buildLegendItem('Under Work', Colors.orange),
                          _buildLegendItem('Fixed', Colors.green),
                        ],
                      ),
                    ),
                    // Map
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: clusters.isNotEmpty
                              ? LatLng(clusters.first.latitude, clusters.first.longitude)
                              : LatLng(13.0109, 80.2337),
                          initialZoom: 13.0,
                          maxZoom: 18,
                          minZoom: 10,
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
                          MarkerLayer(
                            markers: clusters.map((cluster) {
                              return Marker(
                                point: LatLng(cluster.latitude, cluster.longitude),
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () => _showClusterDialog(cluster),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getClusterColor(cluster.complaints),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cluster.complaints.length}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class ComplaintCluster {
  final double latitude;
  final double longitude;
  final List<DocumentSnapshot> complaints;

  ComplaintCluster({
    required this.latitude,
    required this.longitude,
    required this.complaints,
  });
}