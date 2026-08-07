import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:onlygigz_musician/services/api_service.dart';
import 'package:shared_config/shared_config.dart';
import 'package:onlygigz_musician/screens/main/contract_review_screen.dart';
import 'package:onlygigz_musician/models/booking_model.dart';

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  final _apiService = ApiService();
  final _currentUser = FirebaseAuth.instance.currentUser;
  
  List<dynamic> _allContracts = [];
  bool _isLoading = true;
  String _error = '';
  
  // 'All', 'Active', 'Completed', 'Pending'
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Active', 'Completed', 'Pending'];

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  Future<void> _fetchContracts() async {
    if (_currentUser == null) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      
      final data = await _apiService.getBookings(musicianId: _currentUser!.uid);
      setState(() {
        _allContracts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contracts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getContractStatus(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    
    // Derived contract status based on booking status
    if (status == 'pending' || status == 'Awaiting musician signature' || status == 'Contract issued') {
      return 'Pending';
    } else if (status == 'active' || status == 'Payment in escrow') {
      return 'Active';
    } else if (status == 'completed') {
      return 'Completed';
    }
    return 'Pending'; // Default fallback
  }

  List<dynamic> get _filteredContracts {
    if (_selectedTab == 'All') return _allContracts;
    
    return _allContracts.where((booking) {
      final status = _getContractStatus(booking as Map<String, dynamic>);
      return status == _selectedTab;
    }).toList();
  }
  
  Future<void> _downloadPdf(String bookingId) async {
    try {
      final baseUrl = getBackendUrl();
      final uri = Uri.parse('$baseUrl/bookings/$bookingId/contract/pdf');
      
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Contracts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16161D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D2D3A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF06B6D4), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'View and manage all your signed performance contracts',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _tabs.map((tab) {
                final isSelected = tab == _selectedTab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFB3FF00).withOpacity(0.1) : const Color(0xFF16161D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFB3FF00) : const Color(0xFF2D2D3A),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFB3FF00) : Colors.white.withOpacity(0.6),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFB3FF00)))
                : _error.isNotEmpty
                    ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                    : _filteredContracts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 16),
                                Text(
                                  'No contracts found',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredContracts.length,
                            itemBuilder: (context, index) {
                              final contract = _filteredContracts[index] as Map<String, dynamic>;
                              return _buildContractCard(contract);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> booking) {
    final status = _getContractStatus(booking);
    final gigDetails = booking['gigDetails'] ?? {};
    final title = gigDetails['title'] ?? 'Unknown Gig';
    final organizerName = booking['organizerName'] ?? 'Unknown Organizer';
    final amount = gigDetails['price'] != null ? '\$${gigDetails['price']}' : 'TBD';
    final date = gigDetails['date'] ?? 'TBD';
    final imageUrl = gigDetails['imageUrl'];
    
    final musicianSignedAt = booking['musicianSignedAt'];
    String dateSignedStr = 'Pending signature';
    if (musicianSignedAt != null) {
      try {
        DateTime parsed;
        if (musicianSignedAt is Map && musicianSignedAt['_seconds'] != null) {
          parsed = DateTime.fromMillisecondsSinceEpoch(musicianSignedAt['_seconds'] * 1000);
        } else {
          parsed = DateTime.parse(musicianSignedAt.toString());
        }
        dateSignedStr = 'Signed on ${DateFormat('MMM dd, yyyy').format(parsed)}';
      } catch (_) {}
    }
    
    // Status colors
    Color statusColor;
    Color statusBgColor;
    if (status == 'Active') {
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
    } else if (status == 'Pending') {
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
    } else {
      statusColor = const Color(0xFF06B6D4);
      statusBgColor = const Color(0xFF06B6D4).withOpacity(0.1);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2D2D3A),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? const Icon(Icons.music_note, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Agreement - $title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organizerName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF2D2D3A), height: 1),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance: $date • $amount',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateSignedStr,
            style: TextStyle(
              color: status == 'Pending' ? const Color(0xFFF59E0B) : Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ContractReviewScreen(
                        booking: Booking.fromFirestore(booking, booking['id']),
                      ),
                    ));
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF2D2D3A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'View',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _downloadPdf(booking['id']),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3FF00).withOpacity(0.1),
                      border: Border.all(color: const Color(0xFFB3FF00)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_rounded, color: Color(0xFFB3FF00), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Download',
                            style: TextStyle(
                              color: Color(0xFFB3FF00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
