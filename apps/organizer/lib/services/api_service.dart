import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';

class ApiService {
  String get _baseUrl => getBackendUrl();

  Future<List<Map<String, dynamic>>> getGigs({String? status, String? organizerId, String? searchQuery}) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (organizerId != null) queryParams['organizer_id'] = organizerId;
    if (searchQuery != null) queryParams['search_query'] = searchQuery;

    final uri = Uri.parse('$_baseUrl/gigs/list').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load gigs: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getGig(String gigId) async {
    final response = await http.get(Uri.parse('$_baseUrl/gigs/$gigId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load gig: ${response.body}');
    }
  }

  Future<void> createGig(Map<String, dynamic> gigData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/gigs/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(gigData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create gig: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getApplications({String? gigId, String? musicianId, String? organizerId, String? status}) async {
    final queryParams = <String, String>{};
    if (gigId != null) queryParams['gig_id'] = gigId;
    if (musicianId != null) queryParams['musician_id'] = musicianId;
    if (organizerId != null) queryParams['organizer_id'] = organizerId;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$_baseUrl/gigs/applications/list').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load applications: ${response.body}');
    }
  }

  Future<void> confirmBooking(Map<String, dynamic> bookingData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bookings/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bookingData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm booking: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getBookings({String? musicianId, String? organizerId}) async {
    final queryParams = <String, String>{};
    if (musicianId != null) queryParams['musician_id'] = musicianId;
    if (organizerId != null) queryParams['organizer_id'] = organizerId;

    final uri = Uri.parse('$_baseUrl/bookings/list').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load bookings: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProfile(String uid) async {
    final response = await http.get(Uri.parse('$_baseUrl/auth/profile/$uid'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/profile/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getReviews(String musicianId) async {
    final response = await http.get(Uri.parse('$_baseUrl/gigs/reviews/$musicianId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reviews: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String organizerId) async {
    final response = await http.get(Uri.parse('$_baseUrl/gigs/dashboard/stats/$organizerId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(String organizerId) async {
    final response = await http.get(Uri.parse('$_baseUrl/gigs/dashboard/activity/$organizerId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load recent activity: ${response.body}');
    }
  }

  Future<String> getOrCreateChat(Map<String, dynamic> chatData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/get-or-create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(chatData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['chatId'];
    } else {
      throw Exception('Failed to get or create chat: ${response.body}');
    }
  }

  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/send-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messageData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/gigs/applications/$applicationId/status').replace(queryParameters: {'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update application status: ${response.body}');
    }
  }
}
