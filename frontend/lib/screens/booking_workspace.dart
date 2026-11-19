import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../services/booking_api.dart';
import '../services/demo_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/resource_card.dart';

class BookingWorkspace extends StatefulWidget {
  final int page;
  final DemoCatalog catalog;
  final ValueChanged<int> navigate;
  final String? apiBase;
  const BookingWorkspace({
    super.key,
    required this.page,
    required this.catalog,
    required this.navigate,
    this.apiBase,
  });
  @override
  State<BookingWorkspace> createState() => _BookingWorkspaceState();
}

class _BookingWorkspaceState extends State<BookingWorkspace> {
  final client = http.Client();
  late final String base = widget.apiBase ?? defaultApiBase;
  late final api = BookingApi(base, client);
  final count = TextEditingController(text: '1');
  final bookingForm = GlobalKey<FormState>();
  final searchForm = GlobalKey<FormState>();
  final pageScroll = ScrollController();
  final tableScroll = ScrollController();
  late DateTime start, end;
  List<Member> members = [];
  List<Resource> resources = [];
  List<Booking> bookings = [];
  List<Resource>? results;
  int? memberId, resourceId, editing, filterMember;
  bool busy = false, loaded = false, saving = false;
  String? error, timeError;
  Resource? get selected =>
      resources.where((r) => r.id == resourceId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    start = DateTime(now.year, now.month, now.day, now.hour + 1);
    end = start.add(const Duration(hours: 1));
    run(refresh);
  }

