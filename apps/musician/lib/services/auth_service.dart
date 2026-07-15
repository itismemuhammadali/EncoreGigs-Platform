import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _backendUrl => getBackendUrl();

  User? _user;
  User? get user => _user;
  User? get currentUser => _user;

  List<String> _appliedGigIds = [];
  List<String> get appliedGigIds => _appliedGigIds;

  FirebaseStorage _resolveStorage() {
    return FirebaseStorage.instance;
  }

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        refreshAppliedGigs();
      } else {
        _appliedGigIds = [];
      }
      notifyListeners();
    });
  }

  final ApiService _apiService = ApiService();

  Future<void> refreshAppliedGigs() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final applications = await _apiService.getApplications(musicianId: uid);
      _appliedGigIds = applications.map((app) => app['gigId'] as String).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing applied gigs: $e');
    }
  }

  String _handleError(http.Response response, String defaultMessage) {
    try {
      final data = jsonDecode(response.body);
      final detail = data['detail'];
      if (detail is List) {
        return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
      }
      return detail?.toString() ?? defaultMessage;
    } catch (_) {
      return defaultMessage;
    }
  }

  Future<String?> signIn(String email, String password) async {
    debugPrint('--- Signin Started ---');
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        
        if (role != 'musician') {
          return 'Access denied. This account is an $role account. Please use the appropriate app.';
        }

        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return null;
      } else {
        String message = _handleError(response, 'Sign in failed');
        if (message.contains('EMAIL_NOT_FOUND')) {
          message = 'User not found. Please sign up.';
        } else if (message.contains('INVALID_PASSWORD')) {
          message = 'Invalid password.';
        }
        return message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<UserCredential?> _signInWithGoogleCredential() async {
    final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithAppleCredential() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await _auth.signInWithCredential(oauthCredential);
  }

  Future<String?> _handleSocialSignIn(UserCredential userCredential, String provider) async {
    final user = userCredential.user;
    if (user == null) return 'Sign in failed';

    final doc = await FirebaseFirestore.instance.collection('musicians').doc(user.uid).get();
    if (doc.exists) {
      return null;
    }

    await FirebaseFirestore.instance.collection('musicians').doc(user.uid).set({
      'email': user.email,
      'fullName': user.displayName ?? '',
      'profileImageUrl': user.photoURL ?? '',
      'authProvider': provider,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return 'new_user';
  }

  Future<String?> signInWithGoogle() async {
    try {
      final credential = await _signInWithGoogleCredential();
      if (credential == null) return 'Google sign in was cancelled';
      return await _handleSocialSignIn(credential, 'google');
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithApple() async {
    try {
      final credential = await _signInWithAppleCredential();
      if (credential == null) return 'Apple sign in was cancelled';
      return await _handleSocialSignIn(credential, 'apple');
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> uploadImage(File file, String path) async {
    debugPrint('AuthService: Starting upload to $path...');
    try {
      final storage = _resolveStorage();
      final ref = storage.ref().child(path);
      
      // Explicitly wait for the upload to complete
      final TaskSnapshot snapshot = await ref.putFile(file).timeout(const Duration(minutes: 5));
      
      if (snapshot.state == TaskState.success) {
        // Small delay for the emulator
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final url = await ref.getDownloadURL();
          debugPrint('AuthService: Upload success, URL: $url');
          return url;
        } catch (e) {
          debugPrint('AuthService: getDownloadURL failed, constructing emulator URL manually...');
          // Fallback for emulator: Manually construct the URL
          // Format: http://<host>:<port>/v0/b/<bucket>/o/<path>?alt=media
          final host = getEmulatorHost();
          final bucket = "demo-onlygigz.appspot.com";
          final encodedPath = Uri.encodeComponent(path);
          final manualUrl = "http://$host:9199/v0/b/$bucket/o/$encodedPath?alt=media";
          debugPrint('AuthService: Manual Emulator URL: $manualUrl');
          return manualUrl;
        }
      } else {
        debugPrint('AuthService: Upload failed with state: ${snapshot.state}');
        return null;
      }
    } catch (e) {
      debugPrint('AuthService: Upload Error at $path: $e');
      return null;
    }
  }

  Future<String?> uploadData(Uint8List data, String path) async {
    debugPrint('AuthService: Uploading data to $path...');
    try {
      final FirebaseStorage storage = _resolveStorage();
      debugPrint('Using Storage Bucket: ${storage.bucket}');
      final ref = storage.ref().child(path);
      final uploadTask = await ref.putData(data, SettableMetadata(contentType: 'image/png'));
      final url = await uploadTask.ref.getDownloadURL();
      debugPrint('AuthService: Upload success, URL: $url');
      return url;
    } catch (e) {
      debugPrint('AuthService: Upload Error: $e');
      throw Exception('Storage Upload Failed: $e');
    }
  }

  Future<String?> signUpMusician({
    required String email,
    required String password,
    required String fullName,
    required String bio,
    required List<String> genres,
    required List<String> instruments,
    required int feeRange,
    required int yearsOfExperience,
    required String location,
    String? website,
    Map<String, dynamic>? portfolio,
    File? profileImage,
  }) async {
    debugPrint('--- Musician Signup Started ---');
    try {
      String? profileImageUrl;
      if (profileImage != null) {
        debugPrint('Uploading profile image...');
        profileImageUrl = await uploadImage(
          profileImage,
          'profile_photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      // Upload portfolio files
      Map<String, List<String>> portfolioUrls = {
        'images': [],
        'videos': [],
        'audioTracks': [],
      };

      if (portfolio != null) {
        for (var type in ['images', 'videos', 'audioTracks']) {
          if (portfolio[type] != null) {
            final files = portfolio[type] as List<dynamic>;
            if (files.isNotEmpty) {
              debugPrint('Uploading ${files.length} $type...');
              for (var file in files) {
                if (file is File) {
                  final fileName = file.path.split('/').last;
                  final url = await uploadImage(
                    file,
                    'portfolios/$type/${DateTime.now().millisecondsSinceEpoch}_$fileName',
                  );
                  if (url != null) {
                    portfolioUrls[type]!.add(url);
                  }
                }
              }
            }
          }
        }
      }

      debugPrint('Sending signup request to backend...');
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/signup/musician'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'bio': bio,
          'genres': genres,
          'instruments': instruments,
          'feeRange': feeRange,
          'yearsOfExperience': yearsOfExperience,
          'location': location,
          'website': website,
          'portfolio': portfolioUrls,
          'profileImageUrl': profileImageUrl,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return null;
      } else {
        return _handleError(response, 'Sign up failed');
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/auth/profile/$uid'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> applyToGig({
    required String gigId,
    required String gigTitle,
    required String organizerId,
    required String organizerName,
    required String gigDate,
    String? gigTime,
    String? duration,
    String? proposedRate,
    String? coverMessage,
    List<String>? attachments,
  }) async {
    debugPrint('--- Apply to Gig Started ---');
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/gigs/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gigId': gigId,
          'gigTitle': gigTitle,
          'musicianId': uid,
          'organizerId': organizerId,
          'organizerName': organizerName,
          'gigDate': gigDate,
          'gigTime': gigTime,
          'duration': duration,
          'proposedRate': proposedRate,
          'coverMessage': coverMessage,
          'attachments': attachments ?? [],
          'status': 'pending',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _appliedGigIds.add(gigId);
        notifyListeners();
        return null;
      } else {
        return _handleError(response, 'Failed to submit application');
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePortfolioItem({
    required String oldUrl,
    required String newUrl,
    required String type,
    String? title,
    String? description,
    String? externalUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      final docRef = FirebaseFirestore.instance.collection('musicians').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return 'Profile not found';

      final data = doc.data() as Map<String, dynamic>;
      final portfolio = data['portfolio'] as Map<String, dynamic>? ?? {};
      
      String fieldKey = '';
      if (type == 'image') {
        fieldKey = 'images';
      } else if (type == 'video') fieldKey = 'videos';
      else if (type == 'music') fieldKey = 'audioTracks';

      if (fieldKey.isEmpty) return 'Invalid item type';

      List<dynamic> items = List.from(portfolio[fieldKey] ?? []);
      
      // Find the item to update (could be a String or Map)
      int foundIndex = -1;
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (item is String && item == oldUrl) {
          foundIndex = i;
          break;
        } else if (item is Map && item['url'] == oldUrl) {
          foundIndex = i;
          break;
        }
      }

      final newItemData = {
        'url': newUrl,
        'title': title ?? '',
        'description': description ?? '',
        'externalUrl': externalUrl ?? '',
      };

      if (foundIndex != -1) {
        items[foundIndex] = newItemData;
      } else {
        // If not found (shouldn't happen on edit), add it
        items.add(newItemData);
      }

      portfolio[fieldKey] = items;
      await docRef.update({'portfolio': portfolio});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deletePortfolioItem({
    required String url,
    required String type,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      final docRef = FirebaseFirestore.instance.collection('musicians').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return 'Profile not found';

      final data = doc.data() as Map<String, dynamic>;
      final portfolio = data['portfolio'] as Map<String, dynamic>? ?? {};
      
      String fieldKey = '';
      if (type == 'image') {
        fieldKey = 'images';
      } else if (type == 'video') fieldKey = 'videos';
      else if (type == 'music') fieldKey = 'audioTracks';

      if (fieldKey.isEmpty) return 'Invalid item type';

      List<dynamic> items = List.from(portfolio[fieldKey] ?? []);
      
      items.removeWhere((item) {
        if (item is String) return item == url;
        if (item is Map) return item['url'] == url;
        return false;
      });

      portfolio[fieldKey] = items;
      await docRef.update({'portfolio': portfolio});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> addPortfolioItem({
    required String type,
    String? url,
    File? file,
    required String title,
    required String description,
    String? externalUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      String finalUrl = url ?? '';
      
      if (file != null) {
        final fileName = file.path.split('/').last;
        final path = 'portfolios/$type/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final uploadUrl = await uploadImage(file, path);
        if (uploadUrl == null) return 'Failed to upload file';
        finalUrl = uploadUrl;
      }

      final docRef = FirebaseFirestore.instance.collection('musicians').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return 'Profile not found';

      final data = doc.data() as Map<String, dynamic>;
      final portfolio = data['portfolio'] as Map<String, dynamic>? ?? {};
      
      String fieldKey = '';
      if (type == 'image') {
        fieldKey = 'images';
      } else if (type == 'video') fieldKey = 'videos';
      else if (type == 'music') fieldKey = 'audioTracks';

      if (fieldKey.isEmpty) return 'Invalid item type';

      List<dynamic> items = List.from(portfolio[fieldKey] ?? []);
      items.add({
        'url': finalUrl,
        'title': title,
        'description': description,
        'externalUrl': externalUrl ?? '',
        'createdAt': Timestamp.now(),
      });

      portfolio[fieldKey] = items;
      await docRef.update({'portfolio': portfolio});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      return await _apiService.getApplications(musicianId: uid);
    } catch (e) {
      debugPrint('Error fetching applications: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGigsByOrganizer(String organizerId) async {
    try {
      return await _apiService.getGigs(organizerId: organizerId);
    } catch (e) {
      debugPrint('Error fetching gigs by organizer: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGig(String gigId) async {
    try {
      return await _apiService.getGig(gigId);
    } catch (e) {
      debugPrint('Error fetching gig: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> sendVerificationEmail(String email) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user signed in';
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/send-verification-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'id_token': idToken}),
      );
      if (response.statusCode == 200) return null;
      final data = jsonDecode(response.body);
      return data['detail']?.toString() ?? 'Failed to send verification email';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/check-email-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email_verified'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> createUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/create-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return null;
      }
      final data = jsonDecode(response.body);
      return data['detail']?.toString() ?? 'Failed to create account';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createDispute({
    required String bookingId,
    required String category,
    required String description,
    required List<String> attachments,
    required String reporterRole,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'User not authenticated';

      await _apiService.createDispute({
        'bookingId': bookingId,
        'reporterId': uid,
        'reporterRole': reporterRole,
        'category': category,
        'description': description,
        'attachments': attachments,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> getDisputes() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return [];
      return await _apiService.getDisputes(uid);
    } catch (e) {
      debugPrint('Error fetching disputes: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDispute(String disputeId) async {
    try {
      return await _apiService.getDispute(disputeId);
    } catch (e) {
      debugPrint('Error fetching dispute: $e');
      return null;
    }
  }

  Future<String?> updateProfilePicture(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      final String path = 'profile_photos/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String? imageUrl = await uploadImage(imageFile, path);
      
      if (imageUrl == null) return 'Failed to upload image';

      // Update Firestore
      await FirebaseFirestore.instance.collection('musicians').doc(uid).update({
        'profileImageUrl': imageUrl,
      });

      return null;
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
      return e.toString();
    }
  }
}
