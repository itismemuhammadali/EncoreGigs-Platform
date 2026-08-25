import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

enum PolicyDocType {
  termsOfService,
  privacyPolicy,
  termsAndConditions,
  pricingAndFees,
  dmcaPolicy,
  aboutUs,
}

class TermsOfServiceScreen extends StatefulWidget {
  final PolicyDocType docType;

  const TermsOfServiceScreen({
    super.key,
    this.docType = PolicyDocType.termsOfService,
  });

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  String _rawContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolicyContent();
  }

  String get _title {
    switch (widget.docType) {
      case PolicyDocType.termsOfService:
        return 'Terms of Service';
      case PolicyDocType.privacyPolicy:
        return 'Privacy Policy';
      case PolicyDocType.termsAndConditions:
        return 'Terms & Conditions';
      case PolicyDocType.pricingAndFees:
        return 'Pricing & Fees Policy';
      case PolicyDocType.dmcaPolicy:
        return 'DMCA & Copyright Policy';
      case PolicyDocType.aboutUs:
        return 'About Us';
    }
  }

  String get _docId {
    switch (widget.docType) {
      case PolicyDocType.termsOfService:
        return 'terms_of_service';
      case PolicyDocType.privacyPolicy:
        return 'privacy_policy';
      case PolicyDocType.termsAndConditions:
        return 'terms_and_conditions';
      case PolicyDocType.pricingAndFees:
        return 'pricing_and_fees';
      case PolicyDocType.dmcaPolicy:
        return 'dmca_policy';
      case PolicyDocType.aboutUs:
        return 'about_us';
    }
  }

  String get _assetPath => 'assets/policies/$_docId.txt';

  String get _webUrl {
    switch (widget.docType) {
      case PolicyDocType.termsOfService:
        return 'https://onlygigz.app/terms-of-service';
      case PolicyDocType.privacyPolicy:
        return 'https://onlygigz.app/privacy-policy';
      case PolicyDocType.termsAndConditions:
        return 'https://onlygigz.app/terms-and-conditions';
      case PolicyDocType.pricingAndFees:
        return 'https://onlygigz.app/pricing-and-fees';
      case PolicyDocType.dmcaPolicy:
        return 'https://onlygigz.app/dmca-policy';
      case PolicyDocType.aboutUs:
        return 'https://onlygigz.app/about-us';
    }
  }

  Future<void> _loadPolicyContent() async {
    // 1. Dynamic fetch from Cloud Firestore
    try {
      final snap = await FirebaseFirestore.instance.collection('policies').doc(_docId).get();
      if (snap.exists && snap.data() != null && snap.data()!['content'] != null) {
        final remoteContent = snap.data()!['content'] as String;
        if (remoteContent.trim().isNotEmpty && mounted) {
          setState(() {
            _rawContent = remoteContent;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Firestore policy fetch warning: $e');
    }

    // 2. Local Asset Fallback
    try {
      final loaded = await rootBundle.loadString(_assetPath);
      if (mounted) {
        setState(() {
          _rawContent = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rawContent = 'Error loading policy text. Please visit $_webUrl';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openWebPage() async {
    final uri = Uri.parse(_webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // Header with Title and Web Link button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: SvgPicture.asset(
                                  'assets/privacyterm.svg',
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFA1F301),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Effective Date: August 2026',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _openWebPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA1F301), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.language, color: Color(0xFFA1F301), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Web Link',
                              style: TextStyle(
                                color: Color(0xFFA1F301),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Policy Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1F301)),
                          ),
                        ),
                      )
                    : _buildParsedPolicyBody(_rawContent),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableWidget(String tableText) {
    final lines = tableText
        .replaceAll('TABLE_START:', '')
        .replaceAll('TABLE_END:', '')
        .split('\n')
        .where((l) => l.trim().isNotEmpty && l.contains('|'))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: lines.map((line) {
          final parts = line.split('|');
          final label = parts[0].trim();
          final val = parts.length > 1 ? parts[1].trim() : '';

          final isLink = val.contains('@') || val.contains('http') || RegExp(r'^\+?\d[\d\-\s\(\)]+$').hasMatch(val);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    val,
                    style: TextStyle(
                      color: isLink ? const Color(0xFFA1F301) : Colors.grey[300],
                      fontSize: 14,
                      fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildParsedPolicyBody(String text) {
    final normalized = text.replaceAll('\r\n', '\n');
    final blocks = normalized.split('\n\n');
    final widgets = <Widget>[];

    for (var block in blocks) {
      final b = block.trim();
      if (b.isEmpty) continue;

      // Handle Table Blocks
      if (b.contains('TABLE_START:')) {
        final tableStartIdx = b.indexOf('TABLE_START:');
        final tableEndIdx = b.indexOf('TABLE_END:');

        if (tableStartIdx > 0) {
          final introPart = b.substring(0, tableStartIdx).trim();
          if (introPart.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText(
                  introPart,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            );
          }
        }

        final tableContent = (tableEndIdx > tableStartIdx)
            ? b.substring(tableStartIdx, tableEndIdx + 'TABLE_END:'.length)
            : b.substring(tableStartIdx);

        widgets.add(_buildTableWidget(tableContent));

        if (tableEndIdx > 0 && tableEndIdx + 'TABLE_END:'.length < b.length) {
          final outroPart = b.substring(tableEndIdx + 'TABLE_END:'.length).trim();
          if (outroPart.isNotEmpty) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: SelectableText(
                  outroPart,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            );
          }
        }
        continue;
      }

      // Handle Centered Effective Date at top
      if (b.startsWith('EFFECTIVE_DATE:') || b.toLowerCase().startsWith('effective date:')) {
        final dateText = b.replaceAll('EFFECTIVE_DATE:', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: Text(
                dateText,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // Handle Footer text centered at the bottom of the screen
      if (b.startsWith('FOOTER:') || b.contains('St. Landry Parish, Louisiana')) {
        final footerText = b.replaceAll('FOOTER:', '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                footerText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      // Section Header detection
      final isHeading = (RegExp(r'^\d+\.\s+').hasMatch(b) && b.length < 100 && !b.contains('\n')) ||
          (b.toUpperCase() == b && b.length < 60 && !b.contains('.')) ||
          RegExp(r"^(Built From the Booking Problems We Lived|How It Started|What We'?re Building|Why OnlyGigz Is Different|Our Mission|Our Vision|Built for the People Who Make Live Entertainment Happen|Our Story|Who We Are|What We Do|Why OnlyGigz|Our Core Values)", caseSensitive: false).hasMatch(b);

      if (isHeading) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              b,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        );
      } else if (b.contains('•') || b.contains('●') || b.startsWith('-')) {
        // Separate intro text from bullet list if present
        final bulletIdx = b.indexOf(RegExp(r'[•●\-]'));
        String introPart = '';
        String bulletPart = b;
        if (bulletIdx > 0) {
          introPart = b.substring(0, bulletIdx).trim();
          bulletPart = b.substring(bulletIdx).trim();
        }

        if (introPart.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(
                introPart,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          );
        }

        // Render bullet lines cleanly with bold title prefixes before colon
        final lines = bulletPart.split(RegExp(r'[\n•●\-]')).where((l) => l.trim().isNotEmpty).toList();

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) {
                final cleanLine = line.trim();
                final colonIdx = cleanLine.indexOf(':');

                Widget contentWidget;
                if (colonIdx > 0 && colonIdx < cleanLine.length - 1 && colonIdx < 50) {
                  final titlePart = cleanLine.substring(0, colonIdx + 1);
                  final descPart = cleanLine.substring(colonIdx + 1);
                  contentWidget = SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: titlePart,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: descPart,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  contentWidget = SelectableText(
                    cleanLine,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: Color(0xFFA1F301),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: contentWidget),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      } else {
        // Standard Body Paragraph
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SelectableText(
              b,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
