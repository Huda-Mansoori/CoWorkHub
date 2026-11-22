// Booking form: stateless fields and callbacks; its parent validates, saves and owns state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../models/resource.dart';
import '../theme/app_theme.dart';
import 'app_ui.dart';
import 'booking_time_fields.dart';

String? validateAttendees(String? value, Resource? resource) {
  final count = int.tryParse(value?.trim() ?? '');
  if (count == null || count < 1 || count > 2147483647) {
    return 'Enter a positive whole number of attendees.';
  }
  if (resource is Desk && count != 1) {
    return 'A desk can only accommodate 1 attendee.';
  }
  if (resource != null && count > resource.capacity) {
    return 'Attendees exceed the room capacity of ${resource.capacity}.';
  }
  return null;
}

class BookingForm extends StatelessWidget {
  final GlobalKey<FormState> bookingForm;
  final TextEditingController count;
  final List<Member> members;
  final List<Resource> resources;
  final int? memberId, resourceId, editing;
  final DateTime start, end;
  final bool busy, saving, inline;
  final String? timeError;
  final ValueChanged<int?> onMemberChanged, onResourceChanged;
  final ValueChanged<bool> onPickDate, onPickTime;
  final VoidCallback onSave, onCancel, onCountChanged;
  const BookingForm({
    super.key,
    required this.bookingForm,
    required this.count,
    required this.members,
    required this.resources,
    this.memberId,
    this.resourceId,
    this.editing,
    required this.start,
    required this.end,
    required this.busy,
    required this.saving,
    this.inline = false,
    this.timeError,
    required this.onMemberChanged,
    required this.onResourceChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onSave,
    required this.onCancel,
    required this.onCountChanged,
  });

  Resource? get selected {
    for (final resource in resources) {
      if (resource.id == resourceId) return resource;
    }
    return null;
  }

  Widget choice(
    String label,
    int? value,
    Map<int, String> options,
    ValueChanged<int?> change, {
    String? Function(int?)? validator,
    bool enabled = true,
  }) => DropdownButtonFormField<int>(
    key: ValueKey('$label-$value'),
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
    onChanged: busy || !enabled ? null : change,
    validator: validator,
  );
  @override
  Widget build(BuildContext context) {
    final r = selected;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): onSave,
        const SingleActivator(LogicalKeyboardKey.enter): onSave,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!busy) onCancel();
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
                {for (final m in members) m.id: m.fullName},
                onMemberChanged,
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
                  onResourceChanged,
                  validator: (v) => v == null
                      ? 'Select a resource.'
                      : selected?.status != 'ACTIVE'
                      ? 'This resource is out of service and cannot be booked.'
                      : null,
                ),
                const SizedBox(height: 24),
                BookingTimeFields(
                  start: start,
                  end: end,
                  busy: busy,
                  onPickDate: onPickDate,
                  onPickTime: onPickTime,
                ),
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
              TextFormField(
                controller: count,
                readOnly: busy,
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => onSave(),
                onChanged: (_) => onCountChanged(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Attendees *',
                  prefixIcon: Icon(Icons.people_outline),
                ),
                validator: (value) => validateAttendees(value, r),
              ),
              if (r != null) ...[
                const SizedBox(height: 22),
                Text(
                  '${r.capacity} ${r.capacity == 1 ? 'seat' : 'seats'} • ${r.hourlyRate.toStringAsFixed(2)} QAR / hour',
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
                    onPressed: busy ? null : () => onCancel(),
                    child: Text(editing == null ? 'Cancel' : 'Discard edit'),
                  ),
                  FilledButton.icon(
                    onPressed: busy ? null : onSave,
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
}
