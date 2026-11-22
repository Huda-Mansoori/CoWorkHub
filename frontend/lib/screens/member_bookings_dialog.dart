// Member history dialog: loads one member's persisted bookings with explicit four-state feedback.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../services/booking_api.dart';
import '../widgets/app_ui.dart';

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
  List<Booking> bookings = [];
  bool isLoading = true;
  String? errorMessage;
  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  // TRACE: member history -> BookingApi.fetchByMember -> GET /api/bookings/member/{id}
  // -> BookingController.getMemberBookings -> BookingService.getBookingsByMember
  // -> BookingRepository.findByMemberId -> MySQL <- 200 JSON -> Booking.fromJson -> setState -> table.
  Future<void> loadBookings() async {
    // Rebuild the dialog when loading, error or the displayed list changes.
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await widget.api.fetchByMember(widget.memberId);
      // The dialog may have closed while the request was running.
      if (!mounted) return;
      setState(() {
        bookings = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = displayError(e);
      });
    }
  }

  Widget history() {
    if (isLoading) {
      return const ListState(
        loading: true,
        title: 'Loading booking history...',
      );
    }
    if (errorMessage != null) {
      return ListState(
        title: 'Could not load booking history.',
        detail: errorMessage,
        icon: Icons.error_outline,
        action: loadBookings,
      );
    }
    if (bookings.isEmpty) {
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
          rows: bookings
              .map(
                (booking) => DataRow(
                  key: ValueKey(booking.id),
                  cells: [
                    DataCell(
                      Text(
                        '${dateTimeLabel(booking.startDateTime)}\n${dateTimeLabel(booking.endDateTime)}',
                      ),
                    ),
                    DataCell(Text(booking.resource.name)),
                    DataCell(StatusBadge(booking.status)),
                    DataCell(Text(booking.totalCost.toStringAsFixed(2))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
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
          child: history(),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: isLoading ? null : loadBookings,
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
