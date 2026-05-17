import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_menu_item.dart';
import 'personal_information_screen.dart';
import 'organization_details_screen.dart';
import 'my_contracts_screen.dart';
import 'musician_management_screen.dart';
import 'payment_history_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x4DA2F301), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  ProfileInfoCard(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  children: [
                    ProfileMenuItem(
                      iconPath: 'assets/profile_icon.svg',
                      title: 'Personal Information',
                      subtitle: 'Update your profile details',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PersonalInformationScreen(),
                        ),
                      ),
                    ),
                    ProfileMenuItem(
                      iconPath: 'assets/organization_icon.svg',
                      title: 'Organization Details',
                      subtitle: 'Venue and company info',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const OrganizationDetailsScreen(),
                        ),
                      ),
                    ),
                    ProfileMenuItem(
                      iconPath: 'assets/application_icon.svg',
                      title: 'Musician Management',
                      subtitle: 'Hired, shortlisted & rejected',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MusicianManagementScreen(),
                        ),
                      ),
                    ),
                    ProfileMenuItem(
                      iconPath: 'assets/application_icon.svg',
                      title: 'My Contracts',
                      subtitle: 'View all signed contracts',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyContractsScreen(),
                        ),
                      ),
                    ),
                    ProfileMenuItem(
                      iconPath: 'assets/wallet_icon.svg',
                      title: 'Wallet',
                      subtitle: 'Manage balance and payments',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WalletScreen(),
                        ),
                      ),
                    ),
                    ProfileMenuItem(
                      iconPath: 'assets/payment_icon.svg',
                      title: 'Payment History',
                      subtitle: 'Transaction records',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PaymentHistoryScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Logout button
                    GestureDetector(
                      onTap: _isLoggingOut
                          ? null
                          : () async {
                              setState(() => _isLoggingOut = true);
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              await authService.signOut();
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login', (route) => false);
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFFF3B30)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: _isLoggingOut
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF3B30),
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout,
                                      color: Color(0xFFFF3B30), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Color(0xFFFF3B30),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'OnlyGigz v1.0.0',
                      style: TextStyle(
                          color: Color(0xFF444444), fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
