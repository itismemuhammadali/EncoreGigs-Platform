import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  
  String get _backendUrl => getBackendUrl();

  User? _user;
  User? get user => _user;

  FirebaseStorage _resolveStorage() {
    return FirebaseStorage.instance;
  }

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    debugPrint('--- Signin Started ---');
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];
        
        if (role != 'organizer') {
          return 'Access denied. This account is a $role account. Please use the appropriate app.';
        }

        // Sign in to Firebase on the client using the ID token from the backend
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return null;
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        if (detail is List) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        String message = detail?.toString() ?? 'Sign in failed';
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
Future<String?> confirmBooking({
  required String gigId,
  required String gigTitle,
  required String musicianId,
  required String musicianName,
  required String organizerName,
  required String location,
  required double amount,
  required String signatureUrl,
  required String gigDate,
  required String gigTime,
  String? duration,
  Map<String, String>? sections,
}) async {
  final String? uid = _auth.currentUser?.uid;
  if (uid == null) return 'User not authenticated';

  try {
    await _apiService.confirmBooking({
      'gigId': gigId,
      'gigTitle': gigTitle,
      'musicianId': musicianId,
      'musicianName': musicianName,
      'organizerId': uid,
      'organizerName': organizerName,
      'location': location,
      'amount': amount,
      'signatureUrl': signatureUrl,
      'gigDate': gigDate,
      'gigTime': gigTime,
      'duration': duration,
      'sections': sections,
    });    return null;
  } catch (e) {
    return e.toString();
  }
}

  Future<String?> uploadImage(File file, String path) async {
    try {
      final FirebaseStorage storage = _resolveStorage();
      final ref = storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String orgName,
    required String type,
    required String contact,
    required String location,
    required String bio,
  }) async {
    debugPrint('--- Signup Started ---');
    debugPrint('Backend URL: $_backendUrl');
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'orgName': orgName,
          'type': type,
          'contact': contact,
          'location': location,
          'bio': bio,
        }),
      );

      debugPrint('Response Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // After successful backend signup, sign in on the client
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        return null;
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        if (detail is List) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        return detail?.toString() ?? 'Sign up failed';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createGig({
    required String title,
    required String description,
    required List<String> requirements,
    required List<String> genres,
    required String date,
    required String time,
    required String budget,
    required String location,
    String? imageUrl,
    String? duration,
  }) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) return 'User not authenticated';

    try {
      await _apiService.createGig({
        'title': title,
        'description': description,
        'requirements': requirements,
        'genres': genres,
        'date': date,
        'time': time,
        'budget': budget,
        'location': location,
        'organizerId': uid,
        'imageUrl': imageUrl,
        'duration': duration,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      return await _apiService.getProfile(uid);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<String?> updateProfile({
    required String uid,
    required String name,
    required String email,
    required String contact,
    required String location,
    required String bio,
    String? profileImageUrl,
  }) async {
    try {
      await _apiService.updateProfile({
        'uid': uid,
        'name': name,
        'email': email,
        'contact': contact,
        'location': location,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
      });
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateOrganization({
    required String uid,
    required String orgName,
    required String type,
    required String businessEmail,
    required String businessPhone,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    required String website,
    required String taxId,
    required String description,
    String? licenseUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/organization/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'orgName': orgName,
          'type': type,
          'businessEmail': businessEmail,
          'businessPhone': businessPhone,
          'address': address,
          'city': city,
          'state': state,
          'zipCode': zipCode,
          'website': website,
          'taxId': taxId,
          'description': description,
          'licenseUrl': licenseUrl,
        }),
      );

      if (response.statusCode == 200) {
        notifyListeners();
        return null;
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        if (detail is List) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        return detail?.toString() ?? 'Failed to update organization';
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
