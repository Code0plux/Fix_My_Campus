import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:fix_my_campus/supabase_config.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

class ComplaintRegister extends StatefulWidget {
  const ComplaintRegister({super.key});

  @override
  State<ComplaintRegister> createState() => _ComplaintRegisterState();
}

class _ComplaintRegisterState extends State<ComplaintRegister> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final _complaintController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  String _detectPriority(String complaint) {
    final text = complaint.toLowerCase();
    
    // High priority keywords
    final highPriorityKeywords = [
      'broken', 'damaged', 'dangerous', 'safety', 'injury', 'accident',
      'fire', 'electrical', 'gas leak', 'water leak', 'flooding', 'collapse',
      'urgent', 'emergency', 'critical', 'severe', 'serious', 'hazard',
      'blocked', 'stuck', 'trapped', 'broken glass', 'sharp', 'bleeding'
    ];
    
    // Medium priority keywords
    final mediumPriorityKeywords = [
      'broken light', 'broken door', 'broken window', 'crack', 'hole',
      'dirty', 'messy', 'stain', 'paint', 'repair', 'fix', 'maintenance',
      'issue', 'problem', 'not working', 'malfunction', 'faulty'
    ];

    // Check for high priority
    for (var keyword in highPriorityKeywords) {
      if (text.contains(keyword)) {
        return 'high';
      }
    }

    // Check for medium priority
    for (var keyword in mediumPriorityKeywords) {
      if (text.contains(keyword)) {
        return 'medium';
      }
    }

    // Default to low priority
    return 'low';
  }

  Future<void> _testSupabaseConnection() async {
    try {
      print('Testing Supabase connection...');
      final buckets = await SupabaseConfig.client.storage.listBuckets();
      print('Buckets found: ${buckets.map((b) => b.name).toList()}');
      final ourBucket = buckets.where((b) => b.name == 'fix_my_campus').firstOrNull;
      if (ourBucket != null) {
        print('fix_my_campus bucket found: ${ourBucket.public}');
      } else {
        print('ERROR: fix_my_campus bucket not found!');
      }
    } catch (e) {
      print('Supabase connection test failed: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<Uint8List> _compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');
    final resized = img.copyResize(image, width: 800);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      print('=== Starting image upload ===');
      print('File path: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');
      print('File size: ${await imageFile.length()} bytes');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('ERROR: User not authenticated');
        return null;
      }
      print('User authenticated: ${user.uid}');

      print('Testing Supabase connection...');
      final buckets = await SupabaseConfig.client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');

      final fileName = 'complaints/complaint_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading file: $fileName to bucket: fix_my_campus');

      print('Compressing image...');
      final compressedBytes = await _compressImage(imageFile);
      print('Compressed image size: ${compressedBytes.length} bytes');

      final response = await SupabaseConfig.client.storage
          .from('fix_my_campus')
          .uploadBinary(fileName, compressedBytes);

      print('Upload response: $response');

      final publicUrl = SupabaseConfig.client.storage
          .from('fix_my_campus')
          .getPublicUrl(fileName);

      print('Public URL generated: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      print('=== ERROR uploading image ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    if (_complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complaint details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final location = ModalRoute.of(context)?.settings.arguments as LatLng?;
      final detectedPriority = _detectPriority(_complaintController.text);

      String? imageUrl;
      if (_image != null) {
        print('Image selected, uploading...');
        imageUrl = await _uploadImageToSupabase(_image!);
        print('Image URL received: $imageUrl');
      } else {
        print('No image selected');
      }

      print('Saving to Firestore with priority: $detectedPriority');
      await _firestore.collection('complaints').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'complaint': _complaintController.text.trim(),
        'imageUrl': imageUrl,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'status': 'pending',
        'priority': detectedPriority,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Complaint saved successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint submitted successfully (Priority: ${detectedPriority.toUpperCase()})'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Complaint")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _complaintController,
              decoration: const InputDecoration(
                labelText: "Enter complaint details",
                border: OutlineInputBorder(),
                hintText: "Describe the issue in detail...",
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priority is automatically detected based on your complaint description.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Upload Image"),
            ),
            const SizedBox(height: 8),
            if (_image != null) ...[
              const SizedBox(height: 16),
              Image.file(_image!, height: 200),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Complaint"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
