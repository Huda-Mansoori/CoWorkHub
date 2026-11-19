import 'package:flutter/material.dart';

import '../services/demo_catalog.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'booking_workspace.dart';
import 'members.dart';
import 'resources.dart';

const destinations = [
  (label: 'Dashboard', icon: Icons.grid_view_outlined),
  (label: 'Resources', icon: Icons.layers_outlined),
  (label: 'Members', icon: Icons.people_outline),
  (label: 'Availability', icon: Icons.event_available_outlined),
  (label: 'New Booking', icon: Icons.add_box_outlined),
  (label: 'Bookings', icon: Icons.calendar_today_outlined),
];

class Dashboard extends StatefulWidget {
  final String? apiBase;
  const Dashboard({super.key, this.apiBase});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int selectedIndex = 0;
  final catalog = DemoCatalog();

  void navigate(int index) => setState(() => selectedIndex = index);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
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
                              const Text(
                                'CoWorkHub',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 20),
                      for (var index = 0; index < destinations.length; index++)
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
                                        foregroundColor: selectedIndex == index
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
              Expanded(
                child: FocusTraversalGroup(
                  child: switch (selectedIndex) {
                    0 => DashboardHome(navigate: navigate),
                    1 => Resources(catalog),
                    2 => Members(catalog),
                    _ => BookingWorkspace(
                      page: selectedIndex,
                      catalog: catalog,
                      navigate: navigate,
                      apiBase: widget.apiBase,
                    ),
                  },
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class DashboardHome extends StatelessWidget {
  final ValueChanged<int> navigate;
  const DashboardHome({super.key, required this.navigate});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final padding = box.maxWidth < 600 ? 20.0 : 32.0;
      final available = box.maxWidth - padding * 2;
      final columns = available >= 900
          ? 3
          : available >= 570
          ? 2
          : 1;
      final width = (available - (columns - 1) * 20) / columns;
      return ListView(
        padding: EdgeInsets.all(padding),
        children: [
          const PageHeading('Dashboard'),
          const SizedBox(height: 32),
          Text(
            'Welcome to CoWorkHub',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final item in [
                (
                  title: 'Resources',
                  button: 'View resources',
                  page: 1,
                  desk: false,
                  image: 1,
                  icon: Icons.meeting_room_outlined,
                ),
                (
                  title: 'Members',
                  button: 'View members',
                  page: 2,
                  desk: true,
                  image: 2,
                  icon: Icons.people_outline,
                ),
                (
                  title: 'Bookings',
                  button: 'View bookings',
                  page: 5,
                  desk: false,
                  image: 2,
                  icon: Icons.calendar_today_outlined,
                ),
              ])
                SizedBox(
                  width: width,
                  child: Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ResourcePhoto(
                          isDesk: item.desk,
                          id: item.image,
                          height: 180,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(item.icon, color: indigo),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => navigate(item.page),
                          child: Text(item.button),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Panel(
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.event_available_outlined,
                  color: indigo,
                  size: 36,
                ),
                const Text(
                  'Find a workspace for your next booking.',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                FilledButton.icon(
                  onPressed: () => navigate(3),
                  icon: const Icon(Icons.search),
                  label: const Text('Check availability'),
                ),
                OutlinedButton.icon(
                  onPressed: () => navigate(4),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('New booking'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
