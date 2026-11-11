import 'package:flutter/material.dart';

import 'resources.dart';

// Creates the Dashboard screen
class Dashboard extends StatefulWidget {
  @override
  State<Dashboard> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  // Remembers which menu button is selected
  // 0 means Dashboard is selected first
  int selectedIndex = 0;
  // to store the message for each menu button
  List<String> screenNames = [
    'Welcome to CoWorkHub',
    'Resources Screen',
    'Member Management Screen',
    'Availability Screen',
    'Bookings Screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CoWorkHub Dashboard')),

      // sidebar
      body: Row(
        children: [
          // Creates the menu on the left
          NavigationRail(
            // Highlights the selected menu button
            selectedIndex: selectedIndex,
            // Runs when the user clicks a menu button
            onDestinationSelected: (index) {
              // Updates the screen
              setState(() {
                // Saves the number of the clicked button
                selectedIndex = index;
              });
            },

            // Shows the names of all menu buttons
            labelType: NavigationRailLabelType.all,

            // Creates the menu buttons
            destinations: [
              // Button 0 - Dashboard
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),

              // Button 1 - Resources
              NavigationRailDestination(
                icon: Icon(Icons.meeting_room),
                label: Text('Resources'),
              ),

              // Button 2 - Members
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Members'),
              ),

              // Button 3 - Availability
              NavigationRailDestination(
                icon: Icon(Icons.event_available),
                label: Text('Availability'),
              ),

              // Button 4 - Bookings
              NavigationRailDestination(
                icon: Icon(Icons.book_online),
                label: Text('Bookings'),
              ),
            ],
          ),

          // Uses the remaining space beside the menu
          Expanded(
            // If Resources is selected, show the Resources screen
            child: selectedIndex == 1
                ? Resources()
                // Otherwise, show the selected menu message
                : Center(
                    child: Text(
                      screenNames[selectedIndex],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
