import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/services/auth_service.dart';
import '../../../Screen/complaint_detail_screen.dart';
import '../../../Screen/admin_map_view.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  
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
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF91C788),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMapView(),
                ),
              );
            },
            tooltip: 'View Complaints on Map',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No complaints yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var complaint = snapshot.data!.docs[index];
              var data = complaint.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    print('Complaint tapped: ${complaint.id}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailScreen(complaint: complaint),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image/Icon
                        data['imageUrl'] != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: data['imageUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.description, color: Colors.grey[600], size: 30),
                              ),
                        
                        SizedBox(width: 12),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['complaint'] ?? 'No complaint text',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text('Email: ${data['userEmail'] ?? 'Unknown'}', style: TextStyle(fontSize: 12)),
                              SizedBox(height: 2),
                              if (data['latitude'] != null && data['longitude'] != null)
                                Text(
                                  'Location: ${data['latitude']?.toStringAsFixed(4)}, ${data['longitude']?.toStringAsFixed(4)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              SizedBox(height: 4),
                              if (data['createdAt'] != null)
                                Text(
                                  'Submitted: ${(data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        
                        // Status and Arrow
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status'] ?? 'pending'),
                                borderRadius: BorderRadius.circular(16),
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
                            SizedBox(height: 8),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminMapView(),
            ),
          );
        },
        icon: Icon(Icons.map),
        label: Text('View Map'),
        backgroundColor: Color(0xFF91C788),
      ),
    );
  }
}