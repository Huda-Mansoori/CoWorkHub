import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_api.dart';

class MemberBookingsDialog extends StatefulWidget {
  final int memberId;
  final String memberName;
  final BookingApi api;

  const MemberBookingsDialog({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.api,
  });

  @override
  State<MemberBookingsDialog> createState() => _MemberBookingsDialogState();
}

class _MemberBookingsDialogState extends State<MemberBookingsDialog> {
  late Future<List<Booking>> bookings;

  @override
  void initState() {
    super.initState();
    bookings = widget.api.memberBookings(widget.memberId);
  }

  String date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bookings for ${widget.memberName}'),
      content: SizedBox(
        width: 900,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 480),
          child: FutureBuilder<List<Booking>>(
            future: bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Could not load booking history.'),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        bookings = widget.api.memberBookings(widget.memberId);
                      }),
                      child: const Text('Retry'),
                    ),
                  ],
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Text('No bookings for this member.');
              }
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Date and time')),
                      DataColumn(label: Text('Resource')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Total (QAR)'), numeric: true),
                    ],
                    rows: [
                      for (final booking in rows)
                        DataRow(
                          key: ValueKey(booking.id),
                          cells: [
                            DataCell(
                              Text(
                                '${date(booking.slot.start)}\n${date(booking.slot.end)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                booking.resourceName ??
                                    'Resource #${booking.slot.resourceId}',
                              ),
                            ),
                            DataCell(Text(booking.status)),
                            DataCell(Text(booking.cost.toStringAsFixed(2))),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
