import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../services/booking_api.dart';
import '../services/demo_catalog.dart';

class BookingWorkspace extends StatefulWidget {
  final int page;
  final DemoCatalog catalog;
  final ValueChanged<int> navigate;
  const BookingWorkspace({
    super.key,
    required this.page,
    required this.catalog,
    required this.navigate,
  });
  @override
  State<BookingWorkspace> createState() => _BookingWorkspaceState();
}

class _BookingWorkspaceState extends State<BookingWorkspace> {
  static const base = String.fromEnvironment(
    'COWORK_API_BASE',
    defaultValue: 'http://localhost:8080/api',
  );
  final client = http.Client();
  late final api = BookingApi(base, client);
  final count = TextEditingController(text: '1');
  late DateTime start, end;
  List<Member> members = [];
  List<Resource> resources = [];
  List<Booking> bookings = [];
  List<Resource>? results;
  int? memberId, resourceId, editing, filterMember;
  bool busy = false, loaded = false;
  String? error;

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
    super.dispose();
  }

  Future<void> refresh() async {
    if (base.isEmpty) {
      members = widget.catalog.members.map(Member.fromJson).toList();
      resources = widget.catalog.resources.map(Resource.fromJson).toList();
      bookings = widget.catalog.bookings;
    } else {
      final data = await (api.members(), api.resources(), api.bookings()).wait;
      members = data.$1;
      resources = data.$2;
      bookings = data.$3;
    }
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
      if (mounted) error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String stamp(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  Future<void> pick(bool first) async {
    final old = first ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: old,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(old),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (first) {
        start = value;
      } else {
        end = value;
      }
      results = null;
      error = null;
    });
  }

  int get attendees {
    final n = int.tryParse(count.text.trim());
    if (n == null || n < 1) {
      throw const FormatException(
        'Enter a positive whole number of attendees.',
      );
    }
    if (!start.isBefore(end)) {
      throw const FormatException('End must be after start.');
    }
    return n;
  }

  bool free(Resource r, int n, {int? except}) =>
      r.status == 'ACTIVE' &&
      r.capacity >= n &&
      !bookings.any((b) => b.id != except && b.conflicts(r.id, start, end));

  Future<void> search() async {
    final n = attendees;
    final options = base.isEmpty ? resources : await api.available(start, end);
    results = options
        .where(
          (r) => base.isEmpty
              ? free(r, n)
              : r.status == 'ACTIVE' && r.capacity >= n,
        )
        .toList();
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> save() async {
    final n = attendees;
    final r = resources.where((r) => r.id == resourceId).firstOrNull;
    if (memberId == null || r == null) {
      throw const FormatException('Select a member and a resource.');
    }
    if (r.status != 'ACTIVE' || n > r.capacity) {
      throw const FormatException(
        'Select an active resource with enough capacity.',
      );
    }
    final slot = Reservation(memberId!, r.id, n, start, end);
    if (base.isEmpty) {
      if (!free(r, n, except: editing)) {
        throw const FormatException(
          'This resource is already booked for that time.',
        );
      }
      final booking = Booking(
        editing ?? widget.catalog.nextBookingId++,
        slot,
        'CONFIRMED',
        r.rate * end.difference(start).inMinutes / 60,
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
    results = null;
    filterMember = null;
    message('Booking saved');
    widget.navigate(5);
    await refresh();
  }

  Future<void> cancel(Booking b) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel booking #${b.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await run(() async {
      if (base.isEmpty) {
        bookings[bookings.indexOf(b)] = Booking(
          b.id,
          b.slot,
          'CANCELLED',
          b.cost,
        );
      } else {
        await api.save(b.slot, id: b.id, cancel: true);
      }
      if (!mounted) return;
      results = null;
      message('Booking cancelled');
      await refresh();
    });
  }

  void edit(Booking b) {
    editing = b.id;
    memberId = b.slot.memberId;
    resourceId = b.slot.resourceId;
    start = b.slot.start;
    end = b.slot.end;
    count.text = b.slot.attendees.toString();
    results = null;
    widget.navigate(4);
  }

  Widget select(
    String label,
    int? value,
    Map<int, String> options,
    ValueChanged<int?> change,
  ) {
    return DropdownButtonFormField<int>(
      key: ValueKey((label, value)),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => setState(() => change(v)),
    );
  }

  List<Widget> interval() => [
    Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final first in [true, false])
          OutlinedButton.icon(
            onPressed: () => pick(first),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              '${first ? 'Start' : 'End'}  ${stamp(first ? start : end)}',
            ),
          ),
      ],
    ),
    TextField(
      controller: count,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() => results = null),
      decoration: const InputDecoration(
        labelText: 'Attendees',
        border: OutlineInputBorder(),
      ),
    ),
  ];
  List<Widget> availability() => [
    ...interval(),
    ElevatedButton.icon(
      onPressed: () => run(search),
      icon: const Icon(Icons.search),
      label: const Text('Check availability'),
    ),
    if (results?.isEmpty == true)
      const Text('No resources available for this time and group size.'),
    for (final r in results ?? <Resource>[])
      Card(
        child: ListTile(
          title: Text(r.name),
          subtitle: Text(
            '${r.location} • ${r.capacity} seats • ${r.rate} QAR/hour',
          ),
          trailing: TextButton(
            onPressed: () {
              editing = null;
              resourceId = r.id;
              widget.navigate(4);
            },
            child: const Text('Book'),
          ),
        ),
      ),
  ];
  List<Widget> form() => [
    select('Member', memberId, {
      for (final m in members) m.id: m.name,
    }, (v) => memberId = v),
    select('Resource', resourceId, {
      for (final r in resources) r.id: r.name,
    }, (v) => resourceId = v),
    ...interval(),
    ElevatedButton.icon(
      onPressed: () => run(save),
      icon: const Icon(Icons.save),
      label: const Text('Save booking'),
    ),
    if (editing != null)
      TextButton(
        onPressed: () {
          editing = null;
          widget.navigate(5);
        },
        child: const Text('Discard edit'),
      ),
  ];
  List<Widget> history() {
    final rows = bookings.where(
      (b) => filterMember == null || b.slot.memberId == filterMember,
    );
    return [
      select('Filter by member', filterMember ?? 0, {
        0: 'All members',
        for (final m in members) m.id: m.name,
      }, (v) => filterMember = v == 0 ? null : v),
      if (rows.isEmpty)
        const Text('No bookings to display.')
      else
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 12,
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
              rows: [
                for (final b in rows)
                  DataRow(
                    key: ValueKey(b.id),
                    cells: [
                      DataCell(
                        Text(
                          resources
                                  .where((r) => r.id == b.slot.resourceId)
                                  .firstOrNull
                                  ?.name ??
                              '#${b.slot.resourceId}',
                        ),
                      ),
                      DataCell(
                        Text(
                          members
                                  .where((m) => m.id == b.slot.memberId)
                                  .firstOrNull
                                  ?.name ??
                              '#${b.slot.memberId}',
                        ),
                      ),
                      DataCell(Text(stamp(b.slot.start))),
                      DataCell(Text(stamp(b.slot.end))),
                      DataCell(Text('${b.slot.attendees}')),
                      DataCell(Text(b.status)),
                      DataCell(Text(b.cost.toStringAsFixed(2))),
                      DataCell(
                        b.status == 'CONFIRMED'
                            ? Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit booking',
                                    onPressed: () => edit(b),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Cancel booking',
                                    onPressed: () => cancel(b),
                                    icon: const Icon(Icons.cancel_outlined),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ];
  }

  @override
  void didUpdateWidget(BookingWorkspace old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page) {
      error = null;
      if (widget.page != 4) editing = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.page) {
      3 => 'Availability',
      4 => editing == null ? 'New Booking' : 'Edit booking #$editing',
      _ => 'Bookings',
    };
    final items = <Widget>[
      Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      if (base.isEmpty)
        const Text('Demo mode • Changes last for this session.'),
      if (busy) const LinearProgressIndicator(),
      if (error != null)
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (!loaded && !busy)
        OutlinedButton(
          onPressed: () => run(refresh),
          child: const Text('Retry'),
        ),
      if (loaded)
        ...switch (widget.page) {
          3 => availability(),
          4 => form(),
          _ => history(),
        },
      if (loaded && base.isNotEmpty)
        TextButton(onPressed: () => run(refresh), child: const Text('Refresh')),
    ];
    return AbsorbPointer(
      absorbing: busy,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final w in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(alignment: Alignment.centerLeft, child: w),
            ),
        ],
      ),
    );
  }
}
