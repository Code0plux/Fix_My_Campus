import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FixedComplaintsHistory extends StatelessWidget {
  const FixedComplaintsHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFFDE),
      appBar: AppBar(
        title: const Text('Fixed Complaints History',
            style: TextStyle(color: Color(0xFF52734D), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF91C788),
        iconTheme: const IconThemeData(color: Color(0xFF52734D)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('status', isEqualTo: 'fixed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF52734D)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFF52734D))));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: const Color(0xFF91C788)),
                  const SizedBox(height: 16),
                  const Text('No fixed complaints yet',
                      style: TextStyle(fontSize: 16, color: Color(0xFF52734D))),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDFFBC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF91C788), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['complaint'] ?? 'No complaint text',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF52734D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF52734D),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('FIXED',
                                style: TextStyle(color: Color(0xFFFEFFDE), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (data['imageUrl'] != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                height: 150, color: const Color(0xFF91C788),
                                child: const Center(child: CircularProgressIndicator(color: Color(0xFF52734D)))),
                            errorWidget: (_, __, ___) => Container(
                                height: 150, color: const Color(0xFF91C788),
                                child: const Icon(Icons.image_not_supported, color: Color(0xFF52734D))),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _infoRow(Icons.person, data['userEmail'] ?? 'Unknown user'),
                      const SizedBox(height: 4),
                      _infoRow(Icons.location_on,
                        data['latitude'] != null && data['longitude'] != null
                            ? '${(data['latitude'] as double).toStringAsFixed(4)}, ${(data['longitude'] as double).toStringAsFixed(4)}'
                            : 'Location not available'),
                      const SizedBox(height: 4),
                      _infoRow(Icons.calendar_today,
                        data['createdAt'] != null
                            ? 'Submitted: ${(data['createdAt'] as Timestamp).toDate().toString().split(' ')[0]}'
                            : 'Date not available'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 14, color: const Color(0xFF52734D)),
      const SizedBox(width: 4),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF52734D)))),
    ],
  );
}
