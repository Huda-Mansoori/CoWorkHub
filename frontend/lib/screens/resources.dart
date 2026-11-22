// Resources page: owns list state, filters and CRUD actions; display widgets receive callbacks.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/resource.dart';
import '../services/resource_api.dart';
import '../widgets/app_ui.dart';
import 'resource_editor_dialog.dart';
import '../widgets/resource_card.dart';

class Resources extends StatefulWidget {
  final ResourceApi? api;
  final FocusNode? searchFocus;
  const Resources({super.key, this.api, this.searchFocus});
  @override
  State<Resources> createState() => _ResourcesState();
}

class _ResourcesState extends State<Resources> {
  late final ResourceApi api = widget.api ?? ResourceApi();
  final search = TextEditingController();
  late final searchFocus = widget.searchFocus ?? FocusNode();
  List<Resource> resources = [];
  bool loading = true, deleting = false;
  String? error;
  String type = 'All', location = 'All locations';
  int? capacity;
  double? price;

  List<Resource> get visible {
    final result = <Resource>[];
    final query = search.text.trim().toLowerCase();
    for (final resource in resources) {
      if (!resource.name.toLowerCase().contains(query)) continue;
      if (type == 'Desk' && resource is! Desk) continue;
      if (type == 'Meeting Room' && resource is! MeetingRoom) continue;
      if (location != 'All locations' && resource.location != location) {
        continue;
      }
      if (capacity != null && resource.capacity < capacity!) continue;
      if (price != null && resource.hourlyRate > price!) continue;
      result.add(resource);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    loadResources();
  }

  @override
  void dispose() {
    if (widget.api == null) api.close();
    search.dispose();
    if (widget.searchFocus == null) searchFocus.dispose();
    super.dispose();
  }

  // TRACE: Resources -> ResourceApi.fetchAll -> GET /api/resources
  // -> ResourceController -> ResourceService -> ResourceRepository.findAll -> MySQL
  // <- 200 JSON -> Resource.fromJson -> setState -> list rebuilds.
  Future<void> loadResources() async {
    // setState schedules a rebuild using the updated loading/list/error values.
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await api.fetchAll();
      // The page may have been removed while the HTTP request was running.
      if (!mounted) return;
      setState(() {
        resources = data;
        loading = false;
      });
      if (!resources.any((r) => r.location == location)) {
        location = 'All locations';
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = displayError(e);
      });
    }
  }

  // TRACE: editor -> ResourceApi.create/update -> POST/PUT /api/resources
  // -> ResourceController -> ResourceService -> ResourceRepository.save -> MySQL
  // <- 201/200 -> close editor -> loadResources -> refreshed list.
  Future<void> edit([Resource? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResourceEditor(
        existing: existing,
        onSave: (draft) async {
          if (existing == null) {
            await api.create(draft);
          } else {
            await api.update(existing.id, draft);
          }
        },
      ),
    );
    if (saved != true || !mounted) return;
    String message = 'Resource added successfully';
    if (existing != null) message = 'Resource updated successfully';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await loadResources();
  }

  // TRACE: Delete -> ResourceApi.delete -> DELETE /api/resources/{id}
  // -> ResourceController -> ResourceService -> ResourceRepository.delete -> MySQL
  // <- 204 -> loadResources; 409 booking-history protection is shown to the user.
  Future<void> remove(Resource resource) async {
    if (deleting) return;
    final yes = await confirmAction(
      context,
      title: 'Delete resource?',
      message:
          'Delete "${resource.name}"? Resources with booking history cannot be deleted.',
      confirmLabel: 'Delete',
    );
    if (!yes || !mounted) return;
    setState(() => deleting = true);
    try {
      await api.delete(resource.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
      await loadResources();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(displayError(e))));
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
    key: ValueKey('$label-$value'),
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
        final places = resources.map((r) => r.location).toSet().toList()
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
                                    resource: rows[row * columns + col],
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
