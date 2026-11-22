// Resource editor: validates input and delegates persistence to its parent page.
import 'package:flutter/material.dart';

import '../models/resource.dart';
import '../widgets/app_ui.dart';

class ResourceEditor extends StatefulWidget {
  final Resource? existing;
  final Future<void> Function(Resource) onSave;
  const ResourceEditor({super.key, this.existing, required this.onSave});
  @override
  State<ResourceEditor> createState() => _ResourceEditorState();
}

class _ResourceEditorState extends State<ResourceEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, location, capacity, rate;
  late String type, status, deskType;
  late bool projector, video;
  bool saving = false;
  String? error;
  bool get editing => widget.existing != null;
  @override
  void initState() {
    super.initState();
    final data = widget.existing;
    name = TextEditingController(text: data?.name ?? '');
    location = TextEditingController(text: data?.location ?? '');
    capacity = TextEditingController(text: data?.capacity.toString() ?? '');
    rate = TextEditingController(text: data?.hourlyRate.toString() ?? '');
    type = data is Desk ? 'Desk' : 'Meeting Room';
    status = data?.status ?? 'ACTIVE';
    deskType = data is Desk ? data.deskType : 'Regular Desk';
    projector = data is MeetingRoom && data.projector;
    video = data is MeetingRoom && data.videoConference;
    if (type == 'Desk') capacity.text = '1';
  }

  @override
  void dispose() {
    for (final c in [name, location, capacity, rate]) {
      c.dispose();
    }
    super.dispose();
  }

  // TRACE: Save -> validate -> parent onSave -> ResourceApi.create/update
  // -> ResourceController -> ResourceService -> ResourceRepository.save -> MySQL
  // <- success closes dialog; failure keeps fields and displays the backend message.
  Future<void> submit() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    final Resource data;
    if (type == 'Desk') {
      data = Desk(
        name: name.text.trim(),
        location: location.text.trim(),
        hourlyRate: double.parse(rate.text.trim()),
        status: status,
        deskType: deskType,
      );
    } else {
      data = MeetingRoom(
        name: name.text.trim(),
        location: location.text.trim(),
        capacity: int.parse(capacity.text.trim()),
        hourlyRate: double.parse(rate.text.trim()),
        status: status,
        projector: projector,
        videoConference: video,
      );
    }
    try {
      await widget.onSave(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = displayError(e);
          saving = false;
        });
      }
    }
  }

  String? requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    if (value.trim().length > 150) return 'Use 150 characters or fewer.';
    return null;
  }

  @override
  Widget build(BuildContext context) => EditorDialog(
    title: editing ? 'Edit resource' : 'Add resource',
    saving: saving,
    error: error,
    onSave: submit,
    onCancel: () => Navigator.pop(context, false),
    child: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldGrid(
            children: [
              TextFormField(
                controller: name,
                onFieldSubmitted: (_) => submit(),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Resource name *',
                  hintText: 'e.g. Meeting Room A',
                ),
                validator: requiredText,
              ),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Resource type'),
                items: ['Meeting Room', 'Desk']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: editing || saving
                    ? null
                    : (v) => setState(() {
                        type = v!;
                        if (type == 'Desk') capacity.text = '1';
                      }),
              ),
              TextFormField(
                controller: location,
                onFieldSubmitted: (_) => submit(),
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g. Floor 1',
                ),
                validator: requiredText,
              ),
              TextFormField(
                controller: capacity,
                onFieldSubmitted: (_) => submit(),
                readOnly: type == 'Desk',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Capacity *',
                  helperText: type == 'Desk'
                      ? 'Desks accommodate one attendee.'
                      : null,
                ),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1
                    ? 'Enter a capacity of at least 1.'
                    : null,
              ),
              TextFormField(
                controller: rate,
                onFieldSubmitted: (_) => submit(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hourly rate (QAR) *',
                  hintText: 'e.g. 80.00',
                ),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || !n.isFinite || n <= 0 || n > 99999999.99) {
                    return 'Enter a rate between 0.01 and 99999999.99 QAR.';
                  }
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(v!.trim())) {
                    return 'Use up to two decimal places, e.g. 80.00.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'OUT_OF_SERVICE',
                    child: Text('Out of service'),
                  ),
                ],
                onChanged: saving ? null : (v) => setState(() => status = v!),
              ),
              if (type == 'Desk')
                DropdownButtonFormField<String>(
                  initialValue: deskType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Desk type'),
                  items:
                      {
                            ...[
                              'Regular Desk',
                              'Standing Desk',
                              'Private Desk',
                            ],
                            deskType,
                          }
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: saving
                      ? null
                      : (v) => setState(() => deskType = v!),
                ),
            ],
          ),
          if (type != 'Desk') ...[
            const SizedBox(height: 18),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Projector'),
              value: projector,
              onChanged: saving ? null : (v) => setState(() => projector = v!),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Video conference'),
              value: video,
              onChanged: saving ? null : (v) => setState(() => video = v!),
            ),
          ],
        ],
      ),
    ),
  );
}
