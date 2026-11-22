// Dashboard: owns sidebar navigation and passes selected booking details between pages.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../models/resource.dart';
import '../theme/app_theme.dart';
import 'availability.dart';
import 'new_booking.dart';
import 'bookings.dart';
import 'dashboard_home.dart';
import 'members.dart';
import 'resources.dart';

class Destination {
  final String label;
  final IconData icon;
  const Destination(this.label, this.icon);
}

const destinations = [
  Destination('Dashboard', Icons.grid_view_outlined),
  Destination('Resources', Icons.layers_outlined),
  Destination('Members', Icons.people_outline),
  Destination('Availability', Icons.event_available_outlined),
  Destination('New Booking', Icons.add_box_outlined),
  Destination('Bookings', Icons.calendar_today_outlined),
];

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;
  Booking? bookingToEdit;
  Resource? resourceToBook;
  DateTime? initialStart, initialEnd;
  int initialAttendees = 1, bookingRevision = 0;
  final searchFocus = FocusNode();

  @override
  void dispose() {
    searchFocus.dispose();
    super.dispose();
  }

  void focusSearch() {
    if (selectedIndex == 1 || selectedIndex == 2) searchFocus.requestFocus();
  }

  void navigate(int index) {
    // setState rebuilds the sidebar selection and the displayed page.
    setState(() {
      selectedIndex = index;
      if (index != 4) bookingToEdit = null;
    });
  }

  void openBooking(
    Resource resource,
    DateTime start,
    DateTime end,
    int attendees,
  ) {
    setState(() {
      bookingToEdit = null;
      resourceToBook = resource;
      initialStart = start;
      initialEnd = end;
      initialAttendees = attendees;
      bookingRevision++;
      selectedIndex = 4;
    });
  }

  void editBooking(Booking booking) {
    setState(() {
      bookingToEdit = booking;
      bookingRevision++;
      selectedIndex = 4;
    });
  }

  Widget currentPage() {
    if (selectedIndex == 0) return DashboardHome(navigate: navigate);
    if (selectedIndex == 1) return Resources(searchFocus: searchFocus);
    if (selectedIndex == 2) return Members(searchFocus: searchFocus);
    // Keep the three booking pages mounted while switching between them so drafts survive.
    return IndexedStack(
      index: selectedIndex - 3,
      children: [
        Availability(
          active: selectedIndex == 3,
          onBook: openBooking,
          onSaved: () => navigate(5),
        ),
        NewBooking(
          active: selectedIndex == 4,
          bookingToEdit: bookingToEdit,
          initialResource: resourceToBook,
          initialStart: initialStart,
          initialEnd: initialEnd,
          initialAttendees: initialAttendees,
          revision: bookingRevision,
          onSaved: () => navigate(5),
          onDiscard: () => navigate(5),
        ),
        Bookings(
          active: selectedIndex == 5,
          onEdit: editBooking,
          onNewBooking: () => navigate(4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): focusSearch,
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final expanded = box.maxWidth >= 1100;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: expanded ? 244 : 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xFFE1E3EF))),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 14 : 8,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chair_outlined,
                                color: indigo,
                                size: 32,
                              ),
                              if (expanded) ...[
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'CoWorkHub',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 20),
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Semantics(
                              selected: selectedIndex == index,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: selectedIndex == index
                                      ? const Color(0xFFEDEBFD)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(
                                    left: BorderSide(
                                      color: selectedIndex == index
                                          ? indigo
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: expanded
                                    ? TextButton(
                                        style: TextButton.styleFrom(
                                          alignment: Alignment.centerLeft,
                                          foregroundColor:
                                              selectedIndex == index
                                              ? indigo
                                              : ink,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => navigate(index),
                                        child: Row(
                                          children: [
                                            Icon(
                                              destinations[index].icon,
                                              size: 23,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                destinations[index].label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      selectedIndex == index
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : IconButton(
                                        tooltip: destinations[index].label,
                                        color: selectedIndex == index
                                            ? indigo
                                            : ink,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        onPressed: () => navigate(index),
                                        icon: Icon(destinations[index].icon),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: FocusTraversalGroup(child: currentPage())),
              ],
            );
          },
        ),
      ),
    ),
  );
}
