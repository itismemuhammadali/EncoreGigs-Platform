import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';
import '../models/gig.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream calendar events for a specific user
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

  // Create a new calendar event
  Future<String?> createCalendarEvent(CalendarEventModel event) async {
    try {
      final docRef = await _firestore.collection('calendar_events').add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Update existing calendar event
  Future<void> updateCalendarEvent(String eventId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('calendar_events').doc(eventId).update(data);
  }

  // Delete calendar event
  Future<void> deleteCalendarEvent(String eventId) async {
    await _firestore.collection('calendar_events').doc(eventId).delete();
  }

  // Sync Gig post automatically to Calendar
  Future<void> syncGigToCalendar({required GigModel gig, required String status}) async {
    try {
      final existingDocs = await _firestore
          .collection('calendar_events')
          .where('gigId', isEqualTo: gig.gigId)
          .where('userId', isEqualTo: gig.organizerId)
          .get();

      // Parse Gig Date and Time
      DateTime startTime = DateTime.now();
      DateTime endTime = DateTime.now().add(const Duration(hours: 3));

      try {
        final dateParts = gig.date.split('/');
        if (dateParts.length == 3) {
          final month = int.parse(dateParts[0]);
          final day = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          startTime = DateTime(year, month, day, 19, 0); // Default to 7 PM if unparsed
          endTime = startTime.add(const Duration(hours: 3));
        }
      } catch (_) {}

      if (existingDocs.docs.isNotEmpty) {
        final docId = existingDocs.docs.first.id;
        await updateCalendarEvent(docId, {
          'title': gig.title,
          'status': status,
          'location': gig.location,
          'rate': gig.budget,
        });
      } else {
        final newEvent = CalendarEventModel(
          id: '',
          userId: gig.organizerId,
          userType: 'organizer',
          source: 'onlygigz_gig',
          gigId: gig.gigId,
          title: gig.title,
          startTime: startTime,
          endTime: endTime,
          status: status,
          privacyLevel: 'private',
          location: gig.location,
          rate: gig.budget,
        );
        await createCalendarEvent(newEvent);
      }
    } catch (_) {}
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
        const blockingStatuses = {'CONFIRMED', 'OUTSIDE_GIG', 'UNAVAILABLE', 'HOLD', 'BOOKED'};
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
