import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../core/constants/app_colors.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final DocumentSnapshot complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  String _currentStatus = 'pending';
  bool _isUpdating = false;
  int _currentMediaIndex = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  List<String> _mediaUrls = [];
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    
    _currentStatus = _complaint['status'] ?? 'pending';
    _mediaUrls = List<String>.from(_complaint['mediaUrls'] ?? []);
    if (_mediaUrls.isEmpty && _complaint['mediaUrl'] != null) {
      _mediaUrls = [_complaint['mediaUrl'] as String];
    }
    if (_mediaUrls.isNotEmpty) {
      _initializeMedia();
    }
  }

  Map<String, dynamic> get _complaint =>
      widget.complaint.data() as Map<String, dynamic>;

  Future<void> _initializeMedia() async {
    if (_mediaUrls.isEmpty) return;
    if (_isVideoFile(_mediaUrls[_currentMediaIndex])) {
      await _initializeVideo(_mediaUrls[_currentMediaIndex]);
    }
  }

  Future<void> _initializeVideo(String url) async {
    try {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Accept': 'video/*'},
      );
      await _videoController!.initialize();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      print('Video initialization error: $e');
      if (mounted) {
        _videoController?.dispose();
        _videoController = null;
        setState(() => _isVideoInitialized = false);
        
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('network') || errorMsg.contains('host')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error: Unable to load video. Check your connection.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video format not supported on this device'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _changeMedia(int index) async {
    setState(() {
      _currentMediaIndex = index;
      _isVideoInitialized = false;
    });
    await _initializeMedia();
  }

  bool _isVideoFile(String url) {
    final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.flv', '.wmv', '.m4v'];
    final urlLower = url.toLowerCase();
    
    if (videoExtensions.any((ext) => urlLower.contains(ext))) {
      return true;
    }
    
    if (urlLower.contains('video')) {
      return true;
    }
    
    if (urlLower.contains('alt=media') && urlLower.contains('video')) {
      return true;
    }
    
    if (urlLower.contains('/videos/')) {
      return true;
    }
    
    return false;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController.dispose();
    super.dispose();
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
        SnackBar(
          content: Text('Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: _getStatusColor(newStatus),
          duration: const Duration(seconds: 2),
        ),
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: FadeTransition(
        opacity: _fadeController,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Complaint Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusChip(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPriorityChip(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildDetailCard(),
                    const SizedBox(height: 20),

                    if (_mediaUrls.isNotEmpty) ...[ 
                      _buildMediaSection(),
                      const SizedBox(height: 20),
                    ],

                    if (_complaint['latitude'] != null && _complaint['longitude'] != null)
                      _buildLocationCard(),
                    const SizedBox(height: 20),

                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(_currentStatus).withOpacity(0.1),
        border: Border.all(
          color: _getStatusColor(_currentStatus),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _currentStatus == 'pending'
                ? Icons.schedule
                : _currentStatus == 'under_work'
                    ? Icons.build
                    : Icons.check_circle,
            color: _getStatusColor(_currentStatus),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _currentStatus.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(_currentStatus),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip() {
    final priority = _complaint['priority'] ?? 'low';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.1),
        border: Border.all(
          color: _getPriorityColor(priority),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            priority == 'high'
                ? Icons.priority_high
                : priority == 'medium'
                    ? Icons.info
                    : Icons.check,
            color: _getPriorityColor(priority),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Priority: ${priority.toUpperCase()}',
              style: TextStyle(
                color: _getPriorityColor(priority),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complaint Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _complaint['complaint'] ?? 'No complaint text',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email, 'Email', _complaint['userEmail'] ?? 'Unknown'),
          const SizedBox(height: 12),
          if (_complaint['createdAt'] != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Submitted',
              (_complaint['createdAt'] as Timestamp).toDate().toString().split('.')[0],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Complaint Media',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            Stack(
              children: [
                if (_isVideoFile(_mediaUrls[_currentMediaIndex]))
                  if (_isVideoInitialized && _videoController != null)
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: FloatingActionButton(
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      color: AppColors.greyLight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading video...',
                              style: TextStyle(color: AppColors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _initializeMedia(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CachedNetworkImage(
                      imageUrl: _mediaUrls[_currentMediaIndex],
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 280,
                        color: AppColors.greyLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 280,
                        color: AppColors.greyLight,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 48, color: AppColors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_mediaUrls.length > 1) ...[ 
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _currentMediaIndex > 0
                            ? () => _changeMedia(_currentMediaIndex - 1)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: _currentMediaIndex > 0
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _currentMediaIndex < _mediaUrls.length - 1
                            ? () => _changeMedia(_currentMediaIndex + 1)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: _currentMediaIndex < _mediaUrls.length - 1
                                ? Colors.white
                                : Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_mediaUrls.length > 1) ...[ 
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _mediaUrls.length,
                        (i) => GestureDetector(
                          onTap: () => _changeMedia(i),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentMediaIndex == i ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentMediaIndex == i
                                  ? AppColors.primary
                                  : AppColors.greyLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_currentMediaIndex + 1} / ${_mediaUrls.length}',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Complaint Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            Container(
              height: 200,
              color: AppColors.greyLight,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_complaint['latitude'], _complaint['longitude']),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}",
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName: 'com.example.fix_my_campus',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_complaint['latitude'], _complaint['longitude']),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Coordinates: ${_complaint['latitude'].toStringAsFixed(6)}, ${_complaint['longitude'].toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Under Work',
                      AppColors.statusUnderWork,
                      _isUpdating || _currentStatus == 'under_work'
                          ? null
                          : () => _updateStatus('under_work'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Mark Fixed',
                      AppColors.statusFixed,
                      _isUpdating || _currentStatus == 'fixed'
                          ? null
                          : () => _updateStatus('fixed'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _isUpdating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
    );
  }
}
