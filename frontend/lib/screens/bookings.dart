// Bookings page: loads persisted bookings and delegates editing or confirms cancellation.
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../services/booking_api.dart';
import '../services/member_api.dart';
import '../widgets/app_ui.dart';
import '../widgets/booking_list.dart';

class Bookings extends StatefulWidget {
  final BookingApi? api;
  final MemberApi? memberApi;
  final bool active;
  final ValueChanged<Booking> onEdit;
  final VoidCallback onNewBooking;
  const Bookings({
    super.key,
    this.api,
    this.memberApi,
    this.active = true,
    required this.onEdit,
    required this.onNewBooking,
  });
  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  late final BookingApi api = widget.api ?? BookingApi();
  late final MemberApi memberApi = widget.memberApi ?? MemberApi();
  List<Booking> bookings = [];
  List<Member> members = [];
  bool isLoading = true, cancelling = false;
  String? errorMessage;
  int? filterMember;
  final tableScroll = ScrollController();
  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  @override
  void didUpdateWidget(Bookings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      filterMember = null;
      loadBookings();
    }
  }

  @override
  void dispose() {
    if (widget.api == null) api.close();
    if (widget.memberApi == null) memberApi.close();
    tableScroll.dispose();
    super.dispose();
  }

  // TRACE: Bookings -> BookingApi.fetchAll -> GET /api/bookings
  // -> BookingController.getAllBookings -> BookingService.getAllBookings
  // -> BookingRepository.findAll -> MySQL <- 200 JSON -> Booking.fromJson -> setState -> list.
  // MemberApi.fetchAll also supplies the member filter dropdown.
  Future<void> loadBookings() async {
    // setState schedules a rebuild for the new loading/list/error state.
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await api.fetchAll();
      final memberData = await memberApi.fetchAll();
      // Avoid updating a page that was removed during the HTTP request.
      if (!mounted) return;
      setState(() {
        bookings = data;
        members = memberData;
        isLoading = false;
        if (!members.any((member) => member.id == filterMember)) {
          filterMember = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = displayError(e);
      });
    }
  }

  // TRACE: Cancel -> BookingApi.cancel -> PUT /api/bookings/{id}, status CANCELLED
  // -> BookingController.updateBooking -> BookingService.updateBooking
  // -> BookingRepository.save -> MySQL <- 200 -> loadBookings -> updated status and cost.
  Future<void> cancelBooking(Booking booking) async {
    if (cancelling || isLoading) return;
    final yes = await confirmAction(
      context,
      title: 'Cancel booking #${booking.id}?',
      message: 'The booking will remain in history. Its time slot will become available.',
      confirmLabel: 'Cancel booking',
      cancelLabel: 'Keep booking',
    );
    if (!yes || !mounted) return;
    setState(() => cancelling = true);
    try {
      await api.cancel(booking);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      await loadBookings();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = displayError(e));
    } finally {
      if (mounted) setState(() => cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      double pad = 32;
      if (box.maxWidth < 600) pad = 20;
      return ListView(
        padding: EdgeInsets.all(pad),
        children: [
          PageHeading(
            'Bookings',
            action: OutlinedButton.icon(
              onPressed: isLoading || cancelling ? null : loadBookings,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 28),
          if (cancelling)
            const LinearProgressIndicator(semanticsLabel: 'Cancelling'),
          if (isLoading)
            const ListState(loading: true, title: 'Loading booking data...')
          else if (errorMessage != null)
            ListState(
              title: 'Could not load bookings.',
              detail: errorMessage,
              action: loadBookings,
            )
          else
            BookingList(
              bookings: bookings,
              members: members,
              filterMember: filterMember,
              busy: cancelling,
              tableScroll: tableScroll,
              onEdit: widget.onEdit,
              onCancel: cancelBooking,
              onFilterChanged: (value) => setState(() => filterMember = value),
              onNewBooking: widget.onNewBooking,
            ),
        ],
      );
    },
  );
}
