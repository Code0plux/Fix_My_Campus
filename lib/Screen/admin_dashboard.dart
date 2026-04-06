import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Auth/auth_service.dart';
import '../core/constants/app_colors.dart';
import 'complaint_detail_screen.dart';
import 'admin_map_view.dart';
import 'fixed_complaints_history.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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

  int _getPrioritySortValue(String priority) {
    switch (priority) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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

          final complaints = snapshot.data!.docs;
          final activeComplaints = complaints.where((c) {
            final data = c.data() as Map<String, dynamic>;
            return (data['status'] ?? 'pending') != 'fixed';
          }).toList();
          
          activeComplaints.sort((a, b) {
            final priorityA = _getPrioritySortValue(
                (a.data() as Map<String, dynamic>)['priority'] ?? 'low');
            final priorityB = _getPrioritySortValue(
                (b.data() as Map<String, dynamic>)['priority'] ?? 'low');
            return priorityB.compareTo(priorityA);
          });
          
          if (activeComplaints.isEmpty) {
            return const Center(
              child: Text('No active complaints'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeComplaints.length,
            itemBuilder: (context, index) {
              var complaint = activeComplaints[index];
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
                        builder: (context) =>
                            ComplaintDetailScreen(complaint: complaint),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
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
                                    color: AppColors.greyLight,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.greyLight,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.greyLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.description,
                                    color: AppColors.grey, size: 30),
                              ),
                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['complaint'] ?? 'No complaint text',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text('Email: ${data['userEmail'] ?? 'Unknown'}',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              if (data['latitude'] != null &&
                                  data['longitude'] != null)
                                Text(
                                  'Location: ${data['latitude']?.toStringAsFixed(4)}, ${data['longitude']?.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.grey),
                                ),
                              const SizedBox(height: 4),
                              if (data['createdAt'] != null)
                                Text(
                                  'Submitted: ${(data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.grey),
                                ),
                            ],
                          ),
                        ),

                        // Status and Priority
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(
                                    data['priority'] ?? 'low'),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (data['priority'] ?? 'low').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status'] ?? 'pending'),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                (data['status'] ?? 'pending').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: AppColors.grey),
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixedComplaintsHistory(),
                ),
              );
            },
            heroTag: 'history',
            tooltip: 'Fixed Complaints History',
            backgroundColor: AppColors.statusFixed,
            child: const Icon(Icons.history),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminMapView(),
                ),
              );
            },
            heroTag: 'map',
            icon: const Icon(Icons.map),
            label: const Text('View Map'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
