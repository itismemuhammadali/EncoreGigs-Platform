import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'musician_profile_screen.dart';

class MusicianSearchScreen extends StatefulWidget {
  const MusicianSearchScreen({super.key});

  @override
  State<MusicianSearchScreen> createState() => _MusicianSearchScreenState();
}

class _MusicianSearchScreenState extends State<MusicianSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGenre;
  
  static const List<String> _genreFilters = [
    'All',
    'Rock',
    'Pop',
    'Jazz',
    'Country',
    'Hip Hop',
    'R&B',
    'Electronic',
    'Latin',
    'Blues',
    'Classical',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
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
          'Find Talent',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x4DA2F301), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0A0A0F),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by musician name, instrument, or location...',
                      hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFA2F301)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Color(0xFF666666)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1A1A1F),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 12),
                  
                  // Genre Filters
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _genreFilters.length,
                      itemBuilder: (context, index) {
                        final genre = _genreFilters[index];
                        final isSelected = (_selectedGenre == null && genre == 'All') ||
                            _selectedGenre == genre;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGenre = genre == 'All' ? null : genre;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Musician List Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'musician')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading musicians: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFA2F301)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['fullName'] ?? data['name'] ?? '').toString().toLowerCase();
                    final location = (data['location'] ?? '').toString().toLowerCase();
                    final instruments = (data['instruments'] is List)
                        ? (data['instruments'] as List).join(' ').toLowerCase()
                        : (data['instruments'] ?? '').toString().toLowerCase();
                    final genres = (data['genres'] is List)
                        ? (data['genres'] as List).map((e) => e.toString()).toList()
                        : <String>[];

                    // Text search filter
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matches = name.contains(q) || location.contains(q) || instruments.contains(q);
                      if (!matches) return false;
                    }

                    // Genre filter
                    if (_selectedGenre != null) {
                      final hasGenre = genres.any((g) => g.toLowerCase() == _selectedGenre!.toLowerCase());
                      if (!hasGenre) return false;
                    }

                    return true;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, color: Color(0xFF666666), size: 48),
                          SizedBox(height: 12),
                          Text(
                            'No musicians found matching your search.',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['fullName'] ?? data['name'] ?? 'Musician';
                      final profileImage = data['profileImage'] ?? data['photoUrl'];
                      final location = data['location'] ?? 'Location N/A';
                      final instrumentsList = (data['instruments'] is List)
                          ? (data['instruments'] as List).join(', ')
                          : (data['instruments'] ?? 'Musician').toString();
                      final genresList = (data['genres'] is List)
                          ? (data['genres'] as List).take(3).join(', ')
                          : '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MusicianProfileScreen(musicianId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2A2A2F)),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF2A2A2F),
                                backgroundImage: (profileImage != null &&
                                        (profileImage.startsWith('http://') ||
                                            profileImage.startsWith('https://')))
                                    ? NetworkImage(profileImage)
                                    : null,
                                child: (profileImage == null ||
                                        !(profileImage.startsWith('http://') ||
                                            profileImage.startsWith('https://')))
                                    ? const Icon(Icons.person, color: Color(0xFFA2F301), size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      instrumentsList,
                                      style: const TextStyle(
                                        color: Color(0xFFA2F301),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (genresList.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        genresList,
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined,
                                            color: Color(0xFF666666), size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: const TextStyle(
                                              color: Color(0xFF666666),
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(Icons.chevron_right, color: Color(0xFF666666)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
