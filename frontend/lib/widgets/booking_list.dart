// Booking list: stateless wide table or compact cards, with parent-owned action callbacks.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import 'app_ui.dart';

class BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final List<Member> members;
  final int? filterMember;
  final bool busy;
  final ScrollController tableScroll;
  final ValueChanged<Booking> onEdit, onCancel;
  final ValueChanged<int?> onFilterChanged;
  final VoidCallback onNewBooking;
  const BookingList({
    super.key,
    required this.bookings,
    required this.members,
    this.filterMember,
    required this.busy,
    required this.tableScroll,
    required this.onEdit,
    required this.onCancel,
    required this.onFilterChanged,
    required this.onNewBooking,
  });
  Widget choice(
    String label,
    int value,
    Map<int, String> options,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      key: ValueKey(value),
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: busy ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 308;
    final rows = bookings
        .where((b) => filterMember == null || b.member.id == filterMember)
        .toList();
    final table =
        width >= 1000 && MediaQuery.textScalerOf(context).scale(14) < 19;
    Widget actions(Booking b) => b.status == 'CONFIRMED'
        ? Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: busy ? null : () => onEdit(b),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: danger),
                onPressed: busy ? null : () => onCancel(b),
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
              for (final m in members) m.id: m.fullName,
            }, (v) => onFilterChanged(v == 0 ? null : v)),
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
            action: filterMember == null ? () => onNewBooking() : null,
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
                            SizedBox(width: 150, child: Text(b.resource.name)),
                          ),
                          DataCell(
                            SizedBox(
                              width: 110,
                              child: Text(b.member.fullName),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${dateLabel(b.startDateTime)}\n${timeLabel(b.startDateTime)}',
                            ),
                          ),
                          DataCell(
                            Text(
                              '${dateLabel(b.endDateTime)}\n${timeLabel(b.endDateTime)}',
                            ),
                          ),
                          DataCell(Text('${b.attendees}')),
                          DataCell(StatusBadge(b.status)),
                          DataCell(Text(b.totalCost.toStringAsFixed(2))),
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
                      b.resource.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(b.member.fullName),
                    const SizedBox(height: 12),
                    Text(
                      '${dateTimeLabel(b.startDateTime)} - ${dateTimeLabel(b.endDateTime)}',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(b.status),
                        Text('${b.attendees} attendees'),
                        Text(
                          '${b.totalCost.toStringAsFixed(2)} QAR',
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
}
