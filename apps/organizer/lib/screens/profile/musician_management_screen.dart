import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../gigs/musician_profile_screen.dart';
import 'package:intl/intl.dart';

class MusicianManagementScreen extends StatefulWidget {
  const MusicianManagementScreen({super.key});

  @override
  State<MusicianManagementScreen> createState() => _MusicianManagementScreenState();
}

class _MusicianManagementScreenState extends State<MusicianManagementScreen> {
  final ApiService _apiService = ApiService();
  String _activeFilter = 'shortlisted'; // Default filter
  bool _isLoading = false;
  List<Map<String, dynamic>> _applications = [];

  final List<Map<String, String>> _filters = [
    {'id': 'shortlisted', 'label': 'Shortlisted'},
    {'id': 'hired', 'label': 'Hired'},
    {'id': 'rejected', 'label': 'Rejected'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final organizerId = authService.user?.uid;
      
      if (organizerId != null) {
        final apps = await _apiService.getApplications(
          organizerId: organizerId,
          status: _activeFilter,
        );
        setState(() {
          _applications = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  void _onFilterChanged(String filterId) {
    if (_activeFilter == filterId) return;
    setState(() {
      _activeFilter = filterId;
    });
    _fetchApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x4DA2F301), height: 1),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text(
          'Musician Management',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: _filters.map((filter) {
                final isActive = _activeFilter == filter['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onFilterChanged(filter['id']!),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                        ),
                      ),
                      child: Text(
                        filter['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? Colors.black : const Color(0xFF999999),
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)))
                : _applications.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          return _buildMusicianCard(_applications[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activeFilter == 'hired' ? Icons.stars : Icons.person_off,
              color: const Color(0xFF444444),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_activeFilter} musicians found',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicianCard(Map<String, dynamic> app) {
    final name = app['musicianName'] ?? 'Unknown Musician';
    final gigTitle = app['gigTitle'] ?? 'Unknown Gig';
    final musicianId = app['musicianId'];
    final imagePath = app['musicianImage'];
    final appliedAt = app['appliedAt'];
    String dateStr = 'Recent';
    
    if (appliedAt != null) {
      if (appliedAt is String) {
        dateStr = appliedAt.split('T')[0];
      } else if (appliedAt is Map && appliedAt['_seconds'] != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(appliedAt['_seconds'] * 1000);
        dateStr = DateFormat('MMM dd, yyyy').format(dt);
      }
    }

    return GestureDetector(
      onTap: () {
        if (musicianId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MusicianProfileScreen(musicianId: musicianId),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2F)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: imagePath != null && imagePath.startsWith('http')
                  ? Image.network(imagePath, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderImage())
                  : _placeholderImage(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gigTitle,
                    style: const TextStyle(color: Color(0xFFA2F301), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 20),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: const Color(0xFF2A2A2F),
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }
}
