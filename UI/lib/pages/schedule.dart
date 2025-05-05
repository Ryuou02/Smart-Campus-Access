import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final events = {
      "Course 1": "10:00 - 10:50",
      "Course 2": "10:50 - 11:30",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule"),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar picker
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.orange[50],
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      DateFormat('EEE, MMM d').format(_selectedDay ?? _focusedDay),
                      style: TextStyle(fontSize: 20, color: Colors.blue[800]),
                    ),
                    trailing: Icon(Icons.edit, color: Colors.blue[800]),
                  ),
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(onPressed: () {}, child: Text("Cancel", style: TextStyle(color: Colors.deepOrange))),
                      TextButton(onPressed: () {}, child: Text("OK", style: TextStyle(color: Colors.deepOrange))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Course cards
            ...events.entries.map((entry) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Text("A", style: TextStyle(color: Colors.white)),
                  ),
                  title: Text(entry.key, style: TextStyle(color: Colors.blue[800])),
                  subtitle: Text(entry.value),
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}
