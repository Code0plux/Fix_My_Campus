import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_colors.dart';
import 'complaint_detail_screen.dart';
import 'fixed_complaints_history.dart';

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
          .where('status', isNotEqualTo: 'fixed')
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
    const double clusterRadiusMeters = 10;
    List<ComplaintCluster> clusters = [];
    List<bool> assigned = List.filled(complaints.length, false);
    
    for (int i = 0; i < complaints.length; i++) {
      if (assigned[i]) continue;
      
      var data = complaints[i].data() as Map<String, dynamic>;
      double lat = data['latitude'];
      double lng = data['longitude'];
      
      List<DocumentSnapshot> clusterComplaints = [complaints[i]];
      assigned[i] = true;
      
      for (int j = i + 1; j < complaints.length; j++) {
        if (assigned[j]) continue;
        
        var otherData = complaints[j].data() as Map<String, dynamic>;
        double otherLat = otherData['latitude'];
        double otherLng = otherData['longitude'];
        
        double distance = _calculateDistance(lat, lng, otherLat, otherLng);
        if (distance <= clusterRadiusMeters) {
          clusterComplaints.add(complaints[j]);
          assigned[j] = true;
        }
      }
      
      clusters.add(ComplaintCluster(
        latitude: lat,
        longitude: lng,
        complaints: clusterComplaints,
      ));
    }
    
    return clusters;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Distance().as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }

  String _getClusterStatus(List<DocumentSnapshot> complaints) {
    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      if ((data['status'] ?? 'pending') == 'pending') return 'pending';
    }
    return 'under_work';
  }

  String _getHighestPriority(List<DocumentSnapshot> complaints) {
    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      if ((data['priority'] ?? 'low') == 'high') return 'high';
    }
    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      if ((data['priority'] ?? 'low') == 'medium') return 'medium';
    }
    return 'low';
  }

  void _showClusterDialog(ComplaintCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Text(
                  '${cluster.complaints.length} Complaint(s) here',
                  style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: cluster.complaints.length,
                  itemBuilder: (context, index) {
                    var complaint = cluster.complaints[index];
                    var data = complaint.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final priority = data['priority'] ?? 'low';
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ComplaintDetailScreen(complaint: complaint),
                        ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          leading: data['imageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: data['imageUrl'],
                                    width: 40, height: 40, fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(width: 40, height: 40, color: AppColors.primary),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 40, height: 40, color: AppColors.primary,
                                      child: const Icon(Icons.image_not_supported, size: 18, color: AppColors.dark)),
                                  ),
                                )
                              : Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.description, size: 20, color: AppColors.dark),
                                ),
                          title: Text(
                            data['complaint'] ?? 'No complaint text',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.dark, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text('Status: $status | Priority: ${priority.toUpperCase()}',
                            style: const TextStyle(color: AppColors.dark, fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.background,
                      backgroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'under_work':
        return AppColors.statusUnderWork;
      case 'fixed':
        return AppColors.statusFixed;
      default:
        return AppColors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints Map'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixedComplaintsHistory(),
                ),
              );
            },
            tooltip: 'View Fixed Complaints History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadComplaints();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: AppColors.grey),
                      const SizedBox(height: 16),
                      const Text('No active complaints found'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority Levels:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.priorityHigh,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('High', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                              Row(children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.priorityMedium,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Medium', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                              Row(children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: AppColors.priorityLow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('Low', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: clusters.isNotEmpty
                              ? LatLng(clusters.first.latitude, clusters.first.longitude)
                              : const LatLng(13.0109, 80.2337),
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
                              final priority = _getHighestPriority(cluster.complaints);
                              return Marker(
                                point: LatLng(cluster.latitude, cluster.longitude),
                                width: 50,
                                height: 60,
                                child: GestureDetector(
                                  onTap: () => _showClusterDialog(cluster),
                                  child: PriorityMarker(
                                    priority: priority,
                                    count: cluster.complaints.length,
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
}

class PriorityMarker extends StatelessWidget {
  final String priority;
  final int count;

  const PriorityMarker({
    required this.priority,
    required this.count,
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
        return AppColors.priorityLow;
      default:
        return AppColors.grey;
    }
  }

  IconData _getComplaintIcon() {
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();
    final icon = _getComplaintIcon();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 16,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        if (count > 1)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
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
