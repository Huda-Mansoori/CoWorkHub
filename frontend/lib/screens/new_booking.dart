// New Booking page: loads choices, validates a draft and creates or updates a booking.
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../models/resource.dart';
import '../services/booking_api.dart';
import '../services/member_api.dart';
import '../services/resource_api.dart';
import '../widgets/app_ui.dart';
import '../widgets/booking_form.dart';
import '../widgets/resource_summary.dart';

class NewBooking extends StatefulWidget {
  final BookingApi? bookingApi;
  final MemberApi? memberApi;
  final ResourceApi? resourceApi;
  final Booking? bookingToEdit;
  final Resource? initialResource;
  final DateTime? initialStart, initialEnd;
  final int initialAttendees, revision;
  final bool active;
  final VoidCallback onSaved, onDiscard;
  const NewBooking({
    super.key,
    this.bookingApi,
    this.memberApi,
    this.resourceApi,
    this.bookingToEdit,
    this.initialResource,
    this.initialStart,
    this.initialEnd,
    this.initialAttendees = 1,
    this.revision = 0,
    this.active = true,
    required this.onSaved,
    required this.onDiscard,
  });
  @override
  State<NewBooking> createState() => _NewBookingState();
}

class _NewBookingState extends State<NewBooking> {
  late final BookingApi bookingApi = widget.bookingApi ?? BookingApi();
  late final MemberApi memberApi = widget.memberApi ?? MemberApi();
  late final ResourceApi resourceApi = widget.resourceApi ?? ResourceApi();
  final count = TextEditingController(text: '1');
  final bookingForm = GlobalKey<FormState>();
  List<Member> members = [];
  List<Resource> resources = [];
  late DateTime start, end;
  int? memberId, resourceId;
  bool isLoading = true, loaded = false, saving = false;
  String? errorMessage, timeError;
  bool get busy => isLoading || saving;
  Resource? get selected {
    for (final resource in resources) {
      if (resource.id == resourceId) return resource;
    }
    return null;
  }

  @override
  void dispose() {
    if (widget.bookingApi == null) bookingApi.close();
    if (widget.memberApi == null) memberApi.close();
    if (widget.resourceApi == null) resourceApi.close();
    count.dispose();
    super.dispose();
  }

