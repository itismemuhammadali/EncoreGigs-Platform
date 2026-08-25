import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../models/gig.dart';
import '../../services/auth_service.dart';
import '../../services/calendar_service.dart';
import '../gigs/gig_details_screen.dart';
import '../gigs/post_gig_screen.dart';

class OrganizerCalendarScreen extends StatefulWidget {
  const OrganizerCalendarScreen({super.key});

  @override
  State<OrganizerCalendarScreen> createState() => _OrganizerCalendarScreenState();
}

class _OrganizerCalendarScreenState extends State<OrganizerCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  bool _isAgendaView = false;

  final CalendarService _calendarService = CalendarService();

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN_DATE':
        return Colors.orangeAccent;
      case 'POSTED':
        return const Color(0xFFA2F301);
      case 'REVIEWING':
        return Colors.amber;
      case 'BOOKED':
      case 'CONFIRMED':
        return Colors.cyanAccent;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.redAccent;
      default:
        return const Color(0xFFA2F301);
    }
  }

  void _onEmptyDateTapped(DateTime date) {
    final dateStr = DateFormat('MM/dd/yyyy').format(date);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Action — ${DateFormat('MMM dd, yyyy').format(date)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Color(0xFFA2F301)),
                title: const Text('Post a Gig', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Create a new opportunity on $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostGigScreen(
                        gigToEdit: GigModel(
                          gigId: '',
                          title: '',
                          description: '',
                          requirements: [],
                          genres: [],
                          date: dateStr,
                          time: '',
                          budget: '',
                          location: '',
                          organizerId: '',
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(color: Color(0xFF2A2A2F)),
              ListTile(
                leading: const Icon(Icons.event_note, color: Colors.cyanAccent),
                title: const Text('Add Existing Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Log an offline event on this date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddEventDialog(date, 'BOOKED');
                },
              ),
              const Divider(color: Color(0xFF2A2A2F)),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: const Text('Block Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Mark venue unavailable for bookings', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddEventDialog(date, 'UNAVAILABLE');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddEventDialog(DateTime date, String status) async {
    final titleController = TextEditingController(text: status == 'UNAVAILABLE' ? 'Venue Unavailable' : 'Private Booking');
    final dateStr = DateFormat('MM/dd/yyyy').format(date);
    final userId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: Text(
          status == 'UNAVAILABLE' ? 'Block Date ($dateStr)' : 'Add Booking ($dateStr)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Event Title',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA2F301))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA2F301)),
            onPressed: () async {
              final nav = Navigator.of(context);
              final newEvent = CalendarEventModel(
                id: '',
                userId: userId,
                userType: 'organizer',
                source: status == 'UNAVAILABLE' ? 'unavailable_block' : 'outside_gig',
                title: titleController.text.trim(),
                startTime: DateTime(date.year, date.month, date.day, 19, 0),
                endTime: DateTime(date.year, date.month, date.day, 22, 0),
                status: status,
              );
              await _calendarService.createCalendarEvent(newEvent);
              nav.pop();
            },
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Entertainment Schedule',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isAgendaView ? Icons.calendar_month : Icons.view_agenda_outlined,
              color: const Color(0xFFA2F301),
            ),
            tooltip: _isAgendaView ? 'Month View' : 'Agenda View',
            onPressed: () => setState(() => _isAgendaView = !_isAgendaView),
          ),
        ],
      ),
      body: StreamBuilder<List<CalendarEventModel>>(
        stream: _calendarService.streamUserEvents(userId),
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          final eventsMap = <String, List<CalendarEventModel>>{};

          for (final evt in events) {
            final dateKey = DateFormat('yyyy-MM-dd').format(evt.startTime);
            eventsMap.putIfAbsent(dateKey, () => []).add(evt);
          }

          return Column(
            children: [
              // Month Controls Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (!_isAgendaView) ...[
                // Days of week header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Sun', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Mon', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Tue', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Wed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Thu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Fri', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Sat', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                // Calendar Grid
                Expanded(
                  child: _buildMonthGrid(eventsMap),
                ),
              ] else
                // Agenda List View
                Expanded(
                  child: _buildAgendaList(events),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthGrid(Map<String, List<CalendarEventModel>> eventsMap) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final totalCells = startingWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        if (index < startingWeekday || index >= totalCells) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startingWeekday + 1;
        final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
        final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
        final dayEvents = eventsMap[dateKey] ?? [];

        final isToday = cellDate.year == DateTime.now().year &&
            cellDate.month == DateTime.now().month &&
            cellDate.day == DateTime.now().day;

        return GestureDetector(
          onTap: () {
            if (dayEvents.isNotEmpty) {
              _showDateEventsBottomSheet(cellDate, dayEvents);
            } else {
              _onEmptyDateTapped(cellDate);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFA2F301)
                    : (dayEvents.isNotEmpty ? const Color(0xFF2A2A2F) : Colors.transparent),
                width: isToday ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: isToday ? const Color(0xFFA2F301) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (dayEvents.isNotEmpty)
                  Column(
                    children: dayEvents.take(2).map((evt) {
                      final color = _getStatusColor(evt.status);
                      return Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: color, width: 0.5),
                        ),
                        child: Text(
                          evt.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateEventsBottomSheet(DateTime date, List<CalendarEventModel> dayEvents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(date),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFFA2F301)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _onEmptyDateTapped(date);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...dayEvents.map((evt) {
                final color = _getStatusColor(evt.status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(evt.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              '${evt.status} • ${evt.location ?? "Venue"}',
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      if (evt.gigId != null)
                        TextButton(
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            nav.pop();
                            final gigDoc = await FirebaseFirestore.instance.collection('gigs').doc(evt.gigId).get();
                            if (gigDoc.exists) {
                              final gig = GigModel.fromFirestore(gigDoc.data()!, gigDoc.id);
                              nav.push(MaterialPageRoute(builder: (_) => GigDetailsScreen(gig: gig)));
                            }
                          },
                          child: const Text('View', style: TextStyle(color: Color(0xFFA2F301))),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgendaList(List<CalendarEventModel> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('No schedule items found.', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    events.sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final evt = events[index];
        final color = _getStatusColor(evt.status);
        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(evt.startTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2F)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      evt.status,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(evt.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              if (evt.location != null) ...[
                const SizedBox(height: 4),
                Text(evt.location!, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ],
          ),
        );
      },
    );
  }
}
