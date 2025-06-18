import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trig_tok/utils/streak_counter.dart';

class StreakDialog extends StatefulWidget {
  const StreakDialog({super.key});

  @override
  State<StreakDialog> createState() => _StreakDialogState();
}

class _StreakDialogState extends State<StreakDialog> {
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your Streak Calendar 🔥'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your streak is the number of consecutive days you have studied a subject. Keep it going to maintain your streak!',
            ),
            FutureBuilder(
              future: StreakCounter.getStreaks(),
              builder: (context, snapshot) {
                if (snapshot.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) {
                    return snapshot.data!.any(
                      (streak) => isSameDay(streak, day),
                    );
                  },
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  weekendDays: const [],
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Close')),
      ],
    );
  }
}
