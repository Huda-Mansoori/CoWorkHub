import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../services/demo_catalog.dart';
import '../services/resource_api.dart';
import '../widgets/app_ui.dart';
import '../widgets/resource_card.dart';

class Resources extends StatefulWidget {
  final DemoCatalog catalog;
  final String? apiBase;
  final FocusNode? searchFocus;
  const Resources(this.catalog, {super.key, this.apiBase, this.searchFocus});
  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> {
  late final ResourceApi api = ResourceApi(base: widget.apiBase);
  final search = TextEditingController();
  late final searchFocus = widget.searchFocus ?? FocusNode();
  List<Json> resources = [];
  String type = 'All', location = 'All locations';
  int? capacity;
  double? price;
  bool loading = true, deleting = false;
  String? error;
  bool get demo => (widget.apiBase ?? defaultApiBase).isEmpty;
  @override
  void initState() {
    super.initState();
    loadResources();
  }

  @override
  void dispose() {
    api.close();
    search.dispose();
    if (widget.searchFocus == null) searchFocus.dispose();
    super.dispose();
  }

  Future<void> loadResources() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = demo
          ? widget.catalog.resources
          : (await api.getResources()).map((item) => Json.from(item)).toList();
      if (!mounted) return;
      setState(() {
        resources = data;
        if (!resources.any((r) => r['location'] == location)) {
          location = 'All locations';
        }
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = displayError(e);
        });
      }
    }
  }

  List<Json> get visible => resources.where((r) {
    final desk = r['deskType'] != null;
    return r['name'].toString().toLowerCase().contains(
          search.text.trim().toLowerCase(),
        ) &&
        (type == 'All' || (desk ? 'Desk' : 'Meeting Room') == type) &&
        (location == 'All locations' || r['location'] == location) &&
        (capacity == null ||
            (desk ? 1 : (r['capacity'] as num).toInt()) >= capacity!) &&
        (price == null || (r['hourlyRate'] as num).toDouble() <= price!);
  }).toList();

  Future<void> edit([Json? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResourceEditor(
        existing: existing,
        onSave: (data) async {
          if (demo) {
            if (existing == null) {
              widget.catalog.resources.add({
                ...data,
                'id': widget.catalog.nextResourceId++,
              });
            } else {
              existing.addAll(data);
            }
          } else if (data['deskType'] != null) {
            if (existing == null) {
              await api.addDesk(data);
            } else {
              await api.updateDesk(existing['id'], data);
            }
          } else {
            if (existing == null) {
              await api.addMeetingRoom(data);
            } else {
              await api.updateMeetingRoom(existing['id'], data);
            }
          }
        },
      ),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Resource added successfully'
              : 'Resource updated successfully',
        ),
      ),
    );
    await loadResources();
  }

  Future<void> remove(Json resource) async {
    if (deleting) return;
    final yes = await confirmAction(
      context,
      title: 'Delete resource?',
      message:
          'Delete "${resource['name']}"? Resources with booking history cannot be deleted.',
      confirmLabel: 'Delete',
    );
    if (!yes || !mounted) return;
    setState(() => deleting = true);
    try {
      if (demo) {
        if (widget.catalog.bookings.any(
          (b) => b.slot.resourceId == resource['id'],
        )) {
          throw Exception(
            'This resource has booking history. Set it to Out of service instead.',
          );
        }
        widget.catalog.resources.remove(resource);
      } else {
        await api.deleteResource(resource['id']);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
      await loadResources();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
      }
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Widget filter<T>(
    String label,
    T? value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> changed,
  ) => DropdownButtonFormField<T>(
    key: ValueKey((label, value)),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: items,
    onChanged: loading ? null : (v) => setState(() => changed(v)),
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyF, control: true):
          searchFocus.requestFocus,
      const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
          searchFocus.requestFocus,
    },
    child: LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 600 ? 20.0 : 32.0;
        final width = box.maxWidth - pad * 2;
        final columns = math.max(1, (width / 310).floor());
        final rows = visible;
        final places =
            resources.map((r) => r['location'].toString()).toSet().toList()
              ..sort();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 20),
              sliver: SliverList.list(
                children: [
                  PageHeading(
                    'Resources',
                    action: FilledButton.icon(
                      onPressed: loading || deleting ? null : () => edit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add resource'),
                    ),
                  ),
                  if (deleting)
                    const LinearProgressIndicator(semanticsLabel: 'Deleting'),
                  const SizedBox(height: 28),
                  TextField(
                    controller: search,
                    autofocus: true,
                    focusNode: searchFocus,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search resources by name',
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search resources',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 18,
                      children: [
                        SizedBox(
                          width: math.min(200, width - 32),
                          child: filter<String>(
                            'Resource type',
                            type,
                            ['All', 'Meeting Room', 'Desk']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            (v) => type = v!,
                          ),
                        ),
                        SizedBox(
                          width: math.min(180, width - 32),
                          child: filter<int>(
                            'Minimum capacity',
                            capacity ?? 0,
                            [0, 1, 2, 5, 10]
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(n == 0 ? 'Any' : '$n'),
                                  ),
                                )
                                .toList(),
                            (v) => capacity = v == 0 ? null : v,
                          ),
                        ),
                        SizedBox(
                          width: math.min(200, width - 32),
                          child: filter<String>(
                            'Location',
                            location,
                            ['All locations', ...places]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            (v) => location = v!,
                          ),
                        ),
                        SizedBox(
                          width: math.min(180, width - 32),
                          child: filter<double>(
                            'Maximum price',
                            price ?? 0,
                            [0.0, 50.0, 100.0, 200.0, 500.0]
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text(
                                      n == 0 ? 'Any price' : '${n.toInt()} QAR',
                                    ),
                                  ),
                                )
                                .toList(),
                            (v) => price = v == 0 ? null : v,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!loading && error == null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: loadResources,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ),
                ],
              ),
            ),
            if (loading)
              const SliverToBoxAdapter(
                child: ListState(loading: true, title: 'Loading resources...'),
              )
            else if (error != null)
              SliverToBoxAdapter(
                child: ListState(
                  title: 'Could not load resources.',
                  detail: error,
                  icon: Icons.error_outline,
                  action: loadResources,
                ),
              )
            else if (rows.isEmpty)
              SliverToBoxAdapter(
                child: ListState(
                  title: resources.isEmpty
                      ? 'No resources yet'
                      : 'No matching resources',
                  detail: resources.isEmpty
                      ? 'Add your first resource to get started.'
                      : 'Try changing your search or filters.',
                  actionLabel: resources.isEmpty
                      ? 'Add resource'
                      : 'Clear filters',
                  action: resources.isEmpty
                      ? () => edit()
                      : () => setState(() {
                          search.clear();
                          type = 'All';
                          capacity = null;
                          price = null;
                          location = 'All locations';
                        }),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                sliver: SliverList.builder(
                  itemCount: (rows.length / columns).ceil(),
                  itemBuilder: (context, row) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var col = 0; col < columns; col++) ...[
                          if (col > 0) const SizedBox(width: 20),
                          Expanded(
                            child: row * columns + col < rows.length
                                ? ResourceCard(
                                    resource: Resource.fromJson(
                                      rows[row * columns + col],
                                    ),
                                    details: rows[row * columns + col],
                                    disabled: deleting,
                                    onEdit: () =>
                                        edit(rows[row * columns + col]),
                                    onDelete: () =>
                                        remove(rows[row * columns + col]),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ResourceEditor extends StatefulWidget {
  final Json? existing;
  final Future<void> Function(Json) onSave;
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
    name = TextEditingController(text: data?['name'] ?? '');
    location = TextEditingController(text: data?['location'] ?? '');
    capacity = TextEditingController(text: data?['capacity']?.toString() ?? '');
    rate = TextEditingController(text: data?['hourlyRate']?.toString() ?? '');
    type = data?['deskType'] != null ? 'Desk' : 'Meeting Room';
    status = data?['status'] ?? 'ACTIVE';
    deskType = data?['deskType'] ?? 'Regular Desk';
    projector = data?['projector'] ?? false;
    video = data?['videoConference'] ?? false;
    if (type == 'Desk') capacity.text = '1';
  }

  @override
  void dispose() {
    for (final c in [name, location, capacity, rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    final data = <String, dynamic>{
      'name': name.text.trim(),
      'location': location.text.trim(),
      'capacity': type == 'Desk' ? 1 : int.parse(capacity.text.trim()),
      'hourlyRate': double.parse(rate.text.trim()),
      'status': status,
      if (type == 'Desk')
        'deskType': deskType
      else ...{
        'projector': projector,
        'videoConference': video,
      },
    };
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

  String? requiredText(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required.'
      : value.trim().length > 150
      ? 'Use 150 characters or fewer.'
      : null;
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
