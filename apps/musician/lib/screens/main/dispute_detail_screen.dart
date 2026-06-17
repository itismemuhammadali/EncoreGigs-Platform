import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DisputeDetailScreen extends StatefulWidget {
  final String disputeId;
  const DisputeDetailScreen({super.key, required this.disputeId});

  @override
  State<DisputeDetailScreen> createState() => _DisputeDetailScreenState();
}

class _DisputeDetailScreenState extends State<DisputeDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dispute;

  @override
  void initState() {
    super.initState();
    _loadDispute();
  }

  Future<void> _loadDispute() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dispute = await authService.getDispute(widget.disputeId);
    if (mounted) {
      setState(() {
        _dispute = dispute;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: const Text('Dispute Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)))
          : _dispute == null
              ? const Center(child: Text('Dispute not found', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHeader(),
                      const SizedBox(height: 24),
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      const Text('Description', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _dispute!['description'] ?? 'No description provided.',
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_dispute!['attachments'] != null && (_dispute!['attachments'] as List).isNotEmpty) ...[
                        const Text('Attachments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildAttachmentsGrid(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _dispute!['status'] ?? 'pending';
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'resolved':
        color = const Color(0xFFA1F301);
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${status.toUpperCase()}',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Reference: ${widget.disputeId.substring(0, 12).toUpperCase()}',
                style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow('Reason', _dispute!['category'] ?? 'N/A'),
          const Divider(color: Color(0xFF2A2A2F), height: 32),
          _buildDetailRow('Booking ID', _dispute!['bookingId']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'),
          const Divider(color: Color(0xFF2A2A2F), height: 32),
          _buildDetailRow('Created At', 'Recently'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAttachmentsGrid() {
    final attachments = _dispute!['attachments'] as List;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2F),
            borderRadius: BorderRadius.circular(10),
            image: const DecorationImage(
              image: NetworkImage('https://via.placeholder.com/150'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Icon(Icons.file_present, color: Colors.white54),
          ),
        );
      },
    );
  }
}
