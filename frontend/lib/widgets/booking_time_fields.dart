// Booking time controls: stateless date/time buttons; the parent owns the selected values.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_ui.dart';

class BookingTimeFields extends StatelessWidget {
  final DateTime start, end;
  final bool busy;
  final ValueChanged<bool> onPickDate, onPickTime;
  const BookingTimeFields({
    super.key,
    required this.start,
    required this.end,
    required this.busy,
    required this.onPickDate,
    required this.onPickTime,
  });
  Widget timeField(
    String label,
    String value,
    IconData icon,
    VoidCallback action,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: busy ? null : action,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value, style: const TextStyle(color: ink)),
            ),
            const Icon(Icons.expand_more, size: 18),
          ],
        ),
      ),
    ],
  );
  List<Widget> get fields => [
    timeField(
      'Start date',
      dateLabel(start),
      Icons.calendar_today_outlined,
      () => onPickDate(true),
    ),
    timeField(
      'Start time',
      timeLabel(start),
      Icons.schedule,
      () => onPickTime(true),
    ),
    timeField(
      'End date',
      dateLabel(end),
      Icons.calendar_today_outlined,
      () => onPickDate(false),
    ),
    timeField(
      'End time',
      timeLabel(end),
      Icons.schedule,
      () => onPickTime(false),
    ),
  ];

  @override
  Widget build(BuildContext context) => FieldGrid(children: fields);
}