  // TRACE: page load -> MemberApi.fetchAll + ResourceApi.fetchAll -> GET /api/members, /api/resources
  // -> MemberController/ResourceController -> services -> repositories.findAll -> MySQL
  // <- 200 JSON -> models -> setState -> dropdowns rebuild.
  Future<void> loadChoices() async {
    // setState tells Flutter to rebuild from these new state values.
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final memberResult = await memberApi.fetchAll();
      final resourceResult = await resourceApi.fetchAll();
      // The user may navigate away before an awaited request finishes.
      if (!mounted) return;
      setState(() {
        members = memberResult;
        resources = resourceResult;
        if (!members.any((member) => member.id == memberId)) memberId = null;
        if (!resources.any((resource) => resource.id == resourceId)) {
          resourceId = null;
        }
        isLoading = false;
        loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = displayError(e);
      });
    }
  }

  int? editing;
  @override
  void initState() {
    super.initState();
    applySelection();
    loadChoices();
  }

  @override
  void didUpdateWidget(NewBooking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) applySelection();
    if (widget.active && !oldWidget.active) loadChoices();
    if (!widget.active) editing = null;
  }

  void applySelection() {
    final booking = widget.bookingToEdit;
    if (booking != null) {
      editing = booking.id;
      memberId = booking.member.id;
      resourceId = booking.resource.id;
      start = booking.startDateTime;
      end = booking.endDateTime;
      count.text = booking.attendees.toString();
    } else {
      editing = null;
      resourceId = widget.initialResource?.id;
      final now = DateTime.now();
      start =
          widget.initialStart ??
          DateTime(now.year, now.month, now.day, now.hour + 1);
      end = widget.initialEnd ?? start.add(const Duration(hours: 1));
      count.text = widget.initialAttendees.toString();
    }
    errorMessage = null;
    timeError = null;
  }

  Future<void> pickDate(bool first) async {
    final old = first ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: old,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    updateTime(
      first,
      DateTime(date.year, date.month, date.day, old.hour, old.minute),
    );
  }

  Future<void> pickTime(bool first) async {
    final old = first ? start : end;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(old),
    );
    if (time == null || !mounted) return;
    updateTime(
      first,
      DateTime(old.year, old.month, old.day, time.hour, time.minute),
    );
  }

  void updateTime(bool first, DateTime value) => setState(() {
    if (first) {
      start = value;
    } else {
      end = value;
    }
    timeError = null;
    errorMessage = null;
  });
  bool validTime() {
    setState(
      () => timeError = start.isBefore(end)
          ? null
          : 'End must be after start. Choose a later end date or time.',
    );
    return timeError == null;
  }

  // TRACE: Save -> BookingApi.create/update -> POST /api/bookings or PUT /api/bookings/{id}
  // -> BookingController -> BookingService -> checkRules -> BookingRepository.save -> MySQL
  // <- 201/200 -> reload choices -> Bookings reloads its list.
  // checkRules rejects overlap with 409 and time/capacity/status failures with 400.
  Future<void> saveBooking() async {
    if (busy) return;
    final fieldsValid = bookingForm.currentState!.validate();
    if (!validTime() || !fieldsValid) return;
    setState(() {
      saving = true;
      errorMessage = null;
    });
    try {
      final member = members.firstWhere((item) => item.id == memberId);
      final draft = Booking(
        member: member,
        resource: selected!,
        startDateTime: start,
        endDateTime: end,
        attendees: int.parse(count.text.trim()),
      );
      if (editing == null) {
        await bookingApi.create(draft);
      } else {
        await bookingApi.update(editing!, draft);
      }
      editing = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking saved')));
      await loadChoices();
      if (mounted) widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = displayError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void discard() {
    if (busy) return;
    setState(() {
      editing = null;
      resourceId = null;
      timeError = null;
      errorMessage = null;
    });
    widget.onDiscard();
  }

  Widget bookingPanel({bool inline = false}) {
    return BookingForm(
      bookingForm: bookingForm,
      count: count,
      members: members,
      resources: resources,
      memberId: memberId,
      resourceId: resourceId,
      editing: editing,
      start: start,
      end: end,
      busy: busy,
      saving: saving,
      inline: inline,
      timeError: timeError,
      onMemberChanged: (value) => setState(() {
        memberId = value;
        errorMessage = null;
      }),
      onResourceChanged: (value) => setState(() {
        resourceId = value;
        errorMessage = null;
      }),
      onPickDate: pickDate,
      onPickTime: pickTime,
      onCountChanged: () => setState(() {
        errorMessage = null;
      }),
      onSave: saveBooking,
      onCancel: discard,
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'New booking';
    if (editing != null) title = 'Edit booking #$editing';
    return LayoutBuilder(
      builder: (context, box) {
        double pad = 32;
        if (box.maxWidth < 600) pad = 20;
        final wide =
            box.maxWidth - pad * 2 >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) < 19;
        return ListView(
          padding: EdgeInsets.all(pad),
          children: [
            PageHeading(
              title,
              action: OutlinedButton.icon(
                onPressed: busy ? null : loadChoices,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 28),
            if (busy) const LinearProgressIndicator(semanticsLabel: 'Working'),
            if (!loaded && isLoading)
              const ListState(loading: true, title: 'Loading booking data...'),
            if (!loaded && !isLoading)
              ListState(
                title: 'Could not load booking data.',
                detail: errorMessage,
                action: loadChoices,
              ),
            if (loaded) ...[
              if (errorMessage != null) ...[
                ErrorBanner(errorMessage!),
                const SizedBox(height: 20),
              ],
              if (wide && selected != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: bookingPanel()),
                    const SizedBox(width: 24),
                    SizedBox(width: 350, child: ResourceSummary(selected!)),
                  ],
                )
              else
                bookingPanel(),
            ],
          ],
        );
      },
    );
  }
}
