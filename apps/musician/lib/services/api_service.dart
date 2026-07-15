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

  Future<void> applyToGig(Map<String, dynamic> applicationData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/gigs/apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(applicationData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to apply to gig: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getApplications({String? gigId, String? musicianId}) async {
    final queryParams = <String, String>{};
    if (gigId != null) queryParams['gig_id'] = gigId;
    if (musicianId != null) queryParams['musician_id'] = musicianId;

    final uri = Uri.parse('$_baseUrl/gigs/applications/list').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load applications: ${response.body}');
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

  Future<List<Map<String, dynamic>>> getRecentActivity(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/gigs/dashboard/activity/$userId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load recent activity: ${response.body}');
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

  Future<void> createDispute(Map<String, dynamic> disputeData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/disputes/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(disputeData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create dispute: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getDisputes(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/disputes/list?user_id=$userId'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load disputes: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDispute(String disputeId) async {
    final response = await http.get(Uri.parse('$_baseUrl/disputes/$disputeId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dispute: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> onboardMusician(String musicianId, String refreshUrl, String returnUrl) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/musician/onboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'musicianId': musicianId,
        'refreshUrl': refreshUrl,
        'returnUrl': returnUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to onboard musician: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> releasePayment(String bookingId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/booking/$bookingId/release'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to release payment: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createSetupIntent(String musicianId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/organizer/setup-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'organizerId': musicianId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create setup intent: ${response.body}');
    }
  }

  Future<void> savePaymentMethod(String userId, String paymentMethodId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/organizer/save-payment-method'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'organizerId': userId,
        'paymentMethodId': paymentMethodId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save payment method: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> musicianPayout(String musicianId, double amount) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments/musician/payout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'musicianId': musicianId,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process payout: \${response.body}');
    }
  }

  Future<Map<String, dynamic>> getConnectedAccount(String musicianId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/musician/$musicianId/connected-account'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load connected account: \${response.body}');
    }
  }

  Future<Map<String, dynamic>> getWalletData(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/organizer/$userId/wallet'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wallet data: ${response.body}');
    }
  }
}
