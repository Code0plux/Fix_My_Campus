import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:fix_my_campus/supabase_config.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../core/constants/app_colors.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

const _bg = AppColors.background;
const _dark = AppColors.dark;
const _mid = AppColors.primary;
const _light = AppColors.light;

// ─── Store your key securely — never commit it to version control.
// Ideally proxy this call through a Firebase Cloud Function instead.
const _anthropicApiKey = 'YOUR_ANTHROPIC_API_KEY';

class ComplaintRegister extends StatefulWidget {
  const ComplaintRegister({super.key});

  @override
  State<ComplaintRegister> createState() => _ComplaintRegisterState();
}

class _ComplaintRegisterState extends State<ComplaintRegister>
    with SingleTickerProviderStateMixin {
  final List<XFile> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  final _complaintController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 0.6).animate(_pulseController);
  }

  @override
  void dispose() {
    _complaintController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── AI-powered priority detection ──────────────────────────────────────────

  /// Calls Claude to classify the complaint. Returns 'high', 'medium', or 'low'.
  /// Falls back to regex silently if the API call fails, so submission is never blocked.
  Future<String> _detectPriority(String complaint) async {
    const prompt = '''
You are a campus facilities complaint triage system. Classify the priority of the complaint below.

Respond ONLY with a JSON object — no markdown, no preamble, no explanation. Format:
{"priority": "high"|"medium"|"low", "confidence": 0.0-1.0, "reason": "one sentence"}

Priority definitions:
- high: immediate safety risk — fire, smoke, electrical fault, gas leak, flooding near electrics, structural collapse, injury hazard, blocked emergency exit, toxic/chemical exposure
- medium: significant disruption or risk of worsening — broken fixtures, water leak (no electrical risk), HVAC failure, broken locks or doors, persistent maintenance issues, malfunctioning lights
- low: cosmetic, minor, or quality-of-life — peeling paint, dirty areas, aesthetic damage, minor requests, suggestions

Complaint: ''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _anthropicApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 150,
          'messages': [
            {
              'role': 'user',
              'content': '$prompt"${complaint.replaceAll('"', '\\"')}"',
            }
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (data['content'] as List)
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join();

        // Strip accidental markdown fences just in case
        final clean = text.replaceAll(RegExp(r'```[a-z]*\n?|```'), '').trim();
        final parsed = jsonDecode(clean) as Map<String, dynamic>;
        final priority = parsed['priority'] as String;

        if (['high', 'medium', 'low'].contains(priority)) {
          debugPrint(
            'AI priority: $priority '
            '(confidence: ${parsed['confidence']}, reason: ${parsed['reason']})',
          );
          return priority;
        }
      } else {
        debugPrint('Anthropic API error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('AI priority detection failed: $e — using fallback');
    }

    return _detectPriorityFallback(complaint);
  }

  /// Regex fallback — only used when the API call fails or times out.
  String _detectPriorityFallback(String complaint) {
    final text = complaint.toLowerCase();

    final highPatterns = [
      RegExp(r'\b(smoke|fire|burning|flame|electrical|electric|shock|electrocution)\b'),
      RegExp(r'\b(gas|leak|leaking|fume|toxic|poison)\b'),
      RegExp(r'\b(water|flood|flooding|leak|leaking)\b.*\b(electrical|electric|power|box)\b'),
      RegExp(r'\b(broken|damaged|sharp|glass|bleeding|injury|accident|hurt)\b'),
      RegExp(r'\b(dangerous|hazard|unsafe|risk|emergency|urgent|critical|severe)\b'),
      RegExp(r'\b(collapse|falling|fallen|blocked|stuck|trapped)\b'),
    ];

    final mediumPatterns = [
      RegExp(r'\b(broken|damaged)\b.*\b(light|door|window|wall|floor|ceiling)\b'),
      RegExp(r'\b(crack|hole|dent|scratch|stain|dirty|messy)\b'),
      RegExp(r'\b(not working|malfunction|faulty|broken|issue|problem)\b'),
      RegExp(r'\b(paint|repair|fix|maintenance|cleaning)\b'),
      RegExp(r'\b(water|leak)\b(?!.*\b(electrical|electric|power)\b)'),
    ];

    for (final p in highPatterns) if (p.hasMatch(text)) return 'high';
    for (final p in mediumPatterns) if (p.hasMatch(text)) return 'medium';
    return 'low';
  }

  // ─── Media picker ────────────────────────────────────────────────────────────

  Future<void> _showMediaPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _mid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _sheetTile(Icons.photo_library_rounded, 'Images from Gallery', () async {
                Navigator.pop(context);
                final files = await _picker.pickMultiImage();
                if (files.isNotEmpty) setState(() => _mediaFiles.addAll(files));
              }),
              _sheetTile(Icons.videocam_rounded, 'Video from Gallery', () async {
                Navigator.pop(context);
                final file = await _picker.pickVideo(source: ImageSource.gallery);
                if (file != null) setState(() => _mediaFiles.add(file));
              }),
              _sheetTile(Icons.camera_alt_rounded, 'Take Photo', () async {
                Navigator.pop(context);
                final file = await _picker.pickImage(source: ImageSource.camera);
                if (file != null) setState(() => _mediaFiles.add(file));
              }),
              _sheetTile(Icons.video_camera_back_rounded, 'Record Video', () async {
                Navigator.pop(context);
                final file = await _picker.pickVideo(source: ImageSource.camera);
                if (file != null) setState(() => _mediaFiles.add(file));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _dark, size: 22),
      ),
      title: Text(label, style: const TextStyle(color: _dark, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // ─── File handling ───────────────────────────────────────────────────────────

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  Future<Uint8List> _compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    return Uint8List.fromList(img.encodeJpg(img.copyResize(image, width: 800), quality: 85));
  }

  Future<String?> _uploadFile(XFile file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final isVid = _isVideo(file.path);
      final fileName =
          '${isVid ? 'videos' : 'complaints'}/complaint_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.${isVid ? 'mp4' : 'jpg'}';
      final bytes = isVid
          ? await File(file.path).readAsBytes()
          : await _compressImage(File(file.path));
      await SupabaseConfig.client.storage.from('fix_my_campus').uploadBinary(fileName, bytes);
      return SupabaseConfig.client.storage.from('fix_my_campus').getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  // ─── Submit ──────────────────────────────────────────────────────────────────

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

      // AI classification runs concurrently with nothing else here —
      // keeping it sequential so priority is ready before Firestore write.
      final priority = await _detectPriority(_complaintController.text);

      final mediaUrls = <String>[];
      for (final f in _mediaFiles) {
        final url = await _uploadFile(f);
        if (url != null) mediaUrls.add(url);
      }

      await _firestore.collection('complaints').add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'complaint': _complaintController.text.trim(),
        'mediaUrls': mediaUrls,
        'imageUrl': mediaUrls.isNotEmpty ? mediaUrls.first : null,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'status': 'pending',
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submitted! Priority: ${priority.toUpperCase()}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _dark,
        title: const Text('Register Complaint',
            style: TextStyle(color: _bg, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: _bg),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Complaint Details'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _mid.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: _mid.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: TextField(
                controller: _complaintController,
                maxLines: 5,
                style: const TextStyle(color: _dark),
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  hintStyle: TextStyle(color: _dark.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _light,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _dark, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priority is auto-detected from your description',
                      style: TextStyle(fontSize: 12, color: _dark.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Attachments'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showMediaPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _mid, style: BorderStyle.solid),
                  boxShadow: [
                    BoxShadow(
                        color: _mid.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: _dark, size: 32),
                    const SizedBox(height: 6),
                    Text('Tap to add photos or videos',
                        style: TextStyle(color: _dark.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
            ),
            if (_mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mediaFiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, i) {
                  final file = _mediaFiles[i];
                  final isVid = _isVideo(file.path);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isVid
                            ? Container(
                                color: _dark,
                                child: const Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 36),
                              )
                            : Image.file(File(file.path), fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _mediaFiles.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Opacity(
                opacity: _isLoading ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _dark,
                    foregroundColor: _bg,
                    elevation: 4,
                    shadowColor: _dark.withOpacity(0.4),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: _bg, strokeWidth: 2.5),
                        )
                      : const Text('Submit Complaint',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _dark,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}