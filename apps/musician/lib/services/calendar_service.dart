import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream calendar events for a specific musician
  Stream<List<CalendarEventModel>> streamUserEvents(String userId) {
    return _firestore
        .collection('calendar_events')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CalendarEventModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Create a new calendar event (Available, Unavailable, Hold, Outside Gig)
  Future<String?> createCalendarEvent(CalendarEventModel event) async {
    try {
      final docRef = await _firestore.collection('calendar_events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Update calendar event
  Future<void> updateCalendarEvent(String eventId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('calendar_events').doc(eventId).update(data);
  }

  // Delete calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    await _firestore.collection('calendar_events').doc(eventId).delete();
  }

  // Schedule Conflict Detection
  Future<bool> checkConflict({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('calendar_events')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final event = CalendarEventModel.fromFirestore(doc.data(), doc.id);
        const blockingStatuses = {'CONFIRMED', 'OUTSIDE_GIG', 'UNAVAILABLE', 'HOLD'};
        if (blockingStatuses.contains(event.status)) {
          if (start.isBefore(event.endTime) && end.isAfter(event.startTime)) {
            return true; // Conflict detected
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
