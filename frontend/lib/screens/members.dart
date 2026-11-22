// Members page: owns list state, filters and CRUD actions; display widgets receive callbacks.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/member_api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'member_editor_dialog.dart';
import '../services/booking_api.dart';
import 'member_bookings_dialog.dart';

class Members extends StatefulWidget {
  final MemberApi? api;
  final FocusNode? searchFocus;
  final BookingApi? bookingApi;
  const Members({super.key, this.api, this.searchFocus, this.bookingApi});
  @override
  State<Members> createState() => _MembersState();
}

class _MembersState extends State<Members> {
  late final MemberApi api = widget.api ?? MemberApi();
  final search = TextEditingController();
  late final searchFocus = widget.searchFocus ?? FocusNode();
  List<Member> members = [];
  bool loading = true, deleting = false;
  String? error;
  late final BookingApi bookingApi = widget.bookingApi ?? BookingApi();

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  @override
  void dispose() {
    if (widget.api == null) api.close();
    if (widget.bookingApi == null) bookingApi.close();
    search.dispose();
    if (widget.searchFocus == null) searchFocus.dispose();
    super.dispose();
  }

  // TRACE: Members -> MemberApi.fetchAll -> GET /api/members
  // -> MemberController -> MemberService -> MemberRepository.findAll -> MySQL
  // <- 200 JSON -> Member.fromJson -> setState -> list rebuilds.
  Future<void> loadMembers() async {
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
        members = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = displayError(e);
      });
    }
  }

  // TRACE: editor -> MemberApi.create/update -> POST/PUT /api/members
  // -> MemberController -> MemberService -> MemberRepository.save -> MySQL
  // <- 201/200 -> close editor -> loadMembers -> refreshed list.
  Future<void> edit([Member? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MemberEditor(
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
    String message = 'Member added successfully';
    if (existing != null) message = 'Member updated successfully';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await loadMembers();
  }

  // TRACE: Delete -> MemberApi.delete -> DELETE /api/members/{id}
  // -> MemberController -> MemberService -> MemberRepository.delete -> MySQL
  // <- 204 -> loadMembers; 409 booking-history protection is shown to the user.
  Future<void> remove(Member member) async {
    if (deleting) return;
    final yes = await confirmAction(
      context,
      title: 'Delete member?',
      message:
          'Delete "${member.fullName}"? Members with booking history cannot be deleted.',
      confirmLabel: 'Delete',
    );
    if (!yes || !mounted) return;
    setState(() => deleting = true);
    try {
      await api.delete(member.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted successfully')),
      );
      await loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(displayError(e))));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  void viewBookings(Member member) {
    showDialog<void>(
      context: context,
      builder: (_) => MemberBookingsDialog(
        memberId: member.id,
        memberName: member.fullName,
        api: bookingApi,
      ),
    );
  }

  Widget actions(Member member) => Wrap(
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
              (m) => m.fullName.toLowerCase().contains(
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
                                          member.fullName,
                                          style: const TextStyle(
                                            color: indigo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(member.email),
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
                                        member.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        member.email,
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
