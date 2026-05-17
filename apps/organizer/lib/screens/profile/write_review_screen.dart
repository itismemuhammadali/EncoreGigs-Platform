import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_submitted_screen.dart';

class WriteReviewScreen extends StatefulWidget {
  final String bookingId;
  final String musicianId;
  final String musicianName;
  final String gigTitle;
  final String imagePath;

  const WriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.musicianId,
    required this.musicianName,
    required this.gigTitle,
    required this.imagePath,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _reviewController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildMusicianImage() {
    if (_isNetworkImage(widget.imagePath)) {
      return Image.network(
        widget.imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
      );
    } else {
      return Image.asset(
        widget.imagePath,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
      );
    }
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white54, size: 40),
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create review document
      await FirebaseFirestore.instance.collection('reviews').add({
        'bookingId': widget.bookingId,
        'musicianId': widget.musicianId,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'gigTitle': widget.gigTitle,
      });

      // 2. Update booking document with rating and final status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'rating': _rating.toDouble(),
        'reviewText': _reviewController.text.trim(),
        'status': 'completed', // Final status after review
      });

      // 3. Update musician's average rating
      final musicianRef = FirebaseFirestore.instance.collection('musicians').doc(widget.musicianId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final musicianDoc = await transaction.get(musicianRef);
        if (!musicianDoc.exists) return;

        final data = musicianDoc.data() as Map<String, dynamic>;
        final double currentRating = (data['averageRating'] ?? 0.0).toDouble();
        final int currentCount = (data['reviewCount'] ?? 0).toInt();

        final int newCount = currentCount + 1;
        final double newRating = ((currentRating * currentCount) + _rating) / newCount;

        transaction.update(musicianRef, {
          'averageRating': newRating,
          'reviewCount': newCount,
        });
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ReviewSubmittedScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Musician info
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: _buildMusicianImage(),
              ),
              const SizedBox(height: 12),
              Text(
                widget.musicianName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.gigTitle,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
              ),
              const SizedBox(height: 28),
              // Rating section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'How was your experience?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star,
                              size: 40,
                              color: index < _rating
                                  ? const Color(0xFFA2F301)
                                  : const Color(0xFF2A2A2F),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRatingText(),
                      style: const TextStyle(
                        color: Color(0xFFA2F301),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Review text
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Share your experience (Optional)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Tell us about the performance, professionalism, punctuality...',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA2F301)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1AA2F301),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA2F301)),
                ),
                child: const Text(
                  'Your review helps other organizers make informed decisions and helps musicians build their reputation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: _isSubmitting ? null : _submitReview,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isSubmitting ? const Color(0xFF2A2A2F) : const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSubmitting
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
                : const Text(
                    'Submit Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great!';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
