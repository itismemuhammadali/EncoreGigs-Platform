import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../services/auth_service.dart';
import '../../services/calendar_service.dart';

class MusicianCalendarScreen extends StatefulWidget {
  const MusicianCalendarScreen({super.key});

  @override
  State<MusicianCalendarScreen> createState() => _MusicianCalendarScreenState();
}

class _MusicianCalendarScreenState extends State<MusicianCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  bool _isAgendaView = false;

  final CalendarService _calendarService = CalendarService();

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return const Color(0xFFA2F301);
      case 'UNAVAILABLE':
        return const Color(0xFFFF4D4D);
      case 'HOLD':
        return Colors.amber;
      case 'PENDING':
        return Colors.orangeAccent;
      case 'CONFIRMED':
      case 'BOOKED':
        return Colors.cyanAccent;
      case 'COMPLETED':
        return Colors.grey;
      case 'OUTSIDE_GIG':
        return Colors.purpleAccent;
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
                leading: const Icon(Icons.check_circle_outline, color: Color(0xFFA2F301)),
                title: const Text('Mark Available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Open for gig opportunities on $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _addSimpleEvent(date, 'AVAILABLE', 'Available for Gigs');
                },
              ),
              const Divider(color: Color(0xFF2A2A2F)),
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFFF4D4D)),
                title: const Text('Mark Unavailable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Block off time to prevent booking requests', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _addSimpleEvent(date, 'UNAVAILABLE', 'Unavailable');
                },
              ),
              const Divider(color: Color(0xFF2A2A2F)),
              ListTile(
                leading: const Icon(Icons.hourglass_empty, color: Colors.amber),
                title: const Text('Add Hold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Temporarily hold date for potential booking', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _addSimpleEvent(date, 'HOLD', 'Hold for Booking');
                },
              ),
              const Divider(color: Color(0xFF2A2A2F)),
              ListTile(
                leading: const Icon(Icons.music_note_outlined, color: Colors.purpleAccent),
                title: const Text('Add Outside Gig', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Log non-OnlyGigz gig (Private details hidden from organizers)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showOutsideGigDialog(date);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addSimpleEvent(DateTime date, String status, String defaultTitle) async {
    final userId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';
    final startTime = DateTime(date.year, date.month, date.day, 12, 0);
    final endTime = DateTime(date.year, date.month, date.day, 23, 59);

    final hasConflict = await _calendarService.checkConflict(userId: userId, start: startTime, end: endTime);
    if (hasConflict && mounted) {
      final proceed = await _showConflictWarningDialog(date);
      if (!proceed) return;
    }

    final newEvent = CalendarEventModel(
      id: '',
      userId: userId,
      userType: 'musician',
      source: status == 'AVAILABLE' ? 'availability_block' : 'unavailable_block',
      title: defaultTitle,
      startTime: startTime,
      endTime: endTime,
      status: status,
      privacyLevel: 'public_availability',
    );
    await _calendarService.createCalendarEvent(newEvent);
  }

  Future<bool> _showConflictWarningDialog(DateTime date) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('SCHEDULE CONFLICT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'You already have a confirmed booking or unavailable block during this date period.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D4D)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed Anyway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showOutsideGigDialog(DateTime date) async {
    final titleController = TextEditingController();
    final venueController = TextEditingController();
    final rateController = TextEditingController();
    final notesController = TextEditingController();
    final userId = Provider.of<AuthService>(context, listen: false).user?.uid ?? '';
    final dateStr = DateFormat('MM/dd/yyyy').format(date);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        title: Text('Add Outside Gig ($dateStr)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Gig/Event Name *',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA2F301))),
                ),
              ),
              TextField(
                controller: venueController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Venue / Location',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA2F301))),
                ),
              ),
              TextField(
                controller: rateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Agreed Rate',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA2F301))),
                ),
              ),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notes (Private)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA2F301))),
                ),
              ),
            ],
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
              if (titleController.text.trim().isEmpty) return;
              final nav = Navigator.of(context);
              final newEvent = CalendarEventModel(
                id: '',
                userId: userId,
                userType: 'musician',
                source: 'outside_gig',
                title: titleController.text.trim(),
                startTime: DateTime(date.year, date.month, date.day, 19, 0),
                endTime: DateTime(date.year, date.month, date.day, 22, 0),
                status: 'OUTSIDE_GIG',
                privacyLevel: 'private',
                location: venueController.text.trim(),
                rate: rateController.text.trim(),
                notes: notesController.text.trim(),
              );
              await _calendarService.createCalendarEvent(newEvent);
              nav.pop();
            },
            child: const Text('Save Gig', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          'My Availability & Calendar',
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
              // Month Header Controls
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
    final startingWeekday = firstDayOfMonth.weekday % 7;

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
                              '${evt.status} • ${evt.location ?? "Schedule Slot"}',
                              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
        child: Text('No calendar schedule entries found.', style: TextStyle(color: Colors.grey, fontSize: 14)),
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
