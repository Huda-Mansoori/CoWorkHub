import 'package:flutter/material.dart';
import 'members.dart';
import 'booking_workspace.dart';
import '../services/demo_catalog.dart';
import 'resources.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {

  // 1. SELECTED MENU
  int selectedIndex = 0;
  final catalog = DemoCatalog();

  // 2. MAIN SCREEN
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // 2.1 App title
      appBar: AppBar(
        title: Text('CoWorkHub Dashboard'),
      ),

      body: Row(
        children: [

          // 2.2 Sidebar menu
          NavigationRail(
            selectedIndex: selectedIndex,

            // 2.2.1 Change selected menu
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },

            labelType: NavigationRailLabelType.all,

            // 2.2.2 Menu buttons
            destinations: [
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

          // 2.3 Display selected screen
          Expanded(
            child: switch (selectedIndex) {
              0 => const Center(child: Text('Welcome to CoWorkHub', style: TextStyle(fontSize: 24))),
              1 => Resources(catalog),
              2 => Members(catalog),
              _ => BookingWorkspace(page: selectedIndex, catalog: catalog, navigate: (index) => setState(() => selectedIndex = index)),
            },
          ),
        ],
      ),
    );
  }
}