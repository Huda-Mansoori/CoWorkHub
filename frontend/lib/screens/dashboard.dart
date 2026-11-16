
import 'package:flutter/material.dart';
import 'members.dart';
import 'booking_workspace.dart';
import '../services/demo_catalog.dart';
import 'resources.dart';

class Dashboard extends StatefulWidget {
  final String? apiBase;

  const Dashboard({super.key, this.apiBase});

  @override
  State<Dashboard> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  // Selected menu
  int selectedIndex = 0;

  // Shared demo catalog
  final catalog = DemoCatalog();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoWorkHub Dashboard'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.meeting_room),
                label: Text('Resources'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Members'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_available),
                label: Text('Availability'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_box_outlined),
                label: Text('New Booking'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book_online),
                label: Text('Bookings'),
              ),
            ],
          ),

          Expanded(
            child: switch (selectedIndex) {
              0 => const Center(
                  child: Text(
                    'Welcome to CoWorkHub',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              1 => Resources(catalog),
              2 => Members(catalog),
              _ => BookingWorkspace(
                  page: selectedIndex,
                  catalog: catalog,
                  navigate: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  apiBase: widget.apiBase,
                ),
            },
          ),
        ],
      ),
    );
  }
}
