import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_payment_card_screen.dart';
import 'add_bank_account_screen.dart';
import 'transaction_detail_screen.dart';
import 'request_early_release_screen.dart';
import 'request_payout_screen.dart';
import 'default_card_success_screen.dart';

class WalletOverviewScreen extends StatefulWidget {
  const WalletOverviewScreen({super.key});

  @override
  State<WalletOverviewScreen> createState() => _WalletOverviewScreenState();
}

class _WalletOverviewScreenState extends State<WalletOverviewScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Wallet', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage earnings, escrow & payments', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFA1F301), Color(0xFF0A0A0F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Available Balance', style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                              Icon(Icons.visibility_outlined, color: Colors.black.withValues(alpha: 0.6), size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('\$717.51', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.8), size: 16),
                                          const SizedBox(width: 6),
                                          Text('In Escrow', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('\$3135.00', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.trending_up, color: Colors.white.withValues(alpha: 0.8), size: 16),
                                          const SizedBox(width: 6),
                                          Text('Total Earned', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('\$2327.50', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestPayoutScreen())),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: SvgPicture.asset(
                                      'assets/download_icon.svg',
                                      fit: BoxFit.contain,
                                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Withdraw Funds', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab Bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildPillTab('Overview', 0),
                          _buildPillTab('Escrow', 1),
                          _buildPillTab('History', 2),
                          _buildPillTab('Methods', 3),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab Content
                    if (_selectedTabIndex == 0) _buildOverviewTab(),
                    if (_selectedTabIndex == 1) _buildEscrowTab(),
                    if (_selectedTabIndex == 2) _buildHistoryTab(),
                    if (_selectedTabIndex == 3) _buildMethodsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, {required String title, required String subtitle, required VoidCallback onConfirm}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSetDefaultConfirmation(BuildContext context, String cardName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.credit_card, color: Color(0xFFA1F301), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Set as Default?',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '$cardName will be set as your default payment method for all future transactions.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DefaultCardSuccessScreen(cardName: cardName),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Confirm', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFA1F301) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.grey[500],
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: const Color(0xFFA1F301), size: 16),
                        const SizedBox(width: 6),
                        const Text('This Month', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('\$3,580', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('+32% from last month', style: TextStyle(color: Color(0xFFA1F301), fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_outlined, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        const Text('Pending', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('\$3135', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('From 2 gigs', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Active Escrow Section
        const Text('Active Escrow', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildEscrowItem(
          'Corporate Event Entertainment',
          'TechCorp Events',
          'Releases Jan 11, 2026',
          '\$2375.00',
          'Pending',
          const Color(0xFFF59E0B),
          'assets/profile_image.png',
        ),
        const SizedBox(height: 12),
        _buildEscrowItem(
          'Birthday Party DJ Set',
          'Michael Rodriguez',
          'Releases Feb 15, 2026',
          '\$760.00',
          'Held',
          const Color(0xFFF59E0B),
          'assets/profile_image.png',
        ),
        const SizedBox(height: 32),
        // Recent Activity Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 2),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(color: Color(0xFFA1F301), fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFFA1F301), size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem('Payment Released - Wedding', 'Jan 8, 2026', '+\$1140.00', const Color(0xFF00C950), Icons.south_east),
        const SizedBox(height: 12),
        _buildActivityItem('Platform Service Fee', 'Jan 8, 2026', '-\$60.00', const Color(0xFFEF4444), Icons.north_east),
        const SizedBox(height: 12),
        _buildActivityItem('Featured Artist Upgrade', 'Jan 4, 2026', '-\$49.99', const Color(0xFFEF4444), Icons.north_east),
        const SizedBox(height: 12),
        _buildActivityItem('Payment Released - Bar Acoustic', 'Dec 11, 2025', '+\$380.00', const Color(0xFF00C950), Icons.south_east),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEscrowTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Escrow Protection Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/shield_icon.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Secure Escrow Protection', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'When you\'re hired, payment is held securely in escrow until the gig is completed. Funds are automatically released 24 hours after your performance. You can request early release if the gig is completed early or if special circumstances apply.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Detailed Escrow Transaction
        _buildDetailedEscrowItem(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transaction History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: SvgPicture.asset(
                      'assets/download_icon.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Export', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildHistoryItem(
          'Payment Released - Wedding Reception',
          'Emily & John',
          'Jan 6, 2026',
          '2:30 PM',
          '+\$1140.00',
          const Color(0xFF00C950),
          Icons.south_east,
          'completed',
        ),
        const SizedBox(height: 12),
        _buildHistoryItem(
          'Platform Service Fee',
          null,
          'Jan 6, 2026',
          '2:30 PM',
          '-\$60.00',
          const Color(0xFFEF4444),
          Icons.north_east,
          'completed',
        ),
        const SizedBox(height: 12),
        _buildHistoryItem(
          'Featured Artist Upgrade',
          null,
          'Jan 4, 2026',
          '10:15 AM',
          '-\$49.99',
          const Color(0xFFEF4444),
          Icons.north_east,
          'completed',
        ),
        const SizedBox(height: 12),
        _buildHistoryItem(
          'Payment Released - Bar Acoustic Session',
          'The Rusty Nail',
          'Dec 11, 2025',
          '9:00 AM',
          '+\$380.00',
          const Color(0xFF00C950),
          Icons.south_east,
          'completed',
        ),
        const SizedBox(height: 12),
        _buildHistoryItem(
          'Withdrawal to Bank Account',
          null,
          'Dec 5, 2025',
          '11:20 AM',
          '-\$1500.00',
          const Color(0xFF3B82F6),
          Icons.north_east,
          null,
        ),
        const SizedBox(height: 12),
        _buildHistoryItem(
          'Payment Released - Jazz Lounge',
          'Blue Moon Events',
          'Nov 28, 2025',
          '4:45 PM',
          '+\$807.50',
          const Color(0xFF00C950),
          Icons.south_east,
          'completed',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMethodsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Cards Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment Cards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPaymentCardScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA1F301),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text('Add Card', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Visa Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D4A1F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.credit_card, color: Color(0xFFA1F301), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Visa •••• 4242', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('John Doe', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Expires 12/26', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFA1F301), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Default', style: TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(
                    context,
                    title: 'Remove Card?',
                    subtitle: 'This action cannot be undone. The card Visa •••• 4242 will be permanently removed from your account.',
                    onConfirm: () {},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 6),
                        Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mastercard
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D4A1F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.credit_card, color: Color(0xFFA1F301), size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mastercard •••• 8888', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('John Doe', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Expires 09/27', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSetDefaultConfirmation(context, 'Mastercard •••• 8888'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('Set as Default', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(
                      context,
                      title: 'Remove Card?',
                      subtitle: 'This action cannot be undone. The card Mastercard •••• 8888 will be permanently removed from your account.',
                      onConfirm: () {},
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Bank Accounts Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bank Accounts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBankAccountScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Add Bank', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Chase Bank
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A5F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SvgPicture.asset(
                        'assets/bank_icon2.svg',
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chase Bank', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Checking •••• 4532', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Default', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(
                    context,
                    title: 'Remove Bank Account?',
                    subtitle: 'This action cannot be undone. Chase Bank Checking •••• 4532 will be permanently removed from your account.',
                    onConfirm: () {},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 6),
                        Text('Remove', style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Withdrawal Information
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFFA1F301), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Withdrawal Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Withdrawals are processed to your default bank account within 2-3 business days. Minimum withdrawal amount is \$50. No fees for standard withdrawals.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailedEscrowItem() {
    return Column(
      children: [
        // First Card - Corporate Event Entertainment
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wedding Reception Live Band', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Emily & John', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C950).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFF00C950), width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: const Color(0xFF00C950), size: 12),
                              const SizedBox(width: 4),
                              const Text('Released', style: TextStyle(color: Color(0xFF00C950), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAmountRow('Gross Amount', '\$1200.00', Colors.white),
              const SizedBox(height: 16),
              _buildAmountRow('Platform Fee (5%)', '-\$60.00', const Color(0xFFEF4444)),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.grey[800]),
              const SizedBox(height: 20),
              _buildAmountRow('You Receive', '\$1140.00', const Color(0xFFA1F301), isBold: true, isLarge: true),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Dec 28, 2025', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 5, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Released', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 6, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 6),
                  Text('Grand Ballroom Hotel', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 6),
                  Text('4 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C950).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: const Color(0xFF00C950), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text('Payment successfully add to your wallet balance', style: TextStyle(color: Color(0xFF00C950), fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Second Card - Corporate Event Entertainment
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Corporate Event Entertainment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('TechCorp Events', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, color: const Color(0xFFF59E0B), size: 14),
                              const SizedBox(width: 4),
                              const Text('In Escrow - Pending', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAmountRow('Gross Amount', '\$2500.00', Colors.white),
              const SizedBox(height: 16),
              _buildAmountRow('Platform Fee (5%)', '-\$125.00', const Color(0xFFEF4444)),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.grey[800]),
              const SizedBox(height: 20),
              _buildAmountRow('You Receive', '\$2375.00', const Color(0xFFA1F301), isBold: true, isLarge: true),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 3, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 10, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Releases', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 11, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 6),
                  Text('Tech Conference Center', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 6),
                  Text('6 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestEarlyReleaseScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1F301),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: SvgPicture.asset(
                          'assets/send_message_icon.svg',
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Request Early Release', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Third Card - Birthday Party DJ Set
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Birthday Party DJ Set', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Michael Rodriguez', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: const Color(0xFFF59E0B), size: 12),
                              const SizedBox(width: 4),
                              const Text('In Escrow - Held', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAmountRow('Gross Amount', '\$800.00', Colors.white),
              const SizedBox(height: 16),
              _buildAmountRow('Platform Fee (5%)', '-\$40.00', const Color(0xFFEF4444)),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.grey[800]),
              const SizedBox(height: 20),
              _buildAmountRow('You Receive', '\$760.00', const Color(0xFFA1F301), isBold: true, isLarge: true),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Jan 8, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Feb 14, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Releases', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text('Feb 15, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),
                  const SizedBox(width: 6),
                  Text('Private Residence', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 6),
                  Text('3 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment will be automatically released 24h after gig completion',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, String amount, Color amountColor, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.grey[400], fontSize: isLarge ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(color: amountColor, fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEscrowItem(String title, String client, String releaseDate, String amount, String status, Color statusColor, String avatarPath) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(avatarPath, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(client, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  border: Border.all(color: statusColor, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: SvgPicture.asset(
                  'assets/lock_icon.svg',
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(Color(0xFFF59E0B), BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 6),
              Text(releaseDate, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              const Spacer(),
              Text(amount, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String date, String amount, Color amountColor, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              title: title,
              subtitle: null,
              date: date,
              time: '',
              amount: amount,
              amountColor: amountColor,
              status: null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: amountColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(amount, style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String? subtitle, String date, String time, String amount, Color amountColor, IconData icon, String? status) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              title: title,
              subtitle: subtitle,
              date: date,
              time: time,
              amount: amount,
              amountColor: amountColor,
              status: status,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: amountColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (subtitle != null) ...[
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold)),
              if (status != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C950).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00C950), width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(status, style: const TextStyle(color: Color(0xFF00C950), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}