import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/application_card.dart';
import '../../widgets/status_filter_chips.dart';
import '../../models/application_model.dart';
import '../../services/auth_service.dart';
import 'application_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  int _currentNavIndex = 1;
  ApplicationStatus? _selectedStatus;
  List<Application> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final appsData = await authService.getApplications();
    
    if (mounted) {
      setState(() {
        _applications = appsData.map((data) => Application.fromMap(data, data['id'] ?? '')).toList();
        _isLoading = false;
      });
    }
  }

  List<Application> get filteredApplications {
    if (_selectedStatus == null) {
      return _applications;
    }
    return _applications
        .where((app) => app.status == _selectedStatus)
        .toList();
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    // Handle navigation to different screens
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        // Applications - already here
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/messages');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/bookings');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  void _onStatusSelected(ApplicationStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Applications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Track your gig applications',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Filter Chips
                    StatusFilterChips(
                      selectedStatus: _selectedStatus,
                      onStatusSelected: _onStatusSelected,
                    ),
                  ],
                ),
              ),
            ),

            // Applications List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1F301)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchApplications,
                      color: const Color(0xFFA1F301),
                      backgroundColor: const Color(0xFF1A1A1F),
                      child: filteredApplications.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                Center(
                                  child: Text(
                                    'No applications found',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredApplications.length,
                              itemBuilder: (context, index) {
                                final application = filteredApplications[index];
                                return ApplicationCard(
                                  application: application,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ApplicationDetailScreen(application: application),
                                      ),
                                    );
                                    _fetchApplications(); // Refresh when coming back
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
