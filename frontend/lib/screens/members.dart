import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';
import '../services/booking_api.dart';
import '../services/demo_catalog.dart';
import '../services/member_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'member_bookings_dialog.dart';

class Members extends StatefulWidget {
  final DemoCatalog catalog;
  final String? apiBase;
  final FocusNode? searchFocus;
  const Members(this.catalog, {super.key, this.apiBase, this.searchFocus});
  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  late final MemberApi api = MemberApi(base: widget.apiBase);
  final bookingClient = http.Client();
  late final bookingApi = BookingApi(
    widget.apiBase ?? defaultApiBase,
    bookingClient,
  );
  final search = TextEditingController();
  late final searchFocus = widget.searchFocus ?? FocusNode();
  List<Map<String, String>> members = [];
  bool loading = true, deleting = false;
  String? error;
  bool get demo => (widget.apiBase ?? defaultApiBase).isEmpty;
  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  @override
  void dispose() {
    api.close();
    bookingClient.close();
    search.dispose();
    if (widget.searchFocus == null) searchFocus.dispose();
    super.dispose();
  }

  Future<void> loadMembers() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = demo
          ? widget.catalog.members
          : (await api.getMembers())
                .map(
                  (m) => <String, String>{
                    'id': m['id'].toString(),
                    'name': m['fullName'].toString(),
                    'email': m['email'].toString(),
                  },
                )
                .toList();
      if (mounted) {
        setState(() {
          members = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = displayError(e);
        });
      }
    }
  }

  Future<void> edit([Map<String, String>? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MemberEditor(
        existing: existing,
        onSave: (name, email) async {
          if (demo) {
            if (members.any(
              (m) =>
                  m['id'] != existing?['id'] &&
                  m['email']!.toLowerCase() == email.toLowerCase(),
            )) {
              throw Exception(
                'This email is already registered. Enter a different email address.',
              );
            }
            if (existing == null) {
              widget.catalog.members.add({
                'id': (widget.catalog.nextMemberId++).toString(),
                'name': name,
                'email': email,
              });
            } else {
              existing.addAll({'name': name, 'email': email});
            }
          } else if (existing == null) {
            await api.addMember(name, email);
          } else {
            await api.updateMember(existing['id']!, name, email);
          }
        },
      ),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null
              ? 'Member added successfully'
              : 'Member updated successfully',
        ),
      ),
    );
    await loadMembers();
  }

  Future<void> remove(Map<String, String> member) async {
    if (deleting) return;
    final yes = await confirmAction(
      context,
      title: 'Delete member?',
      message:
          'Delete "${member['name']}"? Members with booking history cannot be deleted.',
      confirmLabel: 'Delete',
    );
    if (!yes || !mounted) return;
    setState(() => deleting = true);
    try {
      if (demo) {
        if (widget.catalog.bookings.any(
          (b) => b.slot.memberId.toString() == member['id'],
        )) {
          throw Exception(
            'This member has booking history and cannot be deleted.',
          );
        }
        widget.catalog.members.remove(member);
      } else {
        await api.deleteMember(member['id']!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted successfully')),
      );
      await loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(displayError(e))));
      }
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  void viewBookings(Map<String, String> member) => showDialog<void>(
    context: context,
    builder: (_) => MemberBookingsDialog(
      memberId: int.parse(member['id']!),
      memberName: member['name']!,
      api: bookingApi,
      loader: demo
          ? () async => widget.catalog.bookings
                .where((b) => b.slot.memberId.toString() == member['id'])
                .map(
                  (b) => Booking(
                    b.id,
                    b.slot,
                    b.status,
                    b.cost,
                    resourceName: widget.catalog.resources
                        .where((r) => r['id'] == b.slot.resourceId)
                        .firstOrNull?['name'],
                  ),
                )
                .toList()
          : null,
    ),
  );

  Widget actions(Map<String, String> member) => Wrap(
    spacing: 4,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      OutlinedButton.icon(
        onPressed: deleting ? null : () => viewBookings(member),
        icon: const Icon(Icons.history, size: 18),
        label: const Text('View bookings'),
      ),
      IconButton(
        tooltip: 'Edit member',
        onPressed: deleting ? null : () => edit(member),
        color: indigo,
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Delete member',
        onPressed: deleting ? null : () => remove(member),
        color: danger,
        icon: const Icon(Icons.delete_outline),
      ),
    ],
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
        final table =
            box.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) < 19;
        final shown = members
            .where(
              (m) => m['name']!.toLowerCase().contains(
                search.text.trim().toLowerCase(),
              ),
            )
            .toList();
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, 20),
              sliver: SliverList.list(
                children: [
                  PageHeading(
                    'Members',
                    action: FilledButton.icon(
                      onPressed: loading || deleting ? null : () => edit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add member'),
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
                      labelText: 'Search members',
                      hintText: 'Search members by name',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  if (!loading && error == null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: loadMembers,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh'),
                      ),
                    ),
                ],
              ),
            ),
            if (loading)
              const SliverToBoxAdapter(
                child: ListState(loading: true, title: 'Loading members...'),
              )
            else if (error != null)
              SliverToBoxAdapter(
                child: ListState(
                  title: 'Could not load members.',
                  detail: error,
                  icon: Icons.error_outline,
                  action: loadMembers,
                ),
              )
            else if (shown.isEmpty)
              SliverToBoxAdapter(
                child: ListState(
                  title: members.isEmpty
                      ? 'No members yet'
                      : 'No matching members',
                  detail: members.isEmpty
                      ? 'Add your first member to get started.'
                      : 'Try a different name.',
                  actionLabel: members.isEmpty ? 'Add member' : 'Clear search',
                  action: members.isEmpty
                      ? () => edit()
                      : () => setState(search.clear),
                ),
              )
            else ...[
              if (table)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: SliverToBoxAdapter(
                    child: Panel(
                      padding: const EdgeInsets.all(20),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Name',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Email',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(
                            width: 290,
                            child: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, pad),
                sliver: SliverList.builder(
                  itemCount: shown.length,
                  itemBuilder: (context, index) {
                    final member = shown[index];
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFDDE0EC)),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => viewBookings(member),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: table
                                ? Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          member['name']!,
                                          style: const TextStyle(
                                            color: indigo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(member['email']!),
                                      ),
                                      SizedBox(
                                        width: 290,
                                        child: actions(member),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['name']!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        member['email']!,
                                        style: const TextStyle(
                                          color: secondaryInk,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      actions(member),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}

class MemberEditor extends StatefulWidget {
  final Map<String, String>? existing;
  final Future<void> Function(String name, String email) onSave;
  const MemberEditor({super.key, this.existing, required this.onSave});
  @override
  State<MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends State<MemberEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, email;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?['name'] ?? '');
    email = TextEditingController(text: widget.existing?['email'] ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (saving || !formKey.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave(name.text.trim(), email.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = displayError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => EditorDialog(
    title: widget.existing == null ? 'Add member' : 'Edit member',
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
          TextFormField(
            controller: name,
            onFieldSubmitted: (_) => submit(),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Member name *',
              hintText: 'e.g. Dana Ali',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Enter the member name.'
                : v.trim().length > 150
                ? 'Use 150 characters or fewer.'
                : null,
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: email,
            onFieldSubmitted: (_) => submit(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              hintText: 'e.g. dana@example.com',
            ),
            validator: (v) =>
                v == null ||
                    v.trim().length > 150 ||
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                ? 'Enter a valid email address, e.g. dana@example.com.'
                : null,
          ),
        ],
      ),
    ),
  );
}
