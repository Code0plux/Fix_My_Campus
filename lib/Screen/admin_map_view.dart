import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    List<ComplaintCluster> clusters = [];
    const double clusterRadius = 0.001;

    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      double lat = data['latitude'];
      double lng = data['longitude'];
      ComplaintCluster? nearbyCluster;
      for (var cluster in clusters) {
        double distance = _calculateDistance(lat, lng, cluster.latitude, cluster.longitude);
        if (distance <= clusterRadius) {
          nearbyCluster = cluster;
          break;
        }
      }
      if (nearbyCluster != null) {
        nearbyCluster.complaints.add(complaint);
      } else {
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
    return Distance().as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
  }

  String _getClusterStatus(List<DocumentSnapshot> complaints) {
    for (var complaint in complaints) {
      var data = complaint.data() as Map<String, dynamic>;
      if ((data['status'] ?? 'pending') == 'pending') return 'pending';
    }
    return 'under_work';
  }

  void _showClusterDialog(ComplaintCluster cluster) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFEFFDE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF91C788), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFDE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Text(
                  '${cluster.complaints.length} Complaint(s) here',
                  style: const TextStyle(color: Color(0xFF52734D), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              // List
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
                          color: const Color(0xFFFEFFDE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF91C788), width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          leading: data['imageUrl'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: data['imageUrl'],
                                    width: 40, height: 40, fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(width: 40, height: 40, color: const Color(0xFF91C788)),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 40, height: 40, color: const Color(0xFF91C788),
                                      child: const Icon(Icons.image_not_supported, size: 18, color: Color(0xFF52734D))),
                                  ),
                                )
                              : Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: const Color(0xFF91C788), borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.description, size: 20, color: Color(0xFF52734D)),
                                ),
                          title: Text(
                            data['complaint'] ?? 'No complaint text',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF52734D), fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text('Status: $status',
                            style: const TextStyle(color: Color(0xFF52734D), fontSize: 11)),
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
              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFDE),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFEFFDE),
                      backgroundColor: const Color(0xFF52734D),
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
        return const Color(0xFFE53935);
      case 'under_work':
        return const Color(0xFFFB8C00);
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
        title: const Text('Complaints Map'),
        backgroundColor: const Color(0xFF91C788),
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
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No active complaints found'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Legend
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(children: [
                            const SizedBox(width: 44, height: 44, child: _PendingMarker()),
                            const SizedBox(width: 8),
                            const Text('Pending', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                          ]),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          Row(children: [
                            const SizedBox(width: 44, height: 44, child: _UnderWorkMarker()),
                            const SizedBox(width: 8),
                            const Text('Under Work', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFB8C00))),
                          ]),
                        ],
                      ),
                    ),
                    // Map
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
                              final status = _getClusterStatus(cluster.complaints);
                              return Marker(
                                point: LatLng(cluster.latitude, cluster.longitude),
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () => _showClusterDialog(cluster),
                                  child: status == 'pending'
                                      ? const _PendingMarker()
                                      : const _UnderWorkMarker(),
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

// Pending marker — dot with triangle projecting outward + fill animation
class _PendingMarker extends StatefulWidget {
  const _PendingMarker();
  @override
  State<_PendingMarker> createState() => _PendingMarkerState();
}

class _PendingMarkerState extends State<_PendingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _PendingPainter(_controller.value),
      ),
    );
  }
}

class _PendingPainter extends CustomPainter {
  final double progress;
  _PendingPainter(this.progress);

  static const _pi = 3.14159265358979;

  double _cos(double x) {
    x = x % (2 * _pi);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;

    // --- Solid triangle with fill animation ---
    final fillLevel = 0.5 - 0.5 * _cos(progress * 2 * _pi);
    final triH = cy - 10;
    final triW = size.width * 0.65;
    final top = cy - triH - 10;
    final left = cx - triW / 2;
    final right = cx + triW / 2;

    final solidTri = Path()
      ..moveTo(cx, top)
      ..lineTo(right, cy - 12)
      ..lineTo(left, cy - 12)
      ..close();

    canvas.save();
    canvas.clipPath(solidTri);
    final fillY = (cy - 12) - ((cy - 12) * 2 * fillLevel);
    canvas.drawRect(
      Rect.fromLTRB(0, fillY, size.width, cy),
      Paint()..color = const Color(0xFFE53935),
    );
    canvas.restore();

    canvas.drawPath(
      solidTri,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '!',
        style: TextStyle(
          color: fillLevel > 0.4 ? Colors.white : const Color(0xFFE53935),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, top + triH * 0.45));

    // --- Pin dot ---
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(Offset(cx, cy), 5,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_PendingPainter old) => old.progress != progress;
}

// Under Work marker — dot with circle projecting outward + spinning arc
class _UnderWorkMarker extends StatefulWidget {
  const _UnderWorkMarker();
  @override
  State<_UnderWorkMarker> createState() => _UnderWorkMarkerState();
}

class _UnderWorkMarkerState extends State<_UnderWorkMarker>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _UnderWorkPainter(_controller.value),
      ),
    );
  }
}

class _UnderWorkPainter extends CustomPainter {
  final double progress;
  _UnderWorkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 4;
    final maxR = size.width / 3;
    final circleCenter = Offset(cx, cy - maxR - 12);

    // --- Solid circle ---
    canvas.drawCircle(circleCenter, maxR, Paint()..color = const Color(0xFFFB8C00));

    // --- Spinning grey arc - thicker, outside circle ---
    canvas.drawArc(
      Rect.fromCircle(center: circleCenter, radius: maxR + 5),
      progress * 6.28318 * 2,
      4.5,
      false,
      Paint()
        ..color = const Color(0xFF424242)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // White border
    canvas.drawCircle(circleCenter, maxR,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

    // Grey wrench icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.build.codePoint),
        style: TextStyle(
          fontSize: maxR * 1.1,
          fontFamily: Icons.build.fontFamily,
          package: Icons.build.fontPackage,
          color: const Color(0xFF757575),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(circleCenter.dx - iconPainter.width / 2, circleCenter.dy - iconPainter.height / 2));

    // --- Pin dot ---
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = const Color(0xFFFB8C00));
    canvas.drawCircle(Offset(cx, cy), 5,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_UnderWorkPainter old) => old.progress != progress;
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