  @override
  void dispose() {
    client.close();
    count.dispose();
    pageScroll.dispose();
    tableScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BookingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      error = null;
      timeError = null;
      if (widget.page != 4) editing = null;
      if (pageScroll.hasClients) pageScroll.jumpTo(0);
    }
  }

  Future<void> refresh() async {
    if (base.isEmpty) {
      members = widget.catalog.members.map(Member.fromJson).toList();
      resources = widget.catalog.resources.map(Resource.fromJson).toList();
      bookings = widget.catalog.bookings;
    } else {
      final data = await (api.members(), api.resources(), api.bookings()).wait;
      if (!mounted) return;
      members = data.$1;
      resources = data.$2;
      bookings = data.$3;
    }
    if (!members.any((m) => m.id == memberId)) memberId = null;
    if (!resources.any((r) => r.id == resourceId)) resourceId = null;
    if (!members.any((m) => m.id == filterMember)) filterMember = null;
    results = null;
    loaded = true;
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) error = displayError(e);
    } finally {
      if (mounted) setState(() => busy = false);
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
    results = null;
    error = null;
  });
  bool validTime() {
    setState(
      () => timeError = start.isBefore(end)
          ? null
          : 'End must be after start. Choose a later end date or time.',
    );
    return timeError == null;
  }

  String? validateCount(String? value, {bool resource = false}) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 1 || n > 2147483647) {
      return 'Enter a positive whole number of attendees.';
    }
    final r = selected;
    if (resource && r != null) {
      if (r.isDesk && n != 1) return 'A desk can only accommodate 1 attendee.';
      if (n > r.capacity) {
        return 'Attendees exceed the room capacity of ${r.capacity}.';
      }
    }
    return null;
  }

  bool free(Resource r, int n, {int? except}) =>
      r.status == 'ACTIVE' &&
      r.capacity >= n &&
      !bookings.any((b) => b.id != except && b.conflicts(r.id, start, end));

  Future<void> search() async {
    if (busy) return;
    final fieldsValid = searchForm.currentState!.validate();
    if (!validTime() || !fieldsValid) return;
    await run(() async {
      results = null;
      final n = int.parse(count.text.trim());
      final options = base.isEmpty
          ? resources
          : await api.available(start, end);
      if (!mounted) return;
      results = options
          .where(
            (r) => base.isEmpty
                ? free(r, n)
                : r.status == 'ACTIVE' && r.capacity >= n,
          )
          .toList();
      if (!results!.any((r) => r.id == resourceId)) resourceId = null;
    });
  }

  Future<void> submit() async {
    if (busy) return;
    final fieldsValid = bookingForm.currentState!.validate();
    if (!validTime() || !fieldsValid) return;
    setState(() => saving = true);
    await run(() async {
      final r = selected!;
      final slot = Reservation(
        memberId!,
        r.id,
        int.parse(count.text.trim()),
        start,
        end,
      );
      if (base.isEmpty) {
        if (!free(r, slot.attendees, except: editing)) {
          throw const FormatException(
            'This resource is already booked for the selected time slot.',
          );
        }
        final booking = Booking(
          editing ?? widget.catalog.nextBookingId++,
          slot,
          'CONFIRMED',
          r.rate * end.difference(start).inMinutes / 60,
          resourceName: r.name,
        );
        if (editing == null) {
          bookings.add(booking);
        } else {
          bookings[bookings.indexWhere((b) => b.id == editing)] = booking;
        }
      } else {
        await api.save(slot, id: editing);
      }
      if (!mounted) return;
      editing = null;
      filterMember = null;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking saved')));
      await refresh();
      if (mounted) widget.navigate(5);
    });
    if (mounted) setState(() => saving = false);
  }

  Future<void> cancel(Booking booking) async {
    if (busy) return;
    final yes = await confirmAction(
      context,
      title: 'Cancel booking #${booking.id}?',
      message: 'The booking will remain in history. Its time slot will become available.',
      confirmLabel: 'Cancel booking',
      cancelLabel: 'Keep booking',
    );
    if (!yes || !mounted) return;
    await run(() async {
      if (base.isEmpty) {
        bookings[bookings.indexWhere((b) => b.id == booking.id)] = Booking(
          booking.id,
          booking.slot,
          'CANCELLED',
          booking.cost,
          resourceName: booking.resourceName,
        );
      } else {
        await api.save(booking.slot, id: booking.id, cancel: true);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      await refresh();
    });
  }

  void edit(Booking booking) {
    editing = booking.id;
    memberId = booking.slot.memberId;
    resourceId = booking.slot.resourceId;
    start = booking.slot.start;
    end = booking.slot.end;
    count.text = booking.slot.attendees.toString();
    results = null;
    widget.navigate(4);
  }

  void discard({bool inline = false}) {
    setState(() {
      editing = null;
      resourceId = null;
      timeError = null;
      error = null;
    });
    if (!inline) widget.navigate(5);
  }

  Widget choice(
    String label,
    int? value,
    Map<int, String> options,
    ValueChanged<int?> change, {
    String? Function(int?)? validator,
    bool enabled = true,
  }) => DropdownButtonFormField<int>(
    key: ValueKey((label, value)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: options.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: busy || !enabled
        ? null
        : (v) => setState(() {
            change(v);
            error = null;
          }),
    validator: validator,
  );
  Widget countField({bool resource = false}) => TextFormField(
    key: ValueKey(resource ? 'booking-attendees' : 'availability-attendees'),
    controller: count,
    onFieldSubmitted: (_) => resource ? submit() : search(),
    keyboardType: TextInputType.number,
    readOnly: busy,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: const InputDecoration(
      labelText: 'Attendees *',
      prefixIcon: Icon(Icons.people_outline),
    ),
    validator: (v) => validateCount(v, resource: resource),
    onChanged: (_) => setState(() {
      results = null;
      error = null;
    }),
  );

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
  List<Widget> get timeFields => [
    timeField(
      'Start date',
      dateLabel(start),
      Icons.calendar_today_outlined,
      () => pickDate(true),
    ),
    timeField(
      'Start time',
      timeLabel(start),
      Icons.schedule,
      () => pickTime(true),
    ),
    timeField(
      'End date',
      dateLabel(end),
      Icons.calendar_today_outlined,
      () => pickDate(false),
    ),
    timeField(
      'End time',
      timeLabel(end),
      Icons.schedule,
      () => pickTime(false),
    ),
  ];

  Widget bookingPanel({bool inline = false}) {
    final r = selected;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): submit,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): submit,
        const SingleActivator(LogicalKeyboardKey.enter): submit,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!busy) discard(inline: inline);
        },
      },
      child: Panel(
        child: Form(
          key: bookingForm,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (inline) ...[
                Text(
                  'New booking',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, color: indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              choice(
                'Member',
                memberId,
                {for (final m in members) m.id: m.name},
                (v) => memberId = v,
                enabled: editing == null,
                validator: (v) => v == null ? 'Select a member.' : null,
              ),
              if (editing != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'The member cannot be changed when editing a booking.',
                  style: TextStyle(color: secondaryInk, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
              if (!inline) ...[
                choice(
                  'Resource',
                  resourceId,
                  {
                    for (final resource in resources)
                      resource.id: resource.name,
                  },
                  (v) => resourceId = v,
                  validator: (v) => v == null
                      ? 'Select a resource.'
                      : selected?.status != 'ACTIVE'
                      ? 'This resource is out of service and cannot be booked.'
                      : null,
                ),
                const SizedBox(height: 24),
                FieldGrid(children: timeFields),
              ] else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel(start),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${timeLabel(start)} - ${dateTimeLabel(end)}',
                      style: const TextStyle(color: secondaryInk),
                    ),
                  ],
                ),
              if (timeError != null) ...[
                const SizedBox(height: 10),
                Text(timeError!, style: const TextStyle(color: danger)),
              ],
              const SizedBox(height: 24),
              countField(resource: true),
              if (r != null) ...[
                const SizedBox(height: 22),
                Text(
                  '${r.capacity} ${r.capacity == 1 ? 'seat' : 'seats'} • ${r.rate.toStringAsFixed(2)} QAR / hour',
                  style: const TextStyle(color: secondaryInk),
                ),
              ],
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: busy ? null : () => discard(inline: inline),
                    child: Text(editing == null ? 'Cancel' : 'Discard edit'),
                  ),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 19),
                    label: Text(saving ? 'Saving...' : 'Save booking'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summary(Resource r) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResourcePhoto(isDesk: r.isDesk, id: r.id, height: 190),
        const SizedBox(height: 22),
        Text(r.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 22),
        FactRow(Icons.location_on_outlined, r.location),
        FactRow(
          Icons.chair_outlined,
          '${r.capacity} ${r.capacity == 1 ? 'seat' : 'seats'}',
        ),
        FactRow(
          Icons.payments_outlined,
          '${r.rate.toStringAsFixed(2)} QAR / hour',
        ),
        const Divider(height: 28),
        const Text(
          'Final cost is calculated when the booking is saved.',
          style: TextStyle(color: secondaryInk),
        ),
      ],
    ),
  );

  Widget availability(double width) {
    final inline =
        width >= 1000 && MediaQuery.textScalerOf(context).scale(14) < 19;
    final filters = Form(
      key: searchForm,
      child: Panel(
        child: LayoutBuilder(
          builder: (context, box) {
            final fieldWidth = box.maxWidth >= 900
                ? 145.0
                : box.maxWidth >= 500
                ? (box.maxWidth - 20) / 2
                : box.maxWidth;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    for (final field in timeFields)
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
    Widget cards(double available) {
      final columns = math.max(1, (available / 300).floor());
      final cardWidth = (available - (columns - 1) * 20) / columns;
      if (results == null) {
        return const ListState(
          title: 'Find an available workspace',
          detail: 'Choose your dates, times and attendees, then check availability.',
          icon: Icons.event_available_outlined,
        );
      }
      if (results!.isEmpty) {
        return const ListState(
          title: 'No resources available',
          detail: 'Try another time or a smaller group.',
          icon: Icons.event_busy_outlined,
        );
      }
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          for (final resource in results!)
            SizedBox(
              width: cardWidth,
              child: ResourceCard(
                resource: resource,
                selected: resourceId == resource.id,
                disabled: busy,
                onBook: () {
                  setState(() {
                    resourceId = resource.id;
                    editing = null;
                    error = null;
                  });
                  if (!inline) widget.navigate(4);
                },
              ),
            ),
        ],
      );
    }

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
                  builder: (context, box) => cards(box.maxWidth),
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
          cards(width),
      ],
    );
  }

  Widget history(double width) {
    final rows = bookings
        .where((b) => filterMember == null || b.slot.memberId == filterMember)
        .toList();
    final table =
        width >= 1000 && MediaQuery.textScalerOf(context).scale(14) < 19;
    String resourceName(Booking b) =>
        resources.where((r) => r.id == b.slot.resourceId).firstOrNull?.name ??
        b.resourceName ??
        'Resource #${b.slot.resourceId}';
    String memberName(Booking b) =>
        members.where((m) => m.id == b.slot.memberId).firstOrNull?.name ??
        'Member #${b.slot.memberId}';
    Widget actions(Booking b) => b.status == 'CONFIRMED'
        ? Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: busy ? null : () => edit(b),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: danger),
                onPressed: busy ? null : () => cancel(b),
                icon: const Icon(Icons.cancel_outlined, size: 17),
                label: const Text('Cancel'),
              ),
            ],
          )
        : const Text('-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: math.min(360, width),
            child: choice('Filter by member', filterMember ?? 0, {
              0: 'All members',
              for (final m in members) m.id: m.name,
            }, (v) => filterMember = v == 0 ? null : v),
          ),
        ),
        const SizedBox(height: 24),
        if (rows.isEmpty)
          ListState(
            title: 'No bookings to display.',
            detail: filterMember == null
                ? 'Create a booking to get started.'
                : 'This member has no bookings.',
            actionLabel: filterMember == null ? 'New booking' : null,
            action: filterMember == null ? () => widget.navigate(4) : null,
            icon: Icons.calendar_today_outlined,
          )
        else if (table)
          Panel(
            padding: EdgeInsets.zero,
            child: Scrollbar(
              controller: tableScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: tableScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 12),
                child: DataTable(
                  columns: [
                    for (final label in [
                      'Resource',
                      'Member',
                      'Start',
                      'End',
                      'Attendees',
                      'Status',
                      'Total (QAR)',
                      'Actions',
                    ])
                      DataColumn(label: Text(label)),
                  ],
                  dataRowMinHeight: 82,
                  dataRowMaxHeight: 110,
                  rows: [
                    for (final b in rows)
                      DataRow(
                        key: ValueKey(b.id),
                        cells: [
                          DataCell(
                            SizedBox(width: 150, child: Text(resourceName(b))),
                          ),
                          DataCell(
                            SizedBox(width: 110, child: Text(memberName(b))),
                          ),
                          DataCell(
                            Text(
                              '${dateLabel(b.slot.start)}\n${timeLabel(b.slot.start)}',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${dateLabel(b.slot.end)}\n${timeLabel(b.slot.end)}',
                            ),
                          ),
                          DataCell(Text('${b.slot.attendees}')),
                          DataCell(StatusBadge(b.status)),
                          DataCell(Text(b.cost.toStringAsFixed(2))),
                          DataCell(SizedBox(width: 200, child: actions(b))),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          for (final b in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      resourceName(b),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(memberName(b)),
                    const SizedBox(height: 12),
                    Text(
                      '${dateTimeLabel(b.slot.start)} - ${dateTimeLabel(b.slot.end)}',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(b.status),
                        Text('${b.slot.attendees} attendees'),
                        Text(
                          '${b.cost.toStringAsFixed(2)} QAR',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions(b),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final pad = box.maxWidth < 600 ? 20.0 : 32.0;
      final width = box.maxWidth - pad * 2;
      final title = widget.page == 3
          ? 'Availability'
          : widget.page == 4
          ? editing == null
                ? 'New booking'
                : 'Edit booking #$editing'
          : 'Bookings';
      final content = loaded
          ? switch (widget.page) {
              3 => availability(width),
              4 =>
                width >= 1000 &&
                        selected != null &&
                        MediaQuery.textScalerOf(context).scale(14) < 19
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: bookingPanel()),
                          const SizedBox(width: 24),
                          SizedBox(width: 350, child: summary(selected!)),
                        ],
                      )
                    : bookingPanel(),
              _ => history(width),
            }
          : const SizedBox.shrink();
      return ListView(
        controller: pageScroll,
        padding: EdgeInsets.all(pad),
        children: [
          PageHeading(
            title,
            action: loaded
                ? OutlinedButton.icon(
                    onPressed: busy ? null : () => run(refresh),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  )
                : null,
          ),
          const SizedBox(height: 28),
          if (busy) ...[
            const LinearProgressIndicator(semanticsLabel: 'Working'),
            const SizedBox(height: 18),
          ],
          if (!loaded)
            busy
                ? const ListState(
                    loading: true,
                    title: 'Loading booking data...',
                  )
                : ListState(
                    title: 'Could not load booking data.',
                    detail: error,
                    icon: Icons.error_outline,
                    action: () => run(refresh),
                  )
          else ...[
            if (error != null) ...[
              ErrorBanner(error!),
              const SizedBox(height: 20),
            ],
            content,
          ],
        ],
      );
    },
  );
}
