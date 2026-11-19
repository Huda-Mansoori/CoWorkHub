import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../services/booking_api.dart';
import '../widgets/app_ui.dart';

class MemberBookingsDialog extends StatefulWidget {
  final int memberId;
  final String memberName;
  final BookingApi api;
  final Future<List<Booking>> Function()? loader;
  const MemberBookingsDialog({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.api,
    this.loader,
  });
  @override
  State<MemberBookingsDialog> createState() => _MemberBookingsDialogState();
}

class _MemberBookingsDialogState extends State<MemberBookingsDialog> {
  late Future<List<Booking>> bookings;
  Future<List<Booking>> load() =>
      widget.loader?.call() ?? widget.api.memberBookings(widget.memberId);
  void refresh() => setState(() {
    bookings = load();
  });
  @override
  void initState() {
    super.initState();
    bookings = load();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.pop(context),
    },
    child: AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      title: Text('Bookings for ${widget.memberName}'),
      content: SizedBox(
        width: 950,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .65,
          ),
          child: FutureBuilder<List<Booking>>(
            future: bookings,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ListState(
                  loading: true,
                  title: 'Loading booking history...',
                );
              }
              if (snapshot.hasError) {
                return ListState(
                  title: 'Could not load booking history.',
                  detail: displayError(snapshot.error),
                  icon: Icons.error_outline,
                  action: refresh,
                );
              }
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const ListState(
                  title: 'No bookings for this member.',
                  icon: Icons.calendar_today_outlined,
                );
              }
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
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
                                '${dateTimeLabel(booking.slot.start)}\n${dateTimeLabel(booking.slot.end)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                booking.resourceName ??
                                    'Resource #${booking.slot.resourceId}',
                              ),
                            ),
                            DataCell(StatusBadge(booking.status)),
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
        TextButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
