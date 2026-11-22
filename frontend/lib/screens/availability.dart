// Availability page: searches backend availability and supports inline booking on wide layouts.
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../models/resource.dart';
import '../services/booking_api.dart';
import '../services/member_api.dart';
import '../services/resource_api.dart';
import '../widgets/app_ui.dart';
import '../widgets/booking_form.dart';

import '../theme/app_theme.dart';
import '../widgets/availability_results.dart';
import '../widgets/booking_time_fields.dart';

class Availability extends StatefulWidget {
  final BookingApi? bookingApi;
  final MemberApi? memberApi;
  final ResourceApi? resourceApi;
  final void Function(
    Resource resource,
    DateTime start,
    DateTime end,
    int attendees,
  )
  onBook;
  final VoidCallback onSaved;
  final bool active;
  const Availability({
    super.key,
    this.bookingApi,
    this.memberApi,
    this.resourceApi,
    required this.onBook,
    required this.onSaved,
    this.active = true,
  });
  @override
  State<Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<Availability> {
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
  bool get busy => isLoading || saving || searching;
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

  final searchForm = GlobalKey<FormState>();
  List<Resource>? results;
  bool searching = false;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    start = DateTime(now.year, now.month, now.day, now.hour + 1);
    end = start.add(const Duration(hours: 1));
    loadChoices();
  }

  @override
  void didUpdateWidget(Availability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      results = null;
      loadChoices();
    }
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
    results = null;
  });
  bool validTime() {
    setState(
      () => timeError = start.isBefore(end)
          ? null
          : 'End must be after start. Choose a later end date or time.',
    );
    return timeError == null;
  }

  // TRACE: Check availability -> ResourceApi.fetchAvailable -> GET /api/resources/available
  // -> AvailabilityController.getAvailable -> BookingService.getAvailableResources
  // -> ResourceRepository.findByStatus + BookingRepository.hasOverlappingBooking -> MySQL
  // <- 200 JSON -> Resource.fromJson -> filter capacity -> setState -> cards.
  Future<void> search() async {
    if (busy || searching) return;
    final fieldsValid = searchForm.currentState!.validate();
    if (!validTime() || !fieldsValid) return;
    setState(() {
      searching = true;
      errorMessage = null;
      results = null;
    });
    try {
      final options = await resourceApi.fetchAvailable(start, end);
      if (!mounted) return;
      final attendees = int.parse(count.text.trim());
      setState(() {
        results = options
            .where(
              (resource) =>
                  resource.status == 'ACTIVE' && resource.capacity >= attendees,
            )
            .toList();
        if (!results!.any((resource) => resource.id == resourceId)) {
          resourceId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = displayError(e));
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  Widget countField() => TextFormField(
    controller: count,
    readOnly: busy || searching,
    keyboardType: TextInputType.number,
    onFieldSubmitted: (_) => search(),
    validator: (value) => validateAttendees(value, null),
    decoration: const InputDecoration(
      labelText: 'Attendees *',
      prefixIcon: Icon(Icons.people_outline),
    ),
    onChanged: (_) => setState(() {
      results = null;
      errorMessage = null;
    }),
  );
  void discard() {
    if (busy) return;
    setState(() {
      resourceId = null;
      errorMessage = null;
      timeError = null;
    });
  }

  // TRACE: Save -> BookingApi.create -> POST /api/bookings
  // -> BookingController -> BookingService -> checkRules -> BookingRepository.save -> MySQL
  // <- 201 -> reload choices -> Bookings reloads its list.
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
      await bookingApi.create(draft);
      results = null;
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

  Widget bookingPanel({bool inline = false}) {
    return BookingForm(
      bookingForm: bookingForm,
      count: count,
      members: members,
      resources: resources,
      memberId: memberId,
      resourceId: resourceId,
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

  void selectResource(Resource resource, bool inline) {
    setState(() {
      resourceId = resource.id;
      errorMessage = null;
    });
    if (!inline) {
      widget.onBook(resource, start, end, int.parse(count.text.trim()));
    }
  }

  Widget availability(double width) {
    final inline =
        width >= 1000 && MediaQuery.textScalerOf(context).scale(14) < 19;
    final filters = Form(
      key: searchForm,
      child: Panel(
        child: LayoutBuilder(
          builder: (context, box) {
            double fieldWidth = box.maxWidth;
            if (box.maxWidth >= 900) {
              fieldWidth = 145;
            } else if (box.maxWidth >= 500) {
              fieldWidth = (box.maxWidth - 20) / 2;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    for (final field in BookingTimeFields(
                      start: start,
                      end: end,
                      busy: busy,
                      onPickDate: pickDate,
                      onPickTime: pickTime,
                    ).fields)
                      SizedBox(width: fieldWidth, child: field),
                    SizedBox(width: fieldWidth, child: countField()),
                    FilledButton.icon(
                      onPressed: busy ? null : search,
                      icon: const Icon(Icons.search),
                      label: const Text('Check availability'),
                    ),
                  ],
                ),
                if (timeError != null) ...[
                  const SizedBox(height: 12),
                  Text(timeError!, style: const TextStyle(color: danger)),
                ],
              ],
            );
          },
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        const SizedBox(height: 24),
        if (inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => AvailabilityResults(
                    results: results,
                    available: box.maxWidth,
                    resourceId: resourceId,
                    busy: busy,
                    onBook: (resource) => selectResource(resource, inline),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 350,
                child: selected == null
                    ? const Panel(
                        child: ListState(
                          title: 'Choose a resource',
                          detail: 'Select Book on an available workspace.',
                          icon: Icons.meeting_room_outlined,
                        ),
                      )
                    : bookingPanel(inline: true),
              ),
            ],
          )
        else
          AvailabilityResults(
            results: results,
            available: width,
            resourceId: resourceId,
            busy: busy,
            onBook: (resource) => selectResource(resource, inline),
          ),
      ],
    );
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
            'Availability',
            action: OutlinedButton.icon(
              onPressed: busy || searching
                  ? null
                  : () {
                      setState(() => results = null);
                      loadChoices();
                    },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 28),
          if (busy || searching)
            const LinearProgressIndicator(semanticsLabel: 'Working'),
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
              ErrorBanner(errorMessage!, retry: search),
              const SizedBox(height: 20),
            ],
            availability(box.maxWidth - pad * 2),
          ],
        ],
      );
    },
  );
}
