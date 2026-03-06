import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ComplaintRegister extends StatefulWidget {
  const ComplaintRegister({super.key});

  @override
  State<ComplaintRegister> createState() => _ComplaintRegisterState();
}

class _ComplaintRegisterState extends State<ComplaintRegister> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register Complaint")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Enter complaint details",
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text("Upload Image"),
            ),
            if (_image != null) ...[
              SizedBox(height: 16),
              Image.file(_image!, height: 200),
            ],
            ElevatedButton(
              onPressed: () {
              },
              child: Text("Submit Complaint"),
            )
          ],
        ),
      ),
    );
  }
}